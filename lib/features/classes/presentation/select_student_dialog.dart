import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/student.dart';
import '../../../data/repositories/supabase/student_repository.dart';

/// 选择学生对话框
class SelectStudentDialog extends ConsumerStatefulWidget {
  const SelectStudentDialog({required this.existing});

  final List<Student> existing;

  static Future<Student?> show(BuildContext context, List<Student> existing) {
    return showDialog<Student>(
      context: context,
      builder: (_) => SelectStudentDialog(existing: existing),
    );
  }

  @override
  ConsumerState<SelectStudentDialog> createState() => _SelectStudentDialogState();
}

class _SelectStudentDialogState extends ConsumerState<SelectStudentDialog> {
  List<Student> _students = [];
  List<Student> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final rows = await ref.read(supabaseStudentRepositoryProvider).fetchStudents();
      _students = rows;
    } catch (e) {
      _students = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载学员失败：$e')),
        );
      }
    }

    // 过滤掉已在班级的学生
    _students = _students
        .where((s) => !widget.existing.any((exist) => exist.id == s.id))
        .toList();
    _filtered = _students;

    if (mounted) setState(() => _isLoading = false);
  }

  void _onSearch(String keyword) {
    setState(() {
      _filtered = _students
          .where((s) => s.fullName.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(ASSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '选择学员',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: ASSpacing.md),
              ASSearchField(
                controller: _searchController,
                hint: '按姓名搜索',
                onChanged: _onSearch,
                onClear: () => _onSearch(''),
              ),
              const SizedBox(height: ASSpacing.md),
              Expanded(
                child: _isLoading
                    ? const Center(child: ASSkeletonList(itemCount: 5, hasAvatar: true))
                    : _filtered.isEmpty
                        ? const ASEmptyState(
                            type: ASEmptyStateType.noData,
                            title: '没有可添加的学员',
                            description: '请检查筛选或先创建学员',
                            icon: Icons.person_off,
                          )
                        : ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: ASSpacing.sm),
                            itemBuilder: (context, index) {
                              final student = _filtered[index];
                              return ListTile(
                                leading: ASAvatar(
                                  name: student.fullName,
                                  size: ASAvatarSize.sm,
                                  showBorder: true,
                                  backgroundColor: ASColors.info.withValues(alpha: 0.1),
                                  foregroundColor: ASColors.info,
                                ),
                                title: Text(student.fullName),
                                subtitle: Text(
                                  '剩余课时 ${student.remainingSessions} / ${student.totalSessions}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                trailing: TextButton(
                                  onPressed: () => Navigator.of(context).pop(student),
                                  child: const Text('选择'),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
