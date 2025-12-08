import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/animations.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/student.dart';
import '../../../data/repositories/supabase/auth_repository.dart';
import '../application/auth_providers.dart';

/// 绑定孩子页面 - 现代化重构版
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

  List<Student> _matchedStudents = [];
  final Set<String> _selectedStudentIds = {};
  List<Student> _linkedStudents = [];

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
        if (mounted) context.go('/login');
        return;
      }

      final linkedStudents = await authRepo.getLinkedStudents(currentUser.id);

      List<Student> matchedStudents = [];
      if (widget.phoneNumber.isNotEmpty) {
        matchedStudents = await authRepo.findStudentsByPhone(widget.phoneNumber);
        final linkedIds = linkedStudents.map((s) => s.id).toSet();
        matchedStudents = matchedStudents
            .where((s) => !linkedIds.contains(s.id) && s.parentId == null)
            .toList();
      }

      if (mounted) {
        setState(() {
          _linkedStudents = linkedStudents;
          _matchedStudents = matchedStudents;
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

      if (currentUser == null) throw Exception('用户未登录');

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
      body: Stack(
        children: [
          // 动态背景
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFFF5F7FA), const Color(0xFFE4E9F2)],
                ),
              ),
            ),
          ),
          
          // 装饰性背景圆
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ).animate().scale(duration: 2.seconds, curve: Curves.easeInOut).fadeIn(),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ASSpacing.xl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _isLoading
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: const [
                            ASSkeletonProfileCard(),
                            SizedBox(height: ASSpacing.md),
                            ASSkeletonProfileCard(),
                            SizedBox(height: ASSpacing.md),
                            ASSkeletonProfileCard(),
                          ],
                        ).animate().fadeIn()
                      : ASStaggeredColumn(
                          animate: true,
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
                            if (_linkedStudents.isEmpty && _matchedStudents.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: ASSpacing.xl),
                                child: ASEmptyState(
                                  type: ASEmptyStateType.noData,
                                  title: '未找到可绑定的孩子',
                                  description: '您可以手动搜索孩子姓名或电话进行绑定',
                                  icon: Icons.family_restroom,
                                  actionLabel: _showSearchForm ? null : '手动搜索',
                                  onAction: () => setState(() => _showSearchForm = true),
                                ),
                              ),
                            _buildManualSearchSection(theme),
                            const SizedBox(height: ASSpacing.xxl),
                            _buildActions(theme),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;

    return ASGlassContainer.adaptive(
      padding: const EdgeInsets.all(ASSpacing.xl),
      blur: ASColors.glassBlurSigma,
      opacity: 0.9,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.family_restroom,
              size: 48,
              color: primaryColor,
            ),
          ).animate().scale(duration: ASAnimations.medium, curve: ASAnimations.emphasized),
          const SizedBox(height: ASSpacing.lg),
          Text(
            '绑定您的孩子',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: ASSpacing.sm),
          Text(
            '绑定后您可以查看孩子的训练动态和进度',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
          );
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
          );
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
    final borderColor = isLinked
        ? Colors.green
        : isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.surface;

    return ASCard.glass(
      margin: const EdgeInsets.only(bottom: ASSpacing.sm),
      borderColor: borderColor,
      borderWidth: isLinked || isSelected ? 1.5 : 1,
      glassOpacity: 0.85,
      onTap: isLinked ? null : onToggle,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: ASAvatar(
          name: student.fullName,
          size: ASAvatarSize.sm,
          showBorder: true,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          foregroundColor: theme.colorScheme.primary,
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
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
        ),
        if (_showSearchForm) ...[
          const SizedBox(height: ASSpacing.md),
          Container(
            padding: const EdgeInsets.all(ASSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
            child: Form(
              key: _searchFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ASTextField(
                    controller: _searchNameController,
                    label: '孩子姓名',
                    hint: '请输入孩子的姓名',
                    prefixIcon: Icons.person_outlined,
                    validator: NameValidator.getErrorMessage,
                  ),
                  const SizedBox(height: ASSpacing.md),
                  ASTextField(
                    controller: _searchPhoneController,
                    label: '联系电话',
                    hint: '孩子或紧急联系人的电话',
                    prefixIcon: Icons.phone_outlined,
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
          ).animate().fadeIn().slideY(begin: -0.1, end: 0),
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
              );
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
          ),
        ],
      ],
    );
  }
}
