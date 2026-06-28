class PostAuthor {
  final int id;
  final String firstName;
  final String lastName;
  final String email;

  const PostAuthor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get fullName => '$firstName $lastName';

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: (json['id'] as num).toInt(),
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
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

  const PostModel({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: (json['id'] as num).toInt(),
      content: json['content'] as String? ?? '',
      author: PostAuthor.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: json['createdAt'] as String? ?? '',
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
    );
  }
}
