import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/animations.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/supabase/auth_repository.dart';

/// 家长注册页面
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  PasswordValidationResult? _passwordValidation;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _passwordValidation = PasswordValidator.validate(_passwordController.text);
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(supabaseAuthRepositoryProvider);
      
      // 调用注册 API
      await authRepo.createParentAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      if (mounted) {
        // 跳转到邮箱验证页面，传递邮箱和手机号用于后续流程
        context.go('/verify-email', extra: {
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = '注册失败';
        if (e.toString().contains('already registered')) {
          errorMessage = '该邮箱已被注册';
        } else if (e.toString().contains('invalid')) {
          errorMessage = '邮箱格式不正确';
        } else {
          errorMessage = '注册失败：${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
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
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ASSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: ASSpacing.xxl),
                    _buildRegistrationForm(theme),
                    const SizedBox(height: ASSpacing.xl),
                    _buildLoginLink(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;

    return ASGlassContainer.adaptive(
      padding: const EdgeInsets.all(ASSpacing.xl),
      blur: ASColors.glassBlurSigma,
      opacity: 0.9,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.family_restroom,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: ASSpacing.lg),
          Text(
            '家长注册',
            style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
          ),
          const SizedBox(height: ASSpacing.xs),
          Text(
            '创建账号以关注孩子的训练动态',
            style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 姓名
        ASTextField(
          controller: _fullNameController,
          label: '姓名',
          hint: '请输入您的姓名',
          prefixIcon: Icons.person_outlined,
          textInputAction: TextInputAction.next,
          validator: NameValidator.getErrorMessage,
        ),
        const SizedBox(height: ASSpacing.lg),

        // 邮箱
        ASTextField(
          controller: _emailController,
          label: '邮箱',
          hint: '请输入邮箱地址',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: EmailValidator.getErrorMessage,
        ),
        const SizedBox(height: ASSpacing.lg),

        // 手机号
        ASTextField(
          controller: _phoneController,
          label: '手机号',
          hint: '例如：0123456789',
          prefixIcon: Icons.phone_outlined,
          helperText: '用于匹配您孩子的账号',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: PhoneValidator.getErrorMessage,
        ),
        const SizedBox(height: ASSpacing.lg),

        // 密码
        ASTextField(
          controller: _passwordController,
          label: '密码',
          hint: '请设置密码',
          prefixIcon: Icons.lock_outlined,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          textInputAction: TextInputAction.next,
          validator: PasswordValidator.getErrorMessage,
        ),
        const SizedBox(height: ASSpacing.sm),

        // 密码强度指示器
        if (_passwordController.text.isNotEmpty && _passwordValidation != null)
          _buildPasswordStrengthIndicator(theme),
        const SizedBox(height: ASSpacing.lg),

        // 确认密码
        ASTextField(
          controller: _confirmPasswordController,
          label: '确认密码',
          hint: '请再次输入密码',
          prefixIcon: Icons.lock_outlined,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              );
            },
          ),
          textInputAction: TextInputAction.done,
          validator: (value) => ConfirmPasswordValidator.validate(
            value,
            _passwordController.text,
          ),
          onSubmitted: (_) => _register(),
        ),
        const SizedBox(height: ASSpacing.xl),

        // 注册按钮
        ASPrimaryButton(
          label: '注册',
          onPressed: _register,
          isLoading: _isLoading,
          isFullWidth: true,
          height: 52,
          animate: true,
          animationDelay: 550.ms,
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator(ThemeData theme) {
    final validation = _passwordValidation!;
    
    Color strengthColor;
    switch (validation.strength) {
      case PasswordStrength.weak:
        strengthColor = Colors.red;
        break;
      case PasswordStrength.medium:
        strengthColor = Colors.orange;
        break;
      case PasswordStrength.strong:
        strengthColor = Colors.green;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: validation.strengthValue,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: ASSpacing.sm),
            Text(
              '密码强度：${validation.strengthText}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: strengthColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (validation.errors.isNotEmpty) ...[
          const SizedBox(height: ASSpacing.xs),
          ...validation.errors.map(
            (error) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    error,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (validation.isValid && validation.suggestions.isNotEmpty) ...[
          const SizedBox(height: ASSpacing.xs),
          ...validation.suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ).animate().fadeIn(duration: ASAnimations.fast);
  }

  Widget _buildLoginLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '已有账号？',
          style: theme.textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('立即登录'),
        ),
      ],
    )
        .animate(delay: 600.ms)
        .fadeIn(duration: ASAnimations.normal)
        .slideY(begin: 0.2, end: 0);
  }
}
