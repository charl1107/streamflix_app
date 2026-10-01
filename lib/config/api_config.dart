class ApiConfig {
  /// TMDB API key, injected at build time so it never lands in source control:
  ///
  ///   flutter run --dart-define-from-file=env.json
  ///
  /// where `env.json` is `{"TMDB_API_KEY": "..."}` and is gitignored.
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');

  static const String tmdbApiBase = 'https://api.themoviedb.org/3';
  static const String tmdbImageBase = 'https://image.tmdb.org/t/p';

  static bool get hasTmdbKey => tmdbApiKey.isNotEmpty;

  // Image helpers
  static String posterUrl(String? path, {String size = 'w500'}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$tmdbImageBase/$size$path';
  }

  static String backdropUrl(String? path, {String size = 'w1280'}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$tmdbImageBase/$size$path';
  }
}
