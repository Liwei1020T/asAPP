import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/storage_config.dart';

/// Local filesystem storage repository (stores under `StorageConfig.baseDirectory`)
/// and returns HTTP URLs based on `StorageConfig.publicBaseUrl`.
class StorageRepository {
  StorageRepository({Directory? baseDirectory})
      : _baseDir = baseDirectory ?? Directory(StorageConfig.baseDirectory);

  final Directory _baseDir;

  /// Upload file bytes/stream to local folder and return a public URL.
  Future<String> uploadFile({
    Uint8List? bytes,
    Stream<List<int>>? stream,
    int? contentLength,
    required String filename,
    String? folder,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Local filesystem storage is not supported on web builds.');
    }
    if (bytes == null && stream == null) {
      throw ArgumentError('bytes or stream must be provided');
    }

    final folderPath = _normalizeFolder(folder ?? '');
    final dir = Directory(_joinPaths(_baseDir.path, folderPath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final relativePath = folderPath.isEmpty ? filename : '$folderPath/$filename';
    final file = File(_joinPaths(_baseDir.path, relativePath));

    Uint8List payload;
    if (stream != null) {
      onProgress?.call(0);
      final chunks = <int>[];
      var loaded = 0;
      await for (final chunk in stream) {
        chunks.addAll(chunk);
        loaded += chunk.length;
        if (contentLength != null && contentLength > 0) {
          onProgress?.call((loaded / contentLength) * 0.5);
        }
        await Future<void>.delayed(Duration.zero);
      }
      payload = Uint8List.fromList(chunks);
    } else {
      payload = bytes!;
    }

    onProgress?.call(0.75);
    await file.writeAsBytes(payload, flush: true);
    onProgress?.call(1);

    return _toPublicUrl(relativePath, file);
  }

  /// Pre-compute the public URL before upload finishes.
  String buildPublicUrl({
    required String filename,
    String? folder,
  }) {
    if (kIsWeb) {
      throw UnsupportedError('Local filesystem storage is not supported on web builds.');
    }
    final folderPath = _normalizeFolder(folder ?? '');
    final relativePath = folderPath.isEmpty ? filename : '$folderPath/$filename';
    final file = File(_joinPaths(_baseDir.path, relativePath));
    return _toPublicUrl(relativePath, file);
  }

  String _normalizeFolder(String folder) {
    var f = folder.replaceAll('\\', '/').trim();
    f = f.replaceAll(RegExp('/+'), '/');
    if (f.startsWith('/')) f = f.substring(1);
    if (f.endsWith('/')) f = f.substring(0, f.length - 1);
    return f;
  }

  String _joinPaths(String base, String next) {
    if (next.isEmpty) return base;
    final normalizedBase = base.replaceAll(RegExp(r'[\\/]+$'), '');
    final normalizedNext = next.replaceAll(RegExp(r'^[\\/]+'), '');
    return '$normalizedBase${Platform.pathSeparator}$normalizedNext';
  }

  String _toPublicUrl(String relativePath, File file) {
    final cleaned = relativePath.replaceAll('\\', '/');
    final base = StorageConfig.publicBaseUrl.trim();
    if (base.isNotEmpty) {
      final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
      return '$normalizedBase/$cleaned';
    }
    // Fallback to file:// if no base URL provided.
    return file.absolute.uri.toString();
  }
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository();
});
