import 'package:flutter/material.dart';
import '../models/post_comment.dart';
import '../services/community_post_service.dart';
import '../theme/app_colors.dart';
import 'comment_item.dart';

class InlineCommentsSection extends StatefulWidget {
  final int postId;
  final int initialCommentCount;
  final bool isCollapsed;
  final ValueChanged<int>? onCountChanged;

  const InlineCommentsSection({
    super.key,
    required this.postId,
    required this.initialCommentCount,
    this.isCollapsed = true,
    this.onCountChanged,
  });

  @override
  State<InlineCommentsSection> createState() => _InlineCommentsSectionState();
}

class _InlineCommentsSectionState extends State<InlineCommentsSection> {
  List<PostComment> _comments = [];
  bool _isLoading = false;
  bool _isExpanded = false;
  final TextEditingController _commentController = TextEditingController();
  int? _replyingToCommentId;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.isCollapsed;
    if (!widget.isCollapsed && widget.initialCommentCount > 0) {
      _loadComments();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final response = await CommunityPostService.getComments(widget.postId);
    if (response.success && response.data != null) {
      setState(() {
        _comments = response.data!;
        _isLoading = false;
      });
      // Notify parent with accurate count
      widget.onCountChanged?.call(_comments.length);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final response = await CommunityPostService.createComment(
      postId: widget.postId,
      content: content,
      parentCommentId: _replyingToCommentId,
    );

    if (response.success && response.data != null) {
      _commentController.clear();
      _replyingToCommentId = null;
      await _loadComments();
      // If comments aren't expanded, still bump the count
      if (!_isExpanded) {
        widget.onCountChanged?.call(widget.initialCommentCount + 1);
      }
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded && _comments.isEmpty) {
        _loadComments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // View all comments button
        if (widget.initialCommentCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: _toggleExpanded,
              child: Text(
                _isExpanded
                    ? 'Hide comments'
                    : 'View all ${widget.initialCommentCount} comments',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),

        // Comments list (when expanded)
        if (_isExpanded) ...[
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_comments.isEmpty && widget.initialCommentCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'No comments yet. Be the first to comment!',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            )
          else
            ..._comments.take(3).map((comment) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CommentItem(
                  comment: comment,
                  onLike: () async {
                    final response = await CommunityPostService
                        .toggleCommentLike(comment.commentId);
                    if (response.success && mounted) {
                      setState(() {
                        comment.isLiked = response.data ?? false;
                        comment.likeCount += comment.isLiked ? 1 : -1;
                      });
                    }
                  },
                  onReply: () {
                    setState(() {
                      _replyingToCommentId = comment.commentId;
                    });
                  },
                ),
              );
            }),
        ],

        // Add comment input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: _replyingToCommentId != null
                        ? 'Reply...'
                        : 'Add a comment...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 0,
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              TextButton(
                onPressed: _commentController.text.trim().isNotEmpty
                    ? _submitComment
                    : null,
                child: const Text(
                  'Post',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

