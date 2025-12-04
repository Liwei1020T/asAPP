import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/supabase/auth_repository.dart';
import '../../../data/repositories/supabase/storage_repository.dart';
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
      ),
      body: profile == null
          ? const Center(child: ASSkeletonProfileCard())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(ASSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard(Profile profile, String email) {
    return ASCard.gradient(
      padding: const EdgeInsets.all(ASSpacing.cardPadding),
      gradient: ASColors.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ASAvatar(
                imageUrl: _avatarUrl,
                name: profile.fullName,
                size: ASAvatarSize.xl,
                showBorder: true,
              ),
              const SizedBox(width: ASSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: ASSpacing.xs),
                    Text(
                      email,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: ASSpacing.sm),
                    Wrap(
                      spacing: ASSpacing.sm,
                      runSpacing: ASSpacing.sm,
                      children: [
                        ASTag(
                          label: profile.role.name,
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
              const SizedBox(width: ASSpacing.lg),
              OutlinedButton.icon(
                onPressed: _uploadingAvatar ? null : _pickAvatar,
                icon: _uploadingAvatar
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt_outlined),
                label: Text(_uploadingAvatar ? '上传中...' : '更换头像'),
              ),
            ],
          ),
          const Divider(height: ASSpacing.xl),
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
              height: 44,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return ASCard(
      padding: const EdgeInsets.all(ASSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '修改密码',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: ASSpacing.md),
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
              height: 44,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
        ],
      ),
    );
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
    final storageRepo = ref.read(supabaseStorageRepositoryProvider);
    final authRepo = ref.read(supabaseAuthRepositoryProvider);

    try {
      final bytes = result.files.first.bytes as Uint8List;
      final fileName = result.files.first.name;
      final path =
          'avatars/${profile.id}/${DateTime.now().millisecondsSinceEpoch}-$fileName';

      final url = await storageRepo.uploadBytes(
        bytes: bytes,
        bucket: 'avatars',
        path: path,
        fileOptions: const FileOptions(
          upsert: false,
          contentType: 'image/jpeg',
        ),
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
}
