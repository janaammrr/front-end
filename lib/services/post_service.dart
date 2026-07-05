import '../models/post_model.dart';
import 'api_client.dart';
import 'comment_service.dart';

class PostService {
  static Future<List<PostModel>> getAll() async {
    final response = await ApiClient.instance.get(
      '/api/posts',
      options: ApiClient.publicOptions,
    );
    final list = response.data as List<dynamic>;
    return list
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<PostModel> getById(int postId) async {
    final response = await ApiClient.instance.get('/api/posts/$postId');
    return PostModel.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<List<PostModel>> getMyPosts() async {
    final response = await ApiClient.instance.get('/api/posts/me');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<PostModel>> getByUser(int userId) async {
    final response = await ApiClient.instance.get('/api/posts/user/$userId');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<PostModel> create(String content) async {
    final response = await ApiClient.instance.post(
      '/api/posts',
      data: {'content': content},
    );
    return PostModel.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<PostModel> update(int postId, String content) async {
    final response = await ApiClient.instance.put(
      '/api/posts/$postId',
      data: {'content': content},
    );
    return PostModel.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<void> toggleLike(int postId) =>
      ApiClient.instance.post('/api/posts/$postId/likes/toggle');

  static Future<List<CommentModel>> getComments(int postId) async {
    final response = await ApiClient.instance.get('/api/posts/$postId/comments');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<CommentModel> addComment(int postId, String content) async {
    final response = await ApiClient.instance.post(
      '/api/posts/$postId/comments',
      data: {'content': content},
    );
    return CommentModel.fromJson(response.data as Map<String, dynamic>);
  }

  static Future<void> deletePost(int postId) =>
      ApiClient.instance.delete('/api/posts/$postId');
}
