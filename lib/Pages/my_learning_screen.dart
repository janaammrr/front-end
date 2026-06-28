import 'dart:ui';
import 'package:flutter/material.dart';

class MyLearningScreen extends StatefulWidget {
  const MyLearningScreen({super.key});

  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends State<MyLearningScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'AI', 'Design', 'Finance', 'Tech', 'Business'];

  final List<_LearnedVideo> _videos = const [
    _LearnedVideo(title: '3 prompts to learn any topic faster with AI', creator: 'Dr. Amina', category: 'AI', progress: 1.0, gradient: [Color(0xFF7C2D12), Color(0xFF1A0A00)]),
    _LearnedVideo(title: 'How to critique UI like a senior designer', creator: 'DesignWithSam', category: 'Design', progress: 1.0, gradient: [Color(0xFF78350F), Color(0xFF1A0A00)]),
    _LearnedVideo(title: 'Budget framework for creators in 60 seconds', creator: 'Finance Lab', category: 'Finance', progress: 0.75, gradient: [Color(0xFF134E4A), Color(0xFF001A18)]),
    _LearnedVideo(title: 'Python data structures explained simply', creator: 'CodeWithAhmed', category: 'Tech', progress: 0.5, gradient: [Color(0xFF1E3A5F), Color(0xFF001020)]),
    _LearnedVideo(title: 'How AI is changing product management', creator: 'Ibrahim N.', category: 'AI', progress: 1.0, gradient: [Color(0xFF1E3A5F), Color(0xFF001020)]),
    _LearnedVideo(title: 'Design systems in 5 minutes', creator: 'DesignWithSam', category: 'Design', progress: 0.3, gradient: [Color(0xFF78350F), Color(0xFF1A0A00)]),
    _LearnedVideo(title: 'Startup financial modeling basics', creator: 'Finance Lab', category: 'Finance', progress: 1.0, gradient: [Color(0xFF134E4A), Color(0xFF001A18)]),
    _LearnedVideo(title: 'Git workflows for solo developers', creator: 'CodeWithAhmed', category: 'Tech', progress: 0.9, gradient: [Color(0xFF1E3A5F), Color(0xFF001020)]),
  ];

  List<_LearnedVideo> get _filtered => _selectedCategory == 'All' ? _videos : _videos.where((v) => v.category == _selectedCategory).toList();

  int get _completed => _videos.where((v) => v.progress == 1.0).length;

  @override
  Widget build(BuildContext context) {
    final videos = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: _GlowOrb(color: const Color(0xFFFF7A18).withValues(alpha: 0.16), size: 200)),
          Positioned(bottom: -100, left: -60, child: _GlowOrb(color: const Color(0xFF6D28D9).withValues(alpha: 0.14), size: 240)),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _BackButton(onTap: () => Navigator.of(context).pop()),
                            const SizedBox(width: 12),
                            const Text('My Learning', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _ProgressCard(total: _videos.length, completed: _completed),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final sel = _selectedCategory == _categories[i];
                              return GestureDetector(
                                onTap: () => setState(() => _selectedCategory = _categories[i]),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sel ? const Color(0xFFFF7A18).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: sel ? const Color(0xFFFF7A18) : Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  child: Text(_categories[i], style: TextStyle(color: sel ? Colors.white : const Color(0xFFB2B8CB), fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('${videos.length} videos', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      childCount: videos.length,
                      (_, i) => _VideoCard(video: videos[i]),
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

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.total, required this.completed});

  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : completed / total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFFFF7A18).withValues(alpha: 0.18), const Color(0xFF6D28D9).withValues(alpha: 0.12)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFF7A18), size: 20),
                  const SizedBox(width: 8),
                  const Text('Learning Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  Text('${(pct * 100).toInt()}%', style: const TextStyle(color: Color(0xFFFF7A18), fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF7A18)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatChip(label: '$completed Completed', icon: Icons.check_circle_outline_rounded),
                  const SizedBox(width: 10),
                  _StatChip(label: '${total - completed} In Progress', icon: Icons.timelapse_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video});

  final _LearnedVideo video;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: video.gradient))),
          Container(color: Colors.black26),
          Positioned(
            top: 10, left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFFF7A18), borderRadius: BorderRadius.circular(999)),
              child: Text(video.category, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ),
          if (video.progress == 1.0)
            Positioned(
              top: 10, right: 10,
              child: Container(
                width: 26, height: 26,
                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              ),
            ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: video.progress,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF7A18)),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(video.title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.3)),
                      const SizedBox(height: 4),
                      Text(video.creator, style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(child: Material(color: Colors.transparent, child: InkWell(onTap: () {}))),
        ],
      ),
    );
  }
}

class _LearnedVideo {
  const _LearnedVideo({required this.title, required this.creator, required this.category, required this.progress, required this.gradient});

  final String title, creator, category;
  final double progress;
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
