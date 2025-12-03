import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile.dart';
import '../../models/student.dart';
import 'supabase_client_provider.dart';

/// Supabase 认证仓库
///
/// 用户的创建统一通过 Supabase Auth 完成，
/// 数据库通过触发器/函数将 raw_user_meta_data 同步到 profiles 表。
class SupabaseAuthRepository {
  /// 邮箱密码登录，并返回 Profile
  Future<Profile> signInWithEmail(String email, String password) async {
    final response = await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final userId = response.user?.id ?? response.session?.user.id;
    if (userId == null) {
      throw AuthException('登录失败：未获取到用户 ID');
    }

    return _fetchProfile(userId);
  }

  /// 邮箱注册 + 创建对应的 profile 记录（依赖数据库触发器/函数）
  /// 如果触发器未生效，会手动创建 profile 记录
  Future<Profile> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phoneNumber,
    String? parentId,
    double? ratePerSession,
  }) async {
    final metadata = <String, dynamic>{
      'full_name': fullName,
      'role': role.name,
      'phone_number': phoneNumber,
      'parent_id': parentId,
      'rate_per_session': ratePerSession,
    }..removeWhere((_, value) => value == null);

    final signUpRes = await supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );

    final newUserId = signUpRes.user?.id;
    if (newUserId == null) {
      throw Exception('注册失败：未获取到新用户 ID，请检查 Supabase 邮箱验证设置');
    }

    // 尝试获取 profile（由触发器自动创建）
    // 如果不存在，手动创建
    try {
      return await _fetchProfile(newUserId);
    } on PostgrestException catch (e) {
      if (e.code == 'no_profile') {
        // 触发器未生效，手动创建 profile
        await _createProfileManually(
          userId: newUserId,
          email: email,
          fullName: fullName,
          role: role,
          phoneNumber: phoneNumber,
          parentId: parentId,
          ratePerSession: ratePerSession,
        );
        return await _fetchProfile(newUserId);
      }
      rethrow;
    }
  }

  /// 手动创建 profile 记录（当数据库触发器未生效时使用）
  Future<void> _createProfileManually({
    required String userId,
    required String email,
    required String fullName,
    required UserRole role,
    String? phoneNumber,
    String? parentId,
    double? ratePerSession,
  }) async {
    await supabaseClient.from('profiles').upsert({
      'id': userId,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'phone_number': phoneNumber,
      'parent_id': parentId,
      'rate_per_session': ratePerSession,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  }

  /// 退出登录
  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  /// 当前会话的 Profile（若未登录返回 null）
  Future<Profile?> getCurrentProfile() async {
    final session = supabaseClient.auth.currentSession;
    final userId = session?.user.id;
    if (userId == null) return null;
    return _fetchProfile(userId);
  }

  /// 获取用户列表（按角色过滤）
  Future<List<Profile>> getProfilesByRole(UserRole role) async {
    final data = await supabaseClient
        .from('profiles')
        .select()
        .eq('role', role.name);
    return (data as List)
        .map((e) => Profile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Profile>> getAllStudents() => getProfilesByRole(UserRole.student);

  Future<List<Profile>> getAllCoaches() => getProfilesByRole(UserRole.coach);

  /// 订阅教练列表（实时）
  Stream<List<Profile>> watchCoaches() {
    return supabaseClient
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final list = rows
              .map((e) => Profile.fromJson(e as Map<String, dynamic>))
              .where((p) => p.role == UserRole.coach)
              .toList();
          return list;
        });
  }

  /// 家长绑定孩子：将学生 Profile 的 parent_id 指向当前家长
  Future<void> linkChildToParent({
    required String childId,
    required String parentId,
  }) async {
    await supabaseClient
        .from('profiles')
        .update({'parent_id': parentId})
        .eq('id', childId)
        .eq('role', UserRole.student.name);
  }

  /// 管理员创建教练账号（便捷方法）
  Future<Profile> createCoachAccount({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    double? ratePerSession,
  }) async {
    return signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
      role: UserRole.coach,
      phoneNumber: phoneNumber,
      ratePerSession: ratePerSession,
    );
  }

  /// 管理员创建学生账号（便捷方法）
  Future<Profile> createStudentAccount({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? parentId,
  }) async {
    return signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
      role: UserRole.student,
      phoneNumber: phoneNumber,
      parentId: parentId,
    );
  }

  /// 管理员创建家长账号（便捷方法）
  Future<Profile> createParentAccount({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    return signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
      role: UserRole.parent,
      phoneNumber: phoneNumber,
    );
  }

  /// 获取家长的孩子列表（基于 profiles.parent_id）
  Future<List<Profile>> getChildrenOfParent(String parentId) async {
    final data = await supabaseClient
        .from('profiles')
        .select()
        .eq('parent_id', parentId)
        .eq('role', UserRole.student.name);
    return (data as List)
        .map((e) => Profile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 根据手机号查找学生（匹配 phone_number 或 emergency_phone）
  /// 用于家长注册后自动绑定孩子
  Future<List<Student>> findStudentsByPhone(String phoneNumber) async {
    // 标准化手机号（去除空格和横线）
    final normalizedPhone = phoneNumber.replaceAll(RegExp(r'[\s-]'), '');
    
    // 查询 phone_number 或 emergency_phone 匹配的学生
    final data = await supabaseClient
        .from('students')
        .select()
        .or('phone_number.eq.$normalizedPhone,emergency_phone.eq.$normalizedPhone');
    
    return (data as List)
        .map((e) => Student.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 根据姓名和手机号查找学生（用于手动绑定）
  Future<List<Student>> findStudentsByNameAndPhone({
    required String fullName,
    required String phoneNumber,
  }) async {
    final normalizedPhone = phoneNumber.replaceAll(RegExp(r'[\s-]'), '');
    
    final data = await supabaseClient
        .from('students')
        .select()
        .ilike('full_name', '%$fullName%')
        .or('phone_number.eq.$normalizedPhone,emergency_phone.eq.$normalizedPhone');
    
    return (data as List)
        .map((e) => Student.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 批量绑定学生到家长
  /// 更新 students 表的 parent_id 字段
  Future<void> bindStudentsToParent({
    required String parentId,
    required List<String> studentIds,
  }) async {
    if (studentIds.isEmpty) return;
    
    // 获取家长信息用于填充 parent_name
    final parentProfile = await getProfile(parentId);
    final parentName = parentProfile?.fullName;
    
    // 批量更新学生的 parent_id 和 parent_name
    for (final studentId in studentIds) {
      await supabaseClient
          .from('students')
          .update({
            'parent_id': parentId,
            'parent_name': parentName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', studentId);
    }
  }

  /// 解除学生与家长的绑定
  Future<void> unbindStudentFromParent(String studentId) async {
    await supabaseClient
        .from('students')
        .update({
          'parent_id': null,
          'parent_name': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', studentId);
  }

  /// 获取家长绑定的孩子列表（基于 students 表的 parent_id）
  Future<List<Student>> getLinkedStudents(String parentId) async {
    final data = await supabaseClient
        .from('students')
        .select()
        .eq('parent_id', parentId);
    
    return (data as List)
        .map((e) => Student.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 重新发送验证邮件
  Future<void> resendVerificationEmail(String email) async {
    await supabaseClient.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  /// 根据用户 ID 获取 Profile
  Future<Profile> _fetchProfile(String userId) async {
    final data = await supabaseClient
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      throw PostgrestException(
        message: '未找到对应的用户资料',
        details: 'profiles 表缺少记录: $userId',
        hint: '确认 profiles 表已和 auth.users 同步',
        code: 'no_profile',
      );
    }

    return Profile.fromJson(data);
  }

  /// 根据用户 ID 获取 Profile（找不到或错误时返回 null）
  Future<Profile?> getProfile(String userId) async {
    try {
      return await _fetchProfile(userId);
    } on PostgrestException {
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// Supabase Auth Repository Provider
final supabaseAuthRepositoryProvider = Provider<SupabaseAuthRepository>((ref) {
  return SupabaseAuthRepository();
});
