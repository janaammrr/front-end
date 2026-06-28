class ReelModel {
  final int id;
  final String caption;
  final String? videoUrl;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final int views;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;
  final bool savedByMe;
  final String creatorName;
  final int? creatorId;

  const ReelModel({
    required this.id,
    required this.caption,
    this.videoUrl,
    this.thumbnailUrl,
    this.durationSeconds,
    required this.views,
    required this.likesCount,
    required this.commentsCount,
    required this.likedByMe,
    required this.savedByMe,
    required this.creatorName,
    this.creatorId,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>?;
    return ReelModel(
      id: (json['id'] as num).toInt(),
      caption: json['caption'] as String? ?? '',
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      views: (json['views'] as num?)?.toInt() ?? 0,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
      savedByMe: json['savedByMe'] as bool? ?? false,
      creatorName: creator?['name'] as String? ?? 'Unknown',
      creatorId: (creator?['id'] as num?)?.toInt(),
    );
  }
}
