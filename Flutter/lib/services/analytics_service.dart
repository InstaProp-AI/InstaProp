import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AnalyticsService {
  static String get _baseUrl => ApiClient.baseUrl;

  // Market Overview
  static Future<MarketOverviewResponse?> getMarketOverview() async {
    try {
      final token = await ApiClient.getToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/api/analytics/market-overview'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return MarketOverviewResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to get market overview: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error getting market overview: $e');
      return null;
    }
  }

  // Price Trends
  static Future<List<PriceTrendResponse>?> getPriceTrends({
    String? parentPropertyId,
    String? propertyType,
    String? location,
    int months = 12,
  }) async {
    try {
      final token = await ApiClient.getToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final queryParams = <String, String>{};
      if (parentPropertyId != null)
        queryParams['parentPropertyId'] = parentPropertyId.toString();
      if (propertyType != null) queryParams['propertyType'] = propertyType;
      if (location != null) queryParams['location'] = location;
      queryParams['months'] = months.toString();

      final uri = Uri.parse(
        '$_baseUrl/api/analytics/price-trends',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => PriceTrendResponse.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get price trends: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting price trends: $e');
      return null;
    }
  }

  // Gold Comparison
  static Future<GoldComparisonResponse?> getGoldComparison({
    int months = 12,
  }) async {
    try {
      final token = await ApiClient.getToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/api/analytics/gold-comparison?months=$months'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return GoldComparisonResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to get gold comparison: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error getting gold comparison: $e');
      return null;
    }
  }

  // Developer Rankings
  static Future<List<DeveloperRankingResponse>?> getDeveloperRankings() async {
    try {
      final token = await ApiClient.getToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/api/analytics/developer-rankings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => DeveloperRankingResponse.fromJson(item))
            .toList();
      } else {
        throw Exception(
          'Failed to get developer rankings: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error getting developer rankings: $e');
      return null;
    }
  }

  // Best Investments
  static Future<List<BestInvestmentResponse>?> getBestInvestments({
    int limit = 10,
  }) async {
    try {
      final token = await ApiClient.getToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/api/analytics/best-investments?limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => BestInvestmentResponse.fromJson(item))
            .toList();
      } else {
        throw Exception(
          'Failed to get best investments: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error getting best investments: $e');
      return null;
    }
  }

  // Portfolio Analytics
  static Future<PortfolioAnalyticsResponse?> getPortfolioAnalytics(
    String userId,
  ) async {
    try {
      final response = await ApiClient.get(
        '/api/analytics/portfolio/$userId',
        PortfolioAnalyticsResponse.fromJson,
      );

      if (response.success && response.data != null) {
        return response.data;
      } else if (response.statusCode == 404) {
        return null; // No portfolio data available
      } else {
        throw Exception(
          'Failed to get portfolio analytics: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error getting portfolio analytics: $e');
      return null;
    }
  }
}

// Response Models
class MarketOverviewResponse {
  final int totalProperties;
  final int activeAuctions;
  final int totalDevelopers;
  final List<AreaPriceData> areaPrices;
  final List<PropertyTypeDistribution> propertyTypeDistribution;
  final List<PriceTrendData> recentPriceTrends;
  final bool hasData;
  final String? message;
  final DateTime? generatedAt;

  MarketOverviewResponse({
    required this.totalProperties,
    required this.activeAuctions,
    required this.totalDevelopers,
    required this.areaPrices,
    required this.propertyTypeDistribution,
    required this.recentPriceTrends,
    required this.hasData,
    this.message,
    this.generatedAt,
  });

  factory MarketOverviewResponse.fromJson(Map<String, dynamic> json) {
    return MarketOverviewResponse(
      totalProperties: json['totalProperties'] ?? 0,
      activeAuctions: json['activeAuctions'] ?? 0,
      totalDevelopers: json['totalDevelopers'] ?? 0,
      areaPrices:
          (json['areaPrices'] as List<dynamic>?)
              ?.map((e) => AreaPriceData.fromJson(e))
              .toList() ??
          [],
      propertyTypeDistribution:
          (json['propertyTypeDistribution'] as List<dynamic>?)
              ?.map((e) => PropertyTypeDistribution.fromJson(e))
              .toList() ??
          [],
      recentPriceTrends:
          (json['recentPriceTrends'] as List<dynamic>?)
              ?.map((e) => PriceTrendData.fromJson(e))
              .toList() ??
          [],
      hasData: json['hasData'] ?? true,
      message: json['message'],
      generatedAt: json['generatedAtUtc'] != null
          ? DateTime.tryParse(json['generatedAtUtc'])
          : null,
    );
  }
}

class AreaPriceData {
  final String area;
  final double averagePrice;
  final int propertyCount;

  AreaPriceData({
    required this.area,
    required this.averagePrice,
    required this.propertyCount,
  });

  factory AreaPriceData.fromJson(Map<String, dynamic> json) {
    return AreaPriceData(
      area: json['area'] ?? '',
      averagePrice: (json['averagePrice'] ?? 0).toDouble(),
      propertyCount: json['propertyCount'] ?? 0,
    );
  }
}

class PropertyTypeDistribution {
  final String propertyType;
  final int count;
  final double percentage;

  PropertyTypeDistribution({
    required this.propertyType,
    required this.count,
    required this.percentage,
  });

  factory PropertyTypeDistribution.fromJson(Map<String, dynamic> json) {
    return PropertyTypeDistribution(
      propertyType: json['propertyType'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class PriceTrendData {
  final int month;
  final double averagePrice;
  final int transactionCount;

  PriceTrendData({
    required this.month,
    required this.averagePrice,
    required this.transactionCount,
  });

  factory PriceTrendData.fromJson(Map<String, dynamic> json) {
    return PriceTrendData(
      month: json['month'] ?? 0,
      averagePrice: (json['averagePrice'] ?? 0).toDouble(),
      transactionCount: json['transactionCount'] ?? 0,
    );
  }
}

class PriceTrendResponse {
  final DateTime date;
  final double price;
  final String source;
  final String parentPropertyId;
  final String projectName;
  final String propertyType;

  PriceTrendResponse({
    required this.date,
    required this.price,
    required this.source,
    required this.parentPropertyId,
    required this.projectName,
    required this.propertyType,
  });

  factory PriceTrendResponse.fromJson(Map<String, dynamic> json) {
    // Handle both String GUID and int legacy formats
    String parseParentPropertyId(dynamic id) {
      if (id == null) return '';
      if (id is String) return id;
      if (id is int) return id.toString();
      return id.toString();
    }

    return PriceTrendResponse(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      price: (json['price'] ?? 0).toDouble(),
      source: json['source'] ?? '',
      parentPropertyId: parseParentPropertyId(json['parentPropertyId']),
      projectName: json['projectName'] ?? '',
      propertyType: json['propertyType'] ?? '',
    );
  }
}

class GoldComparisonResponse {
  final int periodMonths;
  final double propertyReturnPercentage;
  final double goldReturnPercentage;
  final String betterInvestment;
  final double returnDifference;
  final int propertyDataPoints;
  final int goldDataPoints;
  final String? message;
  final DateTime? generatedAt;

  GoldComparisonResponse({
    required this.periodMonths,
    required this.propertyReturnPercentage,
    required this.goldReturnPercentage,
    required this.betterInvestment,
    required this.returnDifference,
    required this.propertyDataPoints,
    required this.goldDataPoints,
    this.message,
    this.generatedAt,
  });

  factory GoldComparisonResponse.fromJson(Map<String, dynamic> json) {
    return GoldComparisonResponse(
      periodMonths: json['periodMonths'] ?? 0,
      propertyReturnPercentage: (json['propertyReturnPercentage'] ?? 0)
          .toDouble(),
      goldReturnPercentage: (json['goldReturnPercentage'] ?? 0).toDouble(),
      betterInvestment: json['betterInvestment'] ?? '',
      returnDifference: (json['returnDifference'] ?? 0).toDouble(),
      propertyDataPoints: json['propertyDataPoints'] ?? 0,
      goldDataPoints: json['goldDataPoints'] ?? 0,
      message: json['message'],
      generatedAt: json['generatedAtUtc'] != null
          ? DateTime.tryParse(json['generatedAtUtc'])
          : null,
    );
  }
}

class DeveloperRankingResponse {
  final String developerId;
  final String developerName;
  final int projectCount;
  final int totalProperties;
  final double averagePropertyPrice;
  final double averageRating;

  DeveloperRankingResponse({
    required this.developerId,
    required this.developerName,
    required this.projectCount,
    required this.totalProperties,
    required this.averagePropertyPrice,
    required this.averageRating,
  });

  factory DeveloperRankingResponse.fromJson(Map<String, dynamic> json) {
    // Parse developerId - handle both String GUID and int legacy formats
    String parseDeveloperId(dynamic id) {
      if (id == null) return '';
      if (id is String) return id;
      if (id is int) return id.toString();
      return id.toString();
    }

    return DeveloperRankingResponse(
      developerId: parseDeveloperId(json['developerId']),
      developerName: json['developerName'] ?? '',
      projectCount: json['projectCount'] ?? 0,
      totalProperties: json['totalProperties'] ?? 0,
      averagePropertyPrice: (json['averagePropertyPrice'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
    );
  }
}

class BestInvestmentResponse {
  final String propertyId;
  final String propertyName;
  final String location;
  final String propertyType;
  final double currentPrice;
  final double pricePerSqm;
  final String projectName;
  final int bedrooms;
  final int bathrooms;
  final int squareFeet;
  final int priceHistoryCount;
  final double averagePriceHistory;
  final List<double> priceTrend;

  BestInvestmentResponse({
    required this.propertyId,
    required this.propertyName,
    required this.location,
    required this.propertyType,
    required this.currentPrice,
    required this.pricePerSqm,
    required this.projectName,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareFeet,
    required this.priceHistoryCount,
    required this.averagePriceHistory,
    required this.priceTrend,
  });

  factory BestInvestmentResponse.fromJson(Map<String, dynamic> json) {
    // Handle both String GUID and int legacy formats
    String parsePropertyId(dynamic id) {
      if (id == null) return '';
      if (id is String) return id;
      if (id is int) return id.toString();
      return id.toString();
    }

    // Parse priceTrend list - handle both List<dynamic> and List<num>
    List<double> parsePriceTrend(dynamic trend) {
      if (trend == null) return [];
      if (trend is List) {
        return trend.map((e) {
          if (e is double) return e;
          if (e is int) return e.toDouble();
          if (e is String) return double.tryParse(e) ?? 0.0;
          return 0.0;
        }).toList();
      }
      return [];
    }

    return BestInvestmentResponse(
      propertyId: parsePropertyId(json['propertyId']),
      propertyName: json['propertyName'] ?? '',
      location: json['location'] ?? '',
      propertyType: json['propertyType'] ?? '',
      currentPrice: (json['currentPrice'] ?? 0).toDouble(),
      pricePerSqm: (json['pricePerSqm'] ?? 0).toDouble(),
      projectName: json['projectName'] ?? '',
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      squareFeet: json['squareFeet'] ?? 0,
      priceHistoryCount: json['priceHistoryCount'] ?? 0,
      averagePriceHistory: (json['averagePriceHistory'] ?? 0).toDouble(),
      priceTrend: parsePriceTrend(json['priceTrend']),
    );
  }
}

class PortfolioAnalyticsResponse {
  final int userId;
  final int totalProperties;
  final double totalInvested;
  final double totalCurrentValue;
  final double totalProfitLoss;
  final double totalROIPercentage;
  final double averageROIPercentage;
  final String bestPerformingProperty;
  final List<PropertyPerformanceData> propertyBreakdown;

  PortfolioAnalyticsResponse({
    required this.userId,
    required this.totalProperties,
    required this.totalInvested,
    required this.totalCurrentValue,
    required this.totalProfitLoss,
    required this.totalROIPercentage,
    required this.averageROIPercentage,
    required this.bestPerformingProperty,
    required this.propertyBreakdown,
  });

  factory PortfolioAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return PortfolioAnalyticsResponse(
      userId: json['userId'] ?? 0,
      totalProperties: json['totalProperties'] ?? 0,
      totalInvested: (json['totalInvested'] ?? 0).toDouble(),
      totalCurrentValue: (json['totalCurrentValue'] ?? 0).toDouble(),
      totalProfitLoss: (json['totalProfitLoss'] ?? 0).toDouble(),
      totalROIPercentage: (json['totalROIPercentage'] ?? 0).toDouble(),
      averageROIPercentage: (json['averageROIPercentage'] ?? 0).toDouble(),
      bestPerformingProperty: json['bestPerformingProperty'] ?? '',
      propertyBreakdown:
          (json['propertyBreakdown'] as List<dynamic>?)
              ?.map((e) => PropertyPerformanceData.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PropertyPerformanceData {
  final int propertyId;
  final String propertyName;
  final String location;
  final String propertyType;
  final double investedAmount;
  final double currentValue;
  final double roi;

  PropertyPerformanceData({
    required this.propertyId,
    required this.propertyName,
    required this.location,
    required this.propertyType,
    required this.investedAmount,
    required this.currentValue,
    required this.roi,
  });

  factory PropertyPerformanceData.fromJson(Map<String, dynamic> json) {
    return PropertyPerformanceData(
      propertyId: json['propertyId'] ?? 0,
      propertyName: json['propertyName'] ?? '',
      location: json['location'] ?? '',
      propertyType: json['propertyType'] ?? '',
      investedAmount: (json['investedAmount'] ?? 0).toDouble(),
      currentValue: (json['currentValue'] ?? 0).toDouble(),
      roi: (json['roi'] ?? 0).toDouble(),
    );
  }
}
