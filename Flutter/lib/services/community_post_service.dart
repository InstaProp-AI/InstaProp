import 'api_client.dart';
import '../models/community_post.dart';
import '../models/post_comment.dart';
import '../models/poll.dart';

class CommunityPostService {
  static Future<ApiResponse<List<CommunityPost>>> getCommunityPosts(
    int communityId, {
    String sort = 'new',
    int page = 1,
    int pageSize = 20,
  }) async {
    return ApiClient.getList<CommunityPost>(
      '/api/communities/$communityId/posts?sort=$sort&page=$page&pageSize=$pageSize',
      CommunityPost.fromJson,
    );
  }

  static Future<ApiResponse<List<CommunityPost>>> getFeed({
    String sort = 'new',
    int page = 1,
    int pageSize = 20,
  }) async {
    return ApiClient.getList<CommunityPost>(
      '/api/posts/feed?sort=$sort&page=$page&pageSize=$pageSize',
      CommunityPost.fromJson,
    );
  }

  static Future<ApiResponse<CommunityPost>> getPost(int postId) async {
    return ApiClient.get<CommunityPost>(
      '/api/posts/$postId',
      CommunityPost.fromJson,
    );
  }

  static Future<ApiResponse<CommunityPost>> createPost({
    required int communityId,
    required String content,
    String? imageUrl,
    PostType postType = PostType.regular,
    List<String>? categories,
    Map<String, dynamic>? poll,
  }) async {
    return ApiClient.post<CommunityPost>(
      '/api/communities/$communityId/posts',
      {
        'content': content,
        'imageUrl': imageUrl,
        'postType': postType.toString().split('.').last,
        'categories': categories,
        'poll': poll,
      },
      CommunityPost.fromJson,
    );
  }

  static Future<ApiResponse<void>> updatePost({
    required int postId,
    required String content,
    String? imageUrl,
  }) async {
    return ApiClient.put<void>('/api/posts/$postId', {
      'content': content,
      'imageUrl': imageUrl,
    }, (json) => null);
  }

  static Future<ApiResponse<void>> deletePost(int postId) async {
    return ApiClient.delete('/api/posts/$postId');
  }

  static Future<ApiResponse<bool>> toggleBookmark(int postId) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>(
        '/api/posts/$postId/bookmark',
        {},
        (json) => json,
      );
      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!['isBookmarked'] as bool);
      }
      return ApiResponse.error(response.error ?? 'Failed to toggle bookmark');
    } catch (e) {
      return ApiResponse.error('Failed to toggle bookmark: $e');
    }
  }

  static Future<ApiResponse<bool>> getBookmarkStatus(int postId) async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>(
        '/api/posts/$postId/bookmark/status',
        (json) => json,
      );
      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!['isBookmarked'] as bool);
      }
      return ApiResponse.error(response.error ?? 'Failed to get bookmark status');
    } catch (e) {
      return ApiResponse.error('Failed to get bookmark status: $e');
    }
  }

  static Future<ApiResponse<List<CommunityPost>>> getBookmarkedPosts({
    int page = 1,
    int pageSize = 20,
  }) async {
    return ApiClient.getList<CommunityPost>(
      '/api/posts/bookmarked?page=$page&pageSize=$pageSize',
      CommunityPost.fromJson,
    );
  }

  static Future<ApiResponse<int>> sharePost({
    required int postId,
    required int targetCommunityId,
    String? message,
  }) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>(
        '/api/posts/$postId/share',
        {
          'targetCommunityId': targetCommunityId,
          'message': message,
        },
        (json) => json,
      );
      if (response.success && response.data != null) {
        return ApiResponse.success((response.data!['postId'] as num).toInt());
      }
      return ApiResponse.error(response.error ?? 'Failed to share post');
    } catch (e) {
      return ApiResponse.error('Failed to share post: $e');
    }
  }

  static Future<ApiResponse<void>> reportPost({
    required int postId,
    required String reason,
    String? details,
  }) async {
    return ApiClient.post<void>('/api/posts/$postId/report', {
      'reason': reason,
      'details': details,
    }, (json) => null);
  }

  static Future<ApiResponse<bool>> toggleLike(int postId) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>(
        '/api/posts/$postId/like',
        {},
        (json) => json,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!['isLiked'] as bool);
      }
      return ApiResponse.error(response.error ?? 'Failed to like post');
    } catch (e) {
      return ApiResponse.error('Failed to like post: $e');
    }
  }

  static Future<ApiResponse<List<PostComment>>> getComments(int postId) async {
    return ApiClient.getList<PostComment>(
      '/api/posts/$postId/comments',
      PostComment.fromJson,
    );
  }

  static Future<ApiResponse<PostComment>> createComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    return ApiClient.post<PostComment>('/api/posts/$postId/comments', {
      'content': content,
      'parentCommentId': parentCommentId,
    }, PostComment.fromJson);
  }

  static Future<ApiResponse<bool>> toggleCommentLike(int commentId) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>(
        '/api/comments/$commentId/like',
        {},
        (json) => json,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!['isLiked'] as bool);
      }
      return ApiResponse.error(response.error ?? 'Failed to like comment');
    } catch (e) {
      return ApiResponse.error('Failed to like comment: $e');
    }
  }

  static Future<ApiResponse<void>> voteOnPoll(
    int pollId,
    dynamic optionSelection,
  ) async {
    final body = optionSelection is List<int>
        ? {
            'optionIndexes': optionSelection,
          }
        : {
            'optionIndex': optionSelection as int,
          };
    return ApiClient.post<void>('/api/polls/$pollId/vote', body, (json) => null);
  }

  static Future<ApiResponse<Poll>> getPollByPost(int postId) async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>(
        '/api/polls/$postId',
        (json) => json,
      );
      if (!response.success || response.data == null) {
        return ApiResponse.error(response.error ?? 'Failed to load poll');
      }

      final data = response.data!;
      final List<dynamic> opts = data['options'] as List<dynamic>? ?? [];
      final total = (data['totalVotes'] as num?)?.toInt() ?? 0;
      final options = opts.map((o) {
        final text = (o['text'] ?? o['optionText'] ?? '').toString();
        final votes = (o['voteCount'] ?? 0) as int;
        final pct = total > 0 ? (votes / total) * 100.0 : 0.0;
        return PollOption(text: text, voteCount: votes, percentage: pct);
      }).toList();

      final poll = Poll(
        pollId: (data['pollId'] as num?)?.toInt() ?? 0,
        question: (data['question'] ?? '').toString(),
        options: options,
        totalVotes: total,
        endsAt: data['endsAt'] != null ? DateTime.parse(data['endsAt']) : null,
        userVoteOptionIndexes: (data['userSelections'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
        isMultipleChoice: data['isMultipleChoice'] ?? false,
        allowChangeVote: data['allowChangeVote'] ?? true,
        showResultsBeforeVote: data['showResultsBeforeVote'] ?? true,
        imageUrl: data['imageUrl'],
      );

      return ApiResponse.success(poll);
    } catch (e) {
      return ApiResponse.error('Failed to load poll: $e');
    }
  }

  static Future<ApiResponse<Map<String, int>>> getPostCounts(int postId) async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>(
        '/api/posts/$postId/counts',
        (json) => json,
      );
      if (response.success && response.data != null) {
        final d = response.data!;
        return ApiResponse.success({
          'likeCount': (d['likeCount'] as num).toInt(),
          'reactionCount': (d['reactionCount'] as num).toInt(),
          'commentCount': (d['commentCount'] as num).toInt(),
        });
      }
      return ApiResponse.error(response.error ?? 'Failed to load counts');
    } catch (e) {
      return ApiResponse.error('Failed to load counts: $e');
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> getUserReaction(int postId) async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>(
        '/api/posts/$postId/user-reaction',
        (json) => json,
      );
      if (response.success && response.data != null) {
        return ApiResponse.success(response.data!);
      }
      return ApiResponse.error(response.error ?? 'Failed to load user reaction');
    } catch (e) {
      return ApiResponse.error('Failed to load user reaction: $e');
    }
  }
}
