import '../models/community_post.dart';
import 'api_client.dart';
import '../models/community.dart';

class DiscoveryService {
  static Future<ApiResponse<List<CommunityPost>>> getTrendingPosts({
    int page = 1,
    int pageSize = 20,
  }) async {
    return await ApiClient.get<List<CommunityPost>>(
      '/api/discovery/trending/posts',
      queryParams: {'page': page.toString(), 'pageSize': pageSize.toString()},
      fromJson: (json) => CommunityPost.fromJson(json as Map<String, dynamic>),
    );
  }

  static Future<ApiResponse<List<Community>>> getTrendingCommunities() async {
    return await ApiClient.get<List<Community>>(
      '/api/discovery/trending/communities',
      fromJson: (json) => Community.fromJson(json as Map<String, dynamic>),
    );
  }

  static Future<ApiResponse<List<dynamic>>> getPopularMembers({
    int page = 1,
    int pageSize = 20,
  }) async {
    return await ApiClient.get<List<dynamic>>(
      '/api/discovery/popular/members',
      queryParams: {'page': page.toString(), 'pageSize': pageSize.toString()},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  static Future<ApiResponse<List<Community>>> getSuggestedCommunities() async {
    return await ApiClient.get<List<Community>>(
      '/api/discovery/suggested/communities',
      fromJson: (json) => Community.fromJson(json as Map<String, dynamic>),
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> searchContent({
    required String query,
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    return await ApiClient.get<Map<String, dynamic>>(
      '/api/discovery/search',
      queryParams: {
        'query': query,
        if (type != null) 'type': type,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}
