import 'api_client.dart';

class RewardService {
  static Future<ApiResponse<List<Map<String, dynamic>>>> getMyRewards() async {
    return await ApiClient.getList('/api/account/rewards', (json) => json);
  }

  static Future<ApiResponse<List<Map<String, dynamic>>>> getMyBadges() async {
    return await ApiClient.getList('/api/account/badges', (json) => json);
  }
}
