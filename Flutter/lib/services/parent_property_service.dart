import '../models/parent_property.dart';
import 'api_client.dart';

class ParentPropertyService {
  /// Get parent properties with filters
  static Future<ParentPropertyListResponse> getParentProperties({
    String? propertyType,
    int? bedrooms,
    int? bathrooms,
    double? minArea,
    double? maxArea,
    String? governorate,
    String? city,
    bool? hasPool,
    bool? hasGym,
    bool? hasSecurity,
    bool? hasParking,
    String? finishingType,
    String? sortBy,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};

    if (propertyType != null) queryParams['propertyType'] = propertyType;
    if (bedrooms != null) queryParams['bedrooms'] = bedrooms;
    if (bathrooms != null) queryParams['bathrooms'] = bathrooms;
    if (minArea != null) queryParams['minArea'] = minArea;
    if (maxArea != null) queryParams['maxArea'] = maxArea;
    if (governorate != null) queryParams['governorate'] = governorate;
    if (city != null) queryParams['city'] = city;
    if (hasPool != null) queryParams['hasPool'] = hasPool;
    if (hasGym != null) queryParams['hasGym'] = hasGym;
    if (hasSecurity != null) queryParams['hasSecurity'] = hasSecurity;
    if (hasParking != null) queryParams['hasParking'] = hasParking;
    if (finishingType != null) queryParams['finishingType'] = finishingType;
    if (sortBy != null) queryParams['sortBy'] = sortBy;

    final response = await ApiClient.getWithQuery(
      '/api/parentproperty',
      queryParams,
      fromJson: (json) => ParentPropertyListResponse.fromJson(json),
    );

    if (response.success) {
      return response.data!;
    } else {
      throw Exception('Failed to get parent properties: ${response.error}');
    }
  }

  /// Get a specific parent property by ID
  static Future<ParentProperty?> getParentProperty(int id) async {
    final response = await ApiClient.get(
      '/api/parentproperty/$id',
      (json) => ParentProperty.fromJson(json),
    );

    if (response.success) {
      return response.data;
    } else {
      throw Exception('Failed to get parent property: ${response.error}');
    }
  }

  /// Find or create a parent property
  static Future<FindOrCreateResponse> findOrCreateParentProperty(
    FindOrCreateRequest request,
  ) async {
    final response = await ApiClient.post(
      '/api/parentproperty/find-or-create',
      request.toJson(),
      (json) => FindOrCreateResponse.fromJson(json),
    );

    if (response.success) {
      return response.data!;
    } else {
      throw Exception(
        'Failed to find or create parent property: ${response.error}',
      );
    }
  }

  /// Get parent property statistics
  static Future<ParentPropertyStats> getParentPropertyStats() async {
    final response = await ApiClient.get(
      '/api/parentproperty/stats',
      (json) => ParentPropertyStats.fromJson(json),
    );

    if (response.success) {
      return response.data!;
    } else {
      throw Exception('Failed to get parent property stats: ${response.error}');
    }
  }
}

class ParentPropertyListResponse {
  final List<ParentProperty> parentProperties;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  ParentPropertyListResponse({
    required this.parentProperties,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory ParentPropertyListResponse.fromJson(Map<String, dynamic> json) {
    return ParentPropertyListResponse(
      parentProperties:
          (json['parentProperties'] as List<dynamic>?)
              ?.map((item) => ParentProperty.fromJson(item))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}

class FindOrCreateRequest {
  final String projectName;
  final String propertyType;
  final int bedrooms;
  final int bathrooms;
  final double areaSqm;
  final String finishingType;
  final bool hasPool;
  final bool hasGym;
  final bool hasSecurity;
  final bool hasParking;
  final bool hasGarden;
  final bool hasPlayground;
  final bool hasClubhouse;

  FindOrCreateRequest({
    required this.projectName,
    required this.propertyType,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqm,
    required this.finishingType,
    required this.hasPool,
    required this.hasGym,
    required this.hasSecurity,
    required this.hasParking,
    required this.hasGarden,
    required this.hasPlayground,
    required this.hasClubhouse,
  });

  Map<String, dynamic> toJson() {
    return {
      'projectName': projectName,
      'propertyType': propertyType,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'areaSqm': areaSqm,
      'finishingType': finishingType,
      'hasPool': hasPool,
      'hasGym': hasGym,
      'hasSecurity': hasSecurity,
      'hasParking': hasParking,
      'hasGarden': hasGarden,
      'hasPlayground': hasPlayground,
      'hasClubhouse': hasClubhouse,
    };
  }
}

class FindOrCreateResponse {
  final int parentPropertyId;
  final bool isNew;
  final String message;

  FindOrCreateResponse({
    required this.parentPropertyId,
    required this.isNew,
    required this.message,
  });

  factory FindOrCreateResponse.fromJson(Map<String, dynamic> json) {
    return FindOrCreateResponse(
      parentPropertyId: json['parentPropertyId'] ?? 0,
      isNew: json['isNew'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class ParentPropertyStats {
  final int totalCount;
  final List<PropertyTypeCount> byType;
  final List<BedroomCount> byBedrooms;
  final List<FinishingTypeCount> byFinishing;
  final double averageArea;
  final AmenityStats amenities;

  ParentPropertyStats({
    required this.totalCount,
    required this.byType,
    required this.byBedrooms,
    required this.byFinishing,
    required this.averageArea,
    required this.amenities,
  });

  factory ParentPropertyStats.fromJson(Map<String, dynamic> json) {
    return ParentPropertyStats(
      totalCount: json['totalCount'] ?? 0,
      byType:
          (json['byType'] as List<dynamic>?)
              ?.map((item) => PropertyTypeCount.fromJson(item))
              .toList() ??
          [],
      byBedrooms:
          (json['byBedrooms'] as List<dynamic>?)
              ?.map((item) => BedroomCount.fromJson(item))
              .toList() ??
          [],
      byFinishing:
          (json['byFinishing'] as List<dynamic>?)
              ?.map((item) => FinishingTypeCount.fromJson(item))
              .toList() ??
          [],
      averageArea: (json['averageArea'] ?? 0).toDouble(),
      amenities: AmenityStats.fromJson(json['amenities'] ?? {}),
    );
  }
}

class PropertyTypeCount {
  final String type;
  final int count;

  PropertyTypeCount({required this.type, required this.count});

  factory PropertyTypeCount.fromJson(Map<String, dynamic> json) {
    return PropertyTypeCount(
      type: json['type'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class BedroomCount {
  final int bedrooms;
  final int count;

  BedroomCount({required this.bedrooms, required this.count});

  factory BedroomCount.fromJson(Map<String, dynamic> json) {
    return BedroomCount(
      bedrooms: json['bedrooms'] ?? 0,
      count: json['count'] ?? 0,
    );
  }
}

class FinishingTypeCount {
  final String finishingType;
  final int count;

  FinishingTypeCount({required this.finishingType, required this.count});

  factory FinishingTypeCount.fromJson(Map<String, dynamic> json) {
    return FinishingTypeCount(
      finishingType: json['finishingType'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class AmenityStats {
  final int hasPool;
  final int hasGym;
  final int hasSecurity;
  final int hasParking;
  final int hasGarden;
  final int hasPlayground;
  final int hasClubhouse;

  AmenityStats({
    required this.hasPool,
    required this.hasGym,
    required this.hasSecurity,
    required this.hasParking,
    required this.hasGarden,
    required this.hasPlayground,
    required this.hasClubhouse,
  });

  factory AmenityStats.fromJson(Map<String, dynamic> json) {
    return AmenityStats(
      hasPool: json['hasPool'] ?? 0,
      hasGym: json['hasGym'] ?? 0,
      hasSecurity: json['hasSecurity'] ?? 0,
      hasParking: json['hasParking'] ?? 0,
      hasGarden: json['hasGarden'] ?? 0,
      hasPlayground: json['hasPlayground'] ?? 0,
      hasClubhouse: json['hasClubhouse'] ?? 0,
    );
  }
}
