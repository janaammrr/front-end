import 'dart:ui';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/follow_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

/// TikTok-style "Send to friend" sheet, shared by the reel share flow and
/// the posts share flow. Sends via the backend's dedicated share endpoint
/// (`POST /api/chat/share`) so the recipient gets a structured shared-item
/// message rather than a plain text hashtag workaround.
class DmPickerSheet extends StatefulWidget {
  const DmPickerSheet({
    super.key,
    required this.sharedTargetId,
    required this.sharedTargetType,
    this.shareContent,
  });

  /// The reel or post id being shared.
  final int sharedTargetId;

  /// 'REEL' or 'POST'.
  final String sharedTargetType;

  /// Optional caption/content to include alongside the shared item.
  final String? shareContent;

  @override
  State<DmPickerSheet> createState() => _DmPickerSheetState();
}

class _DmPickerSheetState extends State<DmPickerSheet> {
  final TextEditingController _search = TextEditingController();
  final Set<int> _sentTo = {};
  int _myId = 0;
  List<FollowUser> _contacts = [];
  bool _loading = true;

  List<FollowUser> get _filtered {
    final q = _search.text.toLowerCase();
    if (q.isEmpty) return _contacts;
    return _contacts
        .where((c) => c.displayName.toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final me = await UserService.getMe();
    final following = await FollowService.getFollowing(me.id);
    if (!mounted) return;
    setState(() {
      _myId = me.id;
      _contacts = following;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _send(int index) async {
    if (_myId == 0) return;
    final c = _filtered[index];
    setState(() => _sentTo.add(index));
    try {
      await ChatService.shareToChat(
        receiverId: c.id,
        sharedTargetId: widget.sharedTargetId,
        sharedTargetType: widget.sharedTargetType,
        content: widget.shareContent,
      );
    } catch (_) {
      if (mounted) setState(() => _sentTo.remove(index));
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent to ${c.displayName}'),
          backgroundColor: AppColors.amber,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          decoration: BoxDecoration(
            color: AppColors.bg.withValues(alpha: 0.95),
            border: const Border(top: BorderSide(color: Color(0x1AFFFFFF))),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'Send to',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search friends...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.07),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.amber,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.42,
                  ),
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.amber,
                          ),
                        )
                      : _filtered.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Follow someone first to share in chat.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 20),
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(
                            color: Colors.white.withValues(alpha: 0.06),
                            height: 1,
                          ),
                          itemBuilder: (ctx, i) {
                            final c = filtered[i];
                            final sent = _sentTo.contains(i);
                            return _DmContactTile(
                              initial: c.initials.isEmpty ? '?' : c.initials[0],
                              name: c.displayName,
                              status: 'Message',
                              gradient: _dmGradient(i),
                              sent: sent,
                              onSend: () => _send(i),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // On-brand contact avatar gradients, replacing the previous unrelated
  // purple/teal/brown/indigo hues with variations of the site's palette.
  List<Color> _dmGradient(int i) {
    const gradients = [
      [AppColors.amber, AppColors.surface2],
      [AppColors.surface2, AppColors.surface],
      [AppColors.borderHi, AppColors.surface2],
      [AppColors.amberSoft, AppColors.surface2],
    ];
    return gradients[i % gradients.length];
  }
}

class _DmContactTile extends StatelessWidget {
  const _DmContactTile({
    required this.initial,
    required this.name,
    required this.status,
    required this.gradient,
    required this.sent,
    required this.onSend,
  });

  final String initial;
  final String name;
  final String status;
  final List<Color> gradient;
  final bool sent;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: gradient),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (status == 'Online') ...[
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                    Text(
                      status,
                      style: TextStyle(
                        color: status == 'Online'
                            ? const Color(0xFF22C55E)
                            : Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: sent ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: sent
                    ? null
                    : const LinearGradient(
                        colors: [AppColors.amber, AppColors.amberSoft],
                      ),
                color: sent ? Colors.white.withValues(alpha: 0.08) : null,
                borderRadius: BorderRadius.circular(999),
                border: sent
                    ? Border.all(color: Colors.white.withValues(alpha: 0.15))
                    : null,
                boxShadow: sent
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.amber.withValues(alpha: 0.38),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    sent ? Icons.check_rounded : Icons.send_rounded,
                    color: sent ? AppColors.amber : Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    sent ? 'Sent' : 'Send',
                    style: TextStyle(
                      color: sent ? AppColors.amber : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
