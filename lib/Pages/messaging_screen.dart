import 'package:flutter/material.dart';
import '../components/user_avatar.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../services/follow_service.dart';
import '../theme/app_theme.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _unreadOnly = false;

  List<InboxItem> _inbox = [];
  List<FollowUser> _following = [];
  bool _loading = true;
  String? _error;
  int _myId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await UserService.getMe();
      final results = await Future.wait([
        ChatService.getInbox(),
        FollowService.getFollowing(me.id),
      ]);
      final inbox = results[0] as List<InboxItem>;
      final following = results[1] as List<FollowUser>;
      final inboxUserIds = inbox.map((item) => item.otherUser.id).toSet();
      final startableChats = following
          .where((user) => !inboxUserIds.contains(user.id))
          .map(
            (user) => InboxItem(
              otherUser: ChatUser(
                id: user.id,
                firstname: user.firstname,
                lastname: user.lastname,
                profileUrl: user.profileUrl,
              ),
              lastMessage: 'Start a conversation',
              isRead: true,
              unreadCount: 0,
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _inbox = [...inbox, ...startableChats];
        _following = following;
        _myId = me.id;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InboxItem> get _filtered {
    var list = _inbox;
    if (_unreadOnly) {
      list = list.where((c) => c.unreadCount > 0).toList();
    }
    if (_query.isNotEmpty) {
      list = list
          .where((c) => c.otherUser.displayName.toLowerCase().contains(_query))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final convos = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(
              color: AppColors.amber.withValues(alpha: 0.14),
              size: 200,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: _GlowOrb(
              color: AppColors.amberSoft.withValues(alpha: 0.14),
              size: 240,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 12),
                      Text(
                        'Messages',
                        style: TextStyle(
                          color: AppColors.text1,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                    style: TextStyle(color: AppColors.text1),
                    decoration: InputDecoration(
                      hintText: 'Search messages',
                      hintStyle: TextStyle(color: AppColors.text3),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.text3,
                      ),
                      filled: true,
                      fillColor: AppColors.text1.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.text1.withValues(alpha: 0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.text1.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.amber,
                          width: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!_loading && _following.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 76,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _following.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, i) {
                        final friend = _following[i];
                        return GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                otherUser: ChatUser(
                                  id: friend.id,
                                  firstname: friend.firstname,
                                  lastname: friend.lastname,
                                  profileUrl: friend.profileUrl,
                                ),
                                myId: _myId,
                              ),
                            ),
                          ),
                          child: SizedBox(
                            width: 56,
                            child: Column(
                              children: [
                                UserAvatar(
                                  displayName: friend.displayName,
                                  profileUrl: friend.profileUrl,
                                  radius: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  friend.firstname,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.text2,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (!_loading && _error == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _InboxFilterChip(
                          label: 'All',
                          selected: !_unreadOnly,
                          onTap: () => setState(() => _unreadOnly = false),
                        ),
                        const SizedBox(width: 8),
                        _InboxFilterChip(
                          label: 'Unread',
                          selected: _unreadOnly,
                          onTap: () => setState(() => _unreadOnly = true),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.amber,
                          ),
                        )
                      : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppColors.text3,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _load,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.amber,
                                ),
                                child: const Text(
                                  'Retry',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        )
                      : convos.isEmpty
                      ? Center(
                          child: Text(
                            'No conversations yet',
                            style: TextStyle(color: AppColors.text3),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.amber,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: convos.length,
                            separatorBuilder: (_, _) => Divider(
                              color: AppColors.text1.withValues(alpha: 0.06),
                              height: 1,
                            ),
                            itemBuilder: (_, i) => _ConvoTile(
                              item: convos[i],
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    otherUser: convos[i].otherUser,
                                    myId: _myId,
                                  ),
                                ),
                              ),
                            ),
                          ),
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

class _InboxFilterChip extends StatelessWidget {
  const _InboxFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.amber
              : AppColors.text1.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.text3,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _ConvoTile extends StatelessWidget {
  const _ConvoTile({required this.item, required this.onTap});

  final InboxItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      onTap: onTap,
      leading: UserAvatar(
        displayName: item.otherUser.displayName,
        profileUrl: item.otherUser.profileUrl,
        radius: 26,
      ),
      title: Text(
        item.otherUser.displayName,
        style: TextStyle(
          color: AppColors.text1,
          fontWeight: item.unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        item.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: item.unreadCount > 0 ? AppColors.text2 : AppColors.text3,
          fontSize: 13,
        ),
      ),
      trailing: item.unreadCount > 0
          ? Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.amber,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${item.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// ─── Chat Screen ─────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.otherUser, required this.myId});

  final ChatUser otherUser;
  final int myId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ChatService.getConversation(
        widget.otherUser.id,
        widget.myId,
      );
      if (mounted) {
        setState(() {
          _messages = msgs;
          _loading = false;
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);
    try {
      final msg = await ChatService.sendMessage(
        widget.otherUser.id,
        text,
        widget.myId,
      );
      if (mounted) {
        setState(() {
          _messages.add(msg);
          _sending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.text1.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  _BackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 10),
                  UserAvatar(
                    displayName: widget.otherUser.displayName,
                    profileUrl: widget.otherUser.profileUrl,
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.otherUser.displayName,
                    style: TextStyle(
                      color: AppColors.text1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.amber),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _ChatBubble(
                        msg: _messages[i],
                        otherUser: widget.otherUser,
                      ),
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 10 + bottom),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: AppColors.text1, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Message…',
                        hintStyle: TextStyle(
                          color: AppColors.text3,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppColors.text1.withValues(alpha: 0.07),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: AppColors.amber,
                            width: 1.2,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.msg, required this.otherUser});

  final ChatMessage msg;
  final ChatUser otherUser;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: msg.isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isMine) ...[
            UserAvatar(
              displayName: otherUser.displayName,
              profileUrl: otherUser.profileUrl,
              radius: 14,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isMine
                        ? AppColors.amber
                        : AppColors.text1.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(msg.isMine ? 18 : 4),
                      bottomRight: Radius.circular(msg.isMine ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: msg.isMine ? Colors.white : AppColors.text2,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  msg.sentAt,
                  style: TextStyle(color: AppColors.border, fontSize: 11),
                ),
              ],
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
          color: AppColors.text1.withValues(alpha: 0.07),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.text1.withValues(alpha: 0.12)),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.text1,
          size: 18,
        ),
      ),
    );
  }
}
