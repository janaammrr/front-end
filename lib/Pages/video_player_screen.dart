import 'package:flutter/material.dart';
import 'comments_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.title,
    required this.creator,
    required this.category,
    required this.gradient,
  });

  final String title;
  final String creator;
  final String category;
  final List<Color> gradient;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  bool _showControls = true;
  bool _liked = false;
  bool _bookmarked = false;
  bool _following = false;
  double _progress = 0.32;
  int _likes = 12400;

  late final AnimationController _controlsFadeController;
  late final Animation<double> _controlsFade;

  @override
  void initState() {
    super.initState();
    _controlsFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controlsFade = _controlsFadeController.drive(
      CurveTween(curve: Curves.easeOut),
    );
    _controlsFadeController.forward();
  }

  @override
  void dispose() {
    _controlsFadeController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (!_showControls) _showHideControls();
  }

  void _showHideControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _controlsFadeController.forward();
    } else {
      _controlsFadeController.reverse();
    }
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _showHideControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.gradient,
                ),
              ),
            ),
            Container(color: Colors.black38),
            const Center(
              child: Icon(
                Icons.play_circle_filled_rounded,
                color: Colors.white24,
                size: 120,
              ),
            ),
            FadeTransition(
              opacity: _controlsFade,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0, 0.2, 0.6, 1],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7A18),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  widget.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.more_vert_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 70, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(
                                      0xFFFF7A18,
                                    ).withValues(alpha: 0.25),
                                    child: Text(
                                      widget.creator[0],
                                      style: const TextStyle(
                                        color: Color(0xFFFF7A18),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.creator,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () => setState(
                                      () => _following = !_following,
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _following
                                            ? Colors.white.withValues(
                                                alpha: 0.15,
                                              )
                                            : const Color(0xFFFF7A18),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        _following ? 'Following' : '+ Follow',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: _togglePlay,
                                child: Icon(
                                  _isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onHorizontalDragUpdate: (d) {
                                    final width =
                                        MediaQuery.sizeOf(context).width - 100;
                                    setState(
                                      () => _progress =
                                          (_progress + d.delta.dx / width)
                                              .clamp(0, 1),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: _progress,
                                      minHeight: 4,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Color(0xFFFF7A18),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${(_progress * 60).toInt().toString().padLeft(2, '0')}s / 60s',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 100,
                    child: SafeArea(
                      child: Column(
                        children: [
                          _SideAction(
                            icon: _liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            label: _likes >= 1000
                                ? '${(_likes / 1000).toStringAsFixed(1)}K'
                                : '$_likes',
                            color: _liked
                                ? const Color(0xFFEF4444)
                                : Colors.white,
                            onTap: _toggleLike,
                          ),
                          const SizedBox(height: 20),
                          _SideAction(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: '842',
                            onTap: () => CommentsScreen.show(context),
                          ),
                          const SizedBox(height: 20),
                          _SideAction(
                            icon: Icons.reply_outlined,
                            label: 'Share',
                            onTap: () {},
                          ),
                          const SizedBox(height: 20),
                          _SideAction(
                            icon: _bookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            label: 'Save',
                            color: _bookmarked
                                ? const Color(0xFFFF7A18)
                                : Colors.white,
                            onTap: () =>
                                setState(() => _bookmarked = !_bookmarked),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideAction extends StatelessWidget {
  const _SideAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
