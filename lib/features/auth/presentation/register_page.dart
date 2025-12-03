import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/animations.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/as_primary_button.dart';
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

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.family_restroom,
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
          '家长注册',
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
          '创建账号以关注孩子的训练动态',
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

  Widget _buildRegistrationForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 姓名
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: '姓名',
            hintText: '请输入您的姓名',
            prefixIcon: Icon(Icons.person_outlined),
          ),
          textInputAction: TextInputAction.next,
          validator: NameValidator.getErrorMessage,
        )
            .animate(delay: 300.ms)
            .fadeIn(duration: ASAnimations.normal)
            .slideX(begin: -0.1, end: 0),
        const SizedBox(height: ASSpacing.lg),

        // 邮箱
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: '邮箱',
            hintText: '请输入邮箱地址',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: EmailValidator.getErrorMessage,
        )
            .animate(delay: 350.ms)
            .fadeIn(duration: ASAnimations.normal)
            .slideX(begin: -0.1, end: 0),
        const SizedBox(height: ASSpacing.lg),

        // 手机号
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: '手机号',
            hintText: '例如：0123456789',
            prefixIcon: Icon(Icons.phone_outlined),
            helperText: '用于匹配您孩子的账号',
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: PhoneValidator.getErrorMessage,
        )
            .animate(delay: 400.ms)
            .fadeIn(duration: ASAnimations.normal)
            .slideX(begin: -0.1, end: 0),
        const SizedBox(height: ASSpacing.lg),

        // 密码
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: '密码',
            hintText: '请设置密码',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          validator: PasswordValidator.getErrorMessage,
        )
            .animate(delay: 450.ms)
            .fadeIn(duration: ASAnimations.normal)
            .slideX(begin: -0.1, end: 0),
        const SizedBox(height: ASSpacing.sm),

        // 密码强度指示器
        if (_passwordController.text.isNotEmpty && _passwordValidation != null)
          _buildPasswordStrengthIndicator(theme),
        const SizedBox(height: ASSpacing.lg),

        // 确认密码
        TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: '确认密码',
            hintText: '请再次输入密码',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
          ),
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          validator: (value) => ConfirmPasswordValidator.validate(
            value,
            _passwordController.text,
          ),
          onFieldSubmitted: (_) => _register(),
        )
            .animate(delay: 500.ms)
            .fadeIn(duration: ASAnimations.normal)
            .slideX(begin: -0.1, end: 0),
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
