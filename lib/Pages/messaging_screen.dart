import 'package:flutter/material.dart';
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

  List<InboxItem> _inbox = [];
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

  List<InboxItem> get _filtered => _query.isEmpty
      ? _inbox
      : _inbox
            .where(
              (c) => c.otherUser.displayName.toLowerCase().contains(_query),
            )
            .toList();

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
                      const Text(
                        'Messages',
                        style: TextStyle(
                          color: Colors.white,
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
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search messages',
                      hintStyle: const TextStyle(color: AppColors.text3),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.text3,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.amber,
                          width: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.amber,
                          ),
                        )
                      : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.white38,
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
                      ? const Center(
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
                              color: Colors.white.withValues(alpha: 0.06),
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

class _ConvoTile extends StatelessWidget {
  const _ConvoTile({required this.item, required this.onTap});

  final InboxItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      onTap: onTap,
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.amber.withValues(alpha: 0.2),
        child: Text(
          item.otherUser.initials,
          style: const TextStyle(
            color: AppColors.amber,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      title: Text(
        item.otherUser.displayName,
        style: TextStyle(
          color: Colors.white,
          fontWeight: item.unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        item.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: item.unreadCount > 0
              ? AppColors.text2
              : AppColors.text3,
          fontSize: 13,
        ),
      ),
      trailing: item.unreadCount > 0
          ? Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
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
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  _BackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.amber.withValues(alpha: 0.2),
                    child: Text(
                      widget.otherUser.initials,
                      style: const TextStyle(
                        color: AppColors.amber,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.otherUser.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.amber,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _ChatBubble(msg: _messages[i]),
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 10 + bottom),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Message…',
                        hintStyle: const TextStyle(
                          color: AppColors.text3,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.07),
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
                          borderSide: const BorderSide(
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
                      decoration: const BoxDecoration(
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
  const _ChatBubble({required this.msg});

  final ChatMessage msg;

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
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.amber.withValues(alpha: 0.2),
              child: const Text(
                '?',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
                        : Colors.white.withValues(alpha: 0.09),
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
                      color: msg.isMine
                          ? Colors.white
                          : AppColors.text2,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  msg.sentAt,
                  style: const TextStyle(
                    color: AppColors.border,
                    fontSize: 11,
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
