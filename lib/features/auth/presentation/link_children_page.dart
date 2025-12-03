import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/animations.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/as_primary_button.dart';
import '../../../data/models/student.dart';
import '../../../data/repositories/supabase/auth_repository.dart';
import '../application/auth_providers.dart';

/// 绑定孩子页面
/// 家长验证邮箱后进入此页面，系统自动匹配孩子并支持手动绑定
class LinkChildrenPage extends ConsumerStatefulWidget {
  final String phoneNumber;

  const LinkChildrenPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<LinkChildrenPage> createState() => _LinkChildrenPageState();
}

class _LinkChildrenPageState extends ConsumerState<LinkChildrenPage> {
  bool _isLoading = true;
  bool _isBinding = false;
  bool _isSearching = false;

  // 自动匹配到的学生列表
  List<Student> _matchedStudents = [];
  // 选中的学生ID
  final Set<String> _selectedStudentIds = {};
  // 已绑定的学生列表
  List<Student> _linkedStudents = [];

  // 手动搜索表单
  final _searchFormKey = GlobalKey<FormState>();
  final _searchNameController = TextEditingController();
  final _searchPhoneController = TextEditingController();
  List<Student> _searchResults = [];
  bool _showSearchForm = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchNameController.dispose();
    _searchPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(supabaseAuthRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);

      if (currentUser == null) {
        if (mounted) {
          context.go('/login');
        }
        return;
      }

      // 获取已绑定的学生
      final linkedStudents = await authRepo.getLinkedStudents(currentUser.id);

      // 根据手机号自动匹配学生
      List<Student> matchedStudents = [];
      if (widget.phoneNumber.isNotEmpty) {
        matchedStudents = await authRepo.findStudentsByPhone(widget.phoneNumber);
        // 排除已绑定的学生
        final linkedIds = linkedStudents.map((s) => s.id).toSet();
        matchedStudents = matchedStudents
            .where((s) => !linkedIds.contains(s.id) && s.parentId == null)
            .toList();
      }

      if (mounted) {
        setState(() {
          _linkedStudents = linkedStudents;
          _matchedStudents = matchedStudents;
          // 默认选中所有匹配到的学生
          _selectedStudentIds.addAll(matchedStudents.map((s) => s.id));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败：$e')),
        );
      }
    }
  }

  Future<void> _bindSelectedStudents() async {
    if (_selectedStudentIds.isEmpty) {
      _navigateToDashboard();
      return;
    }

    setState(() => _isBinding = true);

    try {
      final authRepo = ref.read(supabaseAuthRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);

      if (currentUser == null) {
        throw Exception('用户未登录');
      }

      await authRepo.bindStudentsToParent(
        parentId: currentUser.id,
        studentIds: _selectedStudentIds.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功绑定 ${_selectedStudentIds.length} 个孩子'),
            backgroundColor: Colors.green,
          ),
        );
        _navigateToDashboard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('绑定失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBinding = false);
      }
    }
  }

  Future<void> _searchStudents() async {
    if (!_searchFormKey.currentState!.validate()) return;

    setState(() => _isSearching = true);

    try {
      final authRepo = ref.read(supabaseAuthRepositoryProvider);
      final results = await authRepo.findStudentsByNameAndPhone(
        fullName: _searchNameController.text.trim(),
        phoneNumber: _searchPhoneController.text.trim(),
      );

      // 排除已绑定的学生和已在匹配列表中的学生
      final excludeIds = {
        ..._linkedStudents.map((s) => s.id),
        ..._matchedStudents.map((s) => s.id),
      };
      
      final filteredResults = results
          .where((s) => !excludeIds.contains(s.id) && s.parentId == null)
          .toList();

      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
          _isSearching = false;
        });

        if (filteredResults.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未找到匹配的学生')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜索失败：$e')),
        );
      }
    }
  }

  void _addSearchResultToSelected(Student student) {
    setState(() {
      _matchedStudents.add(student);
      _selectedStudentIds.add(student.id);
      _searchResults.remove(student);
    });
  }

  void _navigateToDashboard() {
    context.go('/parent-dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(ASSpacing.xl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(theme),
                        const SizedBox(height: ASSpacing.xxl),
                        if (_linkedStudents.isNotEmpty) ...[
                          _buildLinkedStudentsSection(theme),
                          const SizedBox(height: ASSpacing.xl),
                        ],
                        if (_matchedStudents.isNotEmpty) ...[
                          _buildMatchedStudentsSection(theme),
                          const SizedBox(height: ASSpacing.xl),
                        ],
                        _buildManualSearchSection(theme),
                        const SizedBox(height: ASSpacing.xxl),
                        _buildActions(theme),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.family_restroom,
            size: 48,
            color: primaryColor,
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: ASAnimations.medium,
              curve: ASAnimations.emphasizeCurve,
            )
            .fadeIn(duration: ASAnimations.normal),
        const SizedBox(height: ASSpacing.lg),
        Text(
          '绑定您的孩子',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        )
            .animate(delay: 100.ms)
            .fadeIn(duration: ASAnimations.normal)
            .slideY(begin: 0.3, end: 0),
        const SizedBox(height: ASSpacing.sm),
        Text(
          '绑定后您可以查看孩子的训练动态和进度',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
          textAlign: TextAlign.center,
        )
            .animate(delay: 150.ms)
            .fadeIn(duration: ASAnimations.normal),
      ],
    );
  }

  Widget _buildLinkedStudentsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: ASSpacing.sm),
            Text(
              '已绑定的孩子',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: ASSpacing.md),
        ...List.generate(_linkedStudents.length, (index) {
          final student = _linkedStudents[index];
          return _buildStudentCard(
            theme,
            student,
            isLinked: true,
          ).animate(delay: (200 + index * 50).ms).fadeIn().slideX(begin: -0.1);
        }),
      ],
    );
  }

  Widget _buildMatchedStudentsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: ASSpacing.sm),
            Text(
              '自动匹配到的孩子',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: ASSpacing.xs),
        Text(
          '根据您的手机号 ${widget.phoneNumber} 匹配到以下学生，请确认绑定：',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: ASSpacing.md),
        ...List.generate(_matchedStudents.length, (index) {
          final student = _matchedStudents[index];
          final isSelected = _selectedStudentIds.contains(student.id);
          return _buildStudentCard(
            theme,
            student,
            isSelected: isSelected,
            onToggle: () {
              setState(() {
                if (isSelected) {
                  _selectedStudentIds.remove(student.id);
                } else {
                  _selectedStudentIds.add(student.id);
                }
              });
            },
          ).animate(delay: (250 + index * 50).ms).fadeIn().slideX(begin: -0.1);
        }),
      ],
    );
  }

  Widget _buildStudentCard(
    ThemeData theme,
    Student student, {
    bool isLinked = false,
    bool isSelected = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: ASSpacing.sm),
      decoration: BoxDecoration(
        color: isLinked
            ? Colors.green.withValues(alpha: 0.1)
            : isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
        border: Border.all(
          color: isLinked
              ? Colors.green
              : isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          child: Text(
            student.fullName.isNotEmpty ? student.fullName[0] : '?',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.fullName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (student.phoneNumber != null)
              Text('电话：${student.phoneNumber}'),
            Text('等级：${getStudentLevelName(student.level)}'),
          ],
        ),
        trailing: isLinked
            ? const Icon(Icons.check_circle, color: Colors.green)
            : onToggle != null
                ? Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggle(),
                    activeColor: theme.colorScheme.primary,
                  )
                : IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: theme.colorScheme.primary,
                    onPressed: () => _addSearchResultToSelected(student),
                  ),
        onTap: isLinked ? null : onToggle,
      ),
    );
  }

  Widget _buildManualSearchSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showSearchForm = !_showSearchForm;
            });
          },
          borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
          child: Container(
            padding: const EdgeInsets.all(ASSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: ASSpacing.sm),
                Expanded(
                  child: Text(
                    '手动搜索绑定孩子',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  _showSearchForm
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ],
            ),
          ),
        )
            .animate(delay: 300.ms)
            .fadeIn(duration: ASAnimations.normal),
        if (_showSearchForm) ...[
          const SizedBox(height: ASSpacing.md),
          Container(
            padding: const EdgeInsets.all(ASSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
            ),
            child: Form(
              key: _searchFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _searchNameController,
                    decoration: const InputDecoration(
                      labelText: '孩子姓名',
                      hintText: '请输入孩子的姓名',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    validator: NameValidator.getErrorMessage,
                  ),
                  const SizedBox(height: ASSpacing.md),
                  TextFormField(
                    controller: _searchPhoneController,
                    decoration: const InputDecoration(
                      labelText: '联系电话',
                      hintText: '孩子或紧急联系人的电话',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: PhoneValidator.getErrorMessage,
                  ),
                  const SizedBox(height: ASSpacing.lg),
                  ASPrimaryButton(
                    label: '搜索',
                    onPressed: _searchStudents,
                    isLoading: _isSearching,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: ASAnimations.fast)
              .slideY(begin: -0.1, end: 0),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: ASSpacing.md),
            Text(
              '搜索结果：',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ASSpacing.sm),
            ...List.generate(_searchResults.length, (index) {
              final student = _searchResults[index];
              return _buildStudentCard(
                theme,
                student,
              ).animate(delay: (50 * index).ms).fadeIn().slideX(begin: -0.1);
            }),
          ],
        ],
      ],
    );
  }

  Widget _buildActions(ThemeData theme) {
    final hasSelection = _selectedStudentIds.isNotEmpty;

    return Column(
      children: [
        ASPrimaryButton(
          label: hasSelection
              ? '绑定选中的 ${_selectedStudentIds.length} 个孩子'
              : '跳过，稍后绑定',
          onPressed: _bindSelectedStudents,
          isLoading: _isBinding,
          isFullWidth: true,
          height: 52,
          animate: true,
          animationDelay: 350.ms,
        ),
        if (hasSelection) ...[
          const SizedBox(height: ASSpacing.md),
          TextButton(
            onPressed: _navigateToDashboard,
            child: Text(
              '跳过，稍后绑定',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          )
              .animate(delay: 400.ms)
              .fadeIn(duration: ASAnimations.normal),
        ],
      ],
    );
  }
}
