import 'package:flutter/material.dart';
import '../auth/auth.dart';
import 'public_profile_screen.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await UserService.getMe();
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (AuthService.isAuthFailure(e)) {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthPage()),
          (_) => false,
        );
        return;
      }
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_off_rounded,
                  color: AppColors.text3,
                  size: 56,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Could not load profile',
                  style: TextStyle(
                    color: AppColors.text1,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppColors.buttonRadius,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 13,
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _logout,
                  child: const Text(
                    'Log out & log in again',
                    style: TextStyle(color: AppColors.amber),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PublicProfileScreen(
      creatorId: _user?.id,
      creatorName: _user?.fullName ?? 'My Profile',
      profileUrl: _user?.profileUrl,
      username: _user?.username,
      isRootView: true,
      gradient: AppColors.profileHeaderGradient,
    );
  }
}
