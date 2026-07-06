import 'package:dio/dio.dart';
import 'api_client.dart';

class CommunityUser {
  final int id;
  final String firstname;
  final String lastname;
  final String? username;
  final String? profileUrl;

  CommunityUser({
    required this.id,
    required this.firstname,
    required this.lastname,
    this.username,
    this.profileUrl,
  });

  String get displayName => '$firstname $lastname'.trim();
  String get initials {
    final f = firstname.isNotEmpty ? firstname[0] : '';
    final l = lastname.isNotEmpty ? lastname[0] : '';
    return (f + l).toUpperCase();
  }

  factory CommunityUser.fromJson(Map<String, dynamic> j) => CommunityUser(
    id: (j['id'] as num).toInt(),
    firstname: j['firstname'] as String? ?? j['firstName'] as String? ?? '',
    lastname: j['lastname'] as String? ?? j['lastName'] as String? ?? '',
    username: j['username'] as String?,
    profileUrl: j['profileUrl'] as String?,
  );
}

class CommunityModel {
  final int id;
  final String name;
  final String description;
  final String? photoUrl;
  final CommunityUser admin;
  final int memberCount;
  final bool isPrivate;
  final bool isMember;

  CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    this.photoUrl,
    required this.admin,
    required this.memberCount,
    required this.isPrivate,
    required this.isMember,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> j) => CommunityModel(
    id: (j['id'] as num).toInt(),
    name: j['name'] as String? ?? '',
    description: j['description'] as String? ?? '',
    photoUrl: j['photoUrl'] as String?,
    admin: CommunityUser.fromJson(j['admin'] as Map<String, dynamic>),
    memberCount: (j['memberCount'] as num?)?.toInt() ?? 0,
    isPrivate: j['privacyType'] == 'PRIVATE',
    isMember: j['member'] as bool? ?? false,
  );
}

class CommunityPostModel {
  final int id;
  final String content;
  final List<String> mediaUrls;
  final CommunityUser author;
  int likesCount;
  bool likedByMe;
  final int commentsCount;
  final DateTime? createdAt;

  CommunityPostModel({
    required this.id,
    required this.content,
    this.mediaUrls = const [],
    required this.author,
    required this.likesCount,
    required this.likedByMe,
    required this.commentsCount,
    this.createdAt,
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> j) =>
      CommunityPostModel(
        id: (j['id'] as num).toInt(),
        content: j['content'] as String? ?? '',
        mediaUrls: (j['mediaUrls'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        author: CommunityUser.fromJson(j['author'] as Map<String, dynamic>),
        likesCount: (j['likesCount'] as num?)?.toInt() ?? 0,
        likedByMe: j['likedByMe'] as bool? ?? false,
        commentsCount: (j['comments'] as List<dynamic>?)?.length ?? 0,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
      );
}

class CommunityDetailModel {
  final int id;
  final String name;
  final String description;
  final String? photoUrl;
  final bool isPrivate;
  final String postingPermission;
  final CommunityUser owner;
  final List<CommunityUser> admins;
  final List<CommunityUser> members;
  final List<CommunityPostModel> posts;

  CommunityDetailModel({
    required this.id,
    required this.name,
    required this.description,
    this.photoUrl,
    required this.isPrivate,
    required this.postingPermission,
    required this.owner,
    required this.admins,
    required this.members,
    required this.posts,
  });

  factory CommunityDetailModel.fromJson(Map<String, dynamic> j) =>
      CommunityDetailModel(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        photoUrl: j['photoUrl'] as String?,
        isPrivate: j['privacyType'] == 'PRIVATE',
        postingPermission: j['postingPermission'] as String? ?? 'OPEN',
        owner: CommunityUser.fromJson(j['admin'] as Map<String, dynamic>),
        admins: (j['admins'] as List<dynamic>? ?? [])
            .map((e) => CommunityUser.fromJson(e as Map<String, dynamic>))
            .toList(),
        members: (j['members'] as List<dynamic>? ?? [])
            .map((e) => CommunityUser.fromJson(e as Map<String, dynamic>))
            .toList(),
        posts: (j['posts'] as List<dynamic>? ?? [])
            .map((e) => CommunityPostModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CommunityService {
  static Future<List<CommunityModel>> getAll() async {
    // Deliberately authenticated (not publicOptions): the backend only
    // returns an accurate `member` flag when it knows who's asking.
    final res = await ApiClient.instance.get('/api/communities');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => CommunityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> join(int communityId) async {
    await ApiClient.instance.post('/api/communities/$communityId/join');
  }

  static Future<void> requestJoin(int communityId) async {
    await ApiClient.instance.post('/api/communities/$communityId/join-request');
  }

  static Future<void> leave(int communityId) async {
    await ApiClient.instance.delete('/api/communities/$communityId/leave');
  }

  static Future<void> deleteCommunity(int communityId) async {
    await ApiClient.instance.delete('/api/communities/$communityId');
  }

  static Future<List<CommunityPostModel>> getPosts(int communityId) async {
    final res = await ApiClient.instance.get(
      '/api/communities/$communityId/posts',
    );
    final list = res.data as List<dynamic>;
    return list
        .map((e) => CommunityPostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> createPost(
    int communityId,
    String content, {
    String? imagePath,
  }) async {
    final form = FormData.fromMap({
      'content': content,
      if (imagePath != null)
        'files': await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
    });
    await ApiClient.instance.post(
      '/api/communities/$communityId/posts',
      data: form,
    );
  }

  static Future<CommunityPostModel> likePost(
    int communityId,
    int postId,
  ) async {
    final res = await ApiClient.instance.post(
      '/api/communities/$communityId/posts/$postId/like',
    );
    return CommunityPostModel.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<CommunityPostModel> unlikePost(
    int communityId,
    int postId,
  ) async {
    final res = await ApiClient.instance.delete(
      '/api/communities/$communityId/posts/$postId/like',
    );
    return CommunityPostModel.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<CommunityModel> create(
    String name,
    String description, {
    String privacyType = 'PUBLIC',
    String? imagePath,
  }) async {
    final form = FormData.fromMap({
      'name': name,
      'description': description,
      'privacyType': privacyType,
      if (imagePath != null)
        'photo': await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
    });
    final res = await ApiClient.instance.post('/api/communities', data: form);
    return CommunityModel.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<List<CommunityUser>> getMembers(int communityId) async {
    final res = await ApiClient.instance.get(
      '/api/communities/$communityId/members',
    );
    final list = res.data as List<dynamic>;
    return list
        .map((e) => CommunityUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> deletePost(int communityId, int postId) async {
    await ApiClient.instance.delete(
      '/api/communities/$communityId/posts/$postId',
    );
  }

  static Future<CommunityDetailModel> getDetail(int communityId) async {
    final res = await ApiClient.instance.get('/api/communities/$communityId');
    return CommunityDetailModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Only call this once the caller has already confirmed the viewer is the
  /// community owner — the backend returns a 500 (not a clean 403) otherwise.
  static Future<List<CommunityUser>> getPendingJoinRequests(
    int communityId,
  ) async {
    final res = await ApiClient.instance.get(
      '/api/communities/$communityId/join-requests',
    );
    final list = res.data as List<dynamic>;
    return list
        .map((e) => CommunityUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> approveJoinRequest(int communityId, int userId) async {
    await ApiClient.instance.post(
      '/api/communities/$communityId/join-requests/$userId/approve',
    );
  }

  static Future<void> rejectJoinRequest(int communityId, int userId) async {
    await ApiClient.instance.post(
      '/api/communities/$communityId/join-requests/$userId/reject',
    );
  }

  static Future<void> removeMember(int communityId, int memberId) async {
    await ApiClient.instance.delete(
      '/api/communities/$communityId/members/$memberId',
    );
  }

  static Future<void> promoteMember(int communityId, int memberId) async {
    await ApiClient.instance.post(
      '/api/communities/$communityId/members/$memberId/promote',
    );
  }

  static Future<void> demoteMember(int communityId, int memberId) async {
    await ApiClient.instance.post(
      '/api/communities/$communityId/members/$memberId/demote',
    );
  }
}
