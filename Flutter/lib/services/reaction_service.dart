import 'api_client.dart';

enum ReactionType {
  like,
  celebrate,
  insightful,
  helpful,
  love,
  thankYou,
}

class ReactionService {
  static String _reactionTypeToString(ReactionType type) {
    switch (type) {
      case ReactionType.like:
        return 'Like';
      case ReactionType.celebrate:
        return 'Celebrate';
      case ReactionType.insightful:
        return 'Insightful';
      case ReactionType.helpful:
        return 'Helpful';
      case ReactionType.love:
        return 'Love';
      case ReactionType.thankYou:
        return 'ThankYou';
    }
  }

  static Future<ApiResponse<void>> addPostReaction(
    int postId,
    ReactionType reactionType,
  ) async {
    return ApiClient.post<void>(
      '/api/reaction/post/$postId',
      {
        'reactionType': _reactionTypeToString(reactionType),
      },
      (json) => null,
    );
  }

  static Future<ApiResponse<void>> removePostReaction(int postId) async {
    return ApiClient.delete('/api/reaction/post/$postId');
  }

  static Future<ApiResponse<List<Map<String, dynamic>>>> getReactionSummary(
    int postId,
  ) async {
    return ApiClient.getList<Map<String, dynamic>>(
      '/api/reaction/post/$postId/summary',
      (json) => Map<String, dynamic>.from(json),
    );
  }
}

