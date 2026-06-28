import 'api_client.dart';

class FollowUser {
  final int id;
  final String firstname;
  final String lastname;
  final String? profileUrl;

  FollowUser({required this.id, required this.firstname, required this.lastname, this.profileUrl});

  String get displayName => '$firstname $lastname'.trim();
  String get initials {
    final f = firstname.isNotEmpty ? firstname[0] : '';
    final l = lastname.isNotEmpty ? lastname[0] : '';
    return (f + l).toUpperCase();
  }

  factory FollowUser.fromJson(Map<String, dynamic> j) => FollowUser(
        id: (j['id'] as num).toInt(),
        firstname: j['firstname'] as String? ?? '',
        lastname: j['lastname'] as String? ?? '',
        profileUrl: j['profileUrl'] as String?,
      );
}

class FollowService {
  static Future<void> follow(int targetId) async {
    await ApiClient.instance.post('/api/users/$targetId/follow');
  }

  static Future<void> unfollow(int targetId) async {
    await ApiClient.instance.delete('/api/users/$targetId/follow');
  }

  static Future<List<FollowUser>> getFollowers(int userId) async {
    final res = await ApiClient.instance.get('/api/users/$userId/followers');
    final list = res.data as List<dynamic>;
    return list.map((e) => FollowUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<FollowUser>> getFollowing(int userId) async {
    final res = await ApiClient.instance.get('/api/users/$userId/following');
    final list = res.data as List<dynamic>;
    return list.map((e) => FollowUser.fromJson(e as Map<String, dynamic>)).toList();
  }
}
