import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/community_post.dart';
import '../theme/app_colors.dart';
import 'user_badge_widget.dart';
import 'like_animation.dart';
import '../services/reaction_service.dart';
import 'reaction_picker.dart';
import '../models/reaction_type.dart' as ReactionTypeModel;
import 'inline_comments_section.dart';
import '../services/community_post_service.dart';
import '../services/community_service.dart';
import 'select_community_dialog.dart';
import '../models/community.dart';
import 'poll_widget.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

/// Instagram-style post card with borderless design and rich interactions
class PostCard extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final bool showCommunity;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.showCommunity = true,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isExpanded = false;
  bool _isLiked = false;
  ReactionTypeModel.ReactionType? _currentReaction;
  OverlayEntry? _overlayEntry;
  final GlobalKey _likeButtonKey = GlobalKey();
  bool _isBookmarked = false;
  int _likeCount = 0;
  int _reactionCount = 0;
  int _commentCount = 0;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likeCount;
    _reactionCount = widget.post.reactionCount;
    _commentCount = widget.post.commentCount;
    _loadReaction();
    _loadBookmarkStatus();
  }

  Future<void> _loadReaction() async {
    // Load user's current reaction from backend data
    if (widget.post.userReaction != null) {
      _currentReaction = ReactionTypeModel.ReactionType.fromString(widget.post.userReaction);
      _isLiked = true; // User has a reaction, so show as liked
    } else if (_isLiked) {
      _currentReaction = ReactionTypeModel.ReactionType.like;
    }
  }

  Future<void> _loadBookmarkStatus() async {
    final res = await CommunityPostService.getBookmarkStatus(widget.post.postId);
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() {
        _isBookmarked = res.data!;
      });
    }
  }

  Future<void> _refreshCountsAndReaction() async {
    final countsRes = await CommunityPostService.getPostCounts(widget.post.postId);
    if (countsRes.success && countsRes.data != null && mounted) {
      setState(() {
        _likeCount = countsRes.data!['likeCount'] ?? _likeCount;
        _reactionCount = countsRes.data!['reactionCount'] ?? _reactionCount;
        _commentCount = countsRes.data!['commentCount'] ?? _commentCount;
      });
    }

    final reactionRes = await CommunityPostService.getUserReaction(widget.post.postId);
    if (reactionRes.success && reactionRes.data != null && mounted) {
      final d = reactionRes.data!;
      setState(() {
        _isLiked = (d['isLiked'] as bool?) ?? false;
        final ur = d['userReaction'] as String?;
        _currentReaction = ReactionTypeModel.ReactionType.fromString(ur);
      });
    }
  }

  void _toggleLike() {
    if (_currentReaction != null) {
      // Remove reaction
      ReactionService.removePostReaction(widget.post.postId).then((response) {
        if (response.success && mounted) {
          setState(() {
            _isLiked = false;
            _currentReaction = null;
          });
          _refreshCountsAndReaction();
          widget.onLike?.call();
        }
      });
    } else {
      // Add like reaction - convert model ReactionType to service ReactionType
      ReactionService.addPostReaction(widget.post.postId, _convertToServiceReactionType(ReactionTypeModel.ReactionType.like))
          .then((response) {
        if (response.success && mounted) {
          setState(() {
            _isLiked = true;
            _currentReaction = ReactionTypeModel.ReactionType.like;
          });
          _refreshCountsAndReaction();
          widget.onLike?.call();
        }
      });
    }
    HapticFeedback.lightImpact();
  }

  void _handleLike() {
    _toggleLike();
  }

  void _showReactionPicker() {
    if (_overlayEntry != null) return;

    final RenderBox? renderBox =
        _likeButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 100,
        top: position.dy - 60,
        child: ReactionPicker(
          onReactionSelected: (reaction) {
            _selectReaction(reaction);
            _hideReactionPicker();
          },
          onDismiss: _hideReactionPicker,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideReactionPicker() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _selectReaction(ReactionTypeModel.ReactionType reaction) async {
    // If same reaction, remove it
    if (_currentReaction == reaction) {
      await ReactionService.removePostReaction(widget.post.postId);
      setState(() {
        _currentReaction = null;
        _isLiked = false;
      });
      await _refreshCountsAndReaction();
    } else {
      // Update or add reaction - convert model ReactionType to service ReactionType
      await ReactionService.addPostReaction(widget.post.postId, _convertToServiceReactionType(reaction));
      setState(() {
        _currentReaction = reaction;
        _isLiked = true;
      });
      await _refreshCountsAndReaction();
    }
    HapticFeedback.mediumImpact();
    widget.onLike?.call();
  }

  Future<void> _handleShare() async {
    final myCommunitiesRes = await CommunityService.getMyCommunities();
    if (!mounted) return;
    if (!myCommunitiesRes.success || myCommunitiesRes.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(myCommunitiesRes.error ?? 'Failed to load communities')),
      );
      return;
    }

    final List<Community> communities = myCommunitiesRes.data!;
    if (communities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join a community to share this post')),
      );
      return;
    }

    final selected = await showDialog<Community>(
      context: context,
      builder: (ctx) => SelectCommunityDialog(communities: communities),
    );
    if (selected == null) return;

    final res = await CommunityPostService.sharePost(
      postId: widget.post.postId,
      targetCommunityId: selected.communityId,
    );
    if (!mounted) return;
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post shared successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Failed to share post')),
      );
    }
  }

  void _showThreeDotsMenu() {
    final isAuthor = _isCurrentUserAuthor();
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAuthor) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to edit page
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog();
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.report, color: Colors.red),
                title: const Text('Report', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: const Text('Hide'),
                onTap: () {
                  Navigator.pop(context);
                  // Placeholder: local hide only
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post hidden')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final res = await CommunityPostService.deletePost(widget.post.postId);
              if (!mounted) return;
              if (res.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res.error ?? 'Failed to delete post')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Tell us what is wrong with this post',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final res = await CommunityPostService.reportPost(
                postId: widget.post.postId,
                reason: controller.text.isEmpty ? 'Inappropriate' : controller.text,
              );
              if (!mounted) return;
              if (res.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res.error ?? 'Failed to report post')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSave() async {
    HapticFeedback.lightImpact();
    final res = await CommunityPostService.toggleBookmark(widget.post.postId);
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() {
        _isBookmarked = res.data!;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isBookmarked ? 'Saved' : 'Removed from saved')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error ?? 'Failed to update saved status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Calculate total engagement count
    final totalLikes = _likeCount + _reactionCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 0.5,
          ),
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Story ring (if active)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _hasActiveContent()
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFFF6F00),
                              Color(0xFFFFC107),
                              Color(0xFFE91E63),
                            ],
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.surface,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        widget.post.authorName.isNotEmpty
                            ? widget.post.authorName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Username and info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.post.authorName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          UserBadgeWidget(type: _getUserType(), size: 12),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            _formatDateTime(widget.post.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (_hasActiveContent()) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // More options (three dots menu)
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: _showThreeDotsMenu,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Image with double-tap like
          if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
            LikeAnimation(
              isLiked: _isLiked,
              onLike: _handleLike,
              size: 120,
              child: GestureDetector(
                onTap: widget.onTap,
                child: Image.network(
                  widget.post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 400,
                      color: isDark ? AppColors.darkSurface : AppColors.border,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: isDark ? AppColors.darkSurface : AppColors.border,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ),
            ),

          // Caption (moved up - right after image)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(
                              text: '${widget.post.authorName} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: widget.post.content,
                            ),
                          ],
                        ),
                        maxLines: _isExpanded ? null : 2,
                        overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (!_isExpanded && widget.post.content.length > 100)
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = true),
                    child: const Text(
                      'more',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),

          // Hashtags/Categories
          if (widget.post.categories.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: widget.post.categories.take(3).map((category) {
                  return InkWell(
                    onTap: () {},
                    child: Text(
                      '#$category',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Poll (if this is a poll post)
          if (widget.post.postType == PostType.poll) ...[
            const SizedBox(height: 8),
            PollWidget(postId: widget.post.postId),
          ],

          // Like count (total of likes + reactions)
          if (totalLikes > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                '${_formatLikes(totalLikes)} likes',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

          // Action buttons (moved below like count)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                GestureDetector(
                  key: _likeButtonKey,
                  onTap: _toggleLike,
                  onLongPress: _showReactionPicker,
                  child: Icon(
                    _currentReaction == ReactionTypeModel.ReactionType.love ||
                            _currentReaction == ReactionTypeModel.ReactionType.like
                        ? Icons.favorite
                        : _currentReaction == ReactionTypeModel.ReactionType.celebrate
                            ? Icons.celebration
                            : _currentReaction == ReactionTypeModel.ReactionType.insightful
                                ? Icons.lightbulb
                                : _currentReaction == ReactionTypeModel.ReactionType.helpful
                                    ? Icons.handshake
                                    : _currentReaction == ReactionTypeModel.ReactionType.thankYou
                                        ? Icons.volunteer_activism
                                        : Icons.favorite_border,
                    size: 26,
                    color: _isLiked || _currentReaction != null
                        ? _getReactionColor(_currentReaction)
                        : Colors.black,
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.mode_comment_outlined,
                  count: 0,
                  onTap: widget.onComment,
                  iconSize: 26,
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.send_outlined,
                  count: 0,
                  onTap: _handleShare,
                  iconSize: 26,
                ),
                const Spacer(),
                IconButton(
                  icon: _isSaved()
                      ? const Icon(Icons.bookmark, size: 26)
                      : const Icon(Icons.bookmark_border, size: 26),
                  onPressed: _toggleSave,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Inline comments section
          InlineCommentsSection(
            postId: widget.post.postId,
            initialCommentCount: _commentCount,
            onCountChanged: (c) {
              setState(() {
                _commentCount = c;
              });
            },
          ),

          const SizedBox(height: 6),

          // Posted time (footer)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              _formatTime(widget.post.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required VoidCallback? onTap,
    required double iconSize,
  }) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap();
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Text(
              _formatLikes(count),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasActiveContent() {
    // Check if user has active content (for story ring)
    return widget.post.createdAt
            .add(const Duration(days: 1))
            .isAfter(DateTime.now()) &&
        widget.post.likeCount + widget.post.commentCount > 5;
  }

  bool _isSaved() {
    return _isBookmarked;
  }

  bool _isCurrentUserAuthor() {
    try {
      final appState = context.read<AppState>();
      final user = appState.user;
      if (user == null) return false;
      return user.accountId == widget.post.authorId;
    } catch (_) {
      return false;
    }
  }

  String _formatLikes(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  UserType _getUserType() {
    switch (widget.post.authorType.toLowerCase()) {
      case 'admin':
        return UserType.admin;
      case 'developer':
        return UserType.developer;
      default:
        return UserType.owner;
    }
  }

  ReactionType _convertToServiceReactionType(ReactionTypeModel.ReactionType modelType) {
    switch (modelType) {
      case ReactionTypeModel.ReactionType.like:
        return ReactionType.like;
      case ReactionTypeModel.ReactionType.celebrate:
        return ReactionType.celebrate;
      case ReactionTypeModel.ReactionType.insightful:
        return ReactionType.insightful;
      case ReactionTypeModel.ReactionType.helpful:
        return ReactionType.helpful;
      case ReactionTypeModel.ReactionType.love:
        return ReactionType.love;
      case ReactionTypeModel.ReactionType.thankYou:
        return ReactionType.thankYou;
    }
  }

  Color _getReactionColor(ReactionTypeModel.ReactionType? reaction) {
    if (reaction == null) return Colors.red;
    switch (reaction) {
      case ReactionTypeModel.ReactionType.like:
        return Colors.red;
      case ReactionTypeModel.ReactionType.celebrate:
        return Colors.orange;
      case ReactionTypeModel.ReactionType.insightful:
        return Colors.amber;
      case ReactionTypeModel.ReactionType.helpful:
        return Colors.blue;
      case ReactionTypeModel.ReactionType.love:
        return Colors.pink;
      case ReactionTypeModel.ReactionType.thankYou:
        return Colors.purple;
    }
  }

  @override
  void dispose() {
    _hideReactionPicker();
    super.dispose();
  }
}
