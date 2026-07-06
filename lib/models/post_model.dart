class PostAuthor {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? username;

  const PostAuthor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.username,
  });

  String get fullName => '$firstName $lastName';

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: (json['id'] as num).toInt(),
      firstName:
          json['firstName'] as String? ?? json['firstname'] as String? ?? '',
      lastName:
          json['lastName'] as String? ?? json['lastname'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
    );
  }
}

class PostModel {
  final int id;
  final String content;
  final PostAuthor author;
  final String createdAt;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final List<String> mediaUrls;

  const PostModel({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
    this.mediaUrls = const [],
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: (json['id'] as num).toInt(),
      content: json['content'] as String? ?? '',
      author: PostAuthor.fromJson(
        json['author'] as Map<String, dynamic>? ??
            json['user'] as Map<String, dynamic>? ??
            const {},
      ),
      createdAt: json['createdAt'] as String? ?? '',
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
      mediaUrls: (json['mediaUrls'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }
}
