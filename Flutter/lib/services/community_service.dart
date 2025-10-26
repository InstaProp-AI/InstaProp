import 'api_client.dart';
import '../models/community.dart';

class CommunityService {
  static Future<ApiResponse<List<Community>>> getCommunities() async {
    return ApiClient.getList<Community>('/api/community', Community.fromJson);
  }

  static Future<ApiResponse<List<Community>>> getMyCommunities() async {
    return ApiClient.getList<Community>(
      '/api/community/my',
      Community.fromJson,
    );
  }

  static Future<ApiResponse<List<Community>>>
  getRecommendedCommunities() async {
    return ApiClient.getList<Community>(
      '/api/community/recommended',
      Community.fromJson,
    );
  }

  static Future<ApiResponse<Community>> getCommunity(int communityId) async {
    return ApiClient.get<Community>(
      '/api/community/$communityId',
      Community.fromJson,
    );
  }

  static Future<ApiResponse<Community>> createCommunity({
    required String name,
    String? description,
    required CommunityScopeType scopeType,
    required CommunityAccessType accessType,
    List<int>? projectIds,
    List<int>? developerIds,
  }) async {
    return ApiClient.post<Community>('/api/community', {
      'name': name,
      'description': description,
      'scopeType': scopeType.toString().split('.').last,
      'accessType': accessType.toString().split('.').last,
      'projectIds': projectIds,
      'developerIds': developerIds,
    }, Community.fromJson);
  }

  static Future<ApiResponse<void>> joinCommunity(int communityId) async {
    return ApiClient.post<void>(
      '/api/community/$communityId/join',
      {},
      (json) => null,
    );
  }

  static Future<ApiResponse<void>> leaveCommunity(int communityId) async {
    return ApiClient.delete('/api/community/$communityId/leave');
  }

  static Future<ApiResponse<List<dynamic>>> getCommunityMembers(
    int communityId,
  ) async {
    try {
      final response = await ApiClient.getList(
        '/api/community/$communityId/members',
        (json) => json,
      );

      if (response.success && response.data != null) {
        return ApiResponse<List<dynamic>>(
          success: true,
          data: response.data as List<dynamic>,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<List<dynamic>>(
          success: false,
          error: response.error ?? 'Failed to load members',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<dynamic>>(
        success: false,
        error: e.toString(),
        statusCode: 500,
      );
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> getCommunityStats(
    int communityId,
  ) async {
    try {
      final response = await ApiClient.get(
        '/api/community/$communityId/stats',
        (json) => json,
      );

      if (response.success && response.data != null) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data as Map<String, dynamic>,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: response.error ?? 'Failed to load stats',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: e.toString(),
        statusCode: 500,
      );
    }
  }

  static Future<ApiResponse<List<Community>>> getTrendingCommunities() async {
    return ApiClient.getList<Community>(
      '/api/discovery/trending/communities',
      Community.fromJson,
    );
  }

  static Future<ApiResponse<List<Community>>> getSuggestedCommunities() async {
    return ApiClient.getList<Community>(
      '/api/discovery/suggested/communities',
      Community.fromJson,
    );
  }

  static Future<ApiResponse<List<dynamic>>> getPopularMembers() async {
    return ApiClient.getList<dynamic>(
      '/api/discovery/popular/members',
      (json) => json,
    );
  }
}
