import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/animations.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/supabase/classes_repository.dart';
import '../../../data/repositories/supabase/auth_repository.dart';
import 'create_class_dialog.dart';

/// 管理员 - 班级列表页（实时）
class AdminClassListPage extends ConsumerStatefulWidget {
  const AdminClassListPage({super.key});

  @override
  ConsumerState<AdminClassListPage> createState() => _AdminClassListPageState();
}

class _AdminClassListPageState extends ConsumerState<AdminClassListPage> {
  Future<void> _showCreateClassDialog() async {
    final result = await CreateClassDialog.show(context);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('班级「${result.name}」创建成功！'),
          backgroundColor: ASColors.success,
        ),
      );
    }
  }

  Future<void> _deleteClass(ClassGroup classGroup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除班级'),
        content: Text('确定要删除班级「${classGroup.name}」吗？\n此操作将同时删除该班级的所有排课记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: ASColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(supabaseClassesRepositoryProvider).deleteClass(classGroup.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('班级已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败：$e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = ref.read(supabaseClassesRepositoryProvider).watchAllClasses();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('课程管理 Classes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: ASSpacing.md),
            child: ASPrimaryButton(
              label: '新增班级',
              icon: Icons.add,
              onPressed: _showCreateClassDialog,
              height: 32,
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ClassGroup>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(ASSpacing.pagePadding),
              child: ASSkeletonList(itemCount: 5, hasAvatar: false),
            );
          }

          final classes = snapshot.data ?? [];
          if (classes.isEmpty) return _buildEmptyState(isDark);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(ASSpacing.pagePadding),
            child: ASStaggeredColumn(
              children: classes.map((classGroup) => _ClassCard(
                classGroup: classGroup,
                onTap: () => context.push('/admin/classes/${classGroup.id}'),
                onDelete: () => _deleteClass(classGroup),
              )).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ASEmptyState(
            type: ASEmptyStateType.noData,
            title: '暂无班级',
            description: '点击右上角按钮创建第一个班级',
            icon: Icons.class_outlined,
          ),
          const SizedBox(height: ASSpacing.lg),
          ASPrimaryButton(
            label: '创建第一个班级',
            onPressed: _showCreateClassDialog,
          ),
        ],
      ),
    );
  }
}

/// 班级卡片
class _ClassCard extends ConsumerWidget {
  const _ClassCard({
    required this.classGroup,
    required this.onTap,
    required this.onDelete,
  });

  final ClassGroup classGroup;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;
    
    return ASCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  classGroup.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (classGroup.level != null) ...[
                ASLevelTag(level: classGroup.level!),
                const SizedBox(width: ASSpacing.sm),
              ],
              ASTag(
                label: classGroup.isActive ? 'Active' : 'Inactive',
                type: classGroup.isActive ? ASTagType.success : ASTagType.normal,
              ),
              const SizedBox(width: ASSpacing.sm),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: secondaryColor, size: 20),
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: ASColors.error, size: 20),
                        SizedBox(width: 8),
                        Text('删除班级', style: TextStyle(color: ASColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: ASSpacing.md),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  icon: Icons.schedule,
                  label: _getScheduleText(),
                ),
              ),
              if (classGroup.defaultVenue != null)
                Expanded(
                  child: _InfoChip(
                    icon: Icons.location_on,
                    label: classGroup.defaultVenue!,
                  ),
                ),
            ],
          ),
          const SizedBox(height: ASSpacing.sm),
          Row(
            children: [
              _CoachNameChip(coachId: classGroup.defaultCoachId),
              const Spacer(),
              FutureBuilder<int>(
                future: _getStudentCount(ref, classGroup.id),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, size: 14, color: secondaryColor),
                        const SizedBox(width: 4),
                        Text(
                          '$count / ${classGroup.capacity ?? '∞'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: ASSpacing.sm),
              Icon(Icons.chevron_right, color: theme.hintColor),
            ],
          ),
        ],
      ),
    );
  }

  Future<int> _getStudentCount(WidgetRef ref, String classId) async {
    try {
      return await ref.read(supabaseClassesRepositoryProvider).getStudentCountForClass(classId);
    } catch (_) {
      return 0;
    }
  }

  String _getScheduleText() {
    if (classGroup.defaultDayOfWeek == null) return '未设定';
    final day = DateFormatters.weekdayFromZeroIndex(classGroup.defaultDayOfWeek!);
    final startTime = classGroup.defaultStartTime ?? '';
    final endTime = classGroup.defaultEndTime ?? '';
    if (startTime.isEmpty) return day;
    return '$day $startTime-$endTime';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CoachNameChip extends ConsumerWidget {
  const _CoachNameChip({required this.coachId});
  final String? coachId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (coachId == null || coachId!.isEmpty) {
      return const _InfoChip(icon: Icons.sports, label: '默认教练');
    }

    return FutureBuilder<Profile?>(
      future: _loadCoach(ref),
      builder: (context, snapshot) {
        final name = snapshot.data?.fullName ?? '默认教练';
        return _InfoChip(icon: Icons.sports, label: name);
      },
    );
  }

  Future<Profile?> _loadCoach(WidgetRef ref) async {
    try {
      return await ref.read(supabaseAuthRepositoryProvider).getProfile(coachId!);
    } catch (_) {
      return null;
    }
  }
}
