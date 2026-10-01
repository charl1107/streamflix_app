import '../models/media_item.dart';
import '../models/genre.dart';
import '../models/season_episode.dart';
import 'api_service.dart';

/// Movie and TV catalogue backed by api.themoviedb.org directly.
class TmdbService {
  final ApiService _api = ApiService();

  List<MediaItem> _results(Map<String, dynamic> data, String type) {
    final results = data['results'] as List<dynamic>? ?? [];
    return results
        .map(
          (json) => MediaItem.fromTmdbJson(
            Map<String, dynamic>.from(json),
            defaultMediaType: type,
          ),
        )
        .toList();
  }

  Future<List<MediaItem>> getTrending({
    String type = 'movie',
    String window = 'week',
  }) async {
    final data = await _api.get('/trending/$type/$window');
    return _results(data, type);
  }

  Future<Map<String, dynamic>> getDiscover({
    String type = 'movie',
    String sortBy = 'popularity.desc',
    int? genre,
    int page = 1,
  }) async {
    final params = <String, dynamic>{'sort_by': sortBy, 'page': page};
    if (genre != null) params['with_genres'] = genre;

    final data = await _api.get('/discover/$type', queryParameters: params);
    return {
      'results': _results(data, type),
      'totalPages': data['total_pages'] ?? 1,
    };
  }

  Future<List<MediaItem>> search(
    String query, {
    String type = 'multi',
    int page = 1,
  }) async {
    final data = await _api.get(
      '/search/$type',
      queryParameters: {'query': query, 'page': page},
    );
    return _results(data, type);
  }

  Future<MediaItem> getMovieDetails(int id) async {
    final data = await _api.get(
      '/movie/$id',
      queryParameters: {'append_to_response': 'credits,recommendations,videos'},
    );
    return MediaItem.fromTmdbJson(
      Map<String, dynamic>.from(data),
      defaultMediaType: 'movie',
    );
  }

  Future<MediaItem> getTvDetails(int id) async {
    final data = await _api.get(
      '/tv/$id',
      queryParameters: {'append_to_response': 'credits,recommendations,videos'},
    );
    return MediaItem.fromTmdbJson(
      Map<String, dynamic>.from(data),
      defaultMediaType: 'tv',
    );
  }

  Future<List<Episode>> getTvSeason(int seriesId, int seasonNumber) async {
    final data = await _api.get('/tv/$seriesId/season/$seasonNumber');
    final episodes = data['episodes'] as List<dynamic>? ?? [];
    return episodes
        .map((json) => Episode.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<List<Genre>> getGenres({String type = 'movie'}) async {
    final data = await _api.get('/genre/$type/list');
    final genres = data['genres'] as List<dynamic>? ?? [];
    return genres
        .map((json) => Genre.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
}
