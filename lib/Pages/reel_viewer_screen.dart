import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../components/double_tap_like.dart';
import '../components/reel_moderation_sheet.dart';
import '../components/reel_thumbnail.dart';
import '../components/user_avatar.dart';
import '../models/reel_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/reel_service.dart';
import '../services/user_service.dart';
import '../auth/auth.dart';
import 'comments_screen.dart';
import 'public_profile_screen.dart';
import '../theme/app_theme.dart';

/// Full-screen swipeable player for a list of reels, used whenever a video
/// thumbnail is tapped (profile grid, liked videos, saved content, search).
class ReelViewerScreen extends StatefulWidget {
  const ReelViewerScreen({
    super.key,
    required this.reels,
    required this.initialIndex,
  });

  final List<ReelModel> reels;
  final int initialIndex;

  @override
  State<ReelViewerScreen> createState() => _ReelViewerScreenState();
}

class _ReelViewerScreenState extends State<ReelViewerScreen> {
  late final PageController _pageController;
  late List<ReelModel> _reels;
  int? _myId;

  @override
  void initState() {
    super.initState();
    _reels = List.of(widget.reels);
    _pageController = PageController(initialPage: widget.initialIndex);
    UserService.getMe()
        .then((me) {
          if (mounted) setState(() => _myId = me.id);
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _removeAt(int index) {
    setState(() => _reels.removeAt(index));
    if (_reels.isEmpty) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    if (_reels.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _reels.length,
            itemBuilder: (context, index) => _ReelPage(
              key: ValueKey(_reels[index].id),
              reel: _reels[index],
              myId: _myId,
              onDeleted: () => _removeAt(index),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: _CircleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelPage extends StatefulWidget {
  const _ReelPage({
    super.key,
    required this.reel,
    required this.myId,
    required this.onDeleted,
  });

  final ReelModel reel;
  final int? myId;
  final VoidCallback onDeleted;

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> {
  Player? _player;
  VideoController? _videoController;
  StreamSubscription<String>? _errorSub;
  bool _ready = false;
  bool _failed = false;
  bool _paused = false;
  late bool _liked;
  late bool _saved;
  late int _likeCount;

  // See the matching watchdog in home_page.dart's _VideoCardState: some
  // Android devices leave a controller reporting "playing" while the
  // decoded frame never advances (a stuck platform decoder, not a Flutter
  // error). This detects that and forces a full controller rebuild.
  Timer? _stallTimer;
  Duration _lastWatchedPosition = Duration.zero;
  int _stallTicks = 0;
  int _autoReinitCount = 0;
  static const _maxAutoReinits = 3;

  @override
  void initState() {
    super.initState();
    _liked = widget.reel.likedByMe;
    _saved = widget.reel.savedByMe;
    _likeCount = widget.reel.likesCount;
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = widget.reel.videoUrl;
    if (url == null || url.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    final player = Player();
    _player = player;
    _videoController = VideoController(
      player,
      // Hardware-accelerated decode is what hangs on the affected devices
      // (confirmed: MediaTek Codec2 on a Samsung Galaxy A13) — software
      // decode via the bundled FFmpeg avoids the OS decoder entirely.
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: false,
      ),
    );
    _errorSub = player.stream.error.listen((error) {
      debugPrint('Reel ${widget.reel.id} playback error: $error');
      if (mounted) {
        setState(() {
          _failed = true;
          _ready = false;
        });
      }
    });
    try {
      await player
          .open(Media(url), play: false)
          .timeout(const Duration(seconds: 10));
      await player.setPlaylistMode(PlaylistMode.loop);
      if (!mounted || _player != player) return;
      setState(() {
        _ready = true;
        _failed = false;
      });
      player.play();
      _startStallWatchdog();
    } catch (e) {
      debugPrint('Reel ${widget.reel.id} failed to initialize: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _retryVideo() async {
    _stopStallWatchdog();
    await _errorSub?.cancel();
    _errorSub = null;
    final old = _player;
    _player = null;
    _videoController = null;
    await old?.dispose();
    if (!mounted) return;
    setState(() {
      _ready = false;
      _failed = false;
      _paused = false;
    });
    await _initVideo();
  }

  void _startStallWatchdog() {
    _stallTimer?.cancel();
    _stallTicks = 0;
    _lastWatchedPosition = _player?.state.position ?? Duration.zero;
    _stallTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || _paused || _failed) return;
      final player = _player;
      if (player == null) return;
      if (player.state.duration <= Duration.zero) return;
      final position = player.state.position;
      if (position == _lastWatchedPosition) {
        _stallTicks++;
        if (_stallTicks >= 2) {
          _stallTicks = 0;
          if (_autoReinitCount < _maxAutoReinits) {
            _autoReinitCount++;
            debugPrint(
              'Reel ${widget.reel.id} stalled at $position — '
              'forcing reinit ($_autoReinitCount/$_maxAutoReinits).',
            );
            _retryVideo();
          } else {
            debugPrint(
              'Reel ${widget.reel.id} still stalled after '
              '$_maxAutoReinits auto-reinits — giving up.',
            );
            _stopStallWatchdog();
            if (mounted) setState(() => _failed = true);
          }
        }
      } else {
        _stallTicks = 0;
        _lastWatchedPosition = position;
      }
    });
  }

  void _stopStallWatchdog() {
    _stallTimer?.cancel();
    _stallTimer = null;
  }

  @override
  void dispose() {
    _stopStallWatchdog();
    _errorSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  void _togglePause() {
    if (_failed) {
      _autoReinitCount = 0;
      _retryVideo();
      return;
    }
    final player = _player;
    if (player == null) return;
    setState(() {
      _paused = !_paused;
      if (_paused) {
        player.pause();
        _stopStallWatchdog();
      } else {
        player.play();
        _startStallWatchdog();
      }
    });
  }

  Future<void> _toggleLike() async {
    final wasLiked = _liked;
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    try {
      await ReelService.toggleLike(widget.reel.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _liked = wasLiked;
        _likeCount += wasLiked ? 1 : -1;
      });
      _showError(e, 'Could not update like.');
    }
  }

  Future<void> _toggleSave() async {
    final wasSaved = _saved;
    setState(() => _saved = !_saved);
    try {
      await ReelService.toggleSave(widget.reel.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saved = wasSaved);
      _showError(e, 'Could not update save.');
    }
  }

  Future<void> _showError(Object error, String fallback) async {
    if (AuthService.isAuthFailure(error)) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (_) => false,
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ApiClient.errorMessage(error, fallback: fallback)),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final isMine = widget.myId != null && widget.myId == reel.creatorId;

    return DoubleTapLike(
      isLiked: _liked,
      onLike: _toggleLike,
      onTap: _togglePause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready && _videoController != null)
            Video(
              controller: _videoController!,
              fit: BoxFit.cover,
              controls: NoVideoControls,
            )
          else
            Stack(
              fit: StackFit.expand,
              children: [
                ReelThumbnail(thumbnailUrl: reel.thumbnailUrl),
                if (_failed)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_off_rounded,
                          color: Colors.white70,
                          size: 56,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Video unavailable — tap to retry',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Center(
                    child: CircularProgressIndicator(color: AppColors.amber),
                  ),
              ],
            ),
          Container(color: Colors.black.withValues(alpha: _paused ? 0.5 : 0.2)),
          if (_paused)
            const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
          Positioned(
            right: 12,
            bottom: 100,
            child: Column(
              children: [
                _RailIcon(
                  icon: _liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _liked ? AppColors.amber : Colors.white,
                  label: '$_likeCount',
                  onTap: _toggleLike,
                ),
                const SizedBox(height: 18),
                _RailIcon(
                  icon: Icons.chat_bubble_rounded,
                  color: Colors.white,
                  label: '${reel.commentsCount}',
                  onTap: () => CommentsScreen.show(context, reelId: reel.id),
                ),
                const SizedBox(height: 18),
                _RailIcon(
                  icon: _saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: _saved ? AppColors.amber : Colors.white,
                  label: 'Save',
                  onTap: _toggleSave,
                ),
                const SizedBox(height: 18),
                _RailIcon(
                  icon: Icons.more_horiz_rounded,
                  color: Colors.white,
                  label: 'More',
                  onTap: () => showReelActionsSheet(
                    context,
                    reelId: reel.id,
                    isMine: isMine,
                    onDeleted: widget.onDeleted,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 80,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicProfileScreen(
                        creatorId: reel.creatorId,
                        creatorName: reel.creatorName,
                        username: reel.creatorUsername,
                        gradient: AppColors.profileHeaderGradient,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UserAvatar(
                        displayName: reel.creatorName,
                        username: reel.creatorUsername,
                        radius: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        reel.creatorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reel.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailIcon extends StatelessWidget {
  const _RailIcon({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
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

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
