import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/follow_service.dart';
import '../services/user_service.dart';

class FollowersScreen extends StatefulWidget {
  const FollowersScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<FollowUser> _followers = [];
  List<FollowUser> _following = [];
  bool _loading = true;
  String? _error;
  int _myId = 0;
  final Set<int> _followingIds = {};
  final Set<int> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final me = await UserService.getMe();
      final results = await Future.wait([
        FollowService.getFollowers(me.id),
        FollowService.getFollowing(me.id),
      ]);
      if (!mounted) return;
      final followers = results[0];
      final following = results[1];
      setState(() {
        _myId = me.id;
        _followers = followers;
        _following = following;
        _followingIds.addAll(following.map((u) => u.id));
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<FollowUser> _filter(List<FollowUser> list) {
    if (_query.isEmpty) return list;
    return list.where((u) => u.displayName.toLowerCase().contains(_query)).toList();
  }

  Future<void> _toggleFollow(int targetId) async {
    if (_processingIds.contains(targetId)) return;
    setState(() => _processingIds.add(targetId));
    try {
      if (_followingIds.contains(targetId)) {
        await FollowService.unfollow(targetId);
        if (mounted) setState(() => _followingIds.remove(targetId));
      } else {
        await FollowService.follow(targetId);
        if (mounted) setState(() => _followingIds.add(targetId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)));
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(targetId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: _GlowOrb(color: const Color(0xFFFF7A18).withValues(alpha: 0.16), size: 200)),
          Positioned(bottom: -100, left: -60, child: _GlowOrb(color: const Color(0xFF6D28D9).withValues(alpha: 0.14), size: 240)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      const Text('My Network', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                if (_loading)
                  const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFFFF7A18))))
                else if (_error != null)
                  Expanded(
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A18)), child: const Text('Retry', style: TextStyle(color: Colors.white))),
                      ]),
                    ),
                  )
                else ...[
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFFFF7A18),
                    indicatorWeight: 2,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF6B7280),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                    dividerColor: Colors.white.withValues(alpha: 0.08),
                    tabs: [
                      Tab(text: 'Followers (${_followers.length})'),
                      Tab(text: 'Following (${_following.length})'),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v.toLowerCase()),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFF7A18), width: 1.1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _UserList(users: _filter(_followers), followingIds: _followingIds, processingIds: _processingIds, myId: _myId, onToggle: _toggleFollow),
                        _UserList(users: _filter(_following), followingIds: _followingIds, processingIds: _processingIds, myId: _myId, onToggle: _toggleFollow),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  const _UserList({required this.users, required this.followingIds, required this.processingIds, required this.myId, required this.onToggle});

  final List<FollowUser> users;
  final Set<int> followingIds;
  final Set<int> processingIds;
  final int myId;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(child: Text('No users found', style: TextStyle(color: Color(0xFF6B7280))));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final u = users[i];
        final isMe = u.id == myId;
        final isFollowing = followingIds.contains(u.id);
        final processing = processingIds.contains(u.id);
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFFF7A18).withValues(alpha: 0.2),
                    child: Text(u.initials.isNotEmpty ? u.initials : '?', style: const TextStyle(color: Color(0xFFFF7A18), fontWeight: FontWeight.w800, fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(u.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  if (!isMe) ...[
                    const SizedBox(width: 8),
                    processing
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF7A18)))
                        : GestureDetector(
                            onTap: () => onToggle(u.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isFollowing ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFFF7A18),
                                borderRadius: BorderRadius.circular(12),
                                border: isFollowing ? Border.all(color: Colors.white.withValues(alpha: 0.15)) : null,
                              ),
                              child: Text(
                                isFollowing ? 'Following' : 'Follow',
                                style: TextStyle(color: isFollowing ? const Color(0xFFB2B8CB) : Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                          ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
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
