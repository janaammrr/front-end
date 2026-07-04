import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/reel_service.dart';
import '../services/workshop_service.dart';
import '../auth/auth.dart';
import 'edit_profile_screen.dart';
import 'liked_videos_screen.dart';
import 'my_events_screen.dart';
import 'my_workshops_screen.dart';
import 'preferences_screen.dart';
import 'saved_content_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? _likedCount;
  int? _savedCount;
  int? _bookedWorkshopsCount;
  int? _createdWorkshopsCount;
  int? _bookedEventsCount;
  int? _createdEventsCount;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final results = await Future.wait([
        ReelService.getLiked(),
        ReelService.getSaved(),
        WorkshopService.getBooked(),
        WorkshopService.getCreated(),
        EventService.getBooked(),
        EventService.getCreated(),
      ]);
      if (!mounted) return;
      setState(() {
        _likedCount = results[0].length;
        _savedCount = results[1].length;
        _bookedWorkshopsCount = results[2].length;
        _createdWorkshopsCount = results[3].length;
        _bookedEventsCount = results[4].length;
        _createdEventsCount = results[5].length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _likedCount ??= 0;
        _savedCount ??= 0;
        _bookedWorkshopsCount ??= 0;
        _createdWorkshopsCount ??= 0;
        _bookedEventsCount ??= 0;
        _createdEventsCount ??= 0;
      });
    }
  }

  String _countLabel(int? count, String singular, String plural) {
    if (count == null) return 'Loading...';
    return '$count ${count == 1 ? singular : plural}';
  }

  Future<void> _showChangePasswordSheet() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    bool saving = false;
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: oldCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration('Current password'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration('New password'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (oldCtrl.text.isEmpty || newCtrl.text.isEmpty) {
                              setSheet(
                                () => error = 'Both fields are required.',
                              );
                              return;
                            }
                            setSheet(() {
                              saving = true;
                              error = null;
                            });
                            try {
                              await AuthService.changePassword(
                                oldPassword: oldCtrl.text,
                                newPassword: newCtrl.text,
                              );
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              if (mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password updated.'),
                                    backgroundColor: Color(0xFFFF7A18),
                                  ),
                                );
                              }
                            } catch (e) {
                              setSheet(() {
                                saving = false;
                                error = ApiClient.errorMessage(
                                  e,
                                  fallback: 'Could not update password.',
                                );
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A18),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Update Password',
                            style: TextStyle(fontWeight: FontWeight.w700),
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

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF6B7280)),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
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
      borderSide: const BorderSide(color: Color(0xFFFF7A18), width: 1.1),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(
              color: const Color(0xFFFF7A18).withValues(alpha: 0.14),
              size: 200,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: _GlowOrb(
              color: const Color(0xFF6D28D9).withValues(alpha: 0.14),
              size: 240,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _SectionHeader('Account'),
                      _SettingsTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Edit Profile',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Change Password',
                        onTap: _showChangePasswordSheet,
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader('My Content'),
                      _SettingsTile(
                        icon: Icons.school_outlined,
                        title: 'My Workshops',
                        trailing: Text(
                          '${_countLabel(_bookedWorkshopsCount, 'booked', 'booked')} · ${_countLabel(_createdWorkshopsCount, 'created', 'created')}',
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyWorkshopsScreen(),
                          ),
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.event_available_outlined,
                        title: 'My Events',
                        trailing: Text(
                          '${_countLabel(_bookedEventsCount, 'booked', 'booked')} · ${_countLabel(_createdEventsCount, 'created', 'created')}',
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyEventsScreen(),
                          ),
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.favorite_border,
                        title: 'Liked Videos',
                        trailing: Text(
                          _countLabel(_likedCount, 'video', 'videos'),
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LikedVideosScreen(),
                          ),
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.bookmark_border,
                        title: 'Saved Content',
                        trailing: Text(
                          _countLabel(_savedCount, 'reel', 'reels'),
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SavedContentScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader('Preferences'),
                      _SettingsTile(
                        icon: Icons.category_outlined,
                        title: 'Preferred Categories',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PreferencesScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader('Account'),
                      _DangerTile(
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        onTap: () async {
                          final confirm = await _confirmDialog(
                            context,
                            'Sign Out',
                            'Are you sure you want to sign out?',
                            'Sign Out',
                          );
                          if (confirm == true && context.mounted) {
                            await AuthService.logout();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const AuthPage(),
                                ),
                                (_) => false,
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 40),
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

  Future<bool?> _confirmDialog(
    BuildContext context,
    String title,
    String body,
    String action,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(body, style: const TextStyle(color: Color(0xFFB2B8CB))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFB2B8CB)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFFF7A18),
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _GlassTile(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A18).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFF7A18), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF4B5563),
              size: 14,
            ),
        onTap: onTap,
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassTile(
      borderColor: const Color(0xFFEF4444).withValues(alpha: 0.25),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFEF4444), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Color(0xFF4B5563),
          size: 14,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _GlassTile extends StatelessWidget {
  const _GlassTile({required this.child, this.borderColor});

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: child,
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
