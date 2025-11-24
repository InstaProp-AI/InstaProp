import 'property_price_history.dart';
import 'property_type.dart';

class ParentProperty {
  final String parentPropertyId;
  final String? projectName;
  final int bedrooms;
  final int bathrooms;
  final int areaSqm;
  final PropertyType type;
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
    this.projectName,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqm,
    required this.type,
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
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return ParentProperty(
      parentPropertyId: parseId(json['parentPropertyId']),
      projectName: json['projectName'] ??
          (json['project'] is Map ? json['project']['name'] : json['project']) ??
          null,
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      areaSqm: json['areaSqm'] ?? 0,
      type: PropertyTypeX.fromString(
        (json['type'] ?? json['propertyType'])?.toString(),
      ),
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
      'type': type.displayName,
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

  String get displayProjectName => projectName ?? 'N/A';
  String get typeLabel => type.displayName;
}
