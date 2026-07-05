import '../models/event_model.dart';
import '../models/user_model.dart';
import '../models/workshop_model.dart';
import 'api_client.dart';
import 'follow_service.dart';

class Recommendations {
  final String preferences;
  final List<EventModel> events;
  final List<WorkshopModel> workshops;

  const Recommendations({
    required this.preferences,
    required this.events,
    required this.workshops,
  });

  factory Recommendations.fromJson(Map<String, dynamic> json) {
    return Recommendations(
      preferences: json['preferences'] as String? ?? '',
      events: (json['events'] as List<dynamic>? ?? [])
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      workshops: (json['workshops'] as List<dynamic>? ?? [])
          .map((e) => WorkshopModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UserService {
  static Future<UserModel> getMe() async {
    final response = await ApiClient.instance.get('/api/users/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<UserModel> getByUsername(String username) async {
    final response = await ApiClient.instance.get('/api/users/$username');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<UserModel> getMeFull() async {
    final response = await ApiClient.instance.get('/api/users/me/full');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<UserModel> updateProfile({
    String? username,
    String? bio,
    String? location,
  }) async {
    final body = <String, dynamic>{
      if (username != null) 'username': username,
      if (bio != null) 'bio': bio,
      if (location != null) 'location': location,
    };
    final response = await ApiClient.instance.put('/api/users/me', data: body);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<Recommendations> getRecommendations({int limit = 10}) async {
    final response = await ApiClient.instance.get(
      '/api/users/recommendations',
      queryParameters: {'limit': limit},
    );
    return Recommendations.fromJson(response.data as Map<String, dynamic>);
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
