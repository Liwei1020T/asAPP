import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/animations.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/widgets/as_primary_button.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/supabase/auth_repository.dart';
import '../application/auth_providers.dart';

/// 登录页面
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(supabaseAuthRepositoryProvider);
      final user = await authRepo.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null && mounted) {
        ref.read(currentUserProvider.notifier).setUser(user);
        _navigateToDashboard(user.role);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登录失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _quickSignInAs(UserRole role) async {
    setState(() => _isLoading = true);

    try {
      // 根据角色映射到预设测试账号（需在 Supabase 中手动创建）
      const roleAccounts = {
        UserRole.coach: {'email': 'tan.li.wei8008@gmail.com', 'password': 'password'},
        UserRole.parent: {'email': 'liwei1020@1utar.my', 'password': 'Liwei1020@'},
        UserRole.admin: {'email': 'demo@gmail.com', 'password': 'password'},
        UserRole.student: {'email': 'student@example.com', 'password': '123456'},
      };
      final account = roleAccounts[role];
      if (account == null) {
        throw Exception('未配置该角色的快速登录账号');
      }

      final authRepo = ref.read(supabaseAuthRepositoryProvider);
      final user = await authRepo.signInWithEmail(account['email']!, account['password']!);

      if (user != null && mounted) {
        ref.read(currentUserProvider.notifier).setUser(user);
        _navigateToDashboard(user.role);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('快速登录失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToDashboard(UserRole role) {
    switch (role) {
      case UserRole.admin:
        context.go('/admin-dashboard');
        break;
      case UserRole.coach:
        context.go('/coach-dashboard');
        break;
      case UserRole.parent:
        context.go('/parent-dashboard');
        break;
      case UserRole.student:
        context.go('/parent-dashboard');
        break;
    }
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
                  // Logo 和标题 - 带入场动画
                  _buildHeader(theme),
                  const SizedBox(height: ASSpacing.xxl),

                  // 登录表单 - 带入场动画
                  _buildLoginForm(theme),
                  const SizedBox(height: ASSpacing.xl),

                  // 快速登录按钮（开发用）
                  _buildQuickLoginSection(theme),
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
        // Logo 图标 - 带缩放弹跳动画
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.sports_tennis,
            size: 48,
            color: Colors.white,
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
        const SizedBox(height: ASSpacing.lg),
        Text(
          'Art Sport Penang',
          style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
        )
            .animate(delay: 100.ms)
            .fadeIn(duration: ASAnimations.normal)
            .slideY(begin: 0.3, end: 0),
        const SizedBox(height: ASSpacing.xs),
        Text(
          'Management System',
          style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: ASAnimations.normal)
            .slideY(begin: 0.3, end: 0),
      ],
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: '邮箱',
            hintText: '请输入邮箱地址',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        )
            .animate(delay: 300.ms)
            .fadeIn(duration: ASAnimations.normal)
            .slideX(begin: -0.1, end: 0),
        const SizedBox(height: ASSpacing.lg),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: '密码',
            hintText: '请输入密码',
            prefixIcon: Icon(Icons.lock_outlined),
          ),
          obscureText: true,
        )
            .animate(delay: 400.ms)
            .fadeIn(duration: ASAnimations.normal)
            .slideX(begin: -0.1, end: 0),
        const SizedBox(height: ASSpacing.xl),
        ASPrimaryButton(
          label: '登录',
          onPressed: _signIn,
          isLoading: _isLoading,
          isFullWidth: true,
          height: 52,
          animate: true,
          animationDelay: 500.ms,
        ),
        const SizedBox(height: ASSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '没有账号？',
              style: theme.textTheme.bodyMedium,
            ),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('立即注册'),
            ),
          ],
        )
            .animate(delay: 550.ms)
            .fadeIn(duration: ASAnimations.normal)
            .slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildQuickLoginSection(ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(
          '快速登录（开发模式）',
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: ASSpacing.md),
        Row(
          children: [
            Expanded(
              child: _QuickLoginButton(
                label: '教练',
                icon: Icons.sports,
                color: primaryColor,
                onTap: () => _quickSignInAs(UserRole.coach),
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(width: ASSpacing.sm),
            Expanded(
              child: _QuickLoginButton(
                label: '家长',
                icon: Icons.family_restroom,
                color: theme.colorScheme.tertiary,
                onTap: () => _quickSignInAs(UserRole.parent),
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(width: ASSpacing.sm),
            Expanded(
              child: _QuickLoginButton(
                label: '管理员',
                icon: Icons.admin_panel_settings,
                color: Colors.green,
                onTap: () => _quickSignInAs(UserRole.admin),
                isLoading: _isLoading,
              ),
            ),
          ],
        )
            .animate(delay: 600.ms)
            .fadeIn(duration: ASAnimations.normal)
            .slideY(begin: 0.2, end: 0),
      ],
    );
  }
}

class _QuickLoginButton extends StatefulWidget {
  const _QuickLoginButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isLoading,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  State<_QuickLoginButton> createState() => _QuickLoginButtonState();
}

class _QuickLoginButtonState extends State<_QuickLoginButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: ASAnimations.fast,
        child: Material(
          color: widget.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: ASSpacing.md,
              horizontal: ASSpacing.sm,
            ),
            child: Column(
              children: [
                Icon(widget.icon, color: widget.color, size: 28),
                const SizedBox(height: ASSpacing.xs),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.color,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
