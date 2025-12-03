import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/animations.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/widgets/as_primary_button.dart';
import '../../../data/repositories/supabase/auth_repository.dart';
import '../../../data/repositories/supabase/supabase_client_provider.dart';
import '../application/auth_providers.dart';

/// 邮箱验证提示页面
class EmailVerificationPage extends ConsumerStatefulWidget {
  final String email;
  final String phoneNumber;

  const EmailVerificationPage({
    super.key,
    required this.email,
    required this.phoneNumber,
  });

  @override
  ConsumerState<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  bool _isResending = false;
  bool _canResend = true;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _listenToAuthChanges();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  /// 监听认证状态变化，当用户验证邮箱后自动跳转
  void _listenToAuthChanges() {
    _authSubscription = supabaseClient.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        // 用户已验证并登录，跳转到绑定孩子页面
        _onVerificationComplete(session.user.id);
      }
    });
  }

  Future<void> _onVerificationComplete(String userId) async {
    try {
      final authRepo = ref.read(supabaseAuthRepositoryProvider);
      final profile = await authRepo.getProfile(userId);

      if (profile != null && mounted) {
        ref.read(currentUserProvider.notifier).setUser(profile);

        // 跳转到绑定孩子页面
        context.go('/link-children', extra: {
          'phoneNumber': widget.phoneNumber,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取用户信息失败：$e')),
        );
      }
    }
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return;

    setState(() {
      _isResending = true;
    });

    try {
      final authRepo = ref.read(supabaseAuthRepositoryProvider);
      await authRepo.resendVerificationEmail(widget.email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('验证邮件已重新发送，请查收'),
            backgroundColor: Colors.green,
          ),
        );

        // 开始倒计时
        _startResendCountdown();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _startResendCountdown() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ASSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: ASSpacing.xxl),
                  _buildContent(theme),
                  const SizedBox(height: ASSpacing.xxl),
                  _buildActions(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_unread_outlined,
            size: 56,
            color: primaryColor,
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: ASAnimations.medium,
              curve: ASAnimations.emphasizeCurve,
            )
            .fadeIn(duration: ASAnimations.normal),
        const SizedBox(height: ASSpacing.xl),
        Text(
          '验证您的邮箱',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        )
            .animate(delay: 100.ms)
            .fadeIn(duration: ASAnimations.normal)
            .slideY(begin: 0.3, end: 0),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      children: [
        Text(
          '我们已向以下邮箱发送了验证链接：',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: ASAnimations.normal),
        const SizedBox(height: ASSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ASSpacing.lg,
            vertical: ASSpacing.md,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
          ),
          child: Text(
            widget.email,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        )
            .animate(delay: 250.ms)
            .fadeIn(duration: ASAnimations.normal)
            .slideY(begin: 0.2, end: 0),
        const SizedBox(height: ASSpacing.xl),
        Container(
          padding: const EdgeInsets.all(ASSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(ASSpacing.cardRadius),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: ASSpacing.sm),
                  Expanded(
                    child: Text(
                      '请按以下步骤完成验证：',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ASSpacing.md),
              _buildStep(theme, '1', '打开您的邮箱'),
              _buildStep(theme, '2', '找到来自 Art Sport 的验证邮件'),
              _buildStep(theme, '3', '点击邮件中的验证链接'),
              _buildStep(theme, '4', '验证成功后将自动跳转'),
            ],
          ),
        )
            .animate(delay: 300.ms)
            .fadeIn(duration: ASAnimations.normal)
            .slideY(begin: 0.2, end: 0),
        const SizedBox(height: ASSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 4),
            Text(
              '验证链接将在24小时后失效',
              style: theme.textTheme.bodySmall,
            ),
          ],
        )
            .animate(delay: 350.ms)
            .fadeIn(duration: ASAnimations.normal),
      ],
    );
  }

  Widget _buildStep(ThemeData theme, String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: ASSpacing.sm),
          Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Column(
      children: [
        ASPrimaryButton(
          label: _canResend
              ? '重新发送验证邮件'
              : '重新发送 ($_resendCountdown秒)',
          onPressed: _canResend ? _resendEmail : null,
          isLoading: _isResending,
          isFullWidth: true,
          height: 52,
          animate: true,
          animationDelay: 400.ms,
        ),
        const SizedBox(height: ASSpacing.md),
        TextButton(
          onPressed: () {
            // 清除认证状态并返回登录页
            supabaseClient.auth.signOut();
            context.go('/login');
          },
          child: Text(
            '使用其他邮箱注册',
            style: TextStyle(
              color: theme.colorScheme.primary,
            ),
          ),
        )
            .animate(delay: 450.ms)
            .fadeIn(duration: ASAnimations.normal),
        const SizedBox(height: ASSpacing.sm),
        Text(
          '没有收到邮件？请检查垃圾邮件文件夹',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        )
            .animate(delay: 500.ms)
            .fadeIn(duration: ASAnimations.normal),
      ],
    );
  }
}
