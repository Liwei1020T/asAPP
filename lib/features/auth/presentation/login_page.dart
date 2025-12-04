import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/animations.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/supabase/auth_repository.dart';
import '../application/auth_providers.dart';

/// 登录页面 - 现代化重构版
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
      const roleAccounts = {
        UserRole.coach: {'email': 'tan.li.wei8008@gmail.com', 'password': 'password'},
        UserRole.parent: {'email': 'liwei1020@1utar.my', 'password': 'Liwei1020@'},
        UserRole.admin: {'email': 'demo@gmail.com', 'password': 'password'},
        UserRole.student: {'email': 'student@example.com', 'password': '123456'},
      };
      final account = roleAccounts[role];
      if (account == null) throw Exception('未配置该角色的快速登录账号');

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
      case UserRole.student:
        context.go('/parent-dashboard');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    return Scaffold(
      body: Stack(
        children: [
          // 动态背景
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFFF5F7FA), const Color(0xFFE4E9F2)],
                ),
              ),
            ),
          ),
          
          // 装饰性背景圆
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ).animate().scale(duration: 2.seconds, curve: Curves.easeInOut).fadeIn(),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ASSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: ASStaggeredColumn(
                  animate: true,
                  children: [
                    // Logo 区域
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_tennis,
                          size: 48,
                          color: Colors.white,
                        ),
                      ).animate().scale(duration: ASAnimations.medium, curve: ASAnimations.emphasized),
                    ),
                    const SizedBox(height: ASSpacing.xl),
                    
                    // 标题
                    Center(
                      child: Text(
                        'Art Sport Penang',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: ASSpacing.xs),
                    Center(
                      child: Text(
                        'Management System',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: ASSpacing.xxl),

                    // 登录卡片
                    ASCard.glass(
                      padding: const EdgeInsets.all(ASSpacing.xl),
                      glassOpacity: 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ASTextField(
                            controller: _emailController,
                            label: '邮箱',
                            hint: '请输入邮箱地址',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: ASSpacing.lg),
                          ASTextField(
                            controller: _passwordController,
                            label: '密码',
                            hint: '请输入密码',
                            prefixIcon: Icons.lock_outlined,
                            obscureText: true,
                          ),
                          const SizedBox(height: ASSpacing.xl),
                          ASPrimaryButton(
                            label: '登录',
                            onPressed: _signIn,
                            isLoading: _isLoading,
                            isFullWidth: true,
                            height: 52,
                            animate: true,
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
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: ASSpacing.xl),

                    // 快速登录区域
                    const Divider(),
                    const SizedBox(height: ASSpacing.md),
                    Center(
                      child: Text(
                        '快速登录（开发模式）',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: ASSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _QuickLoginIcon(
                          label: '教练',
                          icon: Icons.sports,
                          color: theme.colorScheme.primary,
                          onTap: () => _quickSignInAs(UserRole.coach),
                          isLoading: _isLoading,
                        ),
                        _QuickLoginIcon(
                          label: '家长',
                          icon: Icons.family_restroom,
                          color: theme.colorScheme.tertiary,
                          onTap: () => _quickSignInAs(UserRole.parent),
                          isLoading: _isLoading,
                        ),
                        _QuickLoginIcon(
                          label: '管理员',
                          icon: Icons.admin_panel_settings,
                          color: Colors.green,
                          onTap: () => _quickSignInAs(UserRole.admin),
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLoginIcon extends StatelessWidget {
  const _QuickLoginIcon({
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

