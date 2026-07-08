import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../components/reel_thumbnail.dart';
import '../components/user_avatar.dart';
import '../models/event_model.dart';
import '../models/reel_model.dart';
import '../models/workshop_model.dart';
import '../services/event_service.dart';
import '../services/follow_service.dart';
import '../services/reel_service.dart';
import '../services/user_service.dart';
import '../services/workshop_service.dart';
import '../theme/app_theme.dart';
import 'events_page.dart';
import 'public_profile_screen.dart';
import 'reel_viewer_screen.dart';
import 'workshop_page.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late final TabController _tabController;
  String _query = '';
  Timer? _debounce;

  bool _loadingData = true;
  List<ReelModel> _allReels = [];
  List<WorkshopModel> _allWorkshops = [];
  List<EventModel> _allEvents = [];

  bool _searchingCreators = false;
  List<FollowUser> _creatorResults = [];

  List<ReelModel> get _filteredVideos {
    if (_query.isEmpty) return const [];
    return _allReels
        .where(
          (v) =>
              v.caption.toLowerCase().contains(_query) ||
              v.creatorName.toLowerCase().contains(_query),
        )
        .toList();
  }

  List<WorkshopModel> get _filteredWorkshops {
    if (_query.isEmpty) return const [];
    return _allWorkshops
        .where((w) => w.title.toLowerCase().contains(_query))
        .toList();
  }

  List<EventModel> get _filteredEvents {
    if (_query.isEmpty) return const [];
    return _allEvents
        .where((e) => e.title.toLowerCase().contains(_query))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ReelService.getAll(),
        WorkshopService.getAll(),
        EventService.getAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _allReels = results[0] as List<ReelModel>;
        _allWorkshops = results[1] as List<WorkshopModel>;
        _allEvents = results[2] as List<EventModel>;
        _loadingData = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value.trim().toLowerCase());
    _debounce?.cancel();
    if (_query.isEmpty) {
      setState(() => _creatorResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _searchingCreators = true);
      try {
        final results = await UserService.search(_query);
        if (mounted) {
          setState(() {
            _creatorResults = results;
            _searchingCreators = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _searchingCreators = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: _GlowOrb(
              color: AppColors.amber.withValues(alpha: 0.15),
              size: 200,
            ),
          ),
          Positioned(
            bottom: -80,
            left: -50,
            child: _GlowOrb(
              color: AppColors.amberSoft.withValues(alpha: 0.15),
              size: 220,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Row(
                    children: [
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white),
                          onChanged: _onQueryChanged,
                          decoration: InputDecoration(
                            hintText: 'Search videos, creators, workshops…',
                            hintStyle: TextStyle(
                              color: AppColors.text3,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppColors.text3,
                            ),
                            suffixIcon: _query.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: AppColors.text3,
                                    ),
                                    onPressed: () {
                                      _controller.clear();
                                      _onQueryChanged('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.07),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppColors.amber,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppColors.amber,
                  indicatorWeight: 2,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.text3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  dividerColor: Colors.white.withValues(alpha: 0.08),
                  tabs: const [
                    Tab(text: 'Videos'),
                    Tab(text: 'Creators'),
                    Tab(text: 'Workshops'),
                    Tab(text: 'Events'),
                  ],
                ),
                Expanded(
                  child: _query.isEmpty
                      ? const _EmptySearch(
                          message: 'Start typing to search Flame',
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _loadingData
                                ? const _LoadingState()
                                : _VideoTab(results: _filteredVideos),
                            _searchingCreators
                                ? const _LoadingState()
                                : _CreatorsTab(results: _creatorResults),
                            _loadingData
                                ? const _LoadingState()
                                : _WorkshopsTab(results: _filteredWorkshops),
                            _loadingData
                                ? const _LoadingState()
                                : _EventsTab(results: _filteredEvents),
                          ],
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator(color: AppColors.amber));
  }
}

class _VideoTab extends StatelessWidget {
  const _VideoTab({required this.results});

  final List<ReelModel> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const _EmptySearch(message: 'No videos found');
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final v = results[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ReelThumbnail(thumbnailUrl: v.thumbnailUrl),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.caption,
                        maxLines: 2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        v.creatorName,
                        style: TextStyle(color: AppColors.text2, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            color: AppColors.amber,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${v.likesCount}',
                            style: TextStyle(
                              color: AppColors.text2,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReelViewerScreen(reels: results, initialIndex: i),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CreatorsTab extends StatelessWidget {
  const _CreatorsTab({required this.results});

  final List<FollowUser> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty)
      return const _EmptySearch(message: 'No creators found');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final c = results[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PublicProfileScreen(
                    creatorId: c.id,
                    creatorName: c.displayName,
                    profileUrl: c.profileUrl,
                    gradient: AppColors.profileHeaderGradient,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      displayName: c.displayName,
                      profileUrl: c.profileUrl,
                      radius: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.border,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WorkshopsTab extends StatelessWidget {
  const _WorkshopsTab({required this.results});

  final List<WorkshopModel> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty)
      return const _EmptySearch(message: 'No workshops found');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final w = results[i];
        final price = w.price ?? 0;
        return _ResultTile(
          icon: Icons.school_outlined,
          title: w.title,
          sub1: w.location ?? 'Workshop',
          sub2: w.date ?? 'TBA',
          badge: price <= 0 ? 'Free' : '\$${price.toStringAsFixed(0)}',
          badgeColor: price <= 0 ? const Color(0xFF10B981) : AppColors.amber,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WorkshopPage()),
          ),
        );
      },
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab({required this.results});

  final List<EventModel> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const _EmptySearch(message: 'No events found');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = results[i];
        final price = e.price ?? 0;
        return _ResultTile(
          icon: Icons.event_outlined,
          title: e.title,
          sub1: e.location ?? 'Event',
          sub2: e.date ?? 'TBA',
          badge: price <= 0 ? 'Free' : '\$${price.toStringAsFixed(0)}',
          badgeColor: price <= 0 ? const Color(0xFF10B981) : AppColors.amber,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventsPage()),
          ),
        );
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.icon,
    required this.title,
    required this.sub1,
    required this.sub2,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  final IconData icon;
  final String title, sub1, sub2, badge;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.amber, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$sub1  ·  $sub2',
                        style: TextStyle(color: AppColors.text3, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
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

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: AppColors.border, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: AppColors.text3,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 30)],
      ),
    );
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
