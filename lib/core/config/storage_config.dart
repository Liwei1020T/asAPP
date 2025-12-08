/// Local storage server configuration.
class StorageConfig {
  StorageConfig._();

  /// Base directory (relative or absolute) for storing uploaded files.
  /// Default is a project-local `local_storage` folder.
  static const String baseDirectory = 'local_storage';

  /// Public base URL that serves files from [baseDirectory].
  /// Example: when you run `python3 -m http.server 9000 --directory local_storage`,
  /// set this to `http://localhost:9000` (or your Cloudflare Tunnel domain).
  static const String publicBaseUrl = 'https://asp-media.li-wei.net/';
}
