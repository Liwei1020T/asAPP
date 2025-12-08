import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/supabase/sessions_repository.dart';

class BatchScheduleDialog extends ConsumerStatefulWidget {
  const BatchScheduleDialog({super.key, required this.classGroup});

  final ClassGroup classGroup;

  static Future<bool?> show(BuildContext context, ClassGroup classGroup) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 600,
          child: BatchScheduleDialog(classGroup: classGroup),
        ),
      ),
    );
  }

  @override
  ConsumerState<BatchScheduleDialog> createState() => _BatchScheduleDialogState();
}

class _BatchScheduleDialogState extends ConsumerState<BatchScheduleDialog> {
  DateTimeRange? _selectedRange;
  List<Session> _previewSessions = [];
  bool _isGenerating = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    // Default to next month
    final now = DateTime.now();
    final start = DateTime(now.year, now.month + 1, 1);
    final end = DateTime(now.year, now.month + 2, 0);
    _selectedRange = DateTimeRange(start: start, end: end);
    _calculatePreview();
  }

  void _calculatePreview() {
    if (_selectedRange == null) return;
    if (widget.classGroup.defaultDayOfWeek == null ||
        widget.classGroup.defaultStartTime == null ||
        widget.classGroup.defaultEndTime == null) {
      setState(() => _errorText = '该班级未设置默认上课时间，无法批量排课。请先在班级设置中完善信息。');
      return;
    }

    final sessions = <Session>[];
    final defaultDay = widget.classGroup.defaultDayOfWeek!; // 0=Monday? No, usually 1=Monday in DateTime but let's check usage.
    // In Dart DateTime: 1=Mon, 7=Sun.
    // In our App: 0=Mon, 6=Sun (based on previous code usage in DateFormatters.weekdayFromZeroIndex)
    // Let's assume 0-indexed for now as per previous code.
    
    // Wait, let's verify DateFormatters.weekdayFromZeroIndex usage.
    // In admin_class_detail_page.dart: `DateFormatters.weekdayFromZeroIndex(_classGroup!.defaultDayOfWeek!)`
    // Let's assume the stored value is 0-6.
    // DateTime.weekday is 1-7. So we need to map.
    // 0 (Mon) -> 1
    // ...
    // 6 (Sun) -> 7
    final targetWeekday = widget.classGroup.defaultDayOfWeek! + 1;

    var current = _selectedRange!.start;
    while (current.isBefore(_selectedRange!.end) || current.isAtSameMomentAs(_selectedRange!.end)) {
      if (current.weekday == targetWeekday) {
        final startTime = _combineDateAndTime(current, widget.classGroup.defaultStartTime!);
        final endTime = _combineDateAndTime(current, widget.classGroup.defaultEndTime!);

        sessions.add(Session(
          id: 'preview-${current.millisecondsSinceEpoch}',
          classId: widget.classGroup.id,
          coachId: widget.classGroup.defaultCoachId,
          title: widget.classGroup.name,
          venue: widget.classGroup.defaultVenue,
          startTime: startTime,
          endTime: endTime,
          status: SessionStatus.scheduled,
          isPayable: true,
        ));
      }
      current = current.add(const Duration(days: 1));
    }

    setState(() {
      _previewSessions = sessions;
      _errorText = sessions.isEmpty ? '所选时间段内没有符合周几的日期' : null;
    });
  }

  DateTime _combineDateAndTime(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedRange,
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
      _calculatePreview();
    }
  }

  Future<void> _submit() async {
    if (_previewSessions.isEmpty) return;
    setState(() => _isGenerating = true);
    try {
      final repo = ref.read(supabaseSessionsRepositoryProvider);
      // Create sequentially to avoid overwhelming DB or hitting rate limits if any
      // Also allows for better error handling per item if needed, though here we fail fast.
      for (final session in _previewSessions) {
        // Use the coachId from preview (which is class default or null)
        await repo.createSession(session);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('排课失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '批量排课 Batch Schedule',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Date Range Selector
          InkWell(
            onTap: _isGenerating ? null : _selectDateRange,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: ASColors.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, color: ASColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedRange == null
                          ? '选择日期范围'
                          : '${DateFormat('yyyy-MM-dd').format(_selectedRange!.start)}  至  ${DateFormat('yyyy-MM-dd').format(_selectedRange!.end)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_errorText!, style: const TextStyle(color: ASColors.error)),
            ),

          const SizedBox(height: 16),
          
          // Summary
          if (_previewSessions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ASColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ASColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: ASColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '将生成 ${_previewSessions.length} 节课程 (每周${DateFormatters.weekdayFromZeroIndex(widget.classGroup.defaultDayOfWeek ?? 0)})',
                      style: const TextStyle(color: ASColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          const Text('预览 Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          // Preview List
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                border: Border.all(color: ASColors.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _previewSessions.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('请选择日期范围以生成预览', style: TextStyle(color: ASColors.textHint)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: _previewSessions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final session = _previewSessions[index];
                        return ListTile(
                          dense: true,
                          leading: Text(
                            '${index + 1}',
                            style: const TextStyle(color: ASColors.textHint),
                          ),
                          title: Text(
                            DateFormat('yyyy-MM-dd (EEE)').format(session.startTime),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '${DateFormat('HH:mm').format(session.startTime)} - ${DateFormat('HH:mm').format(session.endTime)}',
                          ),
                          trailing: const Icon(Icons.check_circle_outline, size: 16, color: ASColors.success),
                        );
                      },
                    ),
            ),
          ),

          const SizedBox(height: 24),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isGenerating ? null : () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isGenerating || _previewSessions.isEmpty ? null : _submit,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? '生成中...' : '确认生成'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
