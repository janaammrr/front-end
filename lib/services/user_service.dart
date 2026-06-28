import '../models/user_model.dart';
import 'api_client.dart';

class UserService {
  static Future<UserModel> getMe() async {
    final response = await ApiClient.instance.get('/api/users/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
