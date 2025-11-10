import '../models/price_history.dart';
import 'api_client.dart';

class PriceHistoryService {
  /// Get price history for a parent property
  static Future<PropertyPriceHistoryResponse> getParentPropertyPriceHistory(
    int parentPropertyId,
  ) async {
    final response = await ApiClient.get(
      '/api/pricehistory/parent/$parentPropertyId',
      (json) => PropertyPriceHistoryResponse.fromJson(json),
    );

    if (response.success) {
      return response.data!;
    } else {
      throw Exception(
        'Failed to get parent property price history: ${response.error}',
      );
    }
  }

  /// Get price trends
  static Future<PriceTrendsResponse> getPriceTrends({
    String? propertyType,
    String? governorate,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (propertyType != null) queryParams['propertyType'] = propertyType;
    if (governorate != null) queryParams['governorate'] = governorate;
    if (startDate != null)
      queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

    final response = await ApiClient.getWithQuery(
      '/api/pricehistory/trends',
      queryParams,
      (json) => PriceTrendsResponse.fromJson(json),
    );

    if (response.success) {
      return response.data!;
    } else {
      throw Exception('Failed to get price trends: ${response.error}');
    }
  }

  /// Get price statistics for a parent property
  static Future<PropertyPriceStats> getParentPropertyPriceStats(
    int parentPropertyId,
  ) async {
    final response = await ApiClient.get(
      '/api/pricehistory/parent/$parentPropertyId/stats',
      (json) => PropertyPriceStats.fromJson(json),
    );

    if (response.success) {
      return response.data!;
    } else {
      throw Exception(
        'Failed to get parent property price stats: ${response.error}',
      );
    }
  }

  /// Add price history for a parent property
  static Future<PropertyPriceHistory> addPriceHistory(
    int parentPropertyId,
    AddPriceHistoryRequest request,
  ) async {
    final response = await ApiClient.post(
      '/api/pricehistory/parent/$parentPropertyId',
      request.toJson(),
      (json) => PropertyPriceHistory.fromJson(json),
    );

    if (response.success) {
      return response.data!;
    } else {
      throw Exception('Failed to add price history: ${response.error}');
    }
  }
}

class PropertyPriceHistoryResponse {
  final int parentPropertyId;
  final List<PropertyPriceHistory> priceHistory;
  final PriceStatistics statistics;

  PropertyPriceHistoryResponse({
    required this.parentPropertyId,
    required this.priceHistory,
    required this.statistics,
  });

  factory PropertyPriceHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PropertyPriceHistoryResponse(
      parentPropertyId: json['parentPropertyId'] ?? 0,
      priceHistory:
          (json['priceHistory'] as List<dynamic>?)
              ?.map((item) => PropertyPriceHistory.fromJson(item))
              .toList() ??
          [],
      statistics: PriceStatistics.fromJson(json['statistics'] ?? {}),
    );
  }
}

class PriceStatistics {
  final double averagePrice;
  final double minPrice;
  final double maxPrice;
  final double priceChange;
  final double priceChangePercent;
  final int dataPoints;

  PriceStatistics({
    required this.averagePrice,
    required this.minPrice,
    required this.maxPrice,
    required this.priceChange,
    required this.priceChangePercent,
    required this.dataPoints,
  });

  factory PriceStatistics.fromJson(Map<String, dynamic> json) {
    return PriceStatistics(
      averagePrice: (json['averagePrice'] ?? 0).toDouble(),
      minPrice: (json['minPrice'] ?? 0).toDouble(),
      maxPrice: (json['maxPrice'] ?? 0).toDouble(),
      priceChange: (json['priceChange'] ?? 0).toDouble(),
      priceChangePercent: (json['priceChangePercent'] ?? 0).toDouble(),
      dataPoints: json['dataPoints'] ?? 0,
    );
  }
}

class PriceTrendsResponse {
  final List<PriceTrend> trends;
  final List<PropertyTypeTrend> byPropertyType;
  final List<LocationTrend> byLocation;
  final MarketIndicators marketIndicators;

  PriceTrendsResponse({
    required this.trends,
    required this.byPropertyType,
    required this.byLocation,
    required this.marketIndicators,
  });

  factory PriceTrendsResponse.fromJson(Map<String, dynamic> json) {
    return PriceTrendsResponse(
      trends:
          (json['trends'] as List<dynamic>?)
              ?.map((item) => PriceTrend.fromJson(item))
              .toList() ??
          [],
      byPropertyType:
          (json['byPropertyType'] as List<dynamic>?)
              ?.map((item) => PropertyTypeTrend.fromJson(item))
              .toList() ??
          [],
      byLocation:
          (json['byLocation'] as List<dynamic>?)
              ?.map((item) => LocationTrend.fromJson(item))
              .toList() ??
          [],
      marketIndicators: MarketIndicators.fromJson(
        json['marketIndicators'] ?? {},
      ),
    );
  }
}

class PriceTrend {
  final int year;
  final int month;
  final double averagePrice;
  final double minPrice;
  final double maxPrice;
  final int dataPoints;

  PriceTrend({
    required this.year,
    required this.month,
    required this.averagePrice,
    required this.minPrice,
    required this.maxPrice,
    required this.dataPoints,
  });

  factory PriceTrend.fromJson(Map<String, dynamic> json) {
    return PriceTrend(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      averagePrice: (json['averagePrice'] ?? 0).toDouble(),
      minPrice: (json['minPrice'] ?? 0).toDouble(),
      maxPrice: (json['maxPrice'] ?? 0).toDouble(),
      dataPoints: json['dataPoints'] ?? 0,
    );
  }
}

class PropertyTypeTrend {
  final String propertyType;
  final double averagePrice;
  final int dataPoints;
  final double latestPrice;

  PropertyTypeTrend({
    required this.propertyType,
    required this.averagePrice,
    required this.dataPoints,
    required this.latestPrice,
  });

  factory PropertyTypeTrend.fromJson(Map<String, dynamic> json) {
    return PropertyTypeTrend(
      propertyType: json['propertyType'] ?? '',
      averagePrice: (json['averagePrice'] ?? 0).toDouble(),
      dataPoints: json['dataPoints'] ?? 0,
      latestPrice: (json['latestPrice'] ?? 0).toDouble(),
    );
  }
}

class LocationTrend {
  final String location;
  final double averagePrice;
  final int dataPoints;
  final double latestPrice;

  LocationTrend({
    required this.location,
    required this.averagePrice,
    required this.dataPoints,
    required this.latestPrice,
  });

  factory LocationTrend.fromJson(Map<String, dynamic> json) {
    return LocationTrend(
      location: json['location'] ?? '',
      averagePrice: (json['averagePrice'] ?? 0).toDouble(),
      dataPoints: json['dataPoints'] ?? 0,
      latestPrice: (json['latestPrice'] ?? 0).toDouble(),
    );
  }
}

class MarketIndicators {
  final int totalDataPoints;
  final double averagePrice;
  final double priceVolatility;
  final String trendDirection;

  MarketIndicators({
    required this.totalDataPoints,
    required this.averagePrice,
    required this.priceVolatility,
    required this.trendDirection,
  });

  factory MarketIndicators.fromJson(Map<String, dynamic> json) {
    return MarketIndicators(
      totalDataPoints: json['totalDataPoints'] ?? 0,
      averagePrice: (json['averagePrice'] ?? 0).toDouble(),
      priceVolatility: (json['priceVolatility'] ?? 0).toDouble(),
      trendDirection: json['trendDirection'] ?? 'stable',
    );
  }
}

class PropertyPriceStats {
  final int parentPropertyId;
  final String? message;
  final PriceStatistics statistics;
  final List<PriceRangeDistribution> priceDistribution;
  final TimeRange timeRange;

  PropertyPriceStats({
    required this.parentPropertyId,
    this.message,
    required this.statistics,
    required this.priceDistribution,
    required this.timeRange,
  });

  factory PropertyPriceStats.fromJson(Map<String, dynamic> json) {
    return PropertyPriceStats(
      parentPropertyId: json['parentPropertyId'] ?? 0,
      message: json['message'],
      statistics: PriceStatistics.fromJson(json['statistics'] ?? {}),
      priceDistribution:
          (json['priceDistribution'] as List<dynamic>?)
              ?.map((item) => PriceRangeDistribution.fromJson(item))
              .toList() ??
          [],
      timeRange: TimeRange.fromJson(json['timeRange'] ?? {}),
    );
  }
}

class PriceRangeDistribution {
  final String range;
  final int count;

  PriceRangeDistribution({required this.range, required this.count});

  factory PriceRangeDistribution.fromJson(Map<String, dynamic> json) {
    return PriceRangeDistribution(
      range: json['range'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class TimeRange {
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;

  TimeRange({
    required this.startDate,
    required this.endDate,
    required this.durationDays,
  });

  factory TimeRange.fromJson(Map<String, dynamic> json) {
    return TimeRange(
      startDate: DateTime.parse(
        json['startDate'] ?? DateTime.now().toIso8601String(),
      ),
      endDate: DateTime.parse(
        json['endDate'] ?? DateTime.now().toIso8601String(),
      ),
      durationDays: json['durationDays'] ?? 0,
    );
  }
}

class AddPriceHistoryRequest {
  final double price;
  final DateTime date;
  final String source;
  final String? notes;

  AddPriceHistoryRequest({
    required this.price,
    required this.date,
    required this.source,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'date': date.toIso8601String(),
      'source': source,
      'notes': notes,
    };
  }
}
