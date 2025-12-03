import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/animations.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/coach_shift.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/supabase/auth_repository.dart';
import '../../../data/repositories/supabase/sessions_repository.dart';
import '../../../data/repositories/supabase/hr_repository.dart';

/// 教练列表页（管理员）
class CoachListPage extends ConsumerStatefulWidget {
  const CoachListPage({super.key});

  @override
  ConsumerState<CoachListPage> createState() => _CoachListPageState();
}

class _CoachListPageState extends ConsumerState<CoachListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = ref.read(supabaseAuthRepositoryProvider).watchCoaches();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('教练管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<Profile>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(ASSpacing.pagePadding),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: ASSpacing.lg),
                  Expanded(child: ASSkeletonList(itemCount: 5, hasAvatar: true)),
                ],
              ),
            );
          }

          var coaches = snapshot.data ?? [];
          if (_searchController.text.isNotEmpty) {
            coaches = coaches
                .where((c) => c.fullName.contains(_searchController.text))
                .toList();
          }

          if (coaches.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(ASSpacing.pagePadding),
              children: [
                _buildSearchBar(),
                const SizedBox(height: ASSpacing.lg),
                _buildEmpty(isDark),
              ],
            );
          }

          // 目前只实时显示列表，详细统计可进入详情页加载
          final items = coaches.map((coach) {
            return _CoachCardData(
              profile: coach,
              monthlySummary: CoachSessionSummary(
                coachId: coach.id,
                month: DateTime.now(),
                totalSessions: 0,
                ratePerSession: coach.ratePerSession ?? 0,
                totalSalary: 0,
              ),
              upcomingCount: 0,
            );
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(ASSpacing.pagePadding),
            children: [
              _buildSearchBar(),
              const SizedBox(height: ASSpacing.lg),
              ...items.asMap().entries.map((entry) => 
                _CoachCard(
                  data: entry.value, 
                  animationIndex: entry.key,
                  onTap: () => _openDetail(entry.value.profile.id),
                ),
              ),
              const SizedBox(height: ASSpacing.xl),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _showCreateCoachDialog,
            backgroundColor: ASColors.primary,
            icon: const Icon(Icons.add),
            label: const Text('新增教练'),
          ).animate().scale(
                delay: ASAnimations.normal,
                duration: ASAnimations.medium,
                curve: ASAnimations.bounceCurve,
              ),
          const SizedBox(height: ASSpacing.md),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '按姓名搜索教练',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
            : null,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildEmpty(bool isDark) {
    final hintColor = isDark ? ASColorsDark.textHint : ASColors.textHint;
    final secondaryColor = isDark ? ASColorsDark.textSecondary : ASColors.textSecondary;
    
    return ASCard(
      animate: true,
      child: Padding(
        padding: const EdgeInsets.all(ASSpacing.lg),
        child: Column(
          children: [
            Icon(Icons.person_search, size: 48, color: hintColor),
            const SizedBox(height: ASSpacing.md),
            Text('暂无教练', style: TextStyle(color: secondaryColor)),
          ],
        ),
      ),
    );
  }

  void _openDetail(String coachId) {
    context.push('/admin/coaches/$coachId');
  }

  void _showCreateCoachDialog() {
    showDialog<Profile>(
      context: context,
      builder: (_) => _CreateCoachDialog(),
    ).then((created) {
      if (created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已创建教练账号：${created.fullName}')),
        );
      }
    });
  }
}

class _CoachCardData {
  _CoachCardData({
    required this.profile,
    required this.monthlySummary,
    required this.upcomingCount,
  });

  final Profile profile;
  final CoachSessionSummary monthlySummary;
  final int upcomingCount;
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.data, 
    required this.onTap,
    this.animationIndex = 0,
  });

  final _CoachCardData data;
  final VoidCallback onTap;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final p = data.profile;
    return Padding(
      padding: const EdgeInsets.only(bottom: ASSpacing.md),
      child: ASCard(
        animate: true,
        animationIndex: animationIndex,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(ASSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: ASColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      p.fullName.substring(0, 1),
                      style: const TextStyle(
                        color: ASColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: ASSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.fullName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        if (p.phoneNumber != null)
                          Text(
                            p.phoneNumber!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const ASTag(label: '在职', type: ASTagType.success),
                ],
              ),
              const SizedBox(height: ASSpacing.md),
              Row(
                children: [
                  _StatChip(
                    label: '本月课时',
                    value: '${data.monthlySummary.totalSessions}',
                    icon: Icons.event_available,
                    color: ASColors.primary,
                  ),
                  const SizedBox(width: ASSpacing.sm),
                  _StatChip(
                    label: '预计收入',
                    value: 'RM ${data.monthlySummary.totalSalary.toStringAsFixed(0)}',
                    icon: Icons.payments,
                    color: ASColors.success,
                  ),
                  const SizedBox(width: ASSpacing.sm),
                  _StatChip(
                    label: '待上课',
                    value: '${data.upcomingCount}',
                    icon: Icons.schedule,
                    color: ASColors.info,
                  ),
                ],
              ),
              const SizedBox(height: ASSpacing.sm),
              Text(
                '累计课时 ${p.totalClassesAttended} · 费率 RM ${p.ratePerSession?.toStringAsFixed(0) ?? '--'}/节',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateCoachDialog extends ConsumerStatefulWidget {
  const _CreateCoachDialog();

  @override
  ConsumerState<_CreateCoachDialog> createState() => _CreateCoachDialogState();
}

class _CreateCoachDialogState extends ConsumerState<_CreateCoachDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rateController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();
    final rateText = _rateController.text.trim();
    final rate = rateText.isEmpty ? null : double.tryParse(rateText);

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('姓名、邮箱、密码不能为空')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final authRepo = ref.read(supabaseAuthRepositoryProvider);
      final profile = await authRepo.createCoachAccount(
        email: email,
        password: password,
        fullName: name,
        phoneNumber: phone.isEmpty ? null : phone,
        ratePerSession: rate,
      );

      if (mounted) {
        Navigator.of(context).pop(profile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                    '新增教练账号',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: ASSpacing.lg),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '姓名*'),
            ),
            const SizedBox(height: ASSpacing.md),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: '邮箱*'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: ASSpacing.md),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: '临时密码*'),
              obscureText: true,
            ),
            const SizedBox(height: ASSpacing.md),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: '电话'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: ASSpacing.md),
            TextField(
              controller: _rateController,
              decoration: const InputDecoration(labelText: '课时费率（RM）'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: ASSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: ASSpacing.md),
                Expanded(
                  child: ASPrimaryButton(
                    label: '创建',
                    onPressed: _isSaving ? null : _submit,
                    isLoading: _isSaving,
                    height: 48,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ASSpacing.sm, vertical: ASSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
