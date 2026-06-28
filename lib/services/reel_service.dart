import 'package:dio/dio.dart';
import '../models/reel_model.dart';
import 'api_client.dart';

class ReelService {
  static Future<List<ReelModel>> getAll() async {
    final response = await ApiClient.instance.get('/api/reels');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => ReelModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<void> toggleLike(int reelId) =>
      ApiClient.instance.post('/api/reels/$reelId/like');

  static Future<void> toggleSave(int reelId) =>
      ApiClient.instance.post('/api/reels/$reelId/save');

  static Future<void> upload({
    required String videoPath,
    required String caption,
    required String preferences,
  }) async {
    final formData = FormData.fromMap({
      'video': await MultipartFile.fromFile(
        videoPath,
        filename: videoPath.split('/').last,
      ),
      'caption': caption,
      'preferences': preferences,
    });
    await ApiClient.instance.post('/api/reels/upload', data: formData);
  }
}
