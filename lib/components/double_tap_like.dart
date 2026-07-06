import 'package:flutter/material.dart';

/// Shows a heart burst overlay for ~500ms. Used to give feedback for the
/// double-tap-to-like gesture on posts and reels.
class LikeBurstOverlay extends StatefulWidget {
  const LikeBurstOverlay({super.key, required this.controller});

  final AnimationController controller;

  @override
  State<LikeBurstOverlay> createState() => LikeBurstOverlayState();
}

class LikeBurstOverlayState extends State<LikeBurstOverlay> {
  @override
  Widget build(BuildContext context) {
    final scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
    ]).animate(widget.controller);

    return IgnorePointer(
      child: ScaleTransition(
        scale: scale,
        child: const Icon(
          Icons.favorite_rounded,
          color: Colors.white,
          size: 90,
          shadows: [Shadow(color: Colors.black54, blurRadius: 16)],
        ),
      ),
    );
  }
}

/// Wraps [child] with single-tap and double-tap-to-like handling. Matches
/// the standard convention: double-tap only *likes* (never unlikes) and
/// plays a brief heart animation; it never toggles an already-liked item.
class DoubleTapLike extends StatefulWidget {
  const DoubleTapLike({
    super.key,
    required this.child,
    required this.isLiked,
    required this.onLike,
    this.onTap,
  });

  final Widget child;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback? onTap;

  @override
  State<DoubleTapLike> createState() => _DoubleTapLikeState();
}

class _DoubleTapLikeState extends State<DoubleTapLike> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!widget.isLiked) widget.onLike();
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          LikeBurstOverlay(controller: _controller),
        ],
      ),
    );
  }
}
