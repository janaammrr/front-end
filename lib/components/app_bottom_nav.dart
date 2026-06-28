import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
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
            _AppNavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              active: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
            _AppNavItem(
              icon: Icons.school_outlined,
              label: 'Workshops',
              active: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
            _AppNavItem(
              icon: Icons.event_outlined,
              label: 'Events',
              active: selectedIndex == 2,
              onTap: () => onTap(2),
            ),
            _AppNavItem(
              icon: Icons.groups_outlined,
              label: 'Communities',
              active: selectedIndex == 3,
              onTap: () => onTap(3),
            ),
            _AppNavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              active: selectedIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppNavItem extends StatelessWidget {
  const _AppNavItem({
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
    final color = active ? Colors.white : Colors.white70;

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
              style: TextStyle(color: color, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}