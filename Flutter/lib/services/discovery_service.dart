import 'api_client.dart';

class DiscoveryService {
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
