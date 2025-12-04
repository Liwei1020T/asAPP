import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/student.dart';
import '../../../data/repositories/supabase/student_repository.dart';

/// 选择学生对话框（支持多选）
class SelectStudentDialog extends ConsumerStatefulWidget {
  const SelectStudentDialog({super.key, required this.existing});

  final List<Student> existing;

  static Future<List<Student>?> show(BuildContext context, List<Student> existing) {
    return showDialog<List<Student>>(
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
  final Set<String> _selectedIds = {};
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

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _submit() {
    final selected = _students.where((s) => _selectedIds.contains(s.id)).toList();
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
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
                              final isSelected = _selectedIds.contains(student.id);
                              return InkWell(
                                onTap: () => _toggleSelection(student.id),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? ASColors.primary.withValues(alpha: 0.05) : null,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected ? Border.all(color: ASColors.primary) : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (v) => _toggleSelection(student.id),
                                      ),
                                      const SizedBox(width: 8),
                                      ASAvatar(
                                        name: student.fullName,
                                        size: ASAvatarSize.sm,
                                        showBorder: true,
                                        backgroundColor: ASColors.info.withValues(alpha: 0.1),
                                        foregroundColor: ASColors.info,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student.fullName,
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              '剩余课时 ${student.remainingSessions} / ${student.totalSessions}',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: ASSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '已选 ${_selectedIds.length} 人',
                    style: const TextStyle(color: ASColors.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _selectedIds.isEmpty ? null : _submit,
                    child: const Text('确认添加'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
