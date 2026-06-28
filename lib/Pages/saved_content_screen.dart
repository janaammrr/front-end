import 'dart:ui';
import 'package:flutter/material.dart';

class SavedContentScreen extends StatefulWidget {
  const SavedContentScreen({super.key});

  @override
  State<SavedContentScreen> createState() => _SavedContentScreenState();
}

class _SavedContentScreenState extends State<SavedContentScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const List<_SavedVideo> _videos = [
    _SavedVideo(title: 'How to critique UI like a senior designer', creator: 'DesignWithSam', category: 'Design', gradient: [Color(0xFF78350F), Color(0xFF1A0A00)]),
    _SavedVideo(title: 'Budget framework for creators in 60s', creator: 'Finance Lab', category: 'Finance', gradient: [Color(0xFF134E4A), Color(0xFF001A18)]),
    _SavedVideo(title: 'Python data structures explained simply', creator: 'CodeWithAhmed', category: 'Tech', gradient: [Color(0xFF1E3A5F), Color(0xFF001020)]),
    _SavedVideo(title: 'How AI is changing product management', creator: 'Ibrahim N.', category: 'AI', gradient: [Color(0xFF1E3A5F), Color(0xFF001020)]),
    _SavedVideo(title: 'Color theory crash course for beginners', creator: 'DesignWithSam', category: 'Design', gradient: [Color(0xFF4C1D95), Color(0xFF0A0020)]),
  ];

  static const List<_SavedItem> _workshops = [
    _SavedItem(title: 'Creative Branding Sprint', sub: 'Sarah K.  ·  May 10 • 5:30 PM', badge: '\$49', badgeColor: Color(0xFFFF7A18), icon: Icons.school_outlined),
    _SavedItem(title: 'AI Tools for Product Teams', sub: 'Ibrahim N.  ·  May 14 • 7:00 PM', badge: 'Free', badgeColor: Color(0xFF10B981), icon: Icons.school_outlined),
    _SavedItem(title: 'Mobile UI Motion Lab', sub: 'Kareem T.  ·  May 22 • 8:00 PM', badge: '\$59', badgeColor: Color(0xFFFF7A18), icon: Icons.school_outlined),
  ];

  static const List<_SavedItem> _events = [
    _SavedItem(title: 'Flame Creator Summit 2025', sub: 'Flame Team  ·  Jun 5', badge: 'In-Person', badgeColor: Color(0xFF10B981), icon: Icons.event_outlined),
    _SavedItem(title: 'AI in Education Webinar', sub: 'Ibrahim N.  ·  Jun 12', badge: 'Online', badgeColor: Color(0xFF3B82F6), icon: Icons.event_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: _GlowOrb(color: const Color(0xFFFF7A18).withValues(alpha: 0.16), size: 200)),
          Positioned(bottom: -100, left: -60, child: _GlowOrb(color: const Color(0xFF6D28D9).withValues(alpha: 0.14), size: 240)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saved Content', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                          Text('130 saved items', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.bookmark_rounded, color: Color(0xFFFF7A18), size: 24),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFFF7A18),
                  indicatorWeight: 2,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF6B7280),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  dividerColor: Colors.white.withValues(alpha: 0.08),
                  tabs: [
                    Tab(text: 'Videos (${_videos.length})'),
                    Tab(text: 'Workshops (${_workshops.length})'),
                    Tab(text: 'Events (${_events.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _VideosGrid(videos: _videos),
                      _ItemsList(items: _workshops),
                      _ItemsList(items: _events),
                    ],
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

class _VideosGrid extends StatelessWidget {
  const _VideosGrid({required this.videos});

  final List<_SavedVideo> videos;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72),
      itemCount: videos.length,
      itemBuilder: (_, i) {
        final v = videos[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: v.gradient))),
              Container(color: Colors.black26),
              const Center(child: Icon(Icons.play_circle_outline_rounded, color: Colors.white54, size: 40)),
              Positioned(
                top: 10, left: 10,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFFF7A18), borderRadius: BorderRadius.circular(999)), child: Text(v.category, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
              ),
              Positioned(
                top: 10, right: 10,
                child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle), child: const Icon(Icons.bookmark_rounded, color: Color(0xFFFF7A18), size: 16)),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent])),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(v.title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.3)),
                    const SizedBox(height: 3),
                    Text(v.creator, style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 11)),
                  ]),
                ),
              ),
              Positioned.fill(child: Material(color: Colors.transparent, child: InkWell(onTap: () {}))),
            ],
          ),
        );
      },
    );
  }
}

class _ItemsList extends StatelessWidget {
  const _ItemsList({required this.items});

  final List<_SavedItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final item = items[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
              child: Row(
                children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFFF7A18).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Icon(item.icon, color: const Color(0xFFFF7A18), size: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(item.sub, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: item.badgeColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
                    child: Text(item.badge, style: TextStyle(color: item.badgeColor, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SavedVideo {
  const _SavedVideo({required this.title, required this.creator, required this.category, required this.gradient});

  final String title, creator, category;
  final List<Color> gradient;
}

class _SavedItem {
  const _SavedItem({required this.title, required this.sub, required this.badge, required this.badgeColor, required this.icon});

  final String title, sub, badge;
  final Color badgeColor;
  final IconData icon;
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
