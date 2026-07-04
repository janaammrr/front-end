import 'api_client.dart';

class CommentAuthor {
  final int id;
  final String name;
  final String? username;

  CommentAuthor({required this.id, required this.name, this.username});

  factory CommentAuthor.fromJson(Map<String, dynamic> json) {
    final firstName =
        json['firstName'] as String? ?? json['firstname'] as String? ?? '';
    final lastName =
        json['lastName'] as String? ?? json['lastname'] as String? ?? '';
    return CommentAuthor(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '$firstName $lastName'.trim(),
      username: json['username'] as String?,
    );
  }
}

class CommentModel {
  final int id;
  final String content;
  final CommentAuthor user;

  CommentModel({required this.id, required this.content, required this.user});

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
    id: (json['id'] as num).toInt(),
    content: json['content'] as String? ?? '',
    user: CommentAuthor.fromJson(
      json['user'] as Map<String, dynamic>? ??
          json['author'] as Map<String, dynamic>? ??
          const {},
    ),
  );
}

class CommentService {
  static Future<List<CommentModel>> getComments(int reelId) async {
    final response = await ApiClient.instance.get('/api/comments/$reelId');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<CommentModel> addComment(int reelId, String content) async {
    final response = await ApiClient.instance.post(
      '/api/comments/$reelId',
      data: {'content': content},
    );
    return CommentModel.fromJson(response.data as Map<String, dynamic>);
  }
}
