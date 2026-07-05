import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/reel_service.dart';
import '../services/api_client.dart';
import '../components/reel_moderation_sheet.dart';
import '../components/user_avatar.dart';
import '../services/auth_service.dart';
import '../services/follow_service.dart';
import '../services/user_service.dart';
import '../auth/auth.dart';
import 'profile_screen.dart';
import 'communities_screen.dart';
import 'workshop_page.dart';
import 'events_page.dart';
import 'messaging_screen.dart';
import 'search_screen.dart';
import 'video_upload_screen.dart';
import 'comments_screen.dart';
import 'ai_chatbot_screen.dart';
import 'public_profile_screen.dart';
import 'posts_screen.dart';
import 'trending_screen.dart';
import '../components/dm_picker_sheet.dart';
import '../theme/app_theme.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────

class _VideoItem {
  const _VideoItem({
    required this.id,
    required this.creatorName,
    this.creatorId,
    this.creatorUsername,
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
  final String? creatorUsername;
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
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _tabIndex,
        children: [
          const _FeedView(),
          const WorkshopPage(),
          const EventsPage(),
          const TrendingScreen(),
          const CommunitiesScreen(),
          ProfileScreen(key: ValueKey(_profileRefreshKey)),
        ],
      ),
      bottomNavigationBar: _MainNav(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() {
          _tabIndex = i;
          if (i == 5) _profileRefreshKey++;
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
          color: AppColors.bg.withValues(alpha: 0.9),
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                active: currentIndex == 0,
                onTap: () => onTap(0),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.school_outlined,
                label: 'Workshops',
                active: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.event_outlined,
                label: 'Events',
                active: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.local_fire_department_outlined,
                label: 'Trending',
                active: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.groups_outlined,
                label: 'Communities',
                active: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                active: currentIndex == 5,
                onTap: () => onTap(5),
              ),
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
        ? AppColors.amber
        : Colors.white.withValues(alpha: 0.5);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
  int? _myId;

  // On-brand fallback backgrounds for reel cards with no thumbnail — kept
  // within the website's amber/neutral palette instead of the previous
  // unrelated purple/teal/indigo hues.
  static const _gradients = [
    [AppColors.amber, AppColors.surface2, AppColors.bg],
    [AppColors.amberSoft, AppColors.surface2, AppColors.bg],
    [AppColors.borderHi, AppColors.surface2, AppColors.bg],
    [AppColors.surface2, AppColors.surface, AppColors.bg],
    [AppColors.amber, AppColors.borderHi, AppColors.bg],
  ];

  @override
  void initState() {
    super.initState();
    _loadReels();
    UserService.getMe().then((me) {
      if (mounted) setState(() => _myId = me.id);
    }).catchError((_) {});
  }

  void _removeReelAt(int index) {
    setState(() => _videos.removeAt(index));
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
            creatorUsername: reel.creatorUsername,
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
        _error = ApiClient.errorMessage(e, fallback: 'Could not load feed.');
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
        color: AppColors.bg,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
      );
    }
    if (_error != null) {
      return ColoredBox(
        color: AppColors.bg,
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
                  style: TextStyle(color: AppColors.amber),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_videos.isEmpty) {
      return const ColoredBox(
        color: AppColors.bg,
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
            key: ValueKey(_videos[index].id),
            item: _videos[index],
            isActive: index == _currentPage,
            myId: _myId,
            onVideoEnd: _goToNextPage,
            onDeleted: () => _removeReelAt(index),
          ),
        ),
        _TopBar(
          onPostsTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostsScreen()),
          ),
          onSearchTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
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
    required this.onPostsTap,
    required this.onSearchTap,
    required this.onMessageTap,
    required this.onCreateTap,
  });

  final VoidCallback onPostsTap;
  final VoidCallback onSearchTap;
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
              _TopBtn(icon: Icons.dynamic_feed_rounded, onTap: onPostsTap),
              const SizedBox(width: 8),
              _TopBtn(icon: Icons.search_rounded, onTap: onSearchTap),
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
    required this.myId,
    required this.onVideoEnd,
    required this.onDeleted,
  });

  final _VideoItem item;
  final bool isActive;
  final int? myId;
  final VoidCallback onVideoEnd;
  final VoidCallback onDeleted;

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

  Future<void> _toggleLike() async {
    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    _likeCtrl.forward(from: 0);
    try {
      await ReelService.toggleLike(widget.item.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLiked = wasLiked;
        _likeCount += wasLiked ? 1 : -1;
      });
      _showActionError(e, fallback: 'Could not update like.');
    }
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

  Future<void> _toggleSave() async {
    final wasSaved = _isSaved;
    setState(() => _isSaved = !_isSaved);
    try {
      await ReelService.toggleSave(widget.item.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaved = wasSaved);
      _showActionError(e, fallback: 'Could not update save.');
    }
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
    } catch (e) {
      if (mounted) {
        setState(() => _isFollowing = !willFollow);
        _showActionError(e, fallback: 'Could not update follow.');
      }
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<void> _showActionError(
    Object error, {
    required String fallback,
  }) async {
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
                  AppColors.amber,
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
              onMore: () => showReelActionsSheet(
                context,
                reelId: widget.item.id,
                isMine:
                    widget.myId != null && widget.myId == widget.item.creatorId,
                onDeleted: widget.onDeleted,
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
                    username: widget.item.creatorUsername,
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
    required this.onMore,
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
  final VoidCallback onMore;

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
                color: isLiked ? AppColors.amber : Colors.white,
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
              color: isSaved ? AppColors.amber : Colors.white,
              size: 26,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // More (delete own reel / report others')
        _RailBtn(
          onTap: onMore,
          label: 'More',
          child: const Icon(
            Icons.more_horiz_rounded,
            color: Colors.white,
            size: 26,
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
                  gradient: AppColors.accentGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber.withValues(alpha: 0.45),
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
                    child: UserAvatar(
                      displayName: item.creatorName,
                      username: item.creatorUsername,
                      radius: 15,
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
                            : AppColors.amber,
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
                      color: AppColors.amber.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        color: AppColors.amberSoft,
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
            color: AppColors.bg.withValues(alpha: 0.93),
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
                    color: AppColors.amber.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.amber, size: 22),
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

  SnackBar _shareSnack(String message) => SnackBar(
    content: Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
    backgroundColor: AppColors.amber,
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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          decoration: BoxDecoration(
            color: AppColors.bg.withValues(alpha: 0.93),
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
                              gradient: AppColors.accentGradient,
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
                                    color: AppColors.amber,
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
                      icon: Icons.auto_awesome_rounded,
                      label: 'Flame DM',
                      color: AppColors.amber,
                      onTap: () {
                        Navigator.of(context).pop();
                        showModalBottomSheet<void>(
                          context: parentContext,
                          backgroundColor: Colors.transparent,
                          barrierColor: Colors.black54,
                          useSafeArea: true,
                          isScrollControlled: true,
                          builder: (_) => DmPickerSheet(
                            sharedTargetId: reelId,
                            sharedTargetType: 'REEL',
                            shareContent: caption,
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

// DmPickerSheet and its contact tile now live in
// lib/components/dm_picker_sheet.dart so the Posts share flow can reuse them.
