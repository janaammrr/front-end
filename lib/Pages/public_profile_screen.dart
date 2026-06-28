import 'dart:ui';

import 'package:flutter/material.dart';
import 'messaging_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    super.key,
    required this.creatorName,
    required this.gradient,
  });

  final String creatorName;
  final List<Color> gradient;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _isFollowing = false;

  String get _handle =>
      '@${widget.creatorName.toLowerCase().replaceAll(' ', '_').replaceAll('.', '')}';

  String get _bio {
    final n = widget.creatorName.toLowerCase();
    if (n.contains('amina')) {
      return 'AI researcher & educator. Making machine learning accessible for every learner on Flame.';
    }
    if (n.contains('design')) {
      return 'Senior UX designer · 8 years of experience. Teaching design thinking and visual craft one short video at a time.';
    }
    if (n.contains('finance')) {
      return 'Finance educator. Simplifying money management and investment strategies for creators and entrepreneurs.';
    }
    if (n.contains('ibrahim')) {
      return 'Serial entrepreneur & startup advisor based in Cairo. Sharing real lessons from building companies in MENA.';
    }
    if (n.contains('mona')) {
      return 'Product designer and color theory enthusiast. I teach through beautiful things.';
    }
    return 'Educator and content creator on Flame. Sharing knowledge, one video at a time.';
  }

  int get _videoCount {
    final n = widget.creatorName.toLowerCase();
    if (n.contains('amina')) return 48;
    if (n.contains('design')) return 31;
    if (n.contains('finance')) return 56;
    if (n.contains('ibrahim')) return 23;
    if (n.contains('mona')) return 19;
    return 14;
  }

  int get _followerCount {
    final n = widget.creatorName.toLowerCase();
    if (n.contains('amina')) return 12400;
    if (n.contains('design')) return 8100;
    if (n.contains('finance')) return 9700;
    if (n.contains('ibrahim')) return 15200;
    if (n.contains('mona')) return 6300;
    return 3800;
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  static const _thumbGradients = [
    [Color(0xFF7C2D12), Color(0xFF9A3412)],
    [Color(0xFF134E4A), Color(0xFF0F766E)],
    [Color(0xFF1E1B4B), Color(0xFF4338CA)],
    [Color(0xFF500724), Color(0xFF9F1239)],
    [Color(0xFF78350F), Color(0xFF9D174D)],
    [Color(0xFF064E3B), Color(0xFF065F46)],
  ];

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${widget.creatorName}\'s profile link copied!',
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileInfo(),
                const SizedBox(height: 16),
                _buildStats(),
                const SizedBox(height: 14),
                _buildActionButtons(context),
                const SizedBox(height: 24),
                _buildSectionHeader(),
              ],
            ),
          ),
          _buildVideoGrid(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ─── Expandable cover header ────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: const Color(0xFF09090B),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient cover
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.gradient,
                ),
              ),
            ),
            // Dark overlay
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
            // Back button
            Positioned(
              top: topPad + 8,
              left: 12,
              child: _CircleBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            // Share button
            Positioned(
              top: topPad + 8,
              right: 12,
              child: _CircleBtn(
                icon: Icons.share_outlined,
                onTap: _shareProfile,
              ),
            ),
            // Avatar
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF7A18), width: 3),
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
                          widget.creatorName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF7A18),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x80FF7A18),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Collapsed state — just show the back button + name
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
          child: _CircleBtn(
            icon: Icons.share_outlined,
            onTap: _shareProfile,
          ),
        ),
      ],
    );
  }

  // ─── Name / handle / bio ────────────────────────────────────────────────────

  Widget _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.creatorName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
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
            _bio,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          // Category tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A18).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFFF7A18).withValues(alpha: 0.4)),
            ),
            child: const Text(
              'Creator · Educator',
              style: TextStyle(
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

  // ─── Stats row ──────────────────────────────────────────────────────────────

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
                _Stat(value: '$_videoCount', label: 'Videos'),
                Container(width: 1, height: 36, color: Colors.white12),
                _Stat(value: _fmt(_followerCount), label: 'Followers'),
                Container(width: 1, height: 36, color: Colors.white12),
                _Stat(value: _fmt((_followerCount * 0.014).round() + 80), label: 'Following'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Follow + Message buttons ───────────────────────────────────────────────

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => setState(() => _isFollowing = !_isFollowing),
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
                  boxShadow: _isFollowing
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFFFF7A18).withValues(alpha: 0.38),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MessagingScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 17),
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

  // ─── "Videos" section header ─────────────────────────────────────────────────

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
              border: Border.all(color: const Color(0xFFFF7A18).withValues(alpha: 0.4)),
            ),
            child: Text(
              '$_videoCount total',
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

  // ─── 3-column video grid ─────────────────────────────────────────────────────

  SliverGrid _buildVideoGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.68,
      ),
      delegate: SliverChildBuilderDelegate(
        childCount: 6,
        (context, i) {
          final g = _thumbGradients[i % _thumbGradients.length];
          final likes = (i + 1) * 1300 + i * 430;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: g,
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
                  bottom: 6,
                  left: 6,
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: Colors.white60, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        _fmt(likes),
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
        },
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

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
