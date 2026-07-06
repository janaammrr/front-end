import 'package:flutter/material.dart';

import '../services/user_service.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatefulWidget {
  const UserAvatar({
    super.key,
    required this.displayName,
    this.profileUrl,
    this.username,
    this.radius = 15,
  });

  final String displayName;
  final String? profileUrl;
  final String? username;
  final double radius;

  static final Map<String, String?> _cache = {};

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolvedUrl = widget.profileUrl;
    if (_resolvedUrl == null && widget.username != null) {
      _resolve(widget.username!);
    }
  }

  Future<void> _resolve(String username) async {
    if (UserAvatar._cache.containsKey(username)) {
      final cached = UserAvatar._cache[username];
      if (cached != null && mounted) setState(() => _resolvedUrl = cached);
      return;
    }
    try {
      final user = await UserService.getByUsername(username);
      UserAvatar._cache[username] = user.profileUrl;
      if (mounted && user.profileUrl != null) {
        setState(() => _resolvedUrl = user.profileUrl);
      }
    } catch (_) {
      UserAvatar._cache[username] = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.displayName.trim().isNotEmpty
        ? widget.displayName.trim()[0].toUpperCase()
        : '?';
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppColors.amber.withValues(alpha: 0.25),
      backgroundImage: _resolvedUrl != null
          ? NetworkImage(_resolvedUrl!)
          : null,
      child: _resolvedUrl == null
          ? Text(
              initial,
              style: TextStyle(
                color: AppColors.amber,
                fontWeight: FontWeight.w800,
                fontSize: widget.radius * 0.85,
              ),
            )
          : null,
    );
  }
}
