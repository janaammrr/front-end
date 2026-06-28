import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthService {
  static Future<void> login(String email, String password) async {
    final response = await ApiClient.instance.post(
      '/api/v1/auth/authenticate',
      data: {'email': email, 'password': password},
    );
    final token = response.data['token'] as String;
    await ApiClient.saveToken(token);
  }

  static Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.instance.post(
      '/api/v1/auth/register',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'role': 'USER',
      },
    );
    final token = response.data['token'] as String;
    await ApiClient.saveToken(token);
  }

  static Future<void> logout() => ApiClient.clearToken();

  static Future<bool> isLoggedIn() async {
    final token = await ApiClient.getToken();
    return token != null;
  }

  static String mapDioError(DioException e) {
    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      return 'Invalid email or password.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Check the server is running.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach server. Check your connection.';
    }
    return e.response?.data?['message'] as String? ??
        'Something went wrong. Please try again.';
  }
}
