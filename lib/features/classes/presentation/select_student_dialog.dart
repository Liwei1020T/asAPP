import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
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
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '按姓名搜索',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _onSearch,
              ),
              const SizedBox(height: ASSpacing.md),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filtered.isEmpty
                        ? const Center(child: Text('没有可添加的学员'))
                        : ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: ASSpacing.sm),
                            itemBuilder: (context, index) {
                              final student = _filtered[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: ASColors.info.withOpacity(0.1),
                                  child: Text(
                                    student.fullName.substring(0, 1),
                                    style: const TextStyle(
                                      color: ASColors.info,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
