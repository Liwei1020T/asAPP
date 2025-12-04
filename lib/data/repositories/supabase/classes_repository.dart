import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/class_group.dart';
import 'supabase_client_provider.dart';

/// Supabase 班级仓库
class SupabaseClassesRepository {
  Future<List<ClassGroup>> getAllClasses() async {
    final data = await supabaseClient
        .from('class_groups')
        .select()
        .order('name', ascending: true);
    return (data as List)
        .map((e) => ClassGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 实时订阅班级列表（按名称排序）
  Stream<List<ClassGroup>> watchAllClasses() {
    return supabaseClient
        .from('class_groups')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final list = rows
              .map((e) => ClassGroup.fromJson(e as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => (a.name).compareTo(b.name));
          return list;
        });
  }

  Future<List<ClassGroup>> getActiveClasses() async {
    final data = await supabaseClient
        .from('class_groups')
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);
    return (data as List)
        .map((e) => ClassGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ClassGroup?> getClass(String classId) async {
    final data = await supabaseClient
        .from('class_groups')
        .select()
        .eq('id', classId)
        .maybeSingle();
    return data != null
        ? ClassGroup.fromJson(data as Map<String, dynamic>)
        : null;
  }

  Future<List<ClassGroup>> getClassesForCoach(String coachId) async {
    final data = await supabaseClient
        .from('class_groups')
        .select()
        .eq('default_coach_id', coachId)
        .eq('is_active', true);
    return (data as List)
        .map((e) => ClassGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getStudentCountForClass(String classId) async {
    final rows = await supabaseClient
        .from('class_memberships')
        .select('student_id')
        .eq('class_id', classId)
        .eq('is_active', true);
    return (rows as List).length;
  }

  Future<List<String>> getStudentIdsForClass(String classId) async {
    final rows = await supabaseClient
        .from('class_memberships')
        .select('student_id')
        .eq('class_id', classId)
        .eq('is_active', true);
    return (rows as List)
        .map((e) => (e as Map<String, dynamic>)['student_id'] as String)
        .toList();
  }

  Future<void> addStudentToClass(String classId, String studentId) async {
    await supabaseClient.from('class_memberships').upsert({
      'class_id': classId,
      'student_id': studentId,
      'is_active': true,
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeStudentFromClass(String classId, String studentId) async {
    await supabaseClient
        .from('class_memberships')
        .delete()
        .eq('class_id', classId)
        .eq('student_id', studentId);
  }

  Future<ClassGroup> createClass(ClassGroup classGroup) async {
    // 使用数据库默认 UUID：插入时不传 id
    final payload = classGroup.toJson();
    payload.remove('id');

    final inserted = await supabaseClient
        .from('class_groups')
        .insert(payload)
        .select()
        .single();
    return ClassGroup.fromJson(inserted as Map<String, dynamic>);
  }

  Future<ClassGroup> updateClass(ClassGroup classGroup) async {
    final updated = await supabaseClient
        .from('class_groups')
        .update(classGroup.toJson())
        .eq('id', classGroup.id)
        .select()
        .single();
    return ClassGroup.fromJson(updated as Map<String, dynamic>);
  }

  Future<void> deleteClass(String classId) async {
    await supabaseClient.from('class_groups').delete().eq('id', classId);
  }
}

final supabaseClassesRepositoryProvider = Provider<SupabaseClassesRepository>((ref) {
  return SupabaseClassesRepository();
});
