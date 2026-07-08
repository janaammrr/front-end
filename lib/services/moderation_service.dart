import 'api_client.dart';

class ModerationItem {
  final int reelId;
  final String reelCaption;
  final String? videoUrl;
  final String creatorEmail;
  final bool aiFlagged;
  final double aiConfidenceScore;
  final String? aiReason;
  final String status;

  ModerationItem({
    required this.reelId,
    required this.reelCaption,
    this.videoUrl,
    required this.creatorEmail,
    required this.aiFlagged,
    required this.aiConfidenceScore,
    this.aiReason,
    required this.status,
  });

  factory ModerationItem.fromJson(Map<String, dynamic> j) => ModerationItem(
    reelId: (j['reelId'] as num).toInt(),
    reelCaption: j['reelCaption'] as String? ?? 'Untitled',
    videoUrl: j['videoUrl'] as String?,
    creatorEmail: j['creatorEmail'] as String? ?? '',
    aiFlagged: j['aiFlagged'] as bool? ?? false,
    aiConfidenceScore: (j['aiConfidenceScore'] as num?)?.toDouble() ?? 0.0,
    aiReason: j['aiReason'] as String?,
    status: (j['status'] as String? ?? 'PENDING_REVIEW')
        .toLowerCase()
        .replaceAll('_review', '')
        .replaceAll('ai_flagged', 'flagged'),
  );
}

class ModerationService {
  static Future<List<ModerationItem>> getQueue() async {
    final res = await ApiClient.instance.get('/api/admin/moderation/queue');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => ModerationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ModerationItem>> getAll() async {
    final res = await ApiClient.instance.get('/api/admin/moderation/all');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => ModerationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> review(
    int reelId, {
    required bool approve,
    String note = '',
  }) async {
    await ApiClient.instance.post(
      '/api/admin/moderation/$reelId/review',
      data: {'decision': approve ? 'APPROVED' : 'REJECTED', 'note': note},
    );
  }
}
