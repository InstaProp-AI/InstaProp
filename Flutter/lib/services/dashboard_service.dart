import 'api_client.dart';

class DashboardService {
  static Future<ApiResponse<DashboardStats>> getPublicStats() async {
    return await ApiClient.get(
      '/api/dashboard/public-stats',
      DashboardStats.fromJson,
    );
  }
}

class DashboardStats {
  final int totalUsers;
  final int activeAuctions;
  final int totalBids;
  final int bidsLastWeek;
  final int bidsToday;
  final double totalVolume;
  final double averageBidsPerAuction;
  final int auctionsEndingToday;
  final int totalProperties;

  DashboardStats({
    required this.totalUsers,
    required this.activeAuctions,
    required this.totalBids,
    required this.bidsLastWeek,
    required this.bidsToday,
    required this.totalVolume,
    required this.averageBidsPerAuction,
    required this.auctionsEndingToday,
    required this.totalProperties,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['totalUsers'] ?? 0,
      activeAuctions: json['activeAuctions'] ?? 0,
      totalBids: json['totalBids'] ?? 0,
      bidsLastWeek: json['bidsLastWeek'] ?? 0,
      bidsToday: json['bidsToday'] ?? 0,
      totalVolume: (json['totalVolume'] ?? 0).toDouble(),
      averageBidsPerAuction: (json['averageBidsPerAuction'] ?? 0).toDouble(),
      auctionsEndingToday: json['auctionsEndingToday'] ?? 0,
      totalProperties: json['totalProperties'] ?? 0,
    );
  }
}



