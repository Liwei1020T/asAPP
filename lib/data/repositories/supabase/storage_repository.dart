import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client_provider.dart';

/// Supabase Storage 上传工具
class SupabaseStorageRepository {
  /// 上传文件字节并返回公共 URL
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String bucket,
    required String path,
    required FileOptions fileOptions,
  }) async {
    await supabaseClient.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: fileOptions,
        );
    return supabaseClient.storage.from(bucket).getPublicUrl(path);
  }
}

final supabaseStorageRepositoryProvider = Provider<SupabaseStorageRepository>((ref) {
  return SupabaseStorageRepository();
});
