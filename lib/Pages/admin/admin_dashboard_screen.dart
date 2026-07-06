import 'package:flutter/material.dart';

import '../moderation_panel_screen.dart';
import 'admin_events_screen.dart';
import 'admin_posts_screen.dart';
import 'admin_providers_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_users_screen.dart';
import 'admin_workshops_screen.dart';
import '../../theme/app_theme.dart';

/// Mirrors the web app's /admin/* area (Users, Posts, Providers, Reports,
/// Events, Workshops management). Only reachable for ADMIN-role accounts.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminTile(
            icon: Icons.people_outline_rounded,
            title: 'Users',
            subtitle: 'Manage roles, suspensions, and accounts.',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
          ),
          _AdminTile(
            icon: Icons.article_outlined,
            title: 'Posts',
            subtitle: 'Moderate community text posts.',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPostsScreen())),
          ),
          _AdminTile(
            icon: Icons.storefront_outlined,
            title: 'Providers',
            subtitle: 'Manage workshop/event provider accounts.',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProvidersScreen())),
          ),
          _AdminTile(
            icon: Icons.flag_outlined,
            title: 'Reports',
            subtitle: 'Review reports submitted for posts and reels.',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportsScreen())),
          ),
          _AdminTile(
            icon: Icons.event_outlined,
            title: 'Events',
            subtitle: 'Edit, suspend, or remove events.',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEventsScreen())),
          ),
          _AdminTile(
            icon: Icons.school_outlined,
            title: 'Workshops',
            subtitle: 'Edit, suspend, or remove workshops.',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminWorkshopsScreen())),
          ),
          _AdminTile(
            icon: Icons.gpp_maybe_outlined,
            title: 'Reel Moderation Queue',
            subtitle: 'Approve or reject uploaded reels.',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModerationPanelScreen())),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.amber),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.border, size: 14),
        onTap: onTap,
      ),
    );
  }
}
