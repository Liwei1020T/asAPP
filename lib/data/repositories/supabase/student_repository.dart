import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/student.dart';
import 'supabase_client_provider.dart';

/// Supabase 学员仓库
class SupabaseStudentRepository {
  Future<List<Student>> fetchStudents() async {
    final data = await supabaseClient
        .from('students')
        .select()
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Student.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 实时订阅学员列表（按创建时间倒序）
  Stream<List<Student>> watchStudents() {
    return supabaseClient
        .from('students')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final list = rows
              .map((e) => Student.fromJson(e as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<Student?> getStudentById(String id) async {
    final data = await supabaseClient
        .from('students')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Student.fromJson(data as Map<String, dynamic>);
  }

  Future<Student> createStudent(Student student) async {
    final inserted = await supabaseClient
        .from('students')
        .insert(student.toJson())
        .select()
        .single();
    return Student.fromJson(inserted as Map<String, dynamic>);
  }

  Future<Student> updateStudent(Student student) async {
    final updated = await supabaseClient
        .from('students')
        .update(student.toJson())
        .eq('id', student.id)
        .select()
        .single();
    return Student.fromJson(updated as Map<String, dynamic>);
  }
}

final supabaseStudentRepositoryProvider = Provider<SupabaseStudentRepository>((ref) {
  return SupabaseStudentRepository();
});
