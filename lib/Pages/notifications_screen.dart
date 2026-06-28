import 'dart:ui';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filter = 'All';
  final List<String> _filters = ['All', 'Likes', 'Comments', 'Follows', 'Updates'];

  final List<_NotifItem> _notifs = [
    _NotifItem(type: 'like', user: 'Dr. Amina', avatar: 'DA', action: 'liked your video "3 prompts to learn faster"', time: '2m ago', isRead: false),
    _NotifItem(type: 'follow', user: 'Ibrahim N.', avatar: 'IN', action: 'started following you', time: '15m ago', isRead: false),
    _NotifItem(type: 'comment', user: 'DesignWithSam', avatar: 'DS', action: 'commented: "This is absolutely gold!"', time: '1h ago', isRead: false),
    _NotifItem(type: 'workshop', user: 'Flame', avatar: 'F', action: 'Your workshop "Creative Branding Sprint" starts in 30 minutes', time: '30m ago', isRead: false),
    _NotifItem(type: 'like', user: 'Mona H.', avatar: 'MH', action: 'liked your comment', time: '2h ago', isRead: true),
    _NotifItem(type: 'follow', user: 'Kareem T.', avatar: 'KT', action: 'started following you', time: '3h ago', isRead: true),
    _NotifItem(type: 'comment', user: 'Anas A.', avatar: 'AA', action: 'replied to your comment: "Totally agree!"', time: '5h ago', isRead: true),
    _NotifItem(type: 'workshop', user: 'Flame', avatar: 'F', action: 'New workshop in AI: "Tools for Product Teams"', time: '1d ago', isRead: true),
    _NotifItem(type: 'like', user: 'Finance Lab', avatar: 'FL', action: 'liked your saved video', time: '1d ago', isRead: true),
    _NotifItem(type: 'follow', user: 'Jana A.', avatar: 'JA', action: 'started following you', time: '2d ago', isRead: true),
  ];

  List<_NotifItem> get _filtered {
    if (_filter == 'All') return _notifs;
    final map = {'Likes': 'like', 'Comments': 'comment', 'Follows': 'follow', 'Updates': 'workshop'};
    return _notifs.where((n) => n.type == map[_filter]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(color: const Color(0xFFFF7A18).withValues(alpha: 0.18), size: 220),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: _GlowOrb(color: const Color(0xFF6D28D9).withValues(alpha: 0.16), size: 240),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
                  child: Row(
                    children: [
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      const Text(
                        'Notifications',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() {
                          for (final n in _notifs) {
                            n.isRead = true;
                          }
                        }),
                        child: const Text(
                          'Mark all read',
                          style: TextStyle(color: Color(0xFFFF7A18), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final sel = _filter == _filters[i];
                      return GestureDetector(
                        onTap: () => setState(() => _filter = _filters[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFFF7A18).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: sel ? const Color(0xFFFF7A18) : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            _filters[i],
                            style: TextStyle(
                              color: sel ? Colors.white : const Color(0xFFB2B8CB),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Text(
                            'No notifications here',
                            style: TextStyle(color: Color(0xFFB2B8CB)),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _NotifTile(item: items[i]),
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

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.item});

  final _NotifItem item;

  static const _typeIcon = {
    'like': Icons.favorite_rounded,
    'comment': Icons.chat_bubble_rounded,
    'follow': Icons.person_add_rounded,
    'workshop': Icons.school_rounded,
  };

  static const _typeColor = {
    'like': Color(0xFFEF4444),
    'comment': Color(0xFF3B82F6),
    'follow': Color(0xFF10B981),
    'workshop': Color(0xFFFF7A18),
  };

  @override
  Widget build(BuildContext context) {
    final icon = _typeIcon[item.type] ?? Icons.notifications_rounded;
    final color = _typeColor[item.type] ?? const Color(0xFFFF7A18);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: item.isRead
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Text(
                      item.avatar,
                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      child: Icon(icon, size: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${item.user} ',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          TextSpan(
                            text: item.action,
                            style: const TextStyle(color: Color(0xFFB2B8CB), fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(item.time, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                  ],
                ),
              ),
              if (!item.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: const BoxDecoration(color: Color(0xFFFF7A18), shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifItem {
  _NotifItem({
    required this.type,
    required this.user,
    required this.avatar,
    required this.action,
    required this.time,
    required this.isRead,
  });

  final String type;
  final String user;
  final String avatar;
  final String action;
  final String time;
  bool isRead;
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
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}
