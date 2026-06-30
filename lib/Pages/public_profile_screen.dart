import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/reel_model.dart';
import '../services/chat_service.dart';
import '../services/follow_service.dart';
import '../services/reel_service.dart';
import '../services/user_service.dart';
import 'messaging_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    super.key,
    this.creatorId,
    required this.creatorName,
    required this.gradient,
  });

  final int? creatorId;
  final String creatorName;
  final List<Color> gradient;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  List<ReelModel> _reels = [];
  int _followersCount = 0;
  int _followingCount = 0;
  int? _myId;
  bool _isFollowing = false;
  bool _isSelf = false;
  bool _loading = true;
  bool _followBusy = false;
  String? _error;

  String get _handle =>
      '@${widget.creatorName.toLowerCase().replaceAll(' ', '_').replaceAll('.', '')}';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final creatorId = widget.creatorId;
    if (creatorId == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final me = await UserService.getMe();
      final results = await Future.wait([
        ReelService.getByUser(creatorId),
        FollowService.getFollowers(creatorId),
        FollowService.getFollowing(creatorId),
        FollowService.getFollowing(me.id),
      ]);
      final myFollowing = results[3] as List<FollowUser>;
      if (!mounted) return;
      setState(() {
        _myId = me.id;
        _isSelf = me.id == creatorId;
        _reels = results[0] as List<ReelModel>;
        _followersCount = (results[1] as List<FollowUser>).length;
        _followingCount = (results[2] as List<FollowUser>).length;
        _isFollowing = myFollowing.any((user) => user.id == creatorId);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final creatorId = widget.creatorId;
    if (creatorId == null || _isSelf || _followBusy) return;

    final willFollow = !_isFollowing;
    setState(() {
      _isFollowing = willFollow;
      _followersCount += willFollow ? 1 : -1;
      _followBusy = true;
    });

    try {
      if (willFollow) {
        await FollowService.follow(creatorId);
      } else {
        await FollowService.unfollow(creatorId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFollowing = !willFollow;
        _followersCount += willFollow ? -1 : 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update follow: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<void> _openMessage() async {
    final creatorId = widget.creatorId;
    if (creatorId == null || _isSelf) return;

    var myId = _myId;
    if (myId == null) {
      final me = await UserService.getMe();
      myId = me.id;
      if (mounted) setState(() => _myId = myId);
    }
    if (!mounted) return;

    final parts = widget.creatorName.trim().split(RegExp(r'\s+'));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUser: ChatUser(
            id: creatorId,
            firstname: parts.isNotEmpty ? parts.first : widget.creatorName,
            lastname: parts.length > 1 ? parts.sublist(1).join(' ') : '',
          ),
          myId: myId!,
        ),
      ),
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.creatorName} profile link copied'),
        backgroundColor: const Color(0xFFFF7A18),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF7A18)),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: _ErrorState(error: _error!, onRetry: _loadProfile),
            )
          else ...[
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileInfo(),
                  const SizedBox(height: 16),
                  _buildStats(),
                  if (!_isSelf) ...[
                    const SizedBox(height: 14),
                    _buildActionButtons(),
                  ],
                  const SizedBox(height: 24),
                  _buildSectionHeader(),
                ],
              ),
            ),
            _buildVideoGrid(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final initial = widget.creatorName.trim().isEmpty
        ? '?'
        : widget.creatorName.trim()[0].toUpperCase();

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: const Color(0xFF09090B),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.gradient,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              top: topPad + 8,
              left: 12,
              child: _CircleBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            Positioned(
              top: topPad + 8,
              right: 12,
              child: _CircleBtn(
                icon: Icons.share_outlined,
                onTap: _shareProfile,
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF7A18),
                      width: 3,
                    ),
                    gradient: LinearGradient(
                      colors: widget.gradient.length >= 2
                          ? [widget.gradient[0], widget.gradient[1]]
                          : [widget.gradient[0], widget.gradient[0]],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7A18).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      title: Text(
        widget.creatorName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      leading: _CircleBtn(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _CircleBtn(icon: Icons.share_outlined, onTap: _shareProfile),
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.creatorName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _handle,
            style: const TextStyle(
              color: Color(0xFFFF7A18),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Educator and content creator on Flame.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Stat(value: '${_reels.length}', label: 'Videos'),
                Container(width: 1, height: 36, color: Colors.white12),
                _Stat(value: _fmt(_followersCount), label: 'Followers'),
                Container(width: 1, height: 36, color: Colors.white12),
                _Stat(value: _fmt(_followingCount), label: 'Following'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: _toggleFollow,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _isFollowing
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFFF7A18), Color(0xFFFFB073)],
                        ),
                  color: _isFollowing
                      ? Colors.white.withValues(alpha: 0.08)
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  border: _isFollowing
                      ? Border.all(color: Colors.white.withValues(alpha: 0.2))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_followBusy)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        _isFollowing
                            ? Icons.person_remove_outlined
                            : Icons.person_add_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      _isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _openMessage,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Message',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          const Text(
            'Videos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A18).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFFFF7A18).withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              '${_reels.length} total',
              style: const TextStyle(
                color: Color(0xFFFFB073),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid() {
    if (_reels.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text(
              'No public videos yet',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.68,
      ),
      delegate: SliverChildBuilderDelegate(childCount: _reels.length, (
        context,
        i,
      ) {
        final reel = _reels[i];
        final colors = _thumbGradients[i % _thumbGradients.length];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white.withValues(alpha: 0.35),
                  size: 36,
                ),
              ),
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white60,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _fmt(reel.likesCount),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  static const _thumbGradients = [
    [Color(0xFF7C2D12), Color(0xFF9A3412)],
    [Color(0xFF134E4A), Color(0xFF0F766E)],
    [Color(0xFF1E1B4B), Color(0xFF4338CA)],
    [Color(0xFF500724), Color(0xFF9F1239)],
    [Color(0xFF78350F), Color(0xFF9D174D)],
    [Color(0xFF064E3B), Color(0xFF065F46)],
  ];
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A18),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
