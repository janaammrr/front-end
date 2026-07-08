import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'community_detail_screen.dart';
import 'messaging_screen.dart';
import '../components/user_avatar.dart';
import '../services/community_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<CommunityModel> _all = [];
  final Set<int> _joinedIds = {};
  final Set<int> _joiningIds = {};
  final Set<int> _requestedIds = {};
  final Map<int, List<CommunityUser>> _pendingRequests = {};
  bool _loading = true;
  bool _loadingNotifications = false;
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
          _all = communities;
          _joinedIds
            ..clear()
            ..addAll(communities.where((c) => c.isMember).map((c) => c.id));
          _loading = false;
        });
        _loadNotifications(communities, me.id);
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CommunityModel> get _filtered {
    var list = _all;
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

  List<CommunityModel> get _myCommunities =>
      _filtered.where((c) => _joinedIds.contains(c.id)).toList();

  List<CommunityModel> get _recommendedCommunities =>
      _filtered.where((c) => !_joinedIds.contains(c.id)).toList();

  int get _notificationCount =>
      _pendingRequests.values.fold(0, (total, users) => total + users.length);

  Future<void> _loadNotifications(
    List<CommunityModel> communities,
    int myId,
  ) async {
    final owned = communities.where((c) => c.admin.id == myId).toList();
    if (owned.isEmpty) {
      if (mounted) setState(() => _pendingRequests.clear());
      return;
    }
    if (mounted) setState(() => _loadingNotifications = true);
    final next = <int, List<CommunityUser>>{};
    for (final community in owned) {
      try {
        final requests = await CommunityService.getPendingJoinRequests(
          community.id,
        );
        if (requests.isNotEmpty) next[community.id] = requests;
      } catch (_) {
        // Backend may reject non-owner or unsupported cases; ignore silently.
      }
    }
    if (!mounted) return;
    setState(() {
      _pendingRequests
        ..clear()
        ..addAll(next);
      _loadingNotifications = false;
    });
  }

  CommunityModel? _communityById(int id) {
    for (final community in _all) {
      if (community.id == id) return community;
    }
    return null;
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
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _joiningIds.remove(community.id));
    }
  }

  Future<void> _approveJoinRequest(
    CommunityModel community,
    CommunityUser user,
  ) async {
    try {
      await CommunityService.approveJoinRequest(community.id, user.id);
      if (!mounted) return;
      setState(() {
        final users = _pendingRequests[community.id] ?? [];
        users.removeWhere((u) => u.id == user.id);
        if (users.isEmpty) {
          _pendingRequests.remove(community.id);
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(_snackBar('${user.displayName} was approved.'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not approve request: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectJoinRequest(
    CommunityModel community,
    CommunityUser user,
  ) async {
    try {
      await CommunityService.rejectJoinRequest(community.id, user.id);
      if (!mounted) return;
      setState(() {
        final users = _pendingRequests[community.id] ?? [];
        users.removeWhere((u) => u.id == user.id);
        if (users.isEmpty) {
          _pendingRequests.remove(community.id);
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(_snackBar('${user.displayName} was rejected.'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not reject request: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showNotifications() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommunityNotificationsSheet(
        pendingRequests: _pendingRequests,
        communityForId: _communityById,
        loading: _loadingNotifications,
        onApprove: _approveJoinRequest,
        onReject: _rejectJoinRequest,
      ),
    );
  }

  Future<void> _openMyCommunitiesScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MyCommunitiesListScreen(
          communities: _myCommunities,
          onOpen: _openCommunity,
        ),
      ),
    );
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool creating = false;
    bool isPrivate = false;
    XFile? coverPhoto;

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
                color: AppColors.bg.withValues(alpha: 0.92),
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
                        color: AppColors.text1.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    'Create Community',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text1,
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
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final file = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (file != null) {
                        setSheet(() => coverPhoto = file);
                      }
                    },
                    child: Container(
                      height: 118,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.text1.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.text1.withValues(alpha: 0.12),
                        ),
                      ),
                      child: coverPhoto == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  color: AppColors.amber,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Select cover photo',
                                  style: TextStyle(
                                    color: AppColors.text1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  File(coverPhoto!.path),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                    ),
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
                        gradient: LinearGradient(
                          colors: [AppColors.amber, AppColors.amberSoft],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.amber.withValues(alpha: 0.35),
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
                                    privacyType: isPrivate
                                        ? 'PRIVATE'
                                        : 'PUBLIC',
                                    imagePath: coverPhoto?.path,
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
                color: AppColors.amber.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.search_off_rounded,
                color: AppColors.amber,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No communities found',
              style: TextStyle(
                color: AppColors.text1,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text2,
                fontSize: 13,
                height: 1.45,
              ),
            ),
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
    backgroundColor: AppColors.amber,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: const Duration(seconds: 2),
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F0A00), AppColors.bg],
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
                        color: AppColors.text1.withValues(alpha: 0.04),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.text1.withValues(alpha: 0.08),
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
                              Text(
                                'Communities',
                                style: TextStyle(
                                  color: AppColors.text1,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          _NotificationButton(
                            count: _notificationCount,
                            onTap: _showNotifications,
                          ),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MessagingScreen(),
                              ),
                            ),
                            icon: Icon(
                              Icons.chat_bubble_outline,
                              size: 22,
                              color: AppColors.text1,
                            ),
                          ),
                          IconButton(
                            onPressed: _showCreateDialog,
                            icon: Icon(
                              Icons.add_circle_outline,
                              size: 24,
                              color: AppColors.text1,
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
                    style: TextStyle(fontSize: 14, color: AppColors.text1),
                    decoration: InputDecoration(
                      hintText: 'Search communities...',
                      hintStyle: TextStyle(
                        color: AppColors.text3,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.text3,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: AppColors.text1.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.text1.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.amber,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── List ─────────────────────────────────────────────────
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.amber,
                          ),
                        )
                      : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppColors.text3,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _load,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.amber,
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
                          color: AppColors.amber,
                          child: _CommunitiesSections(
                            myCommunities: _myCommunities.take(4).toList(),
                            hasMoreMyCommunities:
                                _myCommunities.length >
                                _myCommunities.take(4).length,
                            showingAllMyCommunities: false,
                            recommendedCommunities: _recommendedCommunities,
                            requestedIds: _requestedIds,
                            joiningIds: _joiningIds,
                            onToggleMyCommunities: _openMyCommunitiesScreen,
                            onOpen: _openCommunity,
                            onJoin: _toggleJoin,
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

class _MyCommunitiesListScreen extends StatelessWidget {
  const _MyCommunitiesListScreen({
    required this.communities,
    required this.onOpen,
  });

  final List<CommunityModel> communities;
  final ValueChanged<CommunityModel> onOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(
          'My Communities',
          style: TextStyle(color: AppColors.text1, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        itemCount: communities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final community = communities[index];
          return _RecommendedCommunityTile(
            community: community,
            isRequested: false,
            isLoading: false,
            showJoinAction: false,
            onOpen: () {
              Navigator.pop(context);
              onOpen(community);
            },
            onJoin: () {},
          );
        },
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(
            Icons.notifications_none_rounded,
            size: 23,
            color: AppColors.text1,
          ),
        ),
        if (count > 0)
          Positioned(
            right: 7,
            top: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.amber,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.bg, width: 1.5),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CommunitiesSections extends StatelessWidget {
  const _CommunitiesSections({
    required this.myCommunities,
    required this.hasMoreMyCommunities,
    required this.showingAllMyCommunities,
    required this.recommendedCommunities,
    required this.requestedIds,
    required this.joiningIds,
    required this.onToggleMyCommunities,
    required this.onOpen,
    required this.onJoin,
  });

  final List<CommunityModel> myCommunities;
  final bool hasMoreMyCommunities;
  final bool showingAllMyCommunities;
  final List<CommunityModel> recommendedCommunities;
  final Set<int> requestedIds;
  final Set<int> joiningIds;
  final VoidCallback onToggleMyCommunities;
  final ValueChanged<CommunityModel> onOpen;
  final ValueChanged<CommunityModel> onJoin;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 110),
      children: [
        _SectionTitle(
          title: 'My Communities',
          actionLabel: showingAllMyCommunities
              ? 'Show Less'
              : (hasMoreMyCommunities ? 'View All' : null),
          onAction: (showingAllMyCommunities || hasMoreMyCommunities)
              ? onToggleMyCommunities
              : null,
        ),
        const SizedBox(height: 12),
        if (myCommunities.isEmpty)
          const _InlineEmptyState(
            message: 'You have not joined any communities yet.',
          )
        else
          SizedBox(
            height: 214,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: myCommunities.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, index) => _MyCommunityCard(
                community: myCommunities[index],
                onOpen: () => onOpen(myCommunities[index]),
              ),
            ),
          ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Recommended'),
        const SizedBox(height: 12),
        if (recommendedCommunities.isEmpty)
          const _InlineEmptyState(
            message: 'No recommended communities right now.',
          )
        else
          ...recommendedCommunities.map(
            (community) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecommendedCommunityTile(
                community: community,
                isRequested: requestedIds.contains(community.id),
                isLoading: joiningIds.contains(community.id),
                onOpen: () => onOpen(community),
                onJoin: () => onJoin(community),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.text1,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.text1.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.text1.withValues(alpha: 0.08)),
      ),
      child: Text(
        message,
        style: TextStyle(color: AppColors.text2),
      ),
    );
  }
}

class _MyCommunityCard extends StatelessWidget {
  const _MyCommunityCard({required this.community, required this.onOpen});

  final CommunityModel community;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        width: 184,
        decoration: BoxDecoration(
          color: AppColors.text1.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.text1.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: _CommunityCover(community: community, height: 106),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.text1,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MiniAdminAvatar(community: community),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Owner: ${community.admin.displayName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.text2,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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

class _RecommendedCommunityTile extends StatelessWidget {
  const _RecommendedCommunityTile({
    required this.community,
    required this.isRequested,
    required this.isLoading,
    required this.onOpen,
    required this.onJoin,
    this.showJoinAction = true,
  });

  final CommunityModel community;
  final bool isRequested;
  final bool isLoading;
  final VoidCallback onOpen;
  final VoidCallback onJoin;
  final bool showJoinAction;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.text1.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.text1.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _CommunityCover(
                community: community,
                width: 58,
                height: 58,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.text1,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${community.memberCount} members',
                    style: TextStyle(
                      color: AppColors.text2,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Owner: ${community.admin.displayName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.text2,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (community.description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      community.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text2,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showJoinAction) ...[
              const SizedBox(width: 8),
              _JoinTextButton(
                label: isRequested
                    ? 'Requested'
                    : (community.isPrivate ? 'Request Join' : '+Join'),
                loading: isLoading,
                disabled: isRequested,
                onTap: onJoin,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JoinTextButton extends StatelessWidget {
  const _JoinTextButton({
    required this.label,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading || disabled ? null : onTap,
      child: SizedBox(
        width: 108,
        child: Center(
          child: loading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.amber,
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: disabled
                        ? AppColors.text3
                        : AppColors.amber,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
        ),
      ),
    );
  }
}

class _MiniAdminAvatar extends StatelessWidget {
  const _MiniAdminAvatar({required this.community});

  final CommunityModel community;

  @override
  Widget build(BuildContext context) {
    return UserAvatar(
      displayName: community.admin.displayName,
      profileUrl: community.admin.profileUrl,
      username: community.admin.username,
      radius: 13,
    );
  }
}

class _CommunityCover extends StatelessWidget {
  const _CommunityCover({
    required this.community,
    this.width,
    required this.height,
  });

  final CommunityModel community;
  final double? width;
  final double height;

  List<Color> get _colors {
    final palettes = [
      [AppColors.amber, AppColors.borderHi],
      [AppColors.surface2, AppColors.borderHi],
      [AppColors.amberSoft, AppColors.surface2],
      [AppColors.borderHi, AppColors.bg],
    ];
    return palettes[community.id % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final photo = community.photoUrl;
    if (photo != null && photo.isNotEmpty) {
      return Image.network(
        photo,
        width: width ?? double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          community.name.isEmpty ? '?' : community.name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
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

  // Deterministic on-brand gradient based on community id (previously an
  // unrelated purple/teal/navy rainbow, now built from the site's palette).
  List<Color> get _gradient {
    final palettes = [
      [AppColors.amber, AppColors.surface2],
      [AppColors.surface2, AppColors.surface],
      [AppColors.borderHi, AppColors.surface2],
      [AppColors.amberSoft, AppColors.surface2],
      [AppColors.surface, AppColors.bg],
      [AppColors.amber, AppColors.borderHi],
      [AppColors.borderHi, AppColors.bg],
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
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
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
                            color: AppColors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${community.memberCount} members',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.amber,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.amber,
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
                        color: AppColors.error,
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
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.amber,
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
                color: AppColors.amberSoft,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isOwner ? 'Owner' : (isRequested ? 'Requested' : 'Joined'),
                style: TextStyle(
                  color: AppColors.amberSoft,
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
          gradient: LinearGradient(
            colors: [AppColors.amber, AppColors.amberSoft],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.amber.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_add_outlined,
              color: Colors.white,
              size: 18,
            ),
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

class _CommunityNotificationsSheet extends StatelessWidget {
  const _CommunityNotificationsSheet({
    required this.pendingRequests,
    required this.communityForId,
    required this.loading,
    required this.onApprove,
    required this.onReject,
  });

  final Map<int, List<CommunityUser>> pendingRequests;
  final CommunityModel? Function(int id) communityForId;
  final bool loading;
  final void Function(CommunityModel community, CommunityUser user) onApprove;
  final void Function(CommunityModel community, CommunityUser user) onReject;

  @override
  Widget build(BuildContext context) {
    final entries = pendingRequests.entries
        .where((entry) => communityForId(entry.key) != null)
        .toList();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          decoration: BoxDecoration(
            color: AppColors.bg.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(color: AppColors.text1.withValues(alpha: 0.1)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: AppColors.text1.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(
                  'Community Notifications',
                  style: TextStyle(
                    color: AppColors.text1,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                if (loading)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppColors.amber),
                    ),
                  )
                else if (entries.isEmpty)
                  const _InlineEmptyState(
                    message: 'No pending join requests right now.',
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final entry in entries) ...[
                          _NotificationGroup(
                            community: communityForId(entry.key)!,
                            users: entry.value,
                            onApprove: onApprove,
                            onReject: onReject,
                          ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup({
    required this.community,
    required this.users,
    required this.onApprove,
    required this.onReject,
  });

  final CommunityModel community;
  final List<CommunityUser> users;
  final void Function(CommunityModel community, CommunityUser user) onApprove;
  final void Function(CommunityModel community, CommunityUser user) onReject;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          community.name,
          style: TextStyle(
            color: AppColors.text1,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        for (final user in users)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.text1.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.text1.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                UserAvatar(
                  displayName: user.displayName,
                  profileUrl: user.profileUrl,
                  username: user.username,
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${user.displayName} requested to join.',
                    style: TextStyle(color: AppColors.text1, fontSize: 13),
                  ),
                ),
                IconButton(
                  onPressed: () => onReject(community, user),
                  icon: const Icon(Icons.close_rounded, color: AppColors.error),
                ),
                IconButton(
                  onPressed: () => onApprove(community, user),
                  icon: Icon(Icons.check_rounded, color: AppColors.amber),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

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
          color: AppColors.text1.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.text1.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ignore: unused_element
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
            ? LinearGradient(colors: [AppColors.amber, AppColors.amberSoft])
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
            ? AppColors.amber.withValues(alpha: 0.14)
            : AppColors.text1.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? AppColors.amber
              : AppColors.text1.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: selected ? AppColors.amber : AppColors.text2,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.text1 : AppColors.text2,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.text2,
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
      style: TextStyle(fontSize: 14, color: AppColors.text1),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.text3),
        filled: true,
        fillColor: AppColors.text1.withValues(alpha: 0.07),
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.text1.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.text1.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.amber, width: 1.5),
        ),
      ),
    );
  }
}
