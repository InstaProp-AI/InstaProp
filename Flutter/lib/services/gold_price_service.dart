import '../models/gold_price.dart';
import 'api_client.dart';

class GoldPriceService {
  /// Get the latest gold price in EGP per gram
  static Future<GoldPrice?> getLatestGoldPrice() async {
    final response = await ApiClient.get(
      '/api/goldprice/latest',
      (json) => GoldPrice.fromJson(json),
    );

    if (response.success) {
      return response.data;
    } else {
      throw Exception('Failed to get latest gold price: ${response.error}');
    }
  }

  /// Get historical gold prices for comparison charts
  static Future<List<GoldPrice>> getGoldPriceHistory({
    DateTime? from,
    DateTime? to,
  }) async {
    final queryParams = <String, dynamic>{};
    if (from != null) {
      queryParams['startDate'] = from.toIso8601String();
    }
    if (to != null) {
      queryParams['endDate'] = to.toIso8601String();
    }

    final response = await ApiClient.getListWithQuery(
      '/api/goldprice/history',
      queryParams,
      (json) => GoldPrice.fromJson(json),
    );

    if (response.success) {
      return response.data ?? [];
    } else {
      throw Exception('Failed to get gold price history: ${response.error}');
    }
  }

  /// Get gold price statistics
  static Future<GoldPriceStats?> getGoldPriceStats() async {
    final response = await ApiClient.get(
      '/api/goldprice/stats',
      (json) => GoldPriceStats.fromJson(json),
    );

    if (response.success) {
      return response.data;
    } else {
      throw Exception('Failed to get gold price stats: ${response.error}');
    }
  }

  /// Compare gold price with property investment returns
  static Future<GoldPropertyComparison?> compareWithProperty({
    required int parentPropertyId,
    DateTime? from,
    DateTime? to,
  }) async {
    final queryParams = <String, dynamic>{'parentPropertyId': parentPropertyId};

    if (from != null) {
      queryParams['startDate'] = from.toIso8601String();
    }
    if (to != null) {
      queryParams['endDate'] = to.toIso8601String();
    }

    final response = await ApiClient.getWithQuery(
      '/api/goldprice/compare-property',
      queryParams,
      (json) => GoldPropertyComparison.fromJson(json),
    );

    if (response.success) {
      return response.data;
    } else {
      throw Exception(
        'Failed to compare gold with property: ${response.error}',
      );
    }
  }
}

// Supporting classes for gold price data
class GoldPriceStats {
  final double latestPrice;
  final double firstPrice;
  final double totalChange;
  final double totalChangeAmount;
  final double averagePrice;
  final double minPrice;
  final double maxPrice;
  final int dataPoints;
  final List<YearlyGoldStats> yearlyStats;

  GoldPriceStats({
    required this.latestPrice,
    required this.firstPrice,
    required this.totalChange,
    required this.totalChangeAmount,
    required this.averagePrice,
    required this.minPrice,
    required this.maxPrice,
    required this.dataPoints,
    required this.yearlyStats,
  });

  factory GoldPriceStats.fromJson(Map<String, dynamic> json) {
    return GoldPriceStats(
      latestPrice: (json['latestPrice'] ?? 0).toDouble(),
      firstPrice: (json['firstPrice'] ?? 0).toDouble(),
      totalChange: (json['totalChange'] ?? 0).toDouble(),
      totalChangeAmount: (json['totalChangeAmount'] ?? 0).toDouble(),
      averagePrice: (json['averagePrice'] ?? 0).toDouble(),
      minPrice: (json['minPrice'] ?? 0).toDouble(),
      maxPrice: (json['maxPrice'] ?? 0).toDouble(),
      dataPoints: json['dataPoints'] ?? 0,
      yearlyStats:
          (json['yearlyStats'] as List<dynamic>?)
              ?.map((item) => YearlyGoldStats.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class YearlyGoldStats {
  final int year;
  final double startPrice;
  final double endPrice;
  final double averagePrice;
  final double yearlyChange;

  YearlyGoldStats({
    required this.year,
    required this.startPrice,
    required this.endPrice,
    required this.averagePrice,
    required this.yearlyChange,
  });

  factory YearlyGoldStats.fromJson(Map<String, dynamic> json) {
    return YearlyGoldStats(
      year: json['year'] ?? 0,
      startPrice: (json['startPrice'] ?? 0).toDouble(),
      endPrice: (json['endPrice'] ?? 0).toDouble(),
      averagePrice: (json['averagePrice'] ?? 0).toDouble(),
      yearlyChange: (json['yearlyChange'] ?? 0).toDouble(),
    );
  }
}

class GoldPropertyComparison {
  final int parentPropertyId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double goldStartPrice;
  final double goldEndPrice;
  final double goldReturn;
  final double propertyStartPrice;
  final double propertyEndPrice;
  final double propertyReturn;
  final String betterInvestment;
  final double returnDifference;
  final List<MonthlyComparisonData> monthlyData;

  GoldPropertyComparison({
    required this.parentPropertyId,
    required this.periodStart,
    required this.periodEnd,
    required this.goldStartPrice,
    required this.goldEndPrice,
    required this.goldReturn,
    required this.propertyStartPrice,
    required this.propertyEndPrice,
    required this.propertyReturn,
    required this.betterInvestment,
    required this.returnDifference,
    required this.monthlyData,
  });

  factory GoldPropertyComparison.fromJson(Map<String, dynamic> json) {
    return GoldPropertyComparison(
      parentPropertyId: json['parentPropertyId'] ?? 0,
      periodStart: DateTime.parse(
        json['periodStart'] ?? DateTime.now().toIso8601String(),
      ),
      periodEnd: DateTime.parse(
        json['periodEnd'] ?? DateTime.now().toIso8601String(),
      ),
      goldStartPrice: (json['goldStartPrice'] ?? 0).toDouble(),
      goldEndPrice: (json['goldEndPrice'] ?? 0).toDouble(),
      goldReturn: (json['goldReturn'] ?? 0).toDouble(),
      propertyStartPrice: (json['propertyStartPrice'] ?? 0).toDouble(),
      propertyEndPrice: (json['propertyEndPrice'] ?? 0).toDouble(),
      propertyReturn: (json['propertyReturn'] ?? 0).toDouble(),
      betterInvestment: json['betterInvestment'] ?? '',
      returnDifference: (json['returnDifference'] ?? 0).toDouble(),
      monthlyData:
          (json['monthlyData'] as List<dynamic>?)
              ?.map((item) => MonthlyComparisonData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class MonthlyComparisonData {
  final int year;
  final int month;
  final double goldPrice;
  final double propertyPrice;
  final double goldReturn;
  final double propertyReturn;

  MonthlyComparisonData({
    required this.year,
    required this.month,
    required this.goldPrice,
    required this.propertyPrice,
    required this.goldReturn,
    required this.propertyReturn,
  });

  factory MonthlyComparisonData.fromJson(Map<String, dynamic> json) {
    return MonthlyComparisonData(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      goldPrice: (json['goldPrice'] ?? 0).toDouble(),
      propertyPrice: (json['propertyPrice'] ?? 0).toDouble(),
      goldReturn: (json['goldReturn'] ?? 0).toDouble(),
      propertyReturn: (json['propertyReturn'] ?? 0).toDouble(),
    );
  }
}
