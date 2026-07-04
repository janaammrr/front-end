import 'dart:ui';
import 'package:flutter/material.dart';
import 'community_detail_screen.dart';
import 'messaging_screen.dart';
import '../components/user_avatar.dart';
import '../services/community_service.dart';
import '../services/user_service.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0;

  List<CommunityModel> _all = [];
  final Set<int> _joinedIds = {};
  final Set<int> _joiningIds = {};
  final Set<int> _requestedIds = {};
  int? _myId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await UserService.getMe();
      final communities = await CommunityService.getAll();
      if (mounted) {
        setState(() {
          _myId = me.id;
          _all = communities;
          _joinedIds
            ..clear()
            ..addAll(
              communities.where((c) => c.isMember).map((c) => c.id),
            );
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _deleteCommunity(CommunityModel community) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text(
          'Delete community',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Delete ${community.name}?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await CommunityService.deleteCommunity(community.id);
      if (mounted) {
        setState(() => _all.removeWhere((c) => c.id == community.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CommunityModel> get _filtered {
    var list = _selectedTab == 1
        ? _all.where((c) => _joinedIds.contains(c.id)).toList()
        : _all;
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return list;
    return list
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _toggleJoin(CommunityModel community) async {
    if (_joiningIds.contains(community.id) ||
        _requestedIds.contains(community.id)) {
      return;
    }
    setState(() => _joiningIds.add(community.id));
    try {
      if (_joinedIds.contains(community.id)) {
        await CommunityService.leave(community.id);
        if (mounted) setState(() => _joinedIds.remove(community.id));
      } else if (community.isPrivate) {
        await CommunityService.requestJoin(community.id);
        if (mounted) {
          setState(() => _requestedIds.add(community.id));
          ScaffoldMessenger.of(context).showSnackBar(
            _snackBar('Request sent. The admin needs to approve it.'),
          );
        }
      } else {
        await CommunityService.join(community.id);
        if (mounted) setState(() => _joinedIds.add(community.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _joiningIds.remove(community.id));
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool creating = false;
    bool isPrivate = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF09090B).withValues(alpha: 0.92),
                border: const Border(top: BorderSide(color: Color(0x1FFFFFFF))),
              ),
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
                    'Create Community',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StyledTextField(
                    controller: nameCtrl,
                    hint: 'Community name',
                  ),
                  const SizedBox(height: 12),
                  _StyledTextField(
                    controller: descCtrl,
                    hint: 'Description',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheet(() => isPrivate = false),
                          child: _PrivacyOption(
                            icon: Icons.public_rounded,
                            label: 'Public',
                            subtitle: 'Anyone can find and join',
                            selected: !isPrivate,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheet(() => isPrivate = true),
                          child: _PrivacyOption(
                            icon: Icons.lock_outline_rounded,
                            label: 'Private',
                            subtitle: 'Approval needed to join',
                            selected: isPrivate,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7A18), Color(0xFFFFB073)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFF7A18,
                            ).withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: creating
                            ? null
                            : () async {
                                if (nameCtrl.text.trim().isEmpty) return;
                                setSheet(() => creating = true);
                                try {
                                  final newComm = await CommunityService.create(
                                    nameCtrl.text.trim(),
                                    descCtrl.text.trim(),
                                    privacyType:
                                        isPrivate ? 'PRIVATE' : 'PUBLIC',
                                  );
                                  if (ctx.mounted) Navigator.of(ctx).pop();
                                  if (mounted) {
                                    setState(() {
                                      _all = [newComm, ..._all];
                                      _joinedIds.add(newComm.id);
                                    });
                                  }
                                } catch (e) {
                                  setSheet(() => creating = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: const Color(
                                          0xFFEF4444,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        child: creating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCommunity(CommunityModel community) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(community: community),
      ),
    );
    if (mounted) _load();
  }

  Widget _buildEmptyState() {
    final isFollowing = _selectedTab == 1;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF7A18).withValues(alpha: 0.1),
                border: Border.all(
                  color: const Color(0xFFFF7A18).withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                isFollowing ? Icons.groups_outlined : Icons.search_off_rounded,
                color: const Color(0xFFFF7A18),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFollowing ? 'No communities yet' : 'No results found',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFollowing
                  ? 'Join communities from the For You tab.'
                  : 'Try a different search term.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            if (isFollowing) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7A18), Color(0xFFFFB073)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7A18).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Discover communities',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  SnackBar _snackBar(String msg) => SnackBar(
    content: Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Text(msg),
      ],
    ),
    backgroundColor: const Color(0xFFFF7A18),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: const Duration(seconds: 2),
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F0A00), Color(0xFF09090B)],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/FLAME_LOGO.png',
                                height: 36,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Communities',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _selectedTab = 0),
                                  child: _PillTab(
                                    label: 'For You',
                                    active: _selectedTab == 0,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _selectedTab = 1),
                                  child: _PillTab(
                                    label: 'Joined',
                                    active: _selectedTab == 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MessagingScreen(),
                              ),
                            ),
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: _showCreateDialog,
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Search ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search communities...',
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
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF7A18),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── List ─────────────────────────────────────────────────
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF7A18),
                          ),
                        )
                      : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.white38,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _load,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF7A18),
                                ),
                                child: const Text(
                                  'Retry',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _filtered.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: const Color(0xFFFF7A18),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final c = _filtered[i];
                              return _CommunityCard(
                                community: c,
                                isJoined: _joinedIds.contains(c.id),
                                isRequested: _requestedIds.contains(c.id),
                                isLoading: _joiningIds.contains(c.id),
                                canDelete: c.admin.id == _myId,
                                onJoin: () => _toggleJoin(c),
                                onDelete: () => _deleteCommunity(c),
                                onShare: () => ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(_snackBar('Link copied!')),
                                onOpen: () => _openCommunity(c),
                              );
                            },
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

// ─── Community Card ───────────────────────────────────────────────────────────

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({
    required this.community,
    required this.isJoined,
    required this.isRequested,
    required this.isLoading,
    required this.canDelete,
    required this.onJoin,
    required this.onDelete,
    required this.onShare,
    required this.onOpen,
  });

  final CommunityModel community;
  final bool isJoined;
  final bool isRequested;
  final bool isLoading;
  final bool canDelete;
  final VoidCallback onJoin;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onOpen;

  // Deterministic gradient based on community id
  List<Color> get _gradient {
    const palettes = [
      [Color(0xFF1a6b8a), Color(0xFF0e4d6e)],
      [Color(0xFF6b2fa0), Color(0xFFa855f7)],
      [Color(0xFF1a1a2e), Color(0xFF16213e)],
      [Color(0xFF7C2D12), Color(0xFF9A3412)],
      [Color(0xFF134E4A), Color(0xFF0F766E)],
      [Color(0xFF1E3A5F), Color(0xFF001020)],
      [Color(0xFF78350F), Color(0xFF1A0A00)],
    ];
    return palettes[community.id % palettes.length];
  }

  String get _logoText {
    final parts = community.name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return community.name
        .substring(0, community.name.length.clamp(0, 2))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onOpen,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _logoText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  community.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (community.isPrivate) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lock_outline_rounded,
                                        size: 11,
                                        color: Colors.white70,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Private',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (community.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    community.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    UserAvatar(
                      displayName: community.admin.displayName,
                      profileUrl: community.admin.profileUrl,
                      username: community.admin.username,
                      radius: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      community.admin.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onOpen,
                      child: Row(
                        children: [
                          Icon(
                            community.isPrivate && !isJoined
                                ? Icons.lock_outline_rounded
                                : Icons.people_outline,
                            size: 14,
                            color: const Color(0xFFFF7A18),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${community.memberCount} members',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF7A18),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFFFF7A18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildJoinButton()),
                    const SizedBox(width: 10),
                    if (canDelete) ...[
                      _SmallActionButton(
                        icon: Icons.delete_outline_rounded,
                        color: const Color(0xFFEF4444),
                        onTap: onDelete,
                      ),
                      const SizedBox(width: 10),
                    ],
                    _SmallActionButton(
                      icon: Icons.ios_share_outlined,
                      color: Colors.white.withValues(alpha: 0.4),
                      onTap: onShare,
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

  Widget _buildJoinButton() {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFFF7A18),
            ),
          ),
        ),
      );
    }

    if (isJoined || isRequested) {
      // The owner is always a member but can't "leave" their own community
      // (the backend has no ownership transfer, and rejects it), so their
      // state here is informational only, not tappable.
      final isOwner = canDelete;
      return GestureDetector(
        onTap: (isRequested || isOwner) ? null : onJoin,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOwner
                    ? Icons.shield_outlined
                    : isRequested
                    ? Icons.hourglass_top_rounded
                    : Icons.check,
                color: const Color(0xFFFFB073),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isOwner ? 'Owner' : (isRequested ? 'Requested' : 'Joined'),
                style: const TextStyle(
                  color: Color(0xFFFFB073),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onJoin,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A18), Color(0xFFFFB073)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7A18).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              community.isPrivate ? 'Request to Join' : 'Join',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [Color(0xFFFF7A18), Color(0xFFFFB073)],
              )
            : null,
        color: active ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _PrivacyOption extends StatelessWidget {
  const _PrivacyOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFFF7A18).withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? const Color(0xFFFF7A18)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: selected ? const Color(0xFFFF7A18) : Colors.white70,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF7A18), width: 1.5),
        ),
      ),
    );
  }
}
