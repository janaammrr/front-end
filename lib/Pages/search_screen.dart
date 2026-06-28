import 'dart:ui';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late final TabController _tabController;
  String _query = '';

  final List<String> _trending = ['AI Tools', 'Design Thinking', 'Finance for Creators', 'Python Basics', 'UI Motion', 'Branding', 'Productivity'];

  final List<_VideoResult> _videos = [
    _VideoResult(title: '3 prompts to learn any topic faster', creator: 'Dr. Amina', category: 'AI', views: '12.4K', gradient: [Color(0xFF7C2D12), Color(0xFF09090B)]),
    _VideoResult(title: 'How to critique UI like a senior designer', creator: 'DesignWithSam', category: 'Design', views: '8.1K', gradient: [Color(0xFF78350F), Color(0xFF09090B)]),
    _VideoResult(title: 'Budget framework for creators in 60 sec', creator: 'Finance Lab', category: 'Finance', views: '9.7K', gradient: [Color(0xFF134E4A), Color(0xFF09090B)]),
    _VideoResult(title: 'How AI is changing product management', creator: 'Ibrahim N.', category: 'AI', views: '5.2K', gradient: [Color(0xFF1E3A5F), Color(0xFF09090B)]),
  ];

  final List<_CreatorResult> _creators = [
    _CreatorResult(name: 'Dr. Amina', username: '@dramina', followers: '28K', category: 'AI & Learning'),
    _CreatorResult(name: 'DesignWithSam', username: '@designwithsam', followers: '15K', category: 'Design'),
    _CreatorResult(name: 'Finance Lab', username: '@financelab', followers: '41K', category: 'Finance'),
    _CreatorResult(name: 'Ibrahim N.', username: '@ibrahimn', followers: '9.3K', category: 'AI & Product'),
  ];

  final List<_WorkshopResult> _workshops = [
    _WorkshopResult(title: 'Creative Branding Sprint', organizer: 'Sarah K.', date: 'May 10 • 5:30 PM', price: '\$49'),
    _WorkshopResult(title: 'AI Tools for Product Teams', organizer: 'Ibrahim N.', date: 'May 14 • 7:00 PM', price: 'Free'),
    _WorkshopResult(title: 'Monetization for Creators', organizer: 'Mona H.', date: 'May 19 • 6:00 PM', price: '\$79'),
  ];

  final List<_EventResult> _events = [
    _EventResult(title: 'Flame Creator Summit 2025', organizer: 'Flame Team', date: 'Jun 5', isOnline: false),
    _EventResult(title: 'AI in Education Webinar', organizer: 'Ibrahim N.', date: 'Jun 12', isOnline: true),
    _EventResult(title: 'Design Thinking Bootcamp', organizer: 'Sarah K.', date: 'Jun 18', isOnline: false),
  ];

  List<_VideoResult> get _filteredVideos => _query.isEmpty ? _videos : _videos.where((v) => v.title.toLowerCase().contains(_query) || v.creator.toLowerCase().contains(_query)).toList();
  List<_CreatorResult> get _filteredCreators => _query.isEmpty ? _creators : _creators.where((c) => c.name.toLowerCase().contains(_query) || c.username.toLowerCase().contains(_query)).toList();
  List<_WorkshopResult> get _filteredWorkshops => _query.isEmpty ? _workshops : _workshops.where((w) => w.title.toLowerCase().contains(_query)).toList();
  List<_EventResult> get _filteredEvents => _query.isEmpty ? _events : _events.where((e) => e.title.toLowerCase().contains(_query)).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          Positioned(top: -60, right: -50, child: _GlowOrb(color: const Color(0xFFFF7A18).withValues(alpha: 0.15), size: 200)),
          Positioned(bottom: -80, left: -50, child: _GlowOrb(color: const Color(0xFF6D28D9).withValues(alpha: 0.15), size: 220)),
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
                          onChanged: (v) => setState(() => _query = v.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Search videos, creators, workshops…',
                            hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280)),
                            suffixIcon: _query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                                    onPressed: () { _controller.clear(); setState(() => _query = ''); },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.07),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFFF7A18), width: 1.2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_query.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Trending topics', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _trending.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () { _controller.text = _trending[i]; setState(() => _query = _trending[i].toLowerCase()); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.trending_up_rounded, color: Color(0xFFFF7A18), size: 14),
                              const SizedBox(width: 6),
                              Text(_trending[i], style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: const Color(0xFFFF7A18),
                  indicatorWeight: 2,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF6B7280),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  dividerColor: Colors.white.withValues(alpha: 0.08),
                  tabs: const [Tab(text: 'Videos'), Tab(text: 'Creators'), Tab(text: 'Workshops'), Tab(text: 'Events')],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _VideoTab(results: _filteredVideos),
                      _CreatorsTab(results: _filteredCreators),
                      _WorkshopsTab(results: _filteredWorkshops),
                      _EventsTab(results: _filteredEvents),
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

class _VideoTab extends StatelessWidget {
  const _VideoTab({required this.results});

  final List<_VideoResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const _EmptySearch();
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72,
      ),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final v = results[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: v.gradient))),
              Container(color: Colors.black26),
              Positioned(
                top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFF7A18), borderRadius: BorderRadius.circular(999)),
                  child: Text(v.category, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.title, maxLines: 2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12, height: 1.3)),
                      const SizedBox(height: 4),
                      Text(v.creator, style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 11)),
                      const SizedBox(height: 2),
                      Row(children: [const Icon(Icons.play_circle_outline, color: Color(0xFFFF7A18), size: 12), const SizedBox(width: 4), Text(v.views, style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 11))]),
                    ],
                  ),
                ),
              ),
              Positioned.fill(child: Material(color: Colors.transparent, child: InkWell(onTap: () {}))),
            ],
          ),
        );
      },
    );
  }
}

class _CreatorsTab extends StatelessWidget {
  const _CreatorsTab({required this.results});

  final List<_CreatorResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const _EmptySearch();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = results[i];
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
                    radius: 26,
                    backgroundColor: const Color(0xFFFF7A18).withValues(alpha: 0.2),
                    child: Text(c.name[0], style: const TextStyle(color: Color(0xFFFF7A18), fontWeight: FontWeight.w800, fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        Text(c.username, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(999)),
                              child: Text(c.category, style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 11)),
                            ),
                            const SizedBox(width: 8),
                            Text('${c.followers} followers', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF7A18),
                      side: const BorderSide(color: Color(0xFFFF7A18)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Follow', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ],
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

  final List<_WorkshopResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const _EmptySearch();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final w = results[i];
        return _ResultTile(
          icon: Icons.school_outlined,
          title: w.title,
          sub1: w.organizer,
          sub2: w.date,
          badge: w.price,
          badgeColor: w.price == 'Free' ? const Color(0xFF10B981) : const Color(0xFFFF7A18),
        );
      },
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab({required this.results});

  final List<_EventResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const _EmptySearch();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final e = results[i];
        return _ResultTile(
          icon: Icons.event_outlined,
          title: e.title,
          sub1: e.organizer,
          sub2: e.date,
          badge: e.isOnline ? 'Online' : 'In-Person',
          badgeColor: e.isOnline ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
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
  });

  final IconData icon;
  final String title, sub1, sub2, badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFFFF7A18).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: const Color(0xFFFF7A18), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('$sub1  ·  $sub2', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999), border: Border.all(color: badgeColor.withValues(alpha: 0.4))),
                child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: Color(0xFF374151), size: 48),
          SizedBox(height: 12),
          Text('No results found', style: TextStyle(color: Color(0xFF6B7280), fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Try a different keyword', style: TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
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
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 30)]),
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
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}

class _VideoResult {
  const _VideoResult({required this.title, required this.creator, required this.category, required this.views, required this.gradient});
  final String title, creator, category, views;
  final List<Color> gradient;
}

class _CreatorResult {
  const _CreatorResult({required this.name, required this.username, required this.followers, required this.category});
  final String name, username, followers, category;
}

class _WorkshopResult {
  const _WorkshopResult({required this.title, required this.organizer, required this.date, required this.price});
  final String title, organizer, date, price;
}

class _EventResult {
  const _EventResult({required this.title, required this.organizer, required this.date, required this.isOnline});
  final String title, organizer, date;
  final bool isOnline;
}
