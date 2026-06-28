import 'package:dio/dio.dart';
import 'api_client.dart';

class CommunityUser {
  final int id;
  final String firstname;
  final String lastname;

  CommunityUser({required this.id, required this.firstname, required this.lastname});

  String get displayName => '$firstname $lastname'.trim();
  String get initials {
    final f = firstname.isNotEmpty ? firstname[0] : '';
    final l = lastname.isNotEmpty ? lastname[0] : '';
    return (f + l).toUpperCase();
  }

  factory CommunityUser.fromJson(Map<String, dynamic> j) => CommunityUser(
        id: (j['id'] as num).toInt(),
        firstname: j['firstname'] as String? ?? '',
        lastname: j['lastname'] as String? ?? '',
      );
}

class CommunityModel {
  final int id;
  final String name;
  final String description;
  final String? photoUrl;
  final CommunityUser admin;
  final int memberCount;

  CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    this.photoUrl,
    required this.admin,
    required this.memberCount,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> j) => CommunityModel(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        photoUrl: j['photoUrl'] as String?,
        admin: CommunityUser.fromJson(j['admin'] as Map<String, dynamic>),
        memberCount: (j['memberCount'] as num?)?.toInt() ?? 0,
      );
}

class CommunityPostModel {
  final int id;
  final String content;
  final String? imageUrl;
  final CommunityUser author;
  int likesCount;
  bool likedByMe;

  CommunityPostModel({
    required this.id,
    required this.content,
    this.imageUrl,
    required this.author,
    required this.likesCount,
    required this.likedByMe,
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> j) => CommunityPostModel(
        id: (j['id'] as num).toInt(),
        content: j['content'] as String? ?? '',
        imageUrl: j['imageUrl'] as String?,
        author: CommunityUser.fromJson(j['author'] as Map<String, dynamic>),
        likesCount: (j['likesCount'] as num?)?.toInt() ?? 0,
        likedByMe: j['likedByMe'] as bool? ?? false,
      );
}

class CommunityService {
  static Future<List<CommunityModel>> getAll() async {
    final res = await ApiClient.instance.get('/api/communities');
    final list = res.data as List<dynamic>;
    return list.map((e) => CommunityModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> join(int communityId) async {
    await ApiClient.instance.post('/api/communities/$communityId/join');
  }

  static Future<void> leave(int communityId) async {
    await ApiClient.instance.delete('/api/communities/$communityId/leave');
  }

  static Future<List<CommunityPostModel>> getPosts(int communityId) async {
    final res = await ApiClient.instance.get('/api/communities/$communityId/posts');
    final list = res.data as List<dynamic>;
    return list.map((e) => CommunityPostModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> createPost(int communityId, String content) async {
    final form = FormData.fromMap({'content': content});
    await ApiClient.instance.post('/api/communities/$communityId/posts', data: form);
  }

  static Future<CommunityPostModel> likePost(int communityId, int postId) async {
    final res = await ApiClient.instance.post('/api/communities/$communityId/posts/$postId/like');
    return CommunityPostModel.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<CommunityPostModel> unlikePost(int communityId, int postId) async {
    final res = await ApiClient.instance.delete('/api/communities/$communityId/posts/$postId/like');
    return CommunityPostModel.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<CommunityModel> create(String name, String description) async {
    final form = FormData.fromMap({'name': name, 'description': description});
    final res = await ApiClient.instance.post('/api/communities', data: form);
    return CommunityModel.fromJson(res.data as Map<String, dynamic>);
  }
}
