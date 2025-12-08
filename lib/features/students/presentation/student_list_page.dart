import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/animations.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/student.dart';
import '../../../data/repositories/supabase/student_repository.dart';

class StudentListPage extends ConsumerStatefulWidget {
  const StudentListPage({super.key});

  @override
  ConsumerState<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends ConsumerState<StudentListPage> {
  String _searchQuery = '';
  StudentStatus? _statusFilter;
  StudentLevel? _levelFilter;
  Map<String, dynamic> _stats = const {
    'total': 0,
    'active': 0,
    'graduated': 0,
  };
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = ref.read(supabaseStudentRepositoryProvider).watchStudents();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学员管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddStudentDialog,
            tooltip: '添加学员',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsRow(_stats),
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<Student>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
                    child: ASSkeletonList(itemCount: 6),
                  );
                }

                var students = snapshot.data ?? [];

                // 过滤
                if (_statusFilter != null) {
                  students = students.where((s) => s.status == _statusFilter).toList();
                }
                if (_levelFilter != null) {
                  students = students.where((s) => s.level == _levelFilter).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  students = students
                      .where((s) =>
                          s.fullName.toLowerCase().contains(q) ||
                          (s.parentName?.toLowerCase().contains(q) ?? false))
                      .toList();
                }

                _stats = _computeStats(students);

                if (students.isEmpty) {
                  return const ASEmptyState(
                    type: ASEmptyStateType.noData,
                    title: '暂无学员',
                    description: '可添加学员或调整筛选条件',
                    icon: Icons.person_off,
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding),
                  child: ASStaggeredColumn(
                    children: students.map((student) => _StudentCard(
                      student: student,
                      onTap: () => context.goNamed(
                        'student-detail',
                        pathParameters: {'studentId': student.id},
                        extra: student,
                      ),
                    )).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    final cards = [
      ASStatCard(
        title: '总学员',
        value: stats['total'],
        icon: Icons.people,
        color: theme.colorScheme.primary,
      ),
      ASStatCard(
        title: '活跃',
        value: stats['active'],
        icon: Icons.check_circle,
        color: ASColors.success,
      ),

      ASStatCard(
        title: '已结业',
        value: stats['graduated'],
        icon: Icons.school,
        color: ASColors.info,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(ASSpacing.pagePadding),
      child: ASResponsiveWrap(
        spacing: ASSpacing.md,
        runSpacing: ASSpacing.md,
        children: cards
            .map((card) => SizedBox(
                  width: 240,
                  child: card,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ASSpacing.pagePadding, vertical: ASSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ASSearchField(
              controller: _searchController,
              hint: '搜索学员姓名或家长...',
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () => setState(() => _searchQuery = ''),
            ),
          ),
          const SizedBox(width: ASSpacing.md),
          Expanded(
            child: DropdownButtonFormField<StudentStatus?>(
              value: _statusFilter,
              decoration: InputDecoration(
                labelText: '状态',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('全部')),
                ...StudentStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(getStudentStatusName(status)),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _statusFilter = value);
              },
            ),
          ),
          const SizedBox(width: ASSpacing.md),
          Expanded(
            child: DropdownButtonFormField<StudentLevel?>(
              value: _levelFilter,
              decoration: InputDecoration(
                labelText: '等级',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('全部')),
                ...StudentLevel.values.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(getStudentLevelName(level)),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _levelFilter = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog() {
    _showStudentFormDialog(null);
  }

  void _showStudentFormDialog(Student? student) {
    final isEditing = student != null;
    final nameController = TextEditingController(text: student?.fullName ?? '');
    final parentNameController = TextEditingController(text: student?.parentName ?? '');
    final phoneController = TextEditingController(text: student?.emergencyPhone ?? '');
    StudentLevel selectedLevel = student?.level ?? StudentLevel.beginner;
    String selectedGender = student?.gender ?? '男';
    DateTime? selectedBirthDate = student?.birthDate;
    StudentStatus selectedStatus = student?.status ?? StudentStatus.active;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? '编辑学员' : '添加学员'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '学员姓名 *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final now = DateTime.now();
                            final initial = selectedBirthDate ??
                                DateTime(now.year - 10, now.month, now.day);
                            final first = DateTime(now.year - 18, 1, 1);
                            final last = DateTime(now.year, now.month, now.day);

                            final picked = await showDatePicker(
                              context: context,
                              initialDate: initial,
                              firstDate: first,
                              lastDate: last,
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedBirthDate = picked;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '出生日期 *',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              selectedBirthDate == null
                                  ? '请选择出生日期'
                                  : '${selectedBirthDate!.year}-${selectedBirthDate!.month}-${selectedBirthDate!.day}',
                              style: TextStyle(
                                color: selectedBirthDate == null
                                    ? Colors.grey.shade500
                                    : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedGender,
                          decoration: const InputDecoration(
                            labelText: '性别',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '男', child: Text('男')),
                            DropdownMenuItem(value: '女', child: Text('女')),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedGender = value ?? '男';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<StudentLevel>(
                          value: selectedLevel,
                          decoration: const InputDecoration(
                            labelText: '等级',
                            border: OutlineInputBorder(),
                          ),
                          items: StudentLevel.values.map((level) {
                            return DropdownMenuItem(
                              value: level,
                              child: Text(getStudentLevelName(level)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedLevel = value ?? StudentLevel.beginner;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isEditing) ...[
                    DropdownButtonFormField<StudentStatus>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: '状态',
                        border: OutlineInputBorder(),
                      ),
                      items: StudentStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(getStudentStatusName(status)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: parentNameController,
                    decoration: const InputDecoration(
                      labelText: '家长姓名 *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: '紧急电话 *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton.icon(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    parentNameController.text.trim().isEmpty ||
                    phoneController.text.trim().isEmpty ||
                    selectedBirthDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写必填项（含出生日期）')),
                  );
                  return;
                }

                Navigator.pop(context);
                final newStudent = _buildStudentFromForm(
                  student,
                  nameController.text.trim(),
                  selectedGender,
                  selectedLevel,
                  parentNameController.text.trim(),
                  phoneController.text.trim(),
                  selectedBirthDate!,
                  status: selectedStatus,
                );
                await _saveStudent(newStudent, isEditing);
              },
              icon: const Icon(Icons.save),
              label: Text(isEditing ? '保存' : '添加'),
            ),
          ],
        ),
      ),
    );
  }

  Student _buildStudentFromForm(
    Student? original,
    String name,
    String gender,
    StudentLevel level,
    String parentName,
    String emergencyPhone,
    DateTime birthDate,
    {required StudentStatus status}) {
    final now = DateTime.now();
    return Student(
      id: original?.id ?? 'student-${now.millisecondsSinceEpoch}',
      fullName: name,
      gender: gender,
      level: level,
      status: status,
      parentName: parentName.isEmpty ? null : parentName,
      emergencyPhone: emergencyPhone.isEmpty ? null : emergencyPhone,
      birthDate: birthDate,
      enrollmentDate: original?.enrollmentDate ?? now,
      remainingSessions: original?.remainingSessions ?? 0,
      totalSessions: original?.totalSessions ?? 0,
      attendanceRate: original?.attendanceRate ?? 0,
      notes: original?.notes,
      avatarUrl: original?.avatarUrl,
      phoneNumber: original?.phoneNumber,
      emergencyContact: original?.emergencyContact,
      parentId: original?.parentId,
      classIds: original?.classIds ?? const [],
      createdAt: original?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _saveStudent(Student student, bool isEditing) async {
    try {
      if (isEditing) {
        await ref.read(supabaseStudentRepositoryProvider).updateStudent(student);
      } else {
        await ref.read(supabaseStudentRepositoryProvider).createStudent(student);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存学员失败：$e')),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? '学员信息已更新' : '学员添加成功')),
      );
    }
  }

  Map<String, dynamic> _computeStats(List<Student> students) {
    final total = students.length;
    final active = students.where((s) => s.status == StudentStatus.active).length;
    final graduated = students.where((s) => s.status == StudentStatus.graduated).length;
    return {
      'total': total,
      'active': active,
      'graduated': graduated,
    };
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return ASCard(
      margin: const EdgeInsets.symmetric(vertical: 8),
      onTap: onTap,
      child: Row(
        children: [
          ASAvatar(
            imageUrl: student.avatarUrl,
            name: student.fullName,
            size: ASAvatarSize.lg,
            showBorder: true,
            backgroundColor:
                student.avatarUrl == null ? primaryColor.withValues(alpha: 0.1) : null,
            foregroundColor: student.avatarUrl == null ? primaryColor : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        student.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _buildStatusBadge(student.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${student.age ?? '-'}岁 · '
                  '${student.gender ?? '未知'} · '
                  '${getStudentLevelName(student.level)} · '
                  '${student.parentName ?? '家长未知'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

              Text(
                '出勤率 ${(student.attendanceRate * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(StudentStatus status) {
    return ASTag(
      label: getStudentStatusName(status),
      type: switch (status) {
        StudentStatus.active => ASTagType.success,
        StudentStatus.inactive => ASTagType.warning,
        StudentStatus.graduated => ASTagType.info,
        StudentStatus.suspended => ASTagType.error,
      },
    );
  }
}
