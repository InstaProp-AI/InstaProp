import 'api_client.dart';

class RewardService {
  static Future<ApiResponse<List<Map<String, dynamic>>>> getMyRewards() async {
    return await ApiClient.getList('/api/account/rewards', (json) => json);
  }

  static Future<ApiResponse<List<Map<String, dynamic>>>> getMyBadges() async {
    return await ApiClient.getList('/api/account/badges', (json) => json);
  }

  static Future<ApiResponse<Map<String, dynamic>>> redeemReward({
    required String rewardType,
    required int points,
  }) async {
    return await ApiClient.post('/api/redemption/redeem', {
      'rewardType': rewardType,
      'points': points,
    }, (json) => json);
  }

  static Future<ApiResponse<List<Map<String, dynamic>>>>
  getRedemptionHistory() async {
    return await ApiClient.getList('/api/redemption/history', (json) => json);
  }
}
