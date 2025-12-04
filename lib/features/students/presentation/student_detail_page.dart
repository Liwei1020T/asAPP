import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/animations.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/student.dart';
import '../../../data/repositories/supabase/student_repository.dart';
import '../../../data/repositories/supabase/storage_repository.dart';

class StudentDetailPage extends ConsumerStatefulWidget {
  final String studentId;
  final Student? student; // Optional, can be passed if available

  const StudentDetailPage({
    super.key,
    required this.studentId,
    this.student,
  });

  @override
  ConsumerState<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends ConsumerState<StudentDetailPage> {
  late Future<Student?> _studentFuture;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  void _loadStudent() {
    if (widget.student != null) {
      _studentFuture = Future.value(widget.student);
    } else {
      _studentFuture = ref.read(supabaseStudentRepositoryProvider).getStudentById(widget.studentId);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _studentFuture = ref.read(supabaseStudentRepositoryProvider).getStudentById(widget.studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学员详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final student = await _studentFuture;
              if (student != null && mounted) {
                _showEditStudentDialog(student);
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Student?>(
        future: _studentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('无法加载学员信息', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _refresh,
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final student = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(ASSpacing.pagePadding),
            child: ASStaggeredColumn(
              animate: true,
              children: [
                // 头部信息
                _buildHeader(student),
                const SizedBox(height: ASSpacing.lg),

                // 课时信息
                const ASSectionTitle(title: '📚 课时信息 Sessions'),
                _buildSessionInfo(student),
                const SizedBox(height: ASSpacing.lg),

                // 联系信息
                const ASSectionTitle(title: '📞 联系信息 Contact'),
                _buildContactInfo(student),
                const SizedBox(height: ASSpacing.lg),

                // 其他信息
                const ASSectionTitle(title: '📝 其他信息 Other'),
                _buildOtherInfo(student),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Student student) {
    final theme = Theme.of(context);
    return ASCard(
      child: Row(
        children: [
          Stack(
            children: [
              ASAvatar(
                imageUrl: student.avatarUrl,
                name: student.fullName,
                size: ASAvatarSize.xl,
                showBorder: true,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: _isUploadingAvatar ? null : () => _uploadStudentAvatar(student),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.surface, width: 2),
                    ),
                    child: _isUploadingAvatar
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : Icon(
                            Icons.camera_alt,
                            size: 12,
                            color: theme.colorScheme.onPrimary,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: ASSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      student.fullName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: ASSpacing.sm),
                    _buildStatusChip(student.status),
                  ],
                ),
                const SizedBox(height: ASSpacing.xs),
                Text(
                  '${student.age ?? '-'}岁 · ${student.gender ?? '未知'} · ${getStudentLevelName(student.level)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfo(Student student) {
    final theme = Theme.of(context);
    return ASCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('课时余额'),
              Text(
                '${student.remainingSessions}/${student.totalSessions}',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: ASSpacing.sm),
          LinearProgressIndicator(
            value: student.sessionBalancePercent,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              student.remainingSessions <= 5 ? ASColors.warning : ASColors.primary,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: ASSpacing.md),
          const Divider(),
          const SizedBox(height: ASSpacing.md),
          _buildDetailRow('剩余课时', '${student.remainingSessions} 节'),
          _buildDetailRow('总课时', '${student.totalSessions} 节'),
          _buildDetailRow('出勤率', '${(student.attendanceRate * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildContactInfo(Student student) {
    return ASCard(
      child: Column(
        children: [
          _buildDetailRow('家长姓名', student.parentName ?? '-'),
          _buildDetailRow('紧急联系人', student.emergencyContact ?? '-'),
          _buildDetailRow('紧急电话', student.emergencyPhone ?? '-'),
          if (student.phoneNumber != null)
            _buildDetailRow('学员电话', student.phoneNumber!),
        ],
      ),
    );
  }

  Widget _buildOtherInfo(Student student) {
    return ASCard(
      child: Column(
        children: [
          _buildDetailRow('入学日期', DateFormatters.date(student.enrollmentDate)),
          if (student.notes != null && student.notes!.isNotEmpty)
            _buildDetailRow('备注', student.notes!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: ASSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(StudentStatus status) {
    Color color;
    switch (status) {
      case StudentStatus.active:
        color = ASColors.success;
        break;
      case StudentStatus.inactive:
        color = ASColors.warning;
        break;
      case StudentStatus.graduated:
        color = ASColors.info;
        break;
      case StudentStatus.suspended:
        color = ASColors.error;
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

  Future<void> _uploadStudentAvatar(Student student) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) {
      return;
    }

    setState(() => _isUploadingAvatar = true);

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
        fileOptions: const FileOptions(
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
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  void _showEditStudentDialog(Student student) {
    final nameController = TextEditingController(text: student.fullName);
    final parentNameController = TextEditingController(text: student.parentName ?? '');
    final phoneController = TextEditingController(text: student.emergencyPhone ?? '');
    final totalSessionsController = TextEditingController(text: student.totalSessions.toString());
    final remainingSessionsController = TextEditingController(text: student.remainingSessions.toString());
    
    StudentLevel selectedLevel = student.level;
    String selectedGender = student.gender ?? '男';
    DateTime selectedBirthDate = student.birthDate ?? DateTime.now();
    StudentStatus selectedStatus = student.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑学员'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '学员姓名 *'),
                  ),
                  const SizedBox(height: 16),
                  // ... (Simplified for brevity, ideally reuse a form widget)
                  // For now, I'll just implement the critical fields
                  DropdownButtonFormField<StudentStatus>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: '状态'),
                    items: StudentStatus.values.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(getStudentStatusName(s)),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedStatus = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: totalSessionsController,
                    decoration: const InputDecoration(labelText: '总课时'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: remainingSessionsController,
                    decoration: const InputDecoration(labelText: '剩余课时'),
                    keyboardType: TextInputType.number,
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
            FilledButton(
              onPressed: () async {
                final updated = student.copyWith(
                  fullName: nameController.text.trim(),
                  status: selectedStatus,
                  totalSessions: int.tryParse(totalSessionsController.text) ?? student.totalSessions,
                  remainingSessions: int.tryParse(remainingSessionsController.text) ?? student.remainingSessions,
                  updatedAt: DateTime.now(),
                );
                
                try {
                  await ref.read(supabaseStudentRepositoryProvider).updateStudent(updated);
                  if (context.mounted) {
                    Navigator.pop(context);
                    _refresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('学员信息已更新')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('更新失败: $e')),
                    );
                  }
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
