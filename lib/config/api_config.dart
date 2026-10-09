import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class ApiConfig {
  /// TMDB API key from `--dart-define-from-file=env.json`:
  ///
  ///   flutter run --dart-define-from-file=env.json
  ///
  /// Optional: an explicit build-time define always wins over the bundled
  /// `env.json` asset below.
  static const String _defineKey = String.fromEnvironment('TMDB_API_KEY');

  /// The same gitignored `env.json`, bundled as an asset so a plain
  /// `flutter run` works without extra flags. Read once in [load].
  static const String _envAsset = 'env.json';

  static String _assetKey = '';
  static bool _loaded = false;

  /// Loads the bundled `env.json`. Must be awaited before `runApp`.
  /// Falls back silently to the dart-define value if the asset is missing
  /// or malformed.
  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = await rootBundle.loadString(_envAsset);
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) {
        final key = data['TMDB_API_KEY'];
        if (key is String) _assetKey = key.trim();
      }
    } catch (_) {
      // Missing or invalid env.json -> dart-define fallback.
    }
  }

  static String get tmdbApiKey =>
      _defineKey.isNotEmpty ? _defineKey : _assetKey;

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
