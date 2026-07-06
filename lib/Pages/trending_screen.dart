import 'package:flutter/material.dart';

import '../components/user_avatar.dart';
import '../models/post_model.dart';
import '../models/reel_model.dart';
import '../services/api_client.dart';
import '../services/post_service.dart';
import '../services/reel_service.dart';
import 'post_detail_screen.dart';
import 'reel_viewer_screen.dart';
import '../theme/app_theme.dart';

/// A trending reel or post, normalized into one shape for the discovery
/// grid. Only reels and posts are considered "trending" — no fabricated
/// topics/hashtags, since the backend has no such concept.
class _TrendingItem {
  const _TrendingItem({
    required this.isReel,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.likeCount,
    required this.commentOrViewCount,
    required this.commentOrViewIcon,
    required this.onTap,
  });

  final bool isReel;
  final String? imageUrl;
  final String title;
  final String subtitle;
  final int likeCount;
  final int commentOrViewCount;
  final IconData commentOrViewIcon;
  final VoidCallback onTap;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  bool _loading = true;
  String? _error;
  List<_TrendingItem> _visualItems = [];
  List<_TrendingItem> _textItems = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([PostService.getAll(), ReelService.getAll()]);
      final posts = results[0] as List<PostModel>;
      final reels = results[1] as List<ReelModel>;

      final reelItems = reels.map((reel) {
        return _TrendingItem(
          isReel: true,
          imageUrl: reel.thumbnailUrl,
          title: reel.creatorName,
          subtitle: reel.caption,
          likeCount: reel.likesCount,
          commentOrViewCount: reel.views,
          commentOrViewIcon: Icons.visibility_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReelViewerScreen(reels: reels, initialIndex: reels.indexOf(reel))),
          ),
        );
      }).toList();

      final postItems = posts.map((post) {
        return _TrendingItem(
          isReel: false,
          imageUrl: post.mediaUrls.isNotEmpty ? post.mediaUrls.first : null,
          title: post.author.fullName,
          subtitle: post.content,
          likeCount: post.likeCount,
          commentOrViewCount: post.commentCount,
          commentOrViewIcon: Icons.chat_bubble_outline_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
          ),
        );
      }).toList();

      final all = [...reelItems, ...postItems]..sort((a, b) => b.likeCount.compareTo(a.likeCount));
      final visual = all.where((e) => e.hasImage).take(20).toList();
      final text = all.where((e) => !e.hasImage).take(15).toList();

      if (!mounted) return;
      setState(() {
        _visualItems = visual;
        _textItems = text;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.errorMessage(e, fallback: 'Could not load trending content.');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Row(
          children: [
            Text('Trending', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            SizedBox(width: 6),
            Text('🔥'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.amber));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_visualItems.isEmpty && _textItems.isEmpty) {
      return const Center(
        child: Text('Nothing trending right now.', style: TextStyle(color: Colors.white54)),
      );
    }

    final left = <_TrendingItem>[];
    final right = <_TrendingItem>[];
    for (var i = 0; i < _visualItems.length; i++) {
      (i.isEven ? left : right).add(_visualItems[i]);
    }

    return RefreshIndicator(
      color: AppColors.amber,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(999)),
                  child: const Text('All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_visualItems.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Column(children: [for (final item in left) _VisualCard(item: item)])),
                const SizedBox(width: 8),
                Expanded(child: Column(children: [for (final item in right) _VisualCard(item: item)])),
              ],
            ),
          for (final item in _textItems) _TextCard(item: item),
        ],
      ),
    );
  }
}

class _VisualCard extends StatelessWidget {
  const _VisualCard({required this.item});

  final _TrendingItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: item.isReel ? 0.72 : 1.1,
                child: Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppColors.surface2),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: Colors.white70, size: 12),
                          const SizedBox(width: 3),
                          Text('${item.likeCount}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(width: 10),
                          Icon(item.commentOrViewIcon, color: Colors.white70, size: 12),
                          const SizedBox(width: 3),
                          Text('${item.commentOrViewCount}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (item.isReel)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Text-only post card (screenshot 4 style) for trending posts with no photo.
class _TextCard extends StatelessWidget {
  const _TextCard({required this.item});

  final _TrendingItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(displayName: item.title, radius: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(item.subtitle, style: const TextStyle(color: Colors.white70, height: 1.4)),
              const Divider(color: Colors.white12, height: 24),
              Row(
                children: [
                  const Icon(Icons.favorite_border_rounded, color: Colors.white54, size: 18),
                  const SizedBox(width: 6),
                  Text('${item.likeCount}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(width: 20),
                  const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white54, size: 17),
                  const SizedBox(width: 6),
                  Text('${item.commentOrViewCount}', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
