import 'package:flutter/material.dart';
import '../models/community_post.dart';
import '../models/post_comment.dart';
import '../services/community_post_service.dart';
import '../theme/app_colors.dart';
import '../widgets/post_card.dart';
import '../widgets/comment_item.dart';
import '../widgets/poll_widget.dart';

class PostDetailsPage extends StatefulWidget {
  final int postId;

  const PostDetailsPage({super.key, required this.postId});

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  CommunityPost? _post;
  List<PostComment> _comments = [];
  bool _isLoading = false;
  bool _isLoadingComments = false;
  final TextEditingController _commentController = TextEditingController();
  int? _replyingToCommentId;

  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    setState(() => _isLoading = true);
    final response = await CommunityPostService.getPost(widget.postId);
    if (response.success && response.data != null) {
      setState(() => _post = response.data);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    final response = await CommunityPostService.getComments(widget.postId);
    if (response.success && response.data != null) {
      setState(() => _comments = response.data!);
    }
    setState(() => _isLoadingComments = false);
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;

    final response = await CommunityPostService.toggleLike(_post!.postId);
    if (response.success) {
      setState(() {
        final wasLiked = _post!.isLiked;
        _post!.isLiked = !wasLiked;
        _post!.likeCount += _post!.isLiked ? 1 : -1;
      });
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final response = await CommunityPostService.createComment(
      postId: widget.postId,
      content: _commentController.text.trim(),
      parentCommentId: _replyingToCommentId,
    );

    if (response.success) {
      _commentController.clear();
      _replyingToCommentId = null;
      _loadComments();
      if (_post != null) {
        setState(() => _post!.commentCount++);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? 'Failed to post comment')),
        );
      }
    }
  }

  Future<void> _toggleCommentLike(int commentId, int index) async {
    final response = await CommunityPostService.toggleCommentLike(commentId);
    if (response.success) {
      setState(() {
        // Find and update comment
        _updateCommentLike(_comments, commentId);
      });
    }
  }

  void _updateCommentLike(List<PostComment> comments, int commentId) {
    for (var comment in comments) {
      if (comment.commentId == commentId) {
        final wasLiked = comment.isLiked;
        comment.isLiked = !wasLiked;
        comment.likeCount += comment.isLiked ? 1 : -1;
        return;
      }
      if (comment.replies.isNotEmpty) {
        _updateCommentLike(comment.replies, commentId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          // Post content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  PostCard(
                    post: _post!,
                    showCommunity: true,
                    onTap: null,
                    onLike: _toggleLike,
                    onComment: null,
                  ),
                  // Poll
                  if (_post!.poll != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: PollWidget(postId: _post!.postId),
                    ),
                  // Comments section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${_comments.length})',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Comments list
                  _isLoadingComments
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _comments.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                size: 48,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No comments yet',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return CommentItem(
                              comment: comment,
                              onLike: () =>
                                  _toggleCommentLike(comment.commentId, index),
                              onReply: () {
                                setState(() {
                                  _replyingToCommentId = comment.commentId;
                                });
                                _commentController.text =
                                    '@${comment.authorName} ';
                                FocusScope.of(
                                  context,
                                ).requestFocus(FocusNode());
                              },
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          // Comment input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowCard,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyingToCommentId != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _commentController.text.trim(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() => _replyingToCommentId = null);
                            _commentController.clear();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _submitComment,
                      icon: const Icon(Icons.send),
                      tooltip: 'Post comment',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
