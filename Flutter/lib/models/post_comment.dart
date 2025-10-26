class PostComment {
  final int commentId;
  final int postId;
  final int authorId;
  final String authorName;
  final String authorType; // 'Owner', 'Developer', 'Admin'
  final String content;
  final int? parentCommentId;
  int likeCount;
  bool isLiked;
  final List<PostComment> replies;
  final DateTime createdAt;

  PostComment({
    required this.commentId,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorType,
    required this.content,
    this.parentCommentId,
    this.likeCount = 0,
    this.isLiked = false,
    this.replies = const [],
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      commentId: json['commentId'] ?? 0,
      postId: json['postId'] ?? 0,
      authorId: json['authorId'] ?? 0,
      authorName: json['authorName'] ?? '',
      authorType: json['authorType'] ?? 'Owner',
      content: json['content'] ?? '',
      parentCommentId: json['parentCommentId'],
      likeCount: json['likeCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      replies:
          (json['replies'] as List<dynamic>?)
              ?.map((r) => PostComment.fromJson(r))
              .toList() ??
          [],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorType': authorType,
      'content': content,
      'parentCommentId': parentCommentId,
      'likeCount': likeCount,
      'isLiked': isLiked,
      'replies': replies.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
