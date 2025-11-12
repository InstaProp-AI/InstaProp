import '../models/community_post.dart';
import 'api_client.dart';
import '../models/community.dart';

class DiscoveryService {
  static Future<ApiResponse<List<CommunityPost>>> getTrendingPosts({
    int page = 1,
    int pageSize = 20,
  }) async {
    return await ApiClient.getListWithQuery<CommunityPost>(
      '/api/discovery/trending/posts',
      {'page': page.toString(), 'pageSize': pageSize.toString()},
      (json) => CommunityPost.fromJson(json as Map<String, dynamic>),
    );
  }

  static Future<ApiResponse<List<Community>>> getTrendingCommunities() async {
    return await ApiClient.getList<Community>(
      '/api/discovery/trending/communities',
      (json) => Community.fromJson(json as Map<String, dynamic>),
    );
  }

  static Future<ApiResponse<List<Map<String, dynamic>>>> getPopularMembers({
    int page = 1,
    int pageSize = 20,
  }) async {
    return await ApiClient.getListWithQuery<Map<String, dynamic>>(
      '/api/discovery/popular/members',
      {'page': page.toString(), 'pageSize': pageSize.toString()},
      (json) => json as Map<String, dynamic>,
    );
  }

  static Future<ApiResponse<List<Community>>> getSuggestedCommunities() async {
    return await ApiClient.getList<Community>(
      '/api/discovery/suggested/communities',
      (json) => Community.fromJson(json as Map<String, dynamic>),
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> searchContent({
    required String query,
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    return await ApiClient.getWithQuery<Map<String, dynamic>>(
      '/api/discovery/search',
      {
        'query': query,
        if (type != null) 'type': type,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      },
      (json) => json as Map<String, dynamic>,
    );
  }
}
