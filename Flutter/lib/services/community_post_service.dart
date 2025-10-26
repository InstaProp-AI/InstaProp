import 'dart:convert';
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
    Poll? poll,
  }) async {
    return ApiClient.post<CommunityPost>(
      '/api/communities/$communityId/posts',
      {
        'content': content,
        'imageUrl': imageUrl,
        'postType': postType.toString().split('.').last,
        'categories': categories,
        'poll': poll != null
            ? {
                'question': poll.question,
                'options': poll.options.map((o) => o.text).toList(),
                'endsAt': poll.endsAt?.toIso8601String(),
              }
            : null,
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

  static Future<ApiResponse<bool>> toggleLike(int postId) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>(
        '/api/posts/$postId/like',
        {},
        (json) => json as Map<String, dynamic>,
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
        (json) => json as Map<String, dynamic>,
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
    int optionIndex,
  ) async {
    return ApiClient.post<void>('/api/polls/$pollId/vote', {
      'optionIndex': optionIndex,
    }, (json) => null);
  }
}
