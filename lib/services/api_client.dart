import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'native_http_adapter.dart'
    if (dart.library.io) 'native_http_adapter_io.dart';

class ApiClient {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://flame-app-backend-production.up.railway.app',
  );
  static const _storage = FlutterSecureStorage();
  static String? _memoryToken;

  static final Dio _dio = _createDio();

  static Dio get instance => _dio;
  static Options get publicOptions => Options(extra: const {'skipAuth': true});

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        // Some endpoints (e.g. the communities list) are slow on the backend
        // and can take 15-20s once there are a few dozen communities, so this
        // needs headroom beyond that rather than a tight client-side cutoff.
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );
    configureNativeHttpAdapter(dio);
    dio.transformer = BackgroundTransformer()
      ..jsonDecodeCallback = (text) {
        try {
          return jsonDecode(text);
        } on FormatException {
          return text;
        }
      };
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_needsJsonContentType(options)) {
            options.contentType = Headers.jsonContentType;
          }
          if (options.extra['skipAuth'] != true) {
            final token = await getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 ||
              error.response?.statusCode == 403) {
            await clearToken();
          }
          handler.next(error);
        },
      ),
    );
    return dio;
  }

  static String errorMessage(Object error, {String? fallback}) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (status == 401 || status == 403) {
        return 'Your session expired. Please log in again.';
      }
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'];
        if (message is String && message.isNotEmpty) return message;
      }
      if (data is String && data.isNotEmpty) return data;
      if (status == 500) {
        return 'The server failed this action. Please try again.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Please try again.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Cannot reach the server. Check your connection.';
      }
    }
    if (fallback != null) return '$fallback ${error.toString()}';
    return error.toString();
  }

  static bool isBadRequest(Object error) =>
      error is DioException && error.response?.statusCode == 400;

  static bool _needsJsonContentType(RequestOptions options) {
    if (options.data == null || options.data is FormData) return false;
    return options.method == 'POST' ||
        options.method == 'PUT' ||
        options.method == 'PATCH' ||
        options.method == 'DELETE';
  }

  static Future<void> saveToken(String token) async {
    _memoryToken = token;
    await _ignoreStorageErrors(
      () => _storage.write(key: 'jwt_token', value: token),
    );
  }

  static Future<void> clearToken() async {
    _memoryToken = null;
    await _ignoreStorageErrors(() => _storage.delete(key: 'jwt_token'));
  }

  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: 'jwt_token') ?? _memoryToken;
    } catch (_) {
      return _memoryToken;
    }
  }

  static Future<void> _ignoreStorageErrors(
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
    } catch (_) {}
  }

  static String? publicUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) {
      final host = uri.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0') {
        return publicUrl(uri.path);
      }
      return url;
    }
    if (url.startsWith('/')) return '$_baseUrl$url';
    return '$_baseUrl/$url';
  }
}
