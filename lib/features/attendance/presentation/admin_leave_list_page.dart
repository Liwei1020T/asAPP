import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/spacing.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/supabase/supabase_client_provider.dart';

/// 管理员查看请假记录列表
class AdminLeaveListPage extends ConsumerWidget {
  const AdminLeaveListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final stream = supabaseClient.from('leave_requests').stream(
      primaryKey: ['id'],
    ).map(
      (rows) => rows
          .map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('请假记录'),
      ),
      body: StreamBuilder<List<LeaveRequest>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(ASSpacing.pagePadding),
              child: ASSkeletonList(itemCount: 6, hasAvatar: false),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: ASEmptyState(
                type: ASEmptyStateType.noData,
                title: '暂无请假记录',
                description: '学生请假后会自动出现在这里',
              ),
            );
          }

          return FutureBuilder<_LeaveMeta>(
            future: _loadMeta(items),
            builder: (context, metaSnapshot) {
              if (!metaSnapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(ASSpacing.pagePadding),
                  child: ASSkeletonList(itemCount: 6, hasAvatar: false),
                );
              }

              final meta = metaSnapshot.data!;

              return ListView.separated(
                padding: const EdgeInsets.all(ASSpacing.pagePadding),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(
                  height: ASSpacing.xs,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final statusColor = _statusColor(theme, item.status);
                  final studentName =
                      meta.studentNames[item.studentId] ?? item.studentId;
                  final sessionDate = meta.sessionDates[item.sessionId];
                  final displayDate = sessionDate != null
                      ? DateFormatters.date(sessionDate)
                      : DateFormatters.date(item.createdAt);

                  return ASCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ASSpacing.md,
                      vertical: ASSpacing.sm,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.event_busy,
                          color: statusColor,
                        ),
                        const SizedBox(width: ASSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      studentName,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  ASTag(
                                    label: _statusText(item.status),
                                    type: ASTagType.info,
                                  ),
                                ],
                              ),
                              const SizedBox(height: ASSpacing.xs),
                              Text(
                                '课程日期：$displayDate',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<_LeaveMeta> _loadMeta(List<LeaveRequest> items) async {
    final studentIds = items.map((e) => e.studentId).toSet().toList();
    final sessionIds = items.map((e) => e.sessionId).toSet().toList();

    final studentNames = <String, String>{};
    final sessionDates = <String, DateTime>{};

    if (studentIds.isNotEmpty) {
      final data = await supabaseClient
          .from('students')
          .select('id, full_name')
          .inFilter('id', studentIds);
      for (final row in data as List) {
        final map = row as Map<String, dynamic>;
        final id = map['id'] as String;
        final name = map['full_name'] as String? ?? id;
        studentNames[id] = name;
      }
    }

    if (sessionIds.isNotEmpty) {
      final data = await supabaseClient
          .from('sessions')
          .select('id, start_time')
          .inFilter('id', sessionIds);
      for (final row in data as List) {
        final map = row as Map<String, dynamic>;
        final id = map['id'] as String;
        final start = map['start_time'] as String?;
        if (start != null) {
          sessionDates[id] = DateTime.parse(start);
        }
      }
    }

    return _LeaveMeta(
      studentNames: studentNames,
      sessionDates: sessionDates,
    );
  }

  Color _statusColor(ThemeData theme, String status) {
    switch (status) {
      case 'approved':
        return theme.colorScheme.primary;
      case 'rejected':
        return theme.colorScheme.error;
      case 'pending':
      default:
        return theme.colorScheme.outline;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return '已通过';
      case 'rejected':
        return '已拒绝';
      case 'pending':
      default:
        return '待处理';
    }
  }
}

class _LeaveMeta {
  final Map<String, String> studentNames;
  final Map<String, DateTime> sessionDates;

  const _LeaveMeta({
    required this.studentNames,
    required this.sessionDates,
  });
}

