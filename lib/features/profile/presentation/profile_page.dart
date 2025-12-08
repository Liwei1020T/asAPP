import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/animations.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/supabase/auth_repository.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../auth/application/auth_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _savingProfile = false;
  bool _updatingPassword = false;
  bool _uploadingAvatar = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _phoneController = TextEditingController(text: profile?.phoneNumber ?? '');
    _avatarUrl = profile?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProvider);
    final email = Supabase.instance.client.auth.currentUser?.email ?? '未设置邮箱';

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人资料'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: profile == null
          ? const Center(child: ASSkeletonProfileCard())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(ASSpacing.pagePadding),
              child: ASStaggeredColumn(
                children: [
                  ASSectionTitle(
                    title: '账户信息',
                    subtitle: '修改姓名、手机号和头像',
                    animate: true,
                  ),
                  const SizedBox(height: ASSpacing.md),
                  _buildProfileCard(profile, email),
                  const SizedBox(height: ASSpacing.xl),
                  ASSectionTitle(
                    title: '安全设置',
                    subtitle: '更新登录密码，建议定期更换',
                    animate: true,
                  ),
                  const SizedBox(height: ASSpacing.md),
                  _buildSecurityCard(),
                  const SizedBox(height: ASSpacing.xxl),
                  ASPrimaryButton(
                    label: '退出登录',
                    icon: Icons.logout,
                    onPressed: _logout,
                    backgroundColor: ASColors.error,
                    foregroundColor: Colors.white,
                    isFullWidth: true,
                    height: 50,
                  ),
                  const SizedBox(height: ASSpacing.xxl),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard(Profile profile, String email) {
    final theme = Theme.of(context);
    
    return ASCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  ASAvatar(
                    imageUrl: _avatarUrl,
                    name: profile.fullName,
                    size: ASAvatarSize.xl,
                    showBorder: true,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _uploadingAvatar ? null : _pickAvatar,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.surface, width: 2),
                        ),
                        child: _uploadingAvatar
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: ASSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: ASSpacing.xs),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: ASSpacing.sm),
                    Wrap(
                      spacing: ASSpacing.sm,
                      runSpacing: ASSpacing.sm,
                      children: [
                        ASTag(
                          label: _getRoleName(profile.role),
                          type: ASTagType.primary,
                        ),
                        if (profile.phoneNumber != null)
                          ASTag(
                            label: profile.phoneNumber!,
                            type: ASTagType.info,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ASSpacing.xl),
          const Divider(),
          const SizedBox(height: ASSpacing.lg),
          ASTextField(
            controller: _nameController,
            label: '姓名',
            hint: '请输入姓名',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: ASSpacing.lg),
          ASTextField(
            controller: _phoneController,
            label: '手机号',
            hint: '请输入手机号',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: ASSpacing.xl),
          Align(
            alignment: Alignment.centerRight,
            child: ASPrimaryButton(
              label: '保存资料',
              isLoading: _savingProfile,
              onPressed: _savingProfile ? null : () => _saveProfile(profile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return ASCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ASTextField(
            controller: _newPasswordController,
            label: '新密码',
            hint: '至少 6 位，建议包含数字和符号',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: ASSpacing.lg),
          ASTextField(
            controller: _confirmPasswordController,
            label: '确认新密码',
            hint: '再次输入新密码',
            prefixIcon: Icons.lock_reset,
            obscureText: true,
          ),
          const SizedBox(height: ASSpacing.xl),
          Align(
            alignment: Alignment.centerRight,
            child: ASPrimaryButton(
              label: '更新密码',
              isLoading: _updatingPassword,
              onPressed: _updatingPassword ? null : _updatePassword,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '管理员';
      case UserRole.coach:
        return '教练';
      case UserRole.parent:
        return '家长';
      case UserRole.student:
        return '学员';
    }
  }

  Future<void> _saveProfile(Profile profile) async {
    setState(() => _savingProfile = true);
    final authRepo = ref.read(supabaseAuthRepositoryProvider);

    try {
      final updated = await authRepo.updateProfile(
        userId: profile.id,
        fullName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        avatarUrl: _avatarUrl,
      );
      ref.read(currentUserProvider.notifier).setUser(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('资料已更新')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败：$e'), backgroundColor: ASColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _updatePassword() async {
    final newPwd = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (newPwd.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入新密码')),
      );
      return;
    }

    if (newPwd != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('两次输入的密码不一致')),
      );
      return;
    }

    setState(() => _updatingPassword = true);
    final authRepo = ref.read(supabaseAuthRepositoryProvider);

    try {
      await authRepo.updatePassword(newPwd);
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('密码已更新，下次登录请使用新密码')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('修改密码失败：$e'), backgroundColor: ASColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingPassword = false);
    }
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;

    final profile = ref.read(currentUserProvider);
    if (profile == null) return;

    setState(() => _uploadingAvatar = true);
    final storageRepo = ref.read(storageRepositoryProvider);
    final authRepo = ref.read(supabaseAuthRepositoryProvider);

    try {
      final bytes = result.files.first.bytes as Uint8List;
      final fileName = result.files.first.name;
      final folder = 'avatars/${profile.id}';
      final timestampedName = '${DateTime.now().millisecondsSinceEpoch}-$fileName';

      final url = await storageRepo.uploadFile(
        bytes: bytes,
        filename: timestampedName,
        folder: folder,
        contentType: 'image/jpeg',
      );

      final updated = await authRepo.updateProfile(
        userId: profile.id,
        avatarUrl: url,
      );

      setState(() => _avatarUrl = url);
      ref.read(currentUserProvider.notifier).setUser(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像已更新')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败：$e'), backgroundColor: ASColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出', style: TextStyle(color: ASColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(supabaseAuthRepositoryProvider).signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }
}
