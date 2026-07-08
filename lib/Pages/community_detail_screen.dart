import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../components/user_avatar.dart';
import '../services/api_client.dart';
import '../services/community_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'public_profile_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({super.key, required this.community});

  final CommunityModel community;

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _postController = TextEditingController();

  int? _myId;
  CommunityDetailModel? _detail;
  bool _loading = true;
  String? _error;
  bool _posting = false;
  bool _joining = false;
  bool _requested = false;
  XFile? _pickedImage;

  List<CommunityUser> _pendingRequests = [];
  bool _loadingRequests = false;

  bool get _isOwner => _detail != null && _detail!.owner.id == _myId;
  bool get _isAdmin =>
      _isOwner || (_detail?.admins.any((a) => a.id == _myId) ?? false);
  bool get _isMember =>
      _isOwner || (_detail?.members.any((m) => m.id == _myId) ?? false);
  bool get _canOpen => _detail == null || !_detail!.isPrivate || _isMember;
  bool get _canPost =>
      _isMember && (_detail?.postingPermission != 'ADMINS_ONLY' || _isAdmin);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        UserService.getMe(),
        CommunityService.getDetail(widget.community.id),
      ]);
      final me = results[0] as dynamic;
      final detail = results[1] as CommunityDetailModel;
      if (!mounted) return;
      setState(() {
        _myId = me.id as int;
        _detail = detail;
        _loading = false;
      });
      if (_isOwner && detail.isPrivate) _loadPendingRequests();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiClient.errorMessage(
            e,
            fallback: 'Could not load this community.',
          );
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _loadingRequests = true);
    try {
      final requests = await CommunityService.getPendingJoinRequests(
        widget.community.id,
      );
      if (mounted) {
        setState(() {
          _pendingRequests = requests;
          _loadingRequests = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRequests = false);
    }
  }

  Future<void> _joinOrRequest() async {
    if (_joining || _requested) return;
    setState(() => _joining = true);
    try {
      if (widget.community.isPrivate) {
        await CommunityService.requestJoin(widget.community.id);
        if (mounted) setState(() => _requested = true);
      } else {
        await CommunityService.join(widget.community.id);
        await _load();
      }
    } catch (e) {
      if (mounted) _showError(e, 'Could not join this community.');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _leave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text(
          'Leave community',
          style: TextStyle(color: AppColors.text1),
        ),
        content: Text(
          'Leave ${widget.community.name}?',
          style: TextStyle(color: AppColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Leave',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await CommunityService.leave(widget.community.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _showError(e, 'Could not leave this community.');
    }
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null && mounted) setState(() => _pickedImage = file);
  }

  Future<void> _submitPost() async {
    final content = _postController.text.trim();
    if ((content.isEmpty && _pickedImage == null) || _posting) return;
    setState(() => _posting = true);
    try {
      await CommunityService.createPost(
        widget.community.id,
        content,
        imagePath: _pickedImage?.path,
      );
      _postController.clear();
      setState(() => _pickedImage = null);
      await _load();
    } catch (e) {
      if (mounted) _showError(e, 'Could not create post.');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _toggleLike(CommunityPostModel post) async {
    final wasLiked = post.likedByMe;
    setState(() {
      post.likedByMe = !wasLiked;
      post.likesCount += wasLiked ? -1 : 1;
    });
    try {
      if (wasLiked) {
        await CommunityService.unlikePost(widget.community.id, post.id);
      } else {
        await CommunityService.likePost(widget.community.id, post.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          post.likedByMe = wasLiked;
          post.likesCount += wasLiked ? 1 : -1;
        });
        _showError(e, 'Could not update like.');
      }
    }
  }

  Future<void> _deletePost(CommunityPostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text('Delete post', style: TextStyle(color: AppColors.text1)),
        content: Text(
          'This cannot be undone.',
          style: TextStyle(color: AppColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await CommunityService.deletePost(widget.community.id, post.id);
      await _load();
    } catch (e) {
      if (mounted) _showError(e, 'Could not delete post.');
    }
  }

  Future<void> _approveRequest(CommunityUser user) async {
    try {
      await CommunityService.approveJoinRequest(widget.community.id, user.id);
      setState(() => _pendingRequests.removeWhere((u) => u.id == user.id));
      await _load();
    } catch (e) {
      if (mounted) _showError(e, 'Could not approve request.');
    }
  }

  Future<void> _rejectRequest(CommunityUser user) async {
    try {
      await CommunityService.rejectJoinRequest(widget.community.id, user.id);
      if (mounted) {
        setState(() => _pendingRequests.removeWhere((u) => u.id == user.id));
      }
    } catch (e) {
      if (mounted) _showError(e, 'Could not reject request.');
    }
  }

  Future<void> _removeMember(CommunityUser member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text(
          'Remove member',
          style: TextStyle(color: AppColors.text1),
        ),
        content: Text(
          'Remove ${member.displayName} from this community?',
          style: TextStyle(color: AppColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await CommunityService.removeMember(widget.community.id, member.id);
      await _load();
    } catch (e) {
      if (mounted) _showError(e, 'Could not remove member.');
    }
  }

  Future<void> _togglePromote(
    CommunityUser member,
    bool isCurrentlyAdmin,
  ) async {
    try {
      if (isCurrentlyAdmin) {
        await CommunityService.demoteMember(widget.community.id, member.id);
      } else {
        await CommunityService.promoteMember(widget.community.id, member.id);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        _showError(
          e,
          isCurrentlyAdmin
              ? 'Could not demote member.'
              : 'Could not promote member.',
        );
      }
    }
  }

  void _showError(Object error, String fallback) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ApiClient.errorMessage(error, fallback: fallback)),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _openProfile(CommunityUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          creatorId: user.id,
          creatorName: user.displayName,
          profileUrl: user.profileUrl,
          username: user.username,
          gradient: AppColors.profileHeaderGradient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _CircleBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.community.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.text1,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.community.isPrivate)
                  Text(
                    'Private community',
                    style: TextStyle(color: AppColors.text3, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (_isMember && !_isOwner)
            _CircleBtn(icon: Icons.logout_rounded, onTap: _leave),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.amber));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.text3, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (!_canOpen) return _buildLockedState();

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.amber,
          labelColor: AppColors.text1,
          unselectedLabelColor: AppColors.text3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Members'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildPostsTab(), _buildMembersTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildLockedState() {
    final detail = _detail;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: AppColors.text3,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              'This is a private community',
              style: TextStyle(
                color: AppColors.text1,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (detail != null) ...[
              Text(
                'Owner: ${detail.owner.displayName}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (detail.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  detail.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text2,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
            Text(
              'Request to join to see posts and members.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.text3, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_joining || _requested) ? null : _joinOrRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _joining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _requested ? 'Requested' : 'Request to Join',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    final posts = _detail?.posts ?? [];
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.amber,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_canPost) ...[_buildComposer(), const SizedBox(height: 16)],
          if (posts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'No posts yet',
                  style: TextStyle(color: AppColors.text2),
                ),
              ),
            )
          else
            ...posts.map(
              (p) => _PostCard(
                post: p,
                canDelete: p.author.id == _myId || _isOwner,
                onAuthorTap: () => _openProfile(p.author),
                onLike: () => _toggleLike(p),
                onDelete: () => _deletePost(p),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.text1.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.text1.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _postController,
            maxLines: 3,
            style: TextStyle(color: AppColors.text1),
            decoration: InputDecoration(
              hintText: 'Share something with the community…',
              hintStyle: TextStyle(color: AppColors.text3),
              filled: true,
              fillColor: AppColors.text1.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_pickedImage != null) ...[
            const SizedBox(height: 10),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_pickedImage!.path),
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => setState(() => _pickedImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.text1.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.text1.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: AppColors.amber,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _posting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _posting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Post',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    final detail = _detail;
    if (detail == null) return const SizedBox.shrink();
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.amber,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isOwner && detail.isPrivate) ...[
            Text(
              'Join Requests',
              style: TextStyle(
                color: AppColors.amber,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            if (_loadingRequests)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.amber),
                ),
              )
            else if (_pendingRequests.isEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'No pending requests',
                  style: TextStyle(color: AppColors.text3, fontSize: 13),
                ),
              )
            else
              ..._pendingRequests.map(
                (u) => _RequestRow(
                  user: u,
                  onTap: () => _openProfile(u),
                  onApprove: () => _approveRequest(u),
                  onReject: () => _rejectRequest(u),
                ),
              ),
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.text1.withValues(alpha: 0.08)),
            const SizedBox(height: 16),
          ],
          Text(
            '${detail.members.length} members',
            style: TextStyle(
              color: AppColors.amber,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ...detail.members.map((m) {
            final memberIsOwner = m.id == detail.owner.id;
            final memberIsAdmin = detail.admins.any((a) => a.id == m.id);
            return _MemberRow(
              user: m,
              badge: memberIsOwner ? 'Owner' : (memberIsAdmin ? 'Admin' : null),
              onTap: () => _openProfile(m),
              canManage: _isOwner && !memberIsOwner,
              isAdmin: memberIsAdmin,
              onPromoteToggle: () => _togglePromote(m, memberIsAdmin),
              onRemove: () => _removeMember(m),
            );
          }),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.canDelete,
    required this.onAuthorTap,
    required this.onLike,
    required this.onDelete,
  });

  final CommunityPostModel post;
  final bool canDelete;
  final VoidCallback onAuthorTap;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (post.mediaUrls.isNotEmpty) {
      return Container(
        height: 340,
        margin: const EdgeInsets.only(bottom: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                post.mediaUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white.withValues(alpha: 0.05),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white24,
                      size: 44,
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                top: 14,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onAuthorTap,
                      child: UserAvatar(
                        displayName: post.author.displayName,
                        profileUrl: post.author.profileUrl,
                        username: post.author.username,
                        radius: 19,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: GestureDetector(
                        onTap: onAuthorTap,
                        child: Text(
                          post.author.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    if (canDelete)
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onLike,
                          child: Icon(
                            post.likedByMe
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likesCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.commentsCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (post.content.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        post.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.text1.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.text1.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onAuthorTap,
                child: Row(
                  children: [
                    UserAvatar(
                      displayName: post.author.displayName,
                      profileUrl: post.author.profileUrl,
                      username: post.author.username,
                      radius: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      post.author.displayName,
                      style: TextStyle(
                        color: AppColors.text1,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (canDelete)
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.text3,
                    size: 18,
                  ),
                ),
            ],
          ),
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              post.content,
              style: TextStyle(
                color: AppColors.text2,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.mediaUrls.first,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: AppColors.text1.withValues(alpha: 0.05),
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.text3,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Row(
                  children: [
                    Icon(
                      post.likedByMe
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: post.likedByMe ? AppColors.amber : AppColors.text3,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likesCount}',
                      style: TextStyle(color: AppColors.text3, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.text3,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${post.commentsCount}',
                style: TextStyle(color: AppColors.text3, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.user,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  final CommunityUser user;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  UserAvatar(
                    displayName: user.displayName,
                    profileUrl: user.profileUrl,
                    username: user.username,
                    radius: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user.displayName,
                      style: TextStyle(
                        color: AppColors.text1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onApprove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onReject,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.user,
    required this.badge,
    required this.onTap,
    required this.canManage,
    required this.isAdmin,
    required this.onPromoteToggle,
    required this.onRemove,
  });

  final CommunityUser user;
  final String? badge;
  final VoidCallback onTap;
  final bool canManage;
  final bool isAdmin;
  final VoidCallback onPromoteToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  UserAvatar(
                    displayName: user.displayName,
                    profileUrl: user.profileUrl,
                    username: user.username,
                    radius: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          color: AppColors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (canManage)
            PopupMenuButton<String>(
              color: AppColors.surface2,
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppColors.text3,
                size: 20,
              ),
              onSelected: (value) {
                if (value == 'promote') onPromoteToggle();
                if (value == 'remove') onRemove();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'promote',
                  child: Text(
                    isAdmin ? 'Demote to member' : 'Promote to admin',
                    style: TextStyle(color: AppColors.text1),
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text(
                    'Remove from community',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.text1.withValues(alpha: 0.07),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.text1.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: AppColors.text1, size: 18),
      ),
    );
  }
}
