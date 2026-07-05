import 'package:flutter/material.dart';
import '../components/reel_thumbnail.dart';
import '../services/reel_service.dart';
import '../models/reel_model.dart';
import 'reel_viewer_screen.dart';
import '../theme/app_theme.dart';

class SavedContentScreen extends StatefulWidget {
  const SavedContentScreen({super.key});

  @override
  State<SavedContentScreen> createState() => _SavedContentScreenState();
}

class _SavedContentScreenState extends State<SavedContentScreen> {
  List<ReelModel> _reels = [];
  bool _loading = true;
  String? _error;

  // On-brand fallback thumbnails, replacing the previous unrelated
  // brown/teal/navy/purple hues with variations of the site's palette.
  static const _gradients = [
    [AppColors.amberSoft, AppColors.bg],
    [AppColors.surface2, AppColors.bg],
    [AppColors.borderHi, AppColors.bg],
    [AppColors.surface, AppColors.bg],
    [AppColors.amber, AppColors.bg],
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final reels = await ReelService.getSaved();
      if (mounted) setState(() { _reels = reels; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: _GlowOrb(color: AppColors.amber.withValues(alpha: 0.16), size: 200)),
          Positioned(bottom: -100, left: -60, child: _GlowOrb(color: AppColors.amberSoft.withValues(alpha: 0.14), size: 240)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Saved Content', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                          Text('${_reels.length} saved reels', style: const TextStyle(color: AppColors.text3, fontSize: 13)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.bookmark_rounded, color: AppColors.amber, size: 24),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
                      : _error != null
                          ? Center(
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.error_outline, color: Colors.white38, size: 48),
                                const SizedBox(height: 12),
                                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.amber, fontSize: 13)),
                                const SizedBox(height: 16),
                                ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber), child: const Text('Retry', style: TextStyle(color: Colors.white))),
                              ]),
                            )
                          : _reels.isEmpty
                              ? const Center(
                                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.bookmark_border_rounded, color: Colors.white24, size: 64),
                                    SizedBox(height: 16),
                                    Text('No saved reels yet', style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w600)),
                                    SizedBox(height: 8),
                                    Text('Save reels on the home feed to see them here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 13)),
                                  ]),
                                )
                              : RefreshIndicator(
                                  onRefresh: _load,
                                  color: AppColors.amber,
                                  child: GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72,
                                    ),
                                    itemCount: _reels.length,
                                    itemBuilder: (context, i) => _ReelCard(
                                      reel: _reels[i],
                                      gradient: _gradients[i % _gradients.length],
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReelViewerScreen(
                                            reels: _reels,
                                            initialIndex: i,
                                          ),
                                        ),
                                      ),
                                    ),
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

class _ReelCard extends StatelessWidget {
  const _ReelCard({required this.reel, required this.gradient, required this.onTap});

  final ReelModel reel;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ReelThumbnail(thumbnailUrl: reel.thumbnailUrl, fallbackGradient: gradient),
          Container(color: Colors.black26),
          Positioned(
            top: 10, right: 10,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
              child: const Icon(Icons.bookmark_rounded, color: AppColors.amber, size: 16),
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
                  Text(reel.caption, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.3)),
                  const SizedBox(height: 3),
                  Text(reel.creatorName, style: const TextStyle(color: AppColors.text2, fontSize: 11)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.favorite_rounded, color: AppColors.error, size: 12),
                    const SizedBox(width: 3),
                    Text('${reel.likesCount}', style: const TextStyle(color: AppColors.text3, fontSize: 11)),
                  ]),
                ],
              ),
            ),
          ),
          Positioned.fill(child: Material(color: Colors.transparent, child: InkWell(onTap: onTap))),
        ],
      ),
    );
  }
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
