import 'package:flutter/material.dart';

import '../components/dm_picker_sheet.dart';
import '../components/double_tap_like.dart';
import '../components/user_avatar.dart';
import 'posts_screen.dart' show MediaGrid, formatRelativeTime;
import '../models/post_model.dart';
import '../services/api_client.dart';
import '../services/comment_service.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import 'public_profile_screen.dart';
import '../theme/app_theme.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final int postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  PostModel? _post;
  List<CommentModel> _comments = [];
  int? _myId;
  bool _loading = true;
  bool _sendingComment = false;
  bool _changed = false;
  String? _error;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final post = await PostService.getById(widget.postId);
      final comments = await PostService.getComments(widget.postId);
      int? myId;
      try {
        myId = (await UserService.getMe()).id;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _post = post;
        _comments = comments;
        _myId = myId;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.errorMessage(e, fallback: 'Could not load post.');
        _loading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final post = _post;
    if (post == null) return;
    setState(() {
      _post = PostModel(
        id: post.id,
        content: post.content,
        author: post.author,
        createdAt: post.createdAt,
        likeCount: post.likedByMe ? post.likeCount - 1 : post.likeCount + 1,
        commentCount: post.commentCount,
        likedByMe: !post.likedByMe,
        mediaUrls: post.mediaUrls,
      );
      _changed = true;
    });
    try {
      await PostService.toggleLike(post.id);
    } catch (_) {
      if (mounted) setState(() => _post = post);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingComment = true);
    try {
      final comment = await PostService.addComment(widget.postId, text);
      _commentController.clear();
      if (!mounted) return;
      setState(() {
        _comments = [..._comments, comment];
        final post = _post;
        if (post != null) {
          _post = PostModel(
            id: post.id,
            content: post.content,
            author: post.author,
            createdAt: post.createdAt,
            likeCount: post.likeCount,
            commentCount: post.commentCount + 1,
            likedByMe: post.likedByMe,
            mediaUrls: post.mediaUrls,
          );
        }
        _changed = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiClient.errorMessage(e, fallback: 'Could not post comment.'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  Future<void> _confirmDelete() async {
    final post = _post;
    if (post == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete post?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This cannot be undone.',
          style: TextStyle(color: AppColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await PostService.deletePost(post.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiClient.errorMessage(e, fallback: 'Could not delete post.'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          elevation: 0,
          title: const Text(
            'Post',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          actions: [
            if (_post != null && _myId != null && _myId == _post!.author.id)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                onPressed: _confirmDelete,
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.amber));
    }
    if (_error != null || _post == null) {
      return Center(
        child: Text(
          _error ?? 'Post not found',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    final post = _post!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(
                          creatorId: post.author.id,
                          creatorName: post.author.fullName,
                          gradient: AppColors.profileHeaderGradient,
                        ),
                      ),
                    ),
                    child: UserAvatar(
                      displayName: post.author.fullName,
                      radius: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        formatRelativeTime(DateTime.tryParse(post.createdAt)),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (post.content.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  post.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
              if (post.mediaUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                DoubleTapLike(
                  isLiked: post.likedByMe,
                  onLike: _toggleLike,
                  child: MediaGrid(urls: post.mediaUrls),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  InkWell(
                    onTap: _toggleLike,
                    child: Row(
                      children: [
                        Icon(
                          post.likedByMe
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: post.likedByMe
                              ? AppColors.amber
                              : Colors.white54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likeCount}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white54,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.commentCount}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
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
                        sharedTargetId: post.id,
                        sharedTargetType: 'POST',
                        shareContent: post.content,
                      ),
                    ),
                    child: const Icon(
                      Icons.send_outlined,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 32),
              const Text(
                'Comments',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (_comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No comments yet. Be the first!',
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              else
                for (final comment in _comments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserAvatar(
                          displayName: comment.user.name,
                          username: comment.user.username,
                          radius: 15,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.user.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                comment.content,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendComment(),
                  ),
                ),
                const SizedBox(width: 8),
                _sendingComment
                    ? SizedBox(
                        width: 40,
                        height: 40,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.amber,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: Icon(Icons.send_rounded, color: AppColors.amber),
                        onPressed: _sendComment,
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
