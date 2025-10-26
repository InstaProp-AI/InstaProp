import '../models/poll.dart';

enum PostType { regular, announcement, poll }

class CommunityPost {
  final int postId;
  final int communityId;
  final String communityName;
  final String? communityCoverPhotoUrl;
  final String communityAccessType;
  final bool isUserJoinedCommunity;
  final int authorId;
  final String authorName;
  final String authorType; // 'Owner', 'Developer', 'Admin'
  final String content;
  final String? imageUrl;
  final PostType postType;
  final bool isPinned;
  int likeCount;
  int commentCount;
  bool isLiked;
  final List<String> categories;
  final Poll? poll;
  final DateTime createdAt;
  double trendingScore;

  CommunityPost({
    required this.postId,
    required this.communityId,
    required this.communityName,
    this.communityCoverPhotoUrl,
    this.communityAccessType = 'Private',
    this.isUserJoinedCommunity = false,
    required this.authorId,
    required this.authorName,
    required this.authorType,
    required this.content,
    this.imageUrl,
    required this.postType,
    this.isPinned = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.categories = const [],
    this.poll,
    required this.createdAt,
    this.trendingScore = 0.0,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      postId: json['postId'] ?? 0,
      communityId: json['communityId'] ?? 0,
      communityName: json['communityName'] ?? '',
      communityCoverPhotoUrl: json['communityCoverPhotoUrl'],
      communityAccessType: json['communityAccessType'] ?? 'Private',
      isUserJoinedCommunity: json['isUserJoinedCommunity'] ?? false,
      authorId: json['authorId'] ?? 0,
      authorName: json['authorName'] ?? '',
      authorType: json['authorType'] ?? 'Owner',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
      postType: PostType.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            json['postType']?.toString().toLowerCase(),
        orElse: () => PostType.regular,
      ),
      isPinned: json['isPinned'] ?? false,
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((c) => c.toString())
              .toList() ??
          [],
      poll: json['poll'] != null ? Poll.fromJson(json['poll']) : null,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      trendingScore: (json['trendingScore'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'communityId': communityId,
      'communityName': communityName,
      'communityCoverPhotoUrl': communityCoverPhotoUrl,
      'communityAccessType': communityAccessType,
      'isUserJoinedCommunity': isUserJoinedCommunity,
      'authorId': authorId,
      'authorName': authorName,
      'authorType': authorType,
      'content': content,
      'imageUrl': imageUrl,
      'postType': postType.toString().split('.').last,
      'isPinned': isPinned,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isLiked': isLiked,
      'categories': categories,
      'poll': poll?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'trendingScore': trendingScore,
    };
  }
}
