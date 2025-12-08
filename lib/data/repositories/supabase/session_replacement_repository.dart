import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/session_replacement.dart';
import 'supabase_client_provider.dart';

class SupabaseSessionReplacementRepository {
  Future<void> createReplacement({
    required String studentId,
    required String sourceSessionId,
    required String targetSessionId,
    String? makeupRightId,
  }) async {
    await supabaseClient.from('session_replacements').upsert(
      {
        'student_id': studentId,
        'source_session_id': sourceSessionId,
        'target_session_id': targetSessionId,
        'makeup_right_id': makeupRightId,
      },
      onConflict: 'student_id,source_session_id',
    );
  }

  Future<List<SessionReplacement>> getReplacementsForStudent(
    String studentId,
  ) async {
    final data = await supabaseClient
        .from('session_replacements')
        .select()
        .eq('student_id', studentId);

    final list = data as List;
    return list
        .map(
          (row) => SessionReplacement.fromJson(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}

final supabaseSessionReplacementRepositoryProvider =
    Provider<SupabaseSessionReplacementRepository>((ref) {
  return SupabaseSessionReplacementRepository();
});

