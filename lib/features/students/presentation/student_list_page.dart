import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/student.dart';
import '../../../data/repositories/supabase/student_repository.dart';
import '../../../data/repositories/supabase/storage_repository.dart';

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
    'lowBalance': 0,
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
                    padding: EdgeInsets.symmetric(horizontal: 16),
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

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return _StudentCard(
                      student: student,
                      onTap: () => _showStudentDetail(student),
                      animationIndex: index,
                    );
                  },
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
        animationIndex: 0,
      ),
      ASStatCard(
        title: '活跃',
        value: stats['active'],
        icon: Icons.check_circle,
        color: Colors.green,
        animationIndex: 1,
      ),
      ASStatCard(
        title: '课时不足',
        value: stats['lowBalance'],
        icon: Icons.warning,
        color: Colors.orange,
        animationIndex: 2,
      ),
      ASStatCard(
        title: '已结业',
        value: stats['graduated'],
        icon: Icons.school,
        color: Colors.blue,
        animationIndex: 3,
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

  void _showStudentDetail(Student student) {
    String? avatarUrl = student.avatarUrl;
    bool isUploadingAvatar = false;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              child: Container(
                width: 600,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ASAvatar(
                            imageUrl: avatarUrl,
                            name: student.fullName,
                            size: ASAvatarSize.xl,
                            showBorder: true,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      student.fullName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatusChip(student.status),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${student.age ?? '-'}岁 · ${student.gender ?? '未知'} · ${getStudentLevelName(student.level)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              OutlinedButton.icon(
                                onPressed: isUploadingAvatar
                                    ? null
                                    : () async {
                                        setDialogState(() {
                                          isUploadingAvatar = true;
                                        });
                                        final url = await _uploadStudentAvatar(student);
                                        setDialogState(() {
                                          isUploadingAvatar = false;
                                          if (url != null) {
                                            avatarUrl = url;
                                          }
                                        });
                                      },
                                icon: isUploadingAvatar
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.camera_alt_outlined),
                                label: Text(isUploadingAvatar ? '上传中...' : '更换头像'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildDetailSection('课时信息', [
                        _DetailRow(label: '剩余课时', value: '${student.remainingSessions}节'),
                        _DetailRow(label: '总课时', value: '${student.totalSessions}节'),
                        _DetailRow(
                          label: '出勤率',
                          value: '${(student.attendanceRate * 100).toStringAsFixed(1)}%',
                        ),
                      ]),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('课时余额'),
                              Text(
                                '${student.remainingSessions}/${student.totalSessions}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: student.sessionBalancePercent,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              student.remainingSessions <= 5 ? Colors.orange : ASColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildDetailSection('联系信息', [
                        _DetailRow(label: '家长', value: student.parentName ?? '-'),
                        _DetailRow(label: '紧急联系人', value: student.emergencyContact ?? '-'),
                        _DetailRow(label: '紧急电话', value: student.emergencyPhone ?? '-'),
                        if (student.phoneNumber != null)
                          _DetailRow(label: '学员电话', value: student.phoneNumber!),
                      ]),
                      const SizedBox(height: 24),
                      _buildDetailSection('其他信息', [
                        _DetailRow(label: '入学日期', value: _formatDate(student.enrollmentDate)),
                        if (student.notes != null && student.notes!.isNotEmpty)
                          _DetailRow(label: '备注', value: student.notes!),
                      ]),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('关闭'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditStudentDialog(student);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('编辑'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildStatusChip(StudentStatus status) {
    Color color;
    switch (status) {
      case StudentStatus.active:
        color = Colors.green;
        break;
      case StudentStatus.inactive:
        color = Colors.orange;
        break;
      case StudentStatus.graduated:
        color = Colors.blue;
        break;
      case StudentStatus.suspended:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        getStudentStatusName(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showAddStudentDialog() {
    _showStudentFormDialog(null);
  }

  void _showEditStudentDialog(Student student) {
    _showStudentFormDialog(student);
  }

  Future<String?> _uploadStudentAvatar(Student student) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) {
      return null;
    }

    final bytes = result.files.first.bytes as Uint8List;
    final fileName = result.files.first.name;
    final storageRepo = ref.read(supabaseStorageRepositoryProvider);
    final studentRepo = ref.read(supabaseStudentRepositoryProvider);
    final path = 'avatars/students/${student.id}/${DateTime.now().millisecondsSinceEpoch}-$fileName';

    try {
      final url = await storageRepo.uploadBytes(
        bytes: bytes,
        bucket: 'avatars',
        path: path,
        fileOptions: FileOptions(
          upsert: false,
          contentType: 'image/jpeg',
        ),
      );

      final updated = student.copyWith(
        avatarUrl: url,
        updatedAt: DateTime.now(),
      );
      await studentRepo.updateStudent(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像已更新')),
        );
      }

      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败：$e')),
        );
      }
      return null;
    }
  }

  void _showStudentFormDialog(Student? student) {
    final isEditing = student != null;
    final nameController = TextEditingController(text: student?.fullName ?? '');
    final parentNameController = TextEditingController(text: student?.parentName ?? '');
    final phoneController = TextEditingController(text: student?.emergencyPhone ?? '');
    final totalSessionsController = TextEditingController(
      text: student != null && student.totalSessions > 0
          ? student.totalSessions.toString()
          : '',
    );
    final remainingSessionsController = TextEditingController(
      text: student != null && student.remainingSessions > 0
          ? student.remainingSessions.toString()
          : '',
    );
    StudentLevel selectedLevel = student?.level ?? StudentLevel.beginner;
    String selectedGender = student?.gender ?? '男';
    DateTime? selectedBirthDate = student?.birthDate;
    StudentStatus selectedStatus = student?.status ?? StudentStatus.active;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? '编辑学员' : '添加学员',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
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
                                : _formatDate(selectedBirthDate!),
                            style: TextStyle(
                              color: selectedBirthDate == null
                                  ? Colors.grey.shade500
                                  : Colors.black,
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
                const SizedBox(height: 16),
                const Text(
                  '课时设置',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: totalSessionsController,
                        decoration: const InputDecoration(
                          labelText: '本月总课时（节） *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: remainingSessionsController,
                        decoration: const InputDecoration(
                          labelText: '当前剩余课时（节）',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
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

                        final totalText = totalSessionsController.text.trim();
                        final remainingText = remainingSessionsController.text.trim();
                        final total = int.tryParse(totalText);
                        if (total == null || total < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('请填写有效的本月总课时（非负整数）')),
                          );
                          return;
                        }

                        int? remaining = int.tryParse(remainingText);
                        final originalRemaining = student?.remainingSessions ?? total;
                        if (remaining == null || remaining < 0) {
                          // 未填或无效时：新增用 total，编辑用原值
                          remaining = isEditing ? originalRemaining : total;
                        }
                        if (remaining > total) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('剩余课时不能大于总课时')),
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
                          totalSessions: total,
                          remainingSessions: remaining,
                          status: selectedStatus,
                        );
                        await _saveStudent(newStudent, isEditing);
                      },
                      icon: const Icon(Icons.save),
                      label: Text(isEditing ? '保存' : '添加'),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
    {required int totalSessions, required int remainingSessions, required StudentStatus status}
  ) {
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
      remainingSessions: remainingSessions,
      totalSessions: totalSessions,
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
    final lowBalance = students.where((s) => s.remainingSessions <= 2).length;
    return {
      'total': total,
      'active': active,
      'lowBalance': lowBalance,
      'graduated': graduated,
    };
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;
  final int animationIndex;

  const _StudentCard({
    required this.student,
    required this.onTap,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return ASCard(
      animate: true,
      animationIndex: animationIndex,
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
                  '${student.age ?? '-'}岁 · ${getStudentLevelName(student.level)} · ${student.parentName ?? '家长未知'}',
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
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: student.remainingSessions <= 5
                        ? Colors.orange
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '余${student.remainingSessions}节',
                    style: TextStyle(
                      color: student.remainingSessions <= 5
                          ? Colors.orange
                          : Colors.grey.shade600,
                      fontWeight: student.remainingSessions <= 5
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
