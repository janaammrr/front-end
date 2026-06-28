import 'dart:ui';
import 'package:flutter/material.dart';

class LikedVideosScreen extends StatelessWidget {
  const LikedVideosScreen({super.key});

  static const List<_LikedVideo> _videos = [
    _LikedVideo(title: '3 prompts to learn any topic faster', creator: 'Dr. Amina', category: 'AI', gradient: [Color(0xFF7C2D12), Color(0xFF1A0A00)]),
    _LikedVideo(title: 'How to critique UI like a senior designer', creator: 'DesignWithSam', category: 'Design', gradient: [Color(0xFF78350F), Color(0xFF1A0A00)]),
    _LikedVideo(title: 'Budget framework for creators in 60s', creator: 'Finance Lab', category: 'Finance', gradient: [Color(0xFF134E4A), Color(0xFF001A18)]),
    _LikedVideo(title: 'Python data structures explained', creator: 'CodeWithAhmed', category: 'Tech', gradient: [Color(0xFF1E3A5F), Color(0xFF001020)]),
    _LikedVideo(title: 'How AI is changing product management', creator: 'Ibrahim N.', category: 'AI', gradient: [Color(0xFF1E3A5F), Color(0xFF001020)]),
    _LikedVideo(title: 'Design systems in 5 minutes', creator: 'DesignWithSam', category: 'Design', gradient: [Color(0xFF78350F), Color(0xFF1A0A00)]),
    _LikedVideo(title: 'Startup financial modeling basics', creator: 'Finance Lab', category: 'Finance', gradient: [Color(0xFF134E4A), Color(0xFF001A18)]),
    _LikedVideo(title: 'Git workflows for solo developers', creator: 'CodeWithAhmed', category: 'Tech', gradient: [Color(0xFF1E3A5F), Color(0xFF001020)]),
    _LikedVideo(title: 'Color theory crash course', creator: 'DesignWithSam', category: 'Design', gradient: [Color(0xFF4C1D95), Color(0xFF0A0020)]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: _GlowOrb(color: const Color(0xFFEF4444).withValues(alpha: 0.16), size: 200)),
          Positioned(bottom: -100, left: -60, child: _GlowOrb(color: const Color(0xFF6D28D9).withValues(alpha: 0.14), size: 240)),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      children: [
                        _BackButton(onTap: () => Navigator.of(context).pop()),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Liked Videos', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                            Text('89 videos', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 24),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      childCount: _videos.length,
                      (_, i) => _VideoCard(video: _videos[i]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video});

  final _LikedVideo video;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: video.gradient))),
          Container(color: Colors.black26),
          const Center(child: Icon(Icons.play_circle_outline_rounded, color: Colors.white54, size: 40)),
          Positioned(
            top: 10, left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFFF7A18), borderRadius: BorderRadius.circular(999)),
              child: Text(video.category, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ),
          Positioned(
            top: 10, right: 10,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.85), shape: BoxShape.circle),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent])),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.3)),
                  const SizedBox(height: 3),
                  Text(video.creator, style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 11)),
                ],
              ),
            ),
          ),
          Positioned.fill(child: Material(color: Colors.transparent, child: InkWell(onTap: () {}))),
        ],
      ),
    );
  }
}

class _LikedVideo {
  const _LikedVideo({required this.title, required this.creator, required this.category, required this.gradient});

  final String title, creator, category;
  final List<Color> gradient;
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 30)]));
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}
