import 'property_price_history.dart';

class ParentProperty {
  final int parentPropertyId;
  final String projectName;
  final int bedrooms;
  final int bathrooms;
  final int areaSqm;
  final String propertyType;
  final String finishingType;

  // Compound amenities
  final bool hasPool;
  final bool hasGym;
  final bool hasSecurity;
  final bool hasParking;
  final bool hasGarden;
  final bool hasPlayground;
  final bool hasClubhouse;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional: For displaying aggregated data
  final int? childCount;
  final double? averagePrice;
  final double? latestPrice;
  final double? priceChange;
  final List<PropertyPriceHistory>? priceHistories;

  ParentProperty({
    required this.parentPropertyId,
    required this.projectName,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqm,
    required this.propertyType,
    required this.finishingType,
    this.hasPool = false,
    this.hasGym = false,
    this.hasSecurity = false,
    this.hasParking = false,
    this.hasGarden = false,
    this.hasPlayground = false,
    this.hasClubhouse = false,
    required this.createdAt,
    required this.updatedAt,
    this.childCount,
    this.averagePrice,
    this.latestPrice,
    this.priceChange,
    this.priceHistories,
  });

  factory ParentProperty.fromJson(Map<String, dynamic> json) {
    return ParentProperty(
      parentPropertyId: json['parentPropertyId'] ?? 0,
      projectName: json['projectName'] ?? '',
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      areaSqm: json['areaSqm'] ?? 0,
      propertyType: json['propertyType'] ?? '',
      finishingType: json['finishingType'] ?? '',
      hasPool: json['hasPool'] ?? false,
      hasGym: json['hasGym'] ?? false,
      hasSecurity: json['hasSecurity'] ?? false,
      hasParking: json['hasParking'] ?? false,
      hasGarden: json['hasGarden'] ?? false,
      hasPlayground: json['hasPlayground'] ?? false,
      hasClubhouse: json['hasClubhouse'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      childCount: json['childCount'],
      averagePrice: json['averagePrice']?.toDouble(),
      latestPrice: json['latestPrice']?.toDouble(),
      priceChange: json['priceChange']?.toDouble(),
      priceHistories: (json['priceHistories'] as List<dynamic>?)
          ?.map((e) => PropertyPriceHistory.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parentPropertyId': parentPropertyId,
      'projectName': projectName,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'areaSqm': areaSqm,
      'propertyType': propertyType,
      'finishingType': finishingType,
      'hasPool': hasPool,
      'hasGym': hasGym,
      'hasSecurity': hasSecurity,
      'hasParking': hasParking,
      'hasGarden': hasGarden,
      'hasPlayground': hasPlayground,
      'hasClubhouse': hasClubhouse,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'childCount': childCount,
      'averagePrice': averagePrice,
      'latestPrice': latestPrice,
      'priceChange': priceChange,
      'priceHistories': priceHistories?.map((e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParentProperty &&
        other.parentPropertyId == parentPropertyId;
  }

  @override
  int get hashCode => parentPropertyId.hashCode;
}
