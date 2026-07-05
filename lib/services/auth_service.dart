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

  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await ApiClient.instance.put(
      '/api/users/me/password',
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
  }

  static Future<bool> isLoggedIn() async {
    final token = await ApiClient.getToken();
    return token != null;
  }

  static Future<void> forgotPassword(String email) async {
    await ApiClient.instance.post(
      '/api/v1/auth/forgot-password',
      data: {'email': email},
      options: ApiClient.publicOptions,
    );
  }

  static Future<bool> validateResetToken(String token) async {
    try {
      await ApiClient.instance.get(
        '/api/v1/auth/reset-password/validate',
        queryParameters: {'token': token},
        options: ApiClient.publicOptions,
      );
      return true;
    } on DioException {
      return false;
    }
  }

  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await ApiClient.instance.post(
      '/api/v1/auth/reset-password',
      data: {'token': token, 'newPassword': newPassword},
      options: ApiClient.publicOptions,
    );
  }

  static bool isAuthFailure(Object error) {
    return error is DioException && error.response?.statusCode == 401;
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
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final serverMessage = data['message'] ?? data['error'];
      if (serverMessage is String && serverMessage.isNotEmpty) {
        // The backend returns a bare 500 with no descriptive message for
        // some failures it should really treat as 400s (e.g. registering
        // with an email that's already taken), so give a more actionable
        // hint for that case instead of just echoing "Internal Server Error".
        if (e.response?.statusCode == 500) {
          return 'The server could not complete this request ($serverMessage). '
              'If you already have an account with this email, try logging in instead.';
        }
        return serverMessage;
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
