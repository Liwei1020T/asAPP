import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/supabase/classes_repository.dart';
import '../../../data/repositories/supabase/supabase_client_provider.dart';

/// 创建/编辑班级对话框
class CreateClassDialog extends ConsumerStatefulWidget {
  const CreateClassDialog({super.key, this.classGroup});

  final ClassGroup? classGroup;

  /// 显示对话框
  static Future<ClassGroup?> show(BuildContext context, {ClassGroup? classGroup}) {
    return showDialog<ClassGroup>(
      context: context,
      builder: (context) => CreateClassDialog(classGroup: classGroup),
    );
  }

  @override
  ConsumerState<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends ConsumerState<CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _venueController;
  late TextEditingController _capacityController;

  String? _selectedLevel;
  int? _selectedDayOfWeek;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _selectedCoachId;
  bool _isActive = true;
  bool _isLoading = false;

  List<Profile> _coaches = [];

  final _levels = ['入门', 'Level 1', 'Level 2', 'Level 3', '竞赛'];
  final _weekdays = [
    {'value': 0, 'label': '周日'},
    {'value': 1, 'label': '周一'},
    {'value': 2, 'label': '周二'},
    {'value': 3, 'label': '周三'},
    {'value': 4, 'label': '周四'},
    {'value': 5, 'label': '周五'},
    {'value': 6, 'label': '周六'},
  ];

  bool get isEditing => widget.classGroup != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.classGroup?.name ?? '');
    _venueController = TextEditingController(text: widget.classGroup?.defaultVenue ?? 'Art Sport Penang 主场');
    _capacityController = TextEditingController(text: widget.classGroup?.capacity?.toString() ?? '12');

    _selectedLevel = widget.classGroup?.level;
    _selectedDayOfWeek = widget.classGroup?.defaultDayOfWeek;
    _selectedCoachId = widget.classGroup?.defaultCoachId;
    _isActive = widget.classGroup?.isActive ?? true;

    // 解析时间
    if (widget.classGroup?.defaultStartTime != null) {
      final parts = widget.classGroup!.defaultStartTime!.split(':');
      _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    if (widget.classGroup?.defaultEndTime != null) {
      final parts = widget.classGroup!.defaultEndTime!.split(':');
      _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    _loadCoaches();
  }

  Future<void> _loadCoaches() async {
    try {
      final rows = await supabaseClient
          .from('profiles')
          .select(
              'id, full_name, role, phone_number, avatar_url, rate_per_session, total_classes_attended')
          .eq('role', 'coach') as List;
      final coaches = rows
          .map((e) => Profile.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() => _coaches = coaches);
      }
    } catch (e) {
      if (mounted) {
        _coaches = [];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载教练列表失败：$e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final initialTime = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? const TimeOfDay(hour: 14, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '选择时间';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final classGroupDraft = ClassGroup(
        id: widget.classGroup?.id ?? 'class-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        level: _selectedLevel,
        defaultVenue: _venueController.text.trim(),
        defaultDayOfWeek: _selectedDayOfWeek,
        defaultStartTime: _startTime != null ? _formatTimeOfDay(_startTime) : null,
        defaultEndTime: _endTime != null ? _formatTimeOfDay(_endTime) : null,
        capacity: int.tryParse(_capacityController.text),
        defaultCoachId: _selectedCoachId,
        isActive: _isActive,
      );

      late final ClassGroup saved;
      if (isEditing) {
        saved = await ref
            .read(supabaseClassesRepositoryProvider)
            .updateClass(classGroupDraft);
      } else {
        saved = await ref
            .read(supabaseClassesRepositoryProvider)
            .createClass(classGroupDraft);
      }

      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e'), backgroundColor: ASColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(ASSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEditing ? '编辑班级' : '新增班级',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: ASSpacing.lg),

                // 表单内容
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 班级名称
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: '班级名称 *',
                            hintText: '例如：Level 2 周五晚班',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入班级名称';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: ASSpacing.lg),

                        // 级别选择
                        DropdownButtonFormField<String>(
                          value: _selectedLevel,
                          decoration: const InputDecoration(
                            labelText: '级别',
                          ),
                          items: _levels.map((level) {
                            return DropdownMenuItem(value: level, child: Text(level));
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedLevel = value),
                        ),
                        const SizedBox(height: ASSpacing.lg),

                        // 上课日期
                        DropdownButtonFormField<int>(
                          value: _selectedDayOfWeek,
                          decoration: const InputDecoration(
                            labelText: '默认上课日',
                          ),
                          items: _weekdays.map((day) {
                            return DropdownMenuItem(
                              value: day['value'] as int,
                              child: Text(day['label'] as String),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedDayOfWeek = value),
                        ),
                        const SizedBox(height: ASSpacing.lg),

                        // 时间选择
                        Row(
                          children: [
                            Expanded(
                              child: _TimePickerField(
                                label: '开始时间',
                                value: _formatTimeOfDay(_startTime),
                                onTap: () => _selectTime(true),
                              ),
                            ),
                            const SizedBox(width: ASSpacing.md),
                            Expanded(
                              child: _TimePickerField(
                                label: '结束时间',
                                value: _formatTimeOfDay(_endTime),
                                onTap: () => _selectTime(false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: ASSpacing.lg),

                        // 场地
                        TextFormField(
                          controller: _venueController,
                          decoration: const InputDecoration(
                            labelText: '上课场地',
                            hintText: '例如：Art Sport Penang 主场',
                          ),
                        ),
                        const SizedBox(height: ASSpacing.lg),

                        // 容量
                        TextFormField(
                          controller: _capacityController,
                          decoration: const InputDecoration(
                            labelText: '班级容量',
                            hintText: '最大学员数',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: ASSpacing.lg),

                        // 默认教练
                        DropdownButtonFormField<String>(
                          value: _selectedCoachId,
                          decoration: const InputDecoration(
                            labelText: '默认教练',
                          ),
                          items: _coaches.map((coach) {
                            return DropdownMenuItem(
                              value: coach.id,
                              child: Text(coach.fullName),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedCoachId = value),
                        ),
                        const SizedBox(height: ASSpacing.lg),

                        // 状态开关
                        SwitchListTile(
                          title: const Text('班级状态'),
                          subtitle: Text(_isActive ? '活跃 Active' : '停用 Inactive'),
                          value: _isActive,
                          activeColor: ASColors.primary,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) => setState(() => _isActive = value),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: ASSpacing.lg),

                // 按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: ASSpacing.md),
                    ASPrimaryButton(
                      label: isEditing ? '保存' : '创建',
                      onPressed: _submit,
                      isLoading: _isLoading,
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
}

/// 时间选择器字段
class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(value),
      ),
    );
  }
}
