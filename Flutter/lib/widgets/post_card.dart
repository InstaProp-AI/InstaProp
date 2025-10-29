import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/community_post.dart';
import '../theme/app_colors.dart';
import 'user_badge_widget.dart';
import 'like_animation.dart';
import '../services/reaction_service.dart';
import 'reaction_picker.dart';
import 'inline_comments_section.dart';

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
  int _likeCount = 0;
  ReactionType? _currentReaction;
  OverlayEntry? _overlayEntry;
  final GlobalKey _likeButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likeCount;
    _loadReaction();
  }

  Future<void> _loadReaction() async {
    // Load user's current reaction if any
    // This would require a backend endpoint to get user's reaction
    // For now, just use isLiked
    if (_isLiked) {
      _currentReaction = ReactionType.like;
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
            _likeCount = (_likeCount - 1).clamp(0, double.infinity).toInt();
          });
          widget.onLike?.call();
        }
      });
    } else {
      // Add like reaction
      ReactionService.addPostReaction(widget.post.postId, ReactionType.like)
          .then((response) {
        if (response.success && mounted) {
          setState(() {
            _isLiked = true;
            _currentReaction = ReactionType.like;
            _likeCount++;
          });
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

  Future<void> _selectReaction(ReactionType reaction) async {
    // If same reaction, remove it
    if (_currentReaction == reaction) {
      await ReactionService.removePostReaction(widget.post.postId);
      setState(() {
        _currentReaction = null;
        _isLiked = false;
        _likeCount = (_likeCount - 1).clamp(0, double.infinity).toInt();
      });
    } else {
      // Update or add reaction
      await ReactionService.addPostReaction(widget.post.postId, reaction);
      setState(() {
        if (_currentReaction == null) {
          _likeCount++;
        }
        _currentReaction = reaction;
        _isLiked = true;
      });
    }
    HapticFeedback.mediumImpact();
    widget.onLike?.call();
  }

  void _handleShare() {
    // TODO: Implement share to communities
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.background,
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
                // More options
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () {},
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

          // Action bar (Instagram-style)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                GestureDetector(
                  key: _likeButtonKey,
                  onTap: _toggleLike,
                  onLongPress: _showReactionPicker,
                  child: Icon(
                    _currentReaction == ReactionType.love ||
                            _currentReaction == ReactionType.like
                        ? Icons.favorite
                        : _currentReaction == ReactionType.celebrate
                            ? Icons.celebration
                            : _currentReaction == ReactionType.insightful
                                ? Icons.lightbulb
                                : _currentReaction == ReactionType.helpful
                                    ? Icons.handshake
                                    : _currentReaction == ReactionType.thankYou
                                        ? Icons.volunteer_activism
                                        : Icons.favorite_border,
                    size: 26,
                    color: _isLiked
                        ? _getReactionColor(_currentReaction)
                        : Colors.black,
                  ),
                ),
                if (_likeCount > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    _formatLikes(_likeCount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.mode_comment_outlined,
                  count: widget.post.commentCount,
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
                  onPressed: () {
                    HapticFeedback.lightImpact();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Likes count
          if (_likeCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${_formatLikes(_likeCount)} likes',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        widget.post.content,
                        style: const TextStyle(fontSize: 14),
                        maxLines: _isExpanded ? null : 2,
                        overflow: _isExpanded ? null : TextOverflow.ellipsis,
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

          // Categories
          if (widget.post.categories.isNotEmpty) ...[
            const SizedBox(height: 6),
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Inline comments section
          InlineCommentsSection(
            postId: widget.post.postId,
            initialCommentCount: widget.post.commentCount,
          ),

          const SizedBox(height: 6),

          // Posted time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatTime(widget.post.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Divider
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.border,
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
    // TODO: Implement save state from backend
    return false;
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

  Color _getReactionColor(ReactionType? reaction) {
    if (reaction == null) return Colors.red;
    switch (reaction) {
      case ReactionType.like:
        return Colors.red;
      case ReactionType.celebrate:
        return Colors.orange;
      case ReactionType.insightful:
        return Colors.amber;
      case ReactionType.helpful:
        return Colors.blue;
      case ReactionType.love:
        return Colors.pink;
      case ReactionType.thankYou:
        return Colors.purple;
    }
  }

  @override
  void dispose() {
    _hideReactionPicker();
    super.dispose();
  }
}
