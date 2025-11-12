import 'package:app1/models/leaderboard_models.dart';

import 'api_client.dart';

class LeaderboardService {
  static const _endpoint = '/api/leaderboard';

  static Future<LeaderboardResponse?> fetchLeaderboard(
    LeaderboardPeriod period,
  ) async {
    final response = await ApiClient.getWithQuery(
      _endpoint,
      {'period': period.apiValue},
      LeaderboardResponse.fromJson,
    );

    if (!response.success) {
      throw Exception(response.error ?? 'Failed to load leaderboard');
    }

    return response.data;
  }

  static Future<LeaderboardHighlightsResponse?> fetchHighlights() async {
    final response = await ApiClient.get(
      '$_endpoint/highlights',
      LeaderboardHighlightsResponse.fromJson,
    );

    if (!response.success) {
      throw Exception(response.error ?? 'Failed to load highlights');
    }

    return response.data;
  }
}


