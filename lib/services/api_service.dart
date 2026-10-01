import 'package:dio/dio.dart';
import '../config/api_config.dart';

/// Thin TMDB client. Every request funnels through [get], so the API key and
/// language are attached in exactly one place.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.tmdbApiBase,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          String message = 'An unexpected error occurred';
          if (e.type == DioExceptionType.connectionTimeout) {
            message = 'Connection timed out';
          } else if (e.type == DioExceptionType.receiveTimeout) {
            message = 'Receive timed out';
          } else if (e.response != null) {
            message = 'Server error: ${e.response?.statusCode}';
          }
          return handler.next(
            DioException(
              requestOptions: e.requestOptions,
              error: message,
              type: e.type,
              response: e.response,
            ),
          );
        },
      ),
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (!ApiConfig.hasTmdbKey) {
      throw StateError(
        'TMDB_API_KEY is not set. Build with --dart-define-from-file=env.json',
      );
    }

    final response = await _dio.get(
      path,
      queryParameters: <String, dynamic>{
        'api_key': ApiConfig.tmdbApiKey,
        'language': 'en-US',
        ...?queryParameters,
      },
    );
    return response.data;
  }
}
