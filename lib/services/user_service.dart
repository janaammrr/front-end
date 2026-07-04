import '../models/user_model.dart';
import 'api_client.dart';
import 'follow_service.dart';

class UserService {
  static Future<UserModel> getMe() async {
    final response = await ApiClient.instance.get('/api/users/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<UserModel> getByUsername(String username) async {
    final response = await ApiClient.instance.get('/api/users/$username');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<List<FollowUser>> search(String query) async {
    final response = await ApiClient.instance.get(
      '/api/users/search',
      queryParameters: {'query': query},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((json) => FollowUser.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
