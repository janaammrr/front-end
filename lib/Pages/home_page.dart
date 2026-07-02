import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/reel_service.dart';
import '../services/auth_service.dart';
import '../services/follow_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../auth/auth.dart';
import 'profile_screen.dart';
import 'communities_screen.dart';
import 'workshop_page.dart';
import 'events_page.dart';
import 'notifications_screen.dart';
import 'messaging_screen.dart';
import 'search_screen.dart';
import 'video_upload_screen.dart';
import 'comments_screen.dart';
import 'ai_chatbot_screen.dart';
import 'public_profile_screen.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────

class _VideoItem {
  const _VideoItem({
    required this.id,
    required this.creatorName,
    this.creatorId,
    required this.caption,
    required this.category,
    required this.likes,
    required this.comments,
    required this.gradient,
    this.videoUrl,
    this.likedByMe = false,
    this.savedByMe = false,
  });

  final int id;
  final String creatorName;
  final int? creatorId;
  final String caption;
  final String category;
  final int likes;
  final String comments;
  final List<Color> gradient;
  final String? videoUrl;
  final bool likedByMe;
  final bool savedByMe;
}

// ─── Home Page (Root Shell) ───────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;
  int _profileRefreshKey = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          const _FeedView(),
          const WorkshopPage(),
          const EventsPage(),
          const CommunitiesScreen(),
          ProfileScreen(key: ValueKey(_profileRefreshKey)),
        ],
      ),
      bottomNavigationBar: _MainNav(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() {
          _tabIndex = i;
          if (i == 4) _profileRefreshKey++;
        }),
      ),
    );
  }
}

// ─── Main Nav Bar ─────────────────────────────────────────────────────────────

class _MainNav extends StatelessWidget {
  const _MainNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        decoration: BoxDecoration(
          color: const Color(0xE509090B),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              active: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.school_outlined,
              label: 'Workshops',
              active: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavItem(
              icon: Icons.event_outlined,
              label: 'Events',
              active: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavItem(
              icon: Icons.groups_outlined,
              label: 'Communities',
              active: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              active: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFFFF7A18)
        : Colors.white.withValues(alpha: 0.5);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feed View (Home Tab) ─────────────────────────────────────────────────────

class _FeedView extends StatefulWidget {
  const _FeedView();

  @override
  State<_FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<_FeedView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<_VideoItem> _videos = [];
  bool _loading = true;
  String? _error;

  static const _gradients = [
    [Color(0xFF7C2D12), Color(0xFF9A3412), Color(0xFF09090B)],
    [Color(0xFF78350F), Color(0xFF9D174D), Color(0xFF09090B)],
    [Color(0xFF134E4A), Color(0xFF0F766E), Color(0xFF09090B)],
    [Color(0xFF1E1B4B), Color(0xFF4338CA), Color(0xFF09090B)],
    [Color(0xFF500724), Color(0xFF9F1239), Color(0xFF09090B)],
  ];

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  Future<void> _loadReels() async {
    try {
      final reels = await ReelService.getAll();
      if (!mounted) return;
      setState(() {
        _videos = reels.asMap().entries.map((e) {
          final reel = e.value;
          final g = _gradients[e.key % _gradients.length];
          return _VideoItem(
            id: reel.id,
            creatorName: reel.creatorName,
            creatorId: reel.creatorId,
            caption: reel.caption,
            category: 'Educational',
            likes: reel.likesCount,
            comments: reel.commentsCount > 999
                ? '${(reel.commentsCount / 1000).toStringAsFixed(1)}K'
                : '${reel.commentsCount}',
            gradient: g,
            videoUrl: reel.videoUrl,
            likedByMe: reel.likedByMe,
            savedByMe: reel.savedByMe,
          );
        }).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (AuthService.isAuthFailure(e)) {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthPage()),
          (_) => false,
        );
        return;
      }
      setState(() {
        _error = 'Could not load feed. Check your connection.';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _videos.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _openCreateMenu() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => const _CreateMenuSheet(),
    );
    if (created == true && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
      await _loadReels();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: Color(0xFF09090B),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF7A18)),
        ),
      );
    }
    if (_error != null) {
      return ColoredBox(
        color: const Color(0xFF09090B),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadReels();
                },
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Color(0xFFFF7A18)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_videos.isEmpty) {
      return const ColoredBox(
        color: Color(0xFF09090B),
        child: Center(
          child: Text('No videos yet', style: TextStyle(color: Colors.white54)),
        ),
      );
    }
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: _videos.length,
          onPageChanged: (page) => setState(() => _currentPage = page),
          itemBuilder: (context, index) => _VideoCard(
            key: ValueKey(index),
            item: _videos[index],
            isActive: index == _currentPage,
            onVideoEnd: _goToNextPage,
          ),
        ),
        _TopBar(
          onSearchTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
          onNotificationTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          onMessageTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MessagingScreen()),
          ),
          onCreateTap: _openCreateMenu,
        ),
      ],
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onSearchTap,
    required this.onNotificationTap,
    required this.onMessageTap,
    required this.onCreateTap,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onMessageTap;
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCC000000), Color(0x00000000)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Image.asset(
                'assets/images/FLAME_LOGO.png',
                height: 52,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              _TopBtn(icon: Icons.add_rounded, onTap: onCreateTap),
              const SizedBox(width: 8),
              _TopBtn(icon: Icons.search_rounded, onTap: onSearchTap),
              const SizedBox(width: 8),
              _TopBtn(
                icon: Icons.notifications_outlined,
                onTap: onNotificationTap,
              ),
              const SizedBox(width: 8),
              _TopBtn(icon: Icons.send_outlined, onTap: onMessageTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBtn extends StatelessWidget {
  const _TopBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.45),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}

// ─── Video Card ───────────────────────────────────────────────────────────────

class _VideoCard extends StatefulWidget {
  const _VideoCard({
    super.key,
    required this.item,
    required this.isActive,
    required this.onVideoEnd,
  });

  final _VideoItem item;
  final bool isActive;
  final VoidCallback onVideoEnd;

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> with TickerProviderStateMixin {
  late final AnimationController _progressCtrl;
  late final AnimationController _likeCtrl;
  late final Animation<double> _likeScale;

  late bool _isLiked;
  late bool _isSaved;
  bool _isPaused = false;
  bool _showOverlay = false;
  bool _isFollowing = false;
  bool _followBusy = false;
  bool _videoReady = false;
  bool _videoFailed = false;
  bool _notifiedVideoEnd = false;
  late int _likeCount;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.item.likedByMe;
    _isSaved = widget.item.savedByMe;
    _likeCount = widget.item.likes;

    _progressCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed && mounted) widget.onVideoEnd();
          });

    _likeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _likeScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.55), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.55, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _likeCtrl, curve: Curves.easeOut));

    _initVideo();
    if (widget.isActive) _startPlayback();
  }

  Future<void> _initVideo() async {
    final url = widget.item.videoUrl;
    if (url == null || url.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;
    try {
      await controller.initialize();
      controller.setLooping(false);
      controller.addListener(_handleVideoTick);
      if (!mounted || _videoController != controller) return;
      _progressCtrl.stop();
      setState(() => _videoReady = true);
      if (widget.isActive && !_isPaused) controller.play();
    } catch (_) {
      if (mounted) setState(() => _videoFailed = true);
      await controller.dispose();
      if (_videoController == controller) _videoController = null;
    }
  }

  void _handleVideoTick() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    final duration = controller.value.duration;
    final position = controller.value.position;
    if (duration > Duration.zero &&
        position >= duration &&
        !_notifiedVideoEnd &&
        mounted) {
      _notifiedVideoEnd = true;
      widget.onVideoEnd();
    }
    if (mounted) setState(() {});
  }

  void _startPlayback() {
    _notifiedVideoEnd = false;
    final controller = _videoController;
    if (controller != null && controller.value.isInitialized) {
      controller.seekTo(Duration.zero);
      controller.play();
    } else {
      _progressCtrl.forward(from: 0);
    }
  }

  void _stopPlayback() {
    final controller = _videoController;
    if (controller != null && controller.value.isInitialized) {
      controller.pause();
    }
    _progressCtrl.stop();
  }

  @override
  void didUpdateWidget(_VideoCard old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _progressCtrl.reset();
      _videoController?.seekTo(Duration.zero);
      if (mounted) {
        setState(() {
          _isPaused = false;
          _showOverlay = false;
        });
      }
      _startPlayback();
    } else if (!widget.isActive && old.isActive) {
      _stopPlayback();
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_handleVideoTick);
    _videoController?.dispose();
    _progressCtrl.dispose();
    _likeCtrl.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    _likeCtrl.forward(from: 0);
    ReelService.toggleLike(widget.item.id);
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      _showOverlay = true;
    });
    if (_isPaused) {
      _stopPlayback();
    } else {
      _videoController?.play();
      if (!_videoReady) _progressCtrl.forward();
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _showOverlay = false);
      });
    }
  }

  void _toggleSave() {
    setState(() => _isSaved = !_isSaved);
    ReelService.toggleSave(widget.item.id);
  }

  Future<void> _toggleFollow() async {
    if (_followBusy || widget.item.creatorId == null) return;
    final willFollow = !_isFollowing;
    setState(() {
      _isFollowing = willFollow;
      _followBusy = true;
    });
    try {
      if (willFollow) {
        await FollowService.follow(widget.item.creatorId!);
      } else {
        await FollowService.unfollow(widget.item.creatorId!);
      }
    } catch (_) {
      if (mounted) setState(() => _isFollowing = !willFollow);
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  void _share() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _ShareSheet(
        reelId: widget.item.id,
        caption: widget.item.caption,
        creatorName: widget.item.creatorName,
        parentContext: context,
      ),
    );
  }

  String get _likesLabel => _likeCount >= 1000
      ? '${(_likeCount / 1000).toStringAsFixed(1)}K'
      : '$_likeCount';

  double get _progressValue {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return _progressCtrl.value;
    }
    final duration = controller.value.duration.inMilliseconds;
    if (duration <= 0) return 0;
    return (controller.value.position.inMilliseconds / duration).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    const floor = 20.0;

    return GestureDetector(
      onTap: _togglePause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background gradient ──────────────────────────────────────────
          if (_videoReady && _videoController != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.item.gradient,
                ),
              ),
              child: _videoFailed
                  ? const Center(
                      child: Icon(
                        Icons.videocam_off_rounded,
                        color: Colors.white30,
                        size: 72,
                      ),
                    )
                  : null,
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: Colors.black.withValues(alpha: _isPaused ? 0.58 : 0.28),
          ),

          // ── Play / Pause overlay ─────────────────────────────────────────
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: (_isPaused || _showOverlay) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  child: Icon(
                    _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),

          // ── Progress bar ─────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: floor - 4,
            child: AnimatedBuilder(
              animation: _progressCtrl,
              builder: (_, __) => LinearProgressIndicator(
                value: _progressValue,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFFF7A18),
                ),
                minHeight: 3,
              ),
            ),
          ),

          // ── Right action rail ────────────────────────────────────────────
          Positioned(
            right: 10,
            bottom: floor + 40,
            child: _ActionRail(
              isLiked: _isLiked,
              isSaved: _isSaved,
              likeScale: _likeScale,
              likesLabel: _likesLabel,
              comments: widget.item.comments,
              onLike: _toggleLike,
              onSave: _toggleSave,
              onComment: () =>
                  CommentsScreen.show(context, reelId: widget.item.id),
              onShare: _share,
              onAI: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AIChatbotScreen()),
              ),
            ),
          ),

          // ── Creator info card ────────────────────────────────────────────
          Positioned(
            left: 12,
            right: 70,
            bottom: floor + 4,
            child: _CreatorCard(
              item: widget.item,
              isFollowing: _isFollowing,
              followBusy: _followBusy,
              onFollowToggle: _toggleFollow,
              onCreatorTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PublicProfileScreen(
                    creatorId: widget.item.creatorId,
                    creatorName: widget.item.creatorName,
                    gradient: widget.item.gradient,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Rail (right side) ─────────────────────────────────────────────────

class _ActionRail extends StatelessWidget {
  const _ActionRail({
    required this.isLiked,
    required this.isSaved,
    required this.likeScale,
    required this.likesLabel,
    required this.comments,
    required this.onLike,
    required this.onSave,
    required this.onComment,
    required this.onShare,
    required this.onAI,
  });

  final bool isLiked;
  final bool isSaved;
  final Animation<double> likeScale;
  final String likesLabel;
  final String comments;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onAI;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Like
        _RailBtn(
          onTap: onLike,
          label: likesLabel,
          child: ScaleTransition(
            scale: likeScale,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(
                isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(isLiked),
                color: isLiked ? const Color(0xFFFF4757) : Colors.white,
                size: 28,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Comment
        _RailBtn(
          onTap: onComment,
          label: comments,
          child: const Icon(
            Icons.chat_bubble_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),

        const SizedBox(height: 16),

        // Share
        _RailBtn(
          onTap: onShare,
          label: 'Share',
          child: const Icon(
            Icons.reply_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),

        const SizedBox(height: 16),

        // Save / Bookmark
        _RailBtn(
          onTap: onSave,
          label: 'Save',
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              key: ValueKey(isSaved),
              color: isSaved ? const Color(0xFFFF7A18) : Colors.white,
              size: 26,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Ask AI
        GestureDetector(
          onTap: onAI,
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7A18), Color(0xFFB83280)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7A18).withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Ask AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RailBtn extends StatelessWidget {
  const _RailBtn({
    required this.child,
    required this.label,
    required this.onTap,
  });

  final Widget child;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.45),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Center(child: child),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Creator Info Card ────────────────────────────────────────────────────────

class _CreatorCard extends StatelessWidget {
  const _CreatorCard({
    required this.item,
    required this.isFollowing,
    required this.followBusy,
    required this.onFollowToggle,
    required this.onCreatorTap,
  });

  final _VideoItem item;
  final bool isFollowing;
  final bool followBusy;
  final VoidCallback onFollowToggle;
  final VoidCallback onCreatorTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onCreatorTap,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: const Color(
                        0xFFFF7A18,
                      ).withValues(alpha: 0.25),
                      child: Text(
                        item.creatorName[0],
                        style: const TextStyle(
                          color: Color(0xFFFF7A18),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: onCreatorTap,
                      child: Text(
                        item.creatorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: followBusy ? null : onFollowToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isFollowing
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFFFF7A18),
                        borderRadius: BorderRadius.circular(999),
                        border: isFollowing
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              )
                            : null,
                      ),
                      child: followBusy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isFollowing ? 'Following' : '+ Follow',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        color: Color(0xFFFED7AA),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Create Menu Sheet ────────────────────────────────────────────────────────

class _CreateMenuSheet extends StatelessWidget {
  const _CreateMenuSheet();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF09090B).withValues(alpha: 0.93),
            border: const Border(top: BorderSide(color: Color(0x1AFFFFFF))),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const Text(
                  'Create with Flame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _CreateTile(
                  icon: Icons.video_library_outlined,
                  title: 'Create a Reel',
                  subtitle: 'Share a quick educational video.',
                  onTap: () async {
                    final created = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VideoUploadScreen(),
                      ),
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop(created == true);
                    }
                  },
                ),
                _CreateTile(
                  icon: Icons.menu_book_outlined,
                  title: 'Host a Workshop',
                  subtitle: 'Lead a structured live learning session.',
                  onTap: () => Navigator.of(context).pop(),
                ),
                _CreateTile(
                  icon: Icons.event_available_outlined,
                  title: 'Create an Event',
                  subtitle: 'Schedule a live or in-person event.',
                  onTap: () => Navigator.of(context).pop(),
                ),
                _CreateTile(
                  icon: Icons.diversity_3_outlined,
                  title: 'Create a Community',
                  subtitle: 'Start a focused knowledge group.',
                  onTap: () => Navigator.of(context).pop(),
                ),
                _CreateTile(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Ask Flame AI',
                  subtitle: 'Get help from your AI learning assistant.',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AIChatbotScreen(),
                      ),
                    );
                  },
                ),
                _CreateTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  subtitle: 'Sign out of your Flame account.',
                  onTap: () async {
                    Navigator.of(context).pop();
                    await AuthService.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthPage()),
                        (_) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateTile extends StatelessWidget {
  const _CreateTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A18).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFFFF7A18), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Share Sheet ──────────────────────────────────────────────────────────────

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({
    required this.reelId,
    required this.caption,
    required this.creatorName,
    required this.parentContext,
  });

  final int reelId;
  final String caption;
  final String creatorName;
  final BuildContext parentContext;

  Future<void> _report(BuildContext context) async {
    Navigator.of(context).pop();
    try {
      await ReelService.reportReel(reelId, 'Reported from reel share menu');
      if (!parentContext.mounted) return;
      ScaffoldMessenger.of(parentContext).showSnackBar(
        _shareSnack('Report sent. Thanks for helping keep Flame safe.'),
      );
    } catch (e) {
      if (!parentContext.mounted) return;
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text('Could not report reel: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  SnackBar _shareSnack(String message) => SnackBar(
    content: Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
    backgroundColor: const Color(0xFFFF7A18),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: const Duration(seconds: 2),
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
  );

  void _copyLink(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      parentContext,
    ).showSnackBar(_shareSnack('Link copied to clipboard!'));
  }

  void _shareToApp(BuildContext context, String appName) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(parentContext).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text('Opening $appName...'),
          ],
        ),
        backgroundColor: const Color(0xFFFF7A18),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF09090B).withValues(alpha: 0.93),
            border: const Border(top: BorderSide(color: Color(0x1AFFFFFF))),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                // Video preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF7A18), Color(0xFF9A3412)],
                              ),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  caption,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  creatorName,
                                  style: const TextStyle(
                                    color: Color(0xFFFF7A18),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Share options row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ShareOption(
                      icon: Icons.chat_rounded,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onTap: () => _shareToApp(context, 'WhatsApp'),
                    ),
                    _ShareOption(
                      icon: Icons.facebook_rounded,
                      label: 'Facebook',
                      color: const Color(0xFF1877F2),
                      onTap: () => _shareToApp(context, 'Facebook'),
                    ),
                    _ShareOption(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Flame DM',
                      color: const Color(0xFFFF7A18),
                      onTap: () {
                        Navigator.of(context).pop();
                        showModalBottomSheet<void>(
                          context: parentContext,
                          backgroundColor: Colors.transparent,
                          barrierColor: Colors.black54,
                          useSafeArea: true,
                          isScrollControlled: true,
                          builder: (_) => _DmPickerSheet(
                            reelId: reelId,
                            caption: caption,
                            creatorName: creatorName,
                          ),
                        );
                      },
                    ),
                    _ShareOption(
                      icon: Icons.link_rounded,
                      label: 'Copy Link',
                      color: Colors.white54,
                      onTap: () => _copyLink(context),
                    ),
                    _ShareOption(
                      icon: Icons.flag_outlined,
                      label: 'Report',
                      color: const Color(0xFFEF4444),
                      onTap: () => _report(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DM Picker Sheet (TikTok-style "Send to friend") ─────────────────────────

class _DmPickerSheet extends StatefulWidget {
  const _DmPickerSheet({
    required this.reelId,
    required this.caption,
    required this.creatorName,
  });

  final int reelId;
  final String caption;
  final String creatorName;

  @override
  State<_DmPickerSheet> createState() => _DmPickerSheetState();
}

class _DmPickerSheetState extends State<_DmPickerSheet> {
  final TextEditingController _search = TextEditingController();
  final Set<int> _sentTo = {};
  int _myId = 0;
  List<FollowUser> _contacts = [];
  bool _loading = true;

  List<FollowUser> get _filtered {
    final q = _search.text.toLowerCase();
    if (q.isEmpty) return _contacts;
    return _contacts
        .where((c) => c.displayName.toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final me = await UserService.getMe();
    final following = await FollowService.getFollowing(me.id);
    if (!mounted) return;
    setState(() {
      _myId = me.id;
      _contacts = following;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _send(int index) async {
    if (_myId == 0) return;
    final c = _filtered[index];
    setState(() => _sentTo.add(index));
    try {
      await ChatService.sendMessage(
        c.id,
        'Shared a reel from ${widget.creatorName}: ${widget.caption} #reel-${widget.reelId}',
        _myId,
      );
    } catch (_) {
      if (mounted) setState(() => _sentTo.remove(index));
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent to ${c.displayName}'),
          backgroundColor: const Color(0xFFFF7A18),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          decoration: BoxDecoration(
            color: const Color(0xFF09090B).withValues(alpha: 0.95),
            border: const Border(top: BorderSide(color: Color(0x1AFFFFFF))),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                // Title
                Row(
                  children: [
                    const Text(
                      'Send to',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Search field
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search friends...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.07),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF7A18),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Contact list
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.42,
                  ),
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF7A18),
                          ),
                        )
                      : _filtered.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Follow someone first to send reels in chat.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 20),
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(
                            color: Colors.white.withValues(alpha: 0.06),
                            height: 1,
                          ),
                          itemBuilder: (ctx, i) {
                            final c = filtered[i];
                            final sent = _sentTo.contains(i);
                            return _DmContactTile(
                              initial: c.initials.isEmpty ? '?' : c.initials[0],
                              name: c.displayName,
                              status: 'Message',
                              gradient: _dmGradient(i),
                              sent: sent,
                              onSend: () => _send(i),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _dmGradient(int i) {
    const gradients = [
      [Color(0xFF7C3AED), Color(0xFFA855F7)],
      [Color(0xFF0F766E), Color(0xFF134E4A)],
      [Color(0xFF9A3412), Color(0xFF7C2D12)],
      [Color(0xFF1D4ED8), Color(0xFF1E1B4B)],
    ];
    return gradients[i % gradients.length];
  }
}

class _DmContactTile extends StatelessWidget {
  const _DmContactTile({
    required this.initial,
    required this.name,
    required this.status,
    required this.gradient,
    required this.sent,
    required this.onSend,
  });

  final String initial;
  final String name;
  final String status;
  final List<Color> gradient;
  final bool sent;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: gradient),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (status == 'Online') ...[
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                    Text(
                      status,
                      style: TextStyle(
                        color: status == 'Online'
                            ? const Color(0xFF22C55E)
                            : Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Send button
          GestureDetector(
            onTap: sent ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: sent
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFFF7A18), Color(0xFFFFB073)],
                      ),
                color: sent ? Colors.white.withValues(alpha: 0.08) : null,
                borderRadius: BorderRadius.circular(999),
                border: sent
                    ? Border.all(color: Colors.white.withValues(alpha: 0.15))
                    : null,
                boxShadow: sent
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(
                            0xFFFF7A18,
                          ).withValues(alpha: 0.38),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    sent ? Icons.check_rounded : Icons.send_rounded,
                    color: sent ? const Color(0xFFFF7A18) : Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    sent ? 'Sent' : 'Send',
                    style: TextStyle(
                      color: sent ? const Color(0xFFFF7A18) : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
