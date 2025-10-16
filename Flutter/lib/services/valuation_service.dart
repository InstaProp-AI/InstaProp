import 'api_client.dart';

class ValuationService {
  // Calculate AI-powered valuation
  static Future<ApiResponse<EnhancedValuationResult>> calculateAIValuation(
    ValuationRequest request,
  ) async {
    return await ApiClient.post(
      '/api/valuation/calculate-ai',
      request.toJson(),
      EnhancedValuationResult.fromJson,
    );
  }

  // Calculate basic valuation (legacy)
  static Future<ApiResponse<ValuationResult>> calculateValuation(
    ValuationRequest request,
  ) async {
    return await ApiClient.post(
      '/api/valuation/calculate',
      request.toJson(),
      ValuationResult.fromJson,
    );
  }
}

// Request Model
class ValuationRequest {
  final int? propertyId;
  final String? location;
  final int bedrooms;
  final int bathrooms;
  final int squareFeet;
  final int yearBuilt;
  final String? propertyType;

  ValuationRequest({
    this.propertyId,
    this.location,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareFeet,
    required this.yearBuilt,
    this.propertyType,
  });

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'location': location,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFeet': squareFeet,
      'yearBuilt': yearBuilt,
      'propertyType': propertyType,
    };
  }
}

// Basic Valuation Result (legacy)
class ValuationResult {
  final double estimatedValue;
  final double basePrice;
  final double locationMultiplier;
  final double yearFactor;
  final double confidence;
  final DateTime calculatedAt;

  ValuationResult({
    required this.estimatedValue,
    required this.basePrice,
    required this.locationMultiplier,
    required this.yearFactor,
    required this.confidence,
    required this.calculatedAt,
  });

  factory ValuationResult.fromJson(Map<String, dynamic> json) {
    return ValuationResult(
      estimatedValue: (json['estimatedValue'] ?? json['EstimatedValue'] ?? 0)
          .toDouble(),
      basePrice: (json['basePrice'] ?? json['BasePrice'] ?? 0).toDouble(),
      locationMultiplier:
          (json['locationMultiplier'] ?? json['LocationMultiplier'] ?? 1)
              .toDouble(),
      yearFactor: (json['yearFactor'] ?? json['YearFactor'] ?? 1).toDouble(),
      confidence: (json['confidence'] ?? json['Confidence'] ?? 0).toDouble(),
      calculatedAt: DateTime.parse(
        json['calculatedAt'] ??
            json['CalculatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }
}

// Enhanced AI Valuation Result
class EnhancedValuationResult {
  final double estimatedValue;
  final double priceRangeLow;
  final double priceRangeHigh;
  final double confidence;
  final String? aiReasoning;
  final String? marketTrends;
  final List<ComparableProperty> topComparables;
  final DateTime calculatedAt;
  final int comparablesCount;
  final int auctionsCount;

  EnhancedValuationResult({
    required this.estimatedValue,
    required this.priceRangeLow,
    required this.priceRangeHigh,
    required this.confidence,
    this.aiReasoning,
    this.marketTrends,
    required this.topComparables,
    required this.calculatedAt,
    required this.comparablesCount,
    required this.auctionsCount,
  });

  factory EnhancedValuationResult.fromJson(Map<String, dynamic> json) {
    List<ComparableProperty> comparables = [];

    final comparablesData = json['topComparables'] ?? json['TopComparables'];
    if (comparablesData != null && comparablesData is List) {
      comparables = comparablesData
          .map((e) => ComparableProperty.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return EnhancedValuationResult(
      estimatedValue: (json['estimatedValue'] ?? json['EstimatedValue'] ?? 0)
          .toDouble(),
      priceRangeLow: (json['priceRangeLow'] ?? json['PriceRangeLow'] ?? 0)
          .toDouble(),
      priceRangeHigh: (json['priceRangeHigh'] ?? json['PriceRangeHigh'] ?? 0)
          .toDouble(),
      confidence: (json['confidence'] ?? json['Confidence'] ?? 0).toDouble(),
      aiReasoning: json['aiReasoning'] ?? json['AiReasoning'],
      marketTrends: json['marketTrends'] ?? json['MarketTrends'],
      topComparables: comparables,
      calculatedAt: DateTime.parse(
        json['calculatedAt'] ??
            json['CalculatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
      comparablesCount:
          json['comparablesCount'] ?? json['ComparablesCount'] ?? 0,
      auctionsCount: json['auctionsCount'] ?? json['AuctionsCount'] ?? 0,
    );
  }
}

// Comparable Property Model
class ComparableProperty {
  final String name;
  final String location;
  final int bedrooms;
  final int bathrooms;
  final int squareFeet;
  final double price;
  final String status;

  ComparableProperty({
    required this.name,
    required this.location,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareFeet,
    required this.price,
    required this.status,
  });

  factory ComparableProperty.fromJson(Map<String, dynamic> json) {
    return ComparableProperty(
      name: json['name'] ?? json['Name'] ?? '',
      location: json['location'] ?? json['Location'] ?? '',
      bedrooms: json['bedrooms'] ?? json['Bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? json['Bathrooms'] ?? 0,
      squareFeet: json['squareFeet'] ?? json['SquareFeet'] ?? 0,
      price: (json['price'] ?? json['Price'] ?? 0).toDouble(),
      status: json['status'] ?? json['Status'] ?? '',
    );
  }
}

