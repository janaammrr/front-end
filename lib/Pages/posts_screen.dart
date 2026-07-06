import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/auth.dart';
import '../components/dm_picker_sheet.dart';
import '../components/double_tap_like.dart';
import '../components/user_avatar.dart';
import '../models/post_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/follow_service.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import 'post_detail_screen.dart';
import 'public_profile_screen.dart';
import '../theme/app_theme.dart';

enum _FeedTab { feed, friends }

/// A post from the personal feed, normalized for the card UI.
class _FeedItem {
  _FeedItem({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorProfileUrl,
    required this.authorUsername,
    required this.createdAt,
    required this.mediaUrls,
    required this.likeCount,
    required this.likedByMe,
    required this.commentCount,
    required this.isMine,
    required this.toggleLike,
    required this.delete,
  });

  final int id;
  final String content;
  final int authorId;
  final String authorName;
  final String? authorProfileUrl;
  final String? authorUsername;
  final DateTime? createdAt;
  final List<String> mediaUrls;
  int likeCount;
  bool likedByMe;
  final int commentCount;
  final bool isMine;
  final Future<void> Function() toggleLike;
  final Future<void> Function() delete;

  factory _FeedItem.fromPost(PostModel post, int? myId) => _FeedItem(
        id: post.id,
        content: post.content,
        authorId: post.author.id,
        authorName: post.author.fullName,
        authorProfileUrl: null,
        authorUsername: post.author.username,
        createdAt: DateTime.tryParse(post.createdAt),
        mediaUrls: post.mediaUrls,
        likeCount: post.likeCount,
        likedByMe: post.likedByMe,
        commentCount: post.commentCount,
        isMine: myId != null && myId == post.author.id,
        toggleLike: () => PostService.toggleLike(post.id),
        delete: () => PostService.deletePost(post.id),
      );
}

String formatRelativeTime(DateTime? dateTime) {
  if (dateTime == null) return '';
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} Minutes Ago';
  if (diff.inHours < 24) return '${diff.inHours} Hours Ago';
  if (diff.inDays < 7) return '${diff.inDays} Days Ago';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  _FeedTab _tab = _FeedTab.feed;
  Set<int> _followingIds = {};

  List<_FeedItem> _feed = [];
  bool _loadingFeed = true;
  String? _feedError;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loadingFeed = true;
      _feedError = null;
    });
    try {
      final posts = await PostService.getAll();
      int? myId;
      Set<int> following = {};
      try {
        myId = (await UserService.getMe()).id;
        following = (await FollowService.getFollowing(myId)).map((f) => f.id).toSet();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _feed = posts.map((p) => _FeedItem.fromPost(p, myId)).toList();
        _followingIds = following;
        _loadingFeed = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (AuthService.isAuthFailure(e)) {
        await AuthService.logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthPage()),
          (_) => false,
        );
        return;
      }
      setState(() {
        _feedError = ApiClient.errorMessage(e, fallback: 'Could not load posts.');
        _loadingFeed = false;
      });
    }
  }

  List<_FeedItem> get _friends =>
      _feed.where((p) => _followingIds.contains(p.authorId)).toList();

  Future<void> _toggleLike(_FeedItem item) async {
    setState(() {
      item.likedByMe = !item.likedByMe;
      item.likeCount += item.likedByMe ? 1 : -1;
    });
    try {
      await item.toggleLike();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        item.likedByMe = !item.likedByMe;
        item.likeCount += item.likedByMe ? 1 : -1;
      });
    }
  }

  Future<void> _delete(_FeedItem item, List<_FeedItem> list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete post?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.', style: TextStyle(color: AppColors.text2)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await item.delete();
      if (mounted) setState(() => list.remove(item));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.errorMessage(e, fallback: 'Could not delete post.'))),
      );
    }
  }

  Future<void> _openCompose() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ComposePostSheet(),
    );
    if (created == true) {
      _loadFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Posts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.amber),
            onPressed: _openCompose,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TabButton(label: 'Feed', active: _tab == _FeedTab.feed, onTap: () => setState(() => _tab = _FeedTab.feed)),
                _TabButton(label: 'Friends', active: _tab == _FeedTab.friends, onTap: () => setState(() => _tab = _FeedTab.friends)),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case _FeedTab.feed:
        return _buildList(_feed, _loadingFeed, _feedError, _loadFeed, 'No posts yet');
      case _FeedTab.friends:
        return _buildList(_friends, _loadingFeed, _feedError, _loadFeed, "You don't follow anyone with posts yet");
    }
  }

  Widget _buildList(List<_FeedItem> items, bool loading, String? error, Future<void> Function() onRefresh, String emptyMessage) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.amber));
    }
    if (error != null && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white38, size: 48),
              const SizedBox(height: 12),
              Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRefresh,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.article_outlined, color: Colors.white24, size: 56),
            const SizedBox(height: 12),
            Text(emptyMessage, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openCompose,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber),
              child: const Text('Write a post'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.amber,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _PostCard(
            item: item,
            onLike: () => _toggleLike(item),
            onDelete: () => _delete(item, items),
            onOpen: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => PostDetailScreen(postId: item.id)),
              );
              if (changed == true) _loadFeed();
            },
            onAuthorTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PublicProfileScreen(
                  creatorId: item.authorId,
                  creatorName: item.authorName,
                  username: item.authorUsername,
                  profileUrl: item.authorProfileUrl,
                  gradient: AppColors.profileHeaderGradient,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.amber : Colors.white54,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: active ? 28 : 0,
            height: 2.5,
            decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(999)),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.item,
    required this.onLike,
    required this.onDelete,
    required this.onOpen,
    required this.onAuthorTap,
  });

  final _FeedItem item;
  final VoidCallback onLike;
  final VoidCallback onDelete;
  final VoidCallback? onOpen;
  final VoidCallback onAuthorTap;

  Future<void> _confirmDelete(BuildContext context) async => onDelete();

  @override
  Widget build(BuildContext context) {
    return DoubleTapLike(
      isLiked: item.likedByMe,
      onLike: onLike,
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onAuthorTap,
                  child: UserAvatar(
                    displayName: item.authorName,
                    profileUrl: item.authorProfileUrl,
                    username: item.authorUsername,
                    radius: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onAuthorTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.authorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        Text(formatRelativeTime(item.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                if (item.isMine)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded, color: Colors.white54),
                    color: AppColors.surface,
                    onSelected: (value) {
                      if (value == 'delete') _confirmDelete(context);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                    ],
                  ),
              ],
            ),
            if (item.content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(item.content, style: const TextStyle(color: Colors.white, height: 1.4)),
            ],
            if (item.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              MediaGrid(urls: item.mediaUrls),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                InkWell(
                  onTap: onLike,
                  child: Row(
                    children: [
                      Icon(
                        item.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: item.likedByMe ? AppColors.amber : Colors.white54,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text('${item.likeCount}', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: onOpen,
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white54, size: 18),
                      const SizedBox(width: 6),
                      Text('${item.commentCount}', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    barrierColor: Colors.black54,
                    useSafeArea: true,
                    isScrollControlled: true,
                    builder: (_) => DmPickerSheet(
                      sharedTargetId: item.id,
                      sharedTargetType: 'POST',
                      shareContent: item.content,
                    ),
                  ),
                  child: const Icon(Icons.send_outlined, color: Colors.white54, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MediaGrid extends StatelessWidget {
  const MediaGrid({super.key, required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final shown = urls.take(4).toList();
    if (shown.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Image.network(shown[0], fit: BoxFit.cover),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: shown.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final isLastVisible = index == 3 && urls.length > 4;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.network(shown[index], fit: BoxFit.cover),
              if (isLastVisible)
                Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  alignment: Alignment.center,
                  child: Text(
                    '+${urls.length - 4}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ComposePostSheet extends StatefulWidget {
  const ComposePostSheet({super.key});

  @override
  State<ComposePostSheet> createState() => ComposePostSheetState();
}

class ComposePostSheetState extends State<ComposePostSheet> {
  final _controller = TextEditingController();
  final List<XFile> _images = [];
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) setState(() => _images.addAll(picked));
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty && _images.isEmpty) return;
    setState(() => _busy = true);
    try {
      await PostService.create(content, imagePaths: _images.map((f) => f.path).toList());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.errorMessage(e, fallback: 'Could not create post.'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          color: AppColors.surface2,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 14),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                if (_images.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(_images[index].path),
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => setState(() => _images.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('Photo'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.amber, side: const BorderSide(color: AppColors.amber)),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Post', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
