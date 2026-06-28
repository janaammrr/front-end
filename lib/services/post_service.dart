import '../models/post_model.dart';
import 'api_client.dart';

class PostService {
  static Future<List<PostModel>> getAll() async {
    final response = await ApiClient.instance.get('/api/posts');
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

  static Future<void> toggleLike(int postId) =>
      ApiClient.instance.post('/api/posts/$postId/likes/toggle');

  static Future<void> addComment(int postId, String content) =>
      ApiClient.instance.post(
        '/api/posts/$postId/comments',
        data: {'content': content},
      );

  static Future<void> deletePost(int postId) =>
      ApiClient.instance.delete('/api/posts/$postId');
}
