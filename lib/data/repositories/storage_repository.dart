import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/config/storage_config.dart';

/// Storage repository that uploads files to a HTTP API
/// and returns public URLs based on [StorageConfig.publicBaseUrl].
class StorageRepository {
  StorageRepository();

  /// Upload file bytes/stream to remote server and return a public URL.
  Future<String> uploadFile({
    Uint8List? bytes,
    Stream<List<int>>? stream,
    int? contentLength,
    required String filename,
    String? folder,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    if (bytes == null && stream == null) {
      throw ArgumentError('bytes or stream must be provided');
    }

    final normalizedFolder = _normalizeFolder(folder ?? '');

    Uint8List payload;
    if (stream != null) {
      final chunks = <int>[];
      var loaded = 0;
      await for (final chunk in stream) {
        chunks.addAll(chunk);
        loaded += chunk.length;
        if (contentLength != null && contentLength > 0) {
          onProgress?.call(loaded / contentLength);
        }
      }
      payload = Uint8List.fromList(chunks);
    } else {
      payload = bytes!;
    }

    final base = StorageConfig.publicBaseUrl.trim();
    if (base.isEmpty) {
      throw StateError('StorageConfig.publicBaseUrl must be configured for uploads.');
    }
    final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final uri = Uri.parse('$normalizedBase/upload').replace(queryParameters: {
      'folder': normalizedFolder,
      'filename': filename,
    });

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': contentType ?? 'application/octet-stream',
      },
      body: payload,
    );

    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final relativePath = (decoded['path'] as String?) ??
        (normalizedFolder.isEmpty ? filename : '$normalizedFolder/$filename');

    onProgress?.call(1);

    return _buildPublicUrl(relativePath);
  }

  /// Pre-compute the public URL before upload finishes.
  String buildPublicUrl({
    required String filename,
    String? folder,
  }) {
    final folderPath = _normalizeFolder(folder ?? '');
    final relativePath = folderPath.isEmpty ? filename : '$folderPath/$filename';
    return _buildPublicUrl(relativePath);
  }

  String _normalizeFolder(String folder) {
    var f = folder.replaceAll('\\', '/').trim();
    f = f.replaceAll(RegExp('/+'), '/');
    if (f.startsWith('/')) f = f.substring(1);
    if (f.endsWith('/')) f = f.substring(0, f.length - 1);
    return f;
  }

  String _buildPublicUrl(String relativePath) {
    final cleaned = relativePath.replaceAll('\\', '/');
    final base = StorageConfig.publicBaseUrl.trim();
    if (base.isNotEmpty) {
      final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
      return '$normalizedBase/$cleaned';
    }
    return cleaned;
  }
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository();
});
