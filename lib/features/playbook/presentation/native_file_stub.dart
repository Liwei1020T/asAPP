// Stub file for web platform to avoid dart:io import errors
// This file is used when compiling for web

class File {
  File(String path);
  Stream<List<int>> openRead([int? start, int? end]) => Stream.empty();
}
