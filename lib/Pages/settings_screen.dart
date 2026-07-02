import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../auth/auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _privateAccount = false;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _workshopReminders = true;
  bool _newFollowers = true;
  bool _likesComments = true;

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
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      _SettingsTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Change Password',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.link_rounded,
                        title: 'Linked Accounts',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.language_rounded,
                        title: 'Language',
                        trailing: const Text(
                          'English',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 13,
                          ),
                        ),
                        onTap: () {},
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader('Privacy'),
                      _SettingsToggle(
                        icon: Icons.visibility_off_outlined,
                        title: 'Private Account',
                        subtitle:
                            'Only approved followers can see your content',
                        value: _privateAccount,
                        onChanged: (v) => setState(() => _privateAccount = v),
                      ),
                      _SettingsTile(
                        icon: Icons.block_rounded,
                        title: 'Blocked Users',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.comment_bank_outlined,
                        title: 'Who can comment',
                        trailing: const Text(
                          'Everyone',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 13,
                          ),
                        ),
                        onTap: () {},
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader('Notifications'),
                      _SettingsToggle(
                        icon: Icons.notifications_outlined,
                        title: 'Push Notifications',
                        value: _pushNotifications,
                        onChanged: (v) =>
                            setState(() => _pushNotifications = v),
                      ),
                      _SettingsToggle(
                        icon: Icons.email_outlined,
                        title: 'Email Notifications',
                        value: _emailNotifications,
                        onChanged: (v) =>
                            setState(() => _emailNotifications = v),
                      ),
                      _SettingsToggle(
                        icon: Icons.school_outlined,
                        title: 'Workshop Reminders',
                        value: _workshopReminders,
                        onChanged: (v) =>
                            setState(() => _workshopReminders = v),
                      ),
                      _SettingsToggle(
                        icon: Icons.person_add_outlined,
                        title: 'New Followers',
                        value: _newFollowers,
                        onChanged: (v) => setState(() => _newFollowers = v),
                      ),
                      _SettingsToggle(
                        icon: Icons.favorite_border_rounded,
                        title: 'Likes & Comments',
                        value: _likesComments,
                        onChanged: (v) => setState(() => _likesComments = v),
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader('Content Preferences'),
                      _SettingsTile(
                        icon: Icons.category_outlined,
                        title: 'Preferred Categories',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.tune_rounded,
                        title: 'Feed Preferences',
                        onTap: () {},
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader('Support'),
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help Center',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.flag_outlined,
                        title: 'Report a Problem',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: 'About Flame',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {},
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader('Danger Zone'),
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
                      _DangerTile(
                        icon: Icons.delete_forever_rounded,
                        title: 'Delete Account',
                        onTap: () async {
                          await _confirmDialog(
                            context,
                            'Delete Account',
                            'This action is permanent and cannot be undone.',
                            'Delete',
                          );
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

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

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
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              )
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFFFF7A18),
          trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? const Color(0xFFFF7A18).withValues(alpha: 0.3)
                : Colors.white12,
          ),
        ),
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
