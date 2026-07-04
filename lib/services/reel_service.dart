import 'package:dio/dio.dart';
import '../models/reel_model.dart';
import 'api_client.dart';

class ReelService {
  static Future<List<ReelModel>> getAll() async {
    // Deliberately authenticated (not publicOptions): the backend only
    // returns accurate likedByMe/savedByMe when it knows who's asking.
    final response = await ApiClient.instance.get('/api/reels');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => ReelModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ReelModel>> getByUser(int userId) async {
    final response = await ApiClient.instance.get('/api/reels/user/$userId');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => ReelModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<void> toggleLike(int reelId) =>
      ApiClient.instance.post('/api/reels/$reelId/like');

  static Future<void> toggleSave(int reelId) =>
      ApiClient.instance.post('/api/reels/$reelId/save');

  static Future<void> deleteReel(int reelId) =>
      ApiClient.instance.delete('/api/reels/$reelId');

  static Future<void> reportReel(int reelId, String reason) =>
      ApiClient.instance.post('/api/reports', data: {
        'targetType': 'REEL',
        'targetId': reelId,
        'reason': reason,
      });

  static Future<List<ReelModel>> getLiked() async {
    final response = await ApiClient.instance.get('/api/reels/liked');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => ReelModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ReelModel>> getSaved() async {
    final response = await ApiClient.instance.get('/api/reels/saved');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => ReelModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<void> upload({
    required String videoPath,
    required String caption,
    required String category,
  }) async {
    final formData = FormData.fromMap({
      'video': await MultipartFile.fromFile(
        videoPath,
        filename: videoPath.split('/').last,
      ),
    });
    await ApiClient.instance.post(
      '/api/reels/upload',
      data: formData,
      queryParameters: {'caption': caption, 'categories': category},
    );
  }
}
