import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'api_client.dart';
import 'parent_property_service.dart';
import 'price_history_service.dart';
import '../models/property.dart';
import '../models/child_property.dart';
import '../models/parent_property.dart';
import '../models/property_image.dart';
import '../models/property_type.dart';
import '../models/installment_summary.dart';

class PropertyService {
  static Future<ApiResponse<List<Property>>> getProperties() async {
    // Use the new parent/child property system
    return await getPropertiesAsChildProperties();
  }

  static Future<ApiResponse<Property>> getProperty(int propertyId) async {
    // Use the new parent/child property system
    return await getPropertyAsChildProperty(propertyId);
  }

  static Future<ApiResponse<InstallmentSummary>> getPropertyInstallmentSummary(
    int propertyId,
  ) async {
    return await ApiClient.get(
      '/api/property/$propertyId/installment-summary',
      InstallmentSummary.fromJson,
    );
  }

  // GET: api/Property/{id}/financials
  static Future<ApiResponse<Map<String, dynamic>>> getPropertyFinancials(
    int propertyId, {
    double? marketValue,
  }) async {
    final queryParams = marketValue != null
        ? '?marketValue=$marketValue'
        : '';
    return await ApiClient.get(
      '/api/property/$propertyId/financials$queryParams',
      (json) => json as Map<String, dynamic>,
    );
  }

  static Future<ApiResponse<InstallmentSummary>>
      upsertPropertyInstallmentSummary(
    int propertyId,
    InstallmentSummaryPayload payload,
  ) async {
    return await ApiClient.put(
      '/api/property/$propertyId/installment-summary',
      payload.toJson(),
      InstallmentSummary.fromJson,
    );
  }

  static Future<ApiResponse<Property>> createProperty({
    required String name,
    required String description,
    required String location,
    required int bedrooms,
    required int bathrooms,
    required int squareFeet,
    required int yearBuilt,
    required PropertyType type,
    String? imageUrl,
    // Additional parameters for parent/child system
    String? projectName,
    int? projectId,
    String? finishingType,
    bool hasPool = false,
    bool hasGym = false,
    bool hasSecurity = false,
    bool hasParking = false,
    bool hasGarden = false,
    bool hasPlayground = false,
    bool hasClubhouse = false,
    // Unit-specific details
    String? phase,
    int? floorNumber,
    String? unitNumber,
    String? viewType,
    String? orientation,
    DateTime? deliveryDate,
    int? parkingSlots,
    bool? hasStorageRoom,
    double? buyingPrice,
    DateTime? buyingDate,
    int quantity = 1,
    bool? hasNannyRoom,
    bool? hasDriverRoom,
    bool? hasMaidRoom,
    bool? hasPrivatePool,
    bool? hasRoofAccess,
    bool? hasBalcony,
    bool? hasGardenUnit,
    bool? hasClubhouseUnit,
    bool? hasInfrastructure,
    bool? hasUndergroundParking,
    bool? hasMedicalCenter,
    bool? hasCommercialStrip,
    bool? hasBusinessHub,
    bool? hasOutdoorPools,
    bool? hasBicycleLanes,
    bool? hasJoggingTrail,
    bool? smartHome,
    bool? centralAC,
    bool? naturalGas,
    bool? hasGenerator,
    bool? seaView,
    bool? nileView,
    bool? pyramidView,
    bool? gardenView,
    bool? streetView,
    InstallmentSummaryPayload? installmentSummary,
  }) async {
    try {
      // Our add-property form uses area in sqm; keep the same value here
      final projectNameToUse =
          projectName ?? _extractProjectNameFromLocation(location);
      final finishingTypeToUse = finishingType ?? 'Finished';
      final int areaSqm = squareFeet;

      // Use the strongly-typed ParentPropertyService to find or create parent
      final parentRequest = FindOrCreateRequest(
        projectName: projectNameToUse,
        type: type,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        areaSqm: areaSqm.toDouble(),
        finishingType: finishingTypeToUse,
        hasPool: hasPool,
        hasGym: hasGym,
        hasSecurity: hasSecurity,
        hasParking: hasParking,
        hasGarden: hasGarden,
        hasPlayground: hasPlayground,
        hasClubhouse: hasClubhouse,
      );

      final parentResult =
          await ParentPropertyService.findOrCreateParentProperty(
        parentRequest,
      );

      final parentPropertyId = parentResult.parentPropertyId;

      final childResponse = await createChildProperty(
        parentPropertyId: parentPropertyId,
        name: name,
        description: description,
        location: location,
        imageUrl: imageUrl ?? '',
        squareFeet: squareFeet,
        yearBuilt: yearBuilt,
        isApproved: false,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        type: type,
        status: 'NotApproved',
        projectId: projectId,
        phase: phase,
        floorNumber: floorNumber,
        unitNumber: unitNumber,
        viewType: viewType,
        orientation: orientation,
        deliveryDate: deliveryDate,
        parkingSlots: parkingSlots,
        hasStorageRoom: hasStorageRoom,
        buyingPrice: buyingPrice,
        buyingDate: buyingDate,
        quantity: quantity,
        hasNannyRoom: hasNannyRoom,
        hasDriverRoom: hasDriverRoom,
        hasMaidRoom: hasMaidRoom,
        hasPrivatePool: hasPrivatePool,
        hasRoofAccess: hasRoofAccess,
        hasBalcony: hasBalcony,
        hasGarden: hasGardenUnit,
        hasClubhouse: hasClubhouseUnit,
        hasInfrastructure: hasInfrastructure,
        hasUndergroundParking: hasUndergroundParking,
        hasMedicalCenter: hasMedicalCenter,
        hasCommercialStrip: hasCommercialStrip,
        hasBusinessHub: hasBusinessHub,
        hasOutdoorPools: hasOutdoorPools,
        hasBicycleLanes: hasBicycleLanes,
        hasJoggingTrail: hasJoggingTrail,
        smartHome: smartHome,
        centralAC: centralAC,
        naturalGas: naturalGas,
        hasGenerator: hasGenerator,
        seaView: seaView,
        nileView: nileView,
        pyramidView: pyramidView,
        gardenView: gardenView,
        streetView: streetView,
      );

      if (!childResponse.success || childResponse.data == null) {
        return ApiResponse<Property>(
          success: false,
          data: null,
          error: 'Failed to create child property: ${childResponse.error}',
          statusCode: childResponse.statusCode,
        );
      }

      final property = Property.fromChildProperty(childResponse.data!);

      await _attemptSyncInstallmentSummary(
        property.propertyId,
        installmentSummary,
      );

      if (installmentSummary != null && installmentSummary.hasRequiredData) {
        final refreshed = await getProperty(property.propertyId);
        if (refreshed.success && refreshed.data != null) {
          return refreshed;
        }
      }

      return ApiResponse<Property>(
        success: true,
        data: property,
        statusCode: 200,
      );
    } catch (e) {
      return ApiResponse<Property>(
        success: false,
        data: null,
        error: 'Error creating property: $e',
        statusCode: 500,
      );
    }
  }

  // Helper method to extract project name from location
  static String _extractProjectNameFromLocation(String location) {
    // Simple extraction - take the first part before comma or use full location
    final parts = location.split(',');
    return parts.isNotEmpty ? parts.first.trim() : location;
  }

  static Future<ApiResponse<Property>> updateProperty({
    required int propertyId,
    required String name,
    required String description,
    required String location,
    InstallmentSummaryPayload? installmentSummary,
  }) async {
    // Use the new parent/child property system
    final childPropertyResponse = await updateChildProperty(
      childPropertyId: propertyId,
      name: name,
      description: description,
      location: location,
    );

    if (childPropertyResponse.success && childPropertyResponse.data != null) {
      final property = Property.fromChildProperty(childPropertyResponse.data!);
      await _attemptSyncInstallmentSummary(propertyId, installmentSummary);
      if (installmentSummary != null && installmentSummary.hasRequiredData) {
        final refreshed = await getProperty(propertyId);
        if (refreshed.success && refreshed.data != null) {
          return refreshed;
        }
      }
      return ApiResponse<Property>(
        success: true,
        data: property,
        statusCode: childPropertyResponse.statusCode,
      );
    } else {
      return ApiResponse<Property>(
        success: false,
        error: childPropertyResponse.error,
        statusCode: childPropertyResponse.statusCode,
      );
    }
  }

  static Future<ApiResponse<void>> deleteProperty(int propertyId) async {
    // Use the new parent/child property system
    return await deleteChildProperty(propertyId);
  }

  static Future<ApiResponse<List<Property>>> getAllProperties() async {
    // Use the new parent/child property system
    return await getPropertiesAsChildProperties();
  }

  static Future<ApiResponse<List<Property>>> getUserProperties() async {
    return await ApiClient.getList('/api/user/properties', Property.fromJson);
  }

  static Future<ApiResponse<Property>> createPropertySkipDocuments({
    required String name,
    required String description,
    required String location,
    required int bedrooms,
    required int bathrooms,
    required int squareFeet,
    required int yearBuilt,
    required PropertyType type,
    String? imageUrl,
    InstallmentSummaryPayload? installmentSummary,
  }) async {
    final response = await ApiClient.post('/api/property/skip-documents', {
      'name': name,
      'description': description,
      'location': location,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFeet': squareFeet,
      'yearBuilt': yearBuilt,
      'type': type.displayName,
      'imageUrl': imageUrl ?? '',
    }, Property.fromJson);

    if (response.success && response.data != null) {
      await _attemptSyncInstallmentSummary(
        response.data!.propertyId,
        installmentSummary,
      );
      if (installmentSummary != null && installmentSummary.hasRequiredData) {
        return await getProperty(response.data!.propertyId);
      }
    }

    return response;
  }

  // Get all child properties (public endpoint - only properties with auctions)
  static Future<ApiResponse<List<ChildProperty>>> getChildProperties() async {
    return await ApiClient.getList('/api/Property', ChildProperty.fromJson);
  }

  // Get user's child properties
  static Future<ApiResponse<List<ChildProperty>>> getMyChildProperties() async {
    return await ApiClient.getList(
      '/api/Property/my-properties',
      ChildProperty.fromJson,
    );
  }

  // Get user's properties (backward compatibility)
  static Future<ApiResponse<List<Property>>> getMyProperties() async {
    final childPropertiesResponse = await getMyChildProperties();
    if (childPropertiesResponse.success &&
        childPropertiesResponse.data != null) {
      final properties = childPropertiesResponse.data!
          .map((childProperty) => Property.fromChildProperty(childProperty))
          .toList();
      return ApiResponse<List<Property>>(
        success: true,
        data: properties,
        statusCode: 200,
      );
    }
    return ApiResponse<List<Property>>(
      success: false,
      data: [],
      statusCode: childPropertiesResponse.statusCode,
    );
  }

  // Upload property images (File - for mobile only)
  static Future<ApiResponse<dynamic>> uploadPropertyImages(
    int propertyId,
    List<File> images, {
    String imageType = 'Gallery',
  }) async {
    return await ApiClient.postMultipart(
      '/api/property/$propertyId/images',
      images,
      fields: {'imageType': imageType},
      fileFieldName: 'images',
      fromJson: (json) => json, // Return raw response
    );
  }

  // Upload property images (PlatformFile - works on both web and mobile)
  static Future<ApiResponse<dynamic>> uploadPropertyImagesPlatform(
    int propertyId,
    List<PlatformFile> images, {
    String imageType = 'Gallery',
  }) async {
    return await ApiClient.postMultipartPlatformFiles(
      '/api/property/$propertyId/images',
      images,
      fields: {'imageType': imageType},
      fileFieldName: 'images',
      fromJson: (json) => json, // Return raw response
    );
  }

  // Get property images
  static Future<ApiResponse<List<PropertyImage>>> getPropertyImages(
    int propertyId,
  ) async {
    return await ApiClient.getList(
      '/api/property/$propertyId/images',
      PropertyImage.fromJson,
    );
  }

  // Delete property image
  static Future<ApiResponse<void>> deletePropertyImage(
    int propertyId,
    int imageId,
  ) async {
    return await ApiClient.delete('/api/property/$propertyId/images/$imageId');
  }

  // Set main image
  static Future<ApiResponse<void>> setMainImage(
    int propertyId,
    int imageId,
  ) async {
    return await ApiClient.put(
      '/api/property/$propertyId/images/$imageId/set-main',
      {},
      (json) => null,
    );
  }

  // ===== NEW PARENT/CHILD PROPERTY SYSTEM METHODS =====

  // Get all parent properties (projects)
  static Future<ApiResponse<List<ParentProperty>>> getParentProperties() async {
    return await ApiClient.getList(
      '/api/parentproperty',
      ParentProperty.fromJson,
    );
  }

  // Get a specific parent property
  static Future<ApiResponse<ParentProperty>> getParentProperty(
    int parentPropertyId,
  ) async {
    return await ApiClient.get(
      '/api/parentproperty/$parentPropertyId',
      ParentProperty.fromJson,
    );
  }

  // Create a new parent property
  static Future<ApiResponse<ParentProperty>> createParentProperty({
    required String projectName,
    required int bedrooms,
    required int bathrooms,
    required int areaSqm,
    required PropertyType type,
    required String finishingType,
    required bool hasPool,
    required bool hasGym,
    required bool hasSecurity,
    required bool hasParking,
    required bool hasGarden,
    required bool hasPlayground,
    required bool hasClubhouse,
  }) async {
    return await ApiClient.post('/api/parentproperty', {
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
    }, ParentProperty.fromJson);
  }

  // Get a specific child property
  static Future<ApiResponse<ChildProperty>> getChildProperty(
    int childPropertyId,
  ) async {
    return await ApiClient.get(
      '/api/Property/$childPropertyId',
      ChildProperty.fromJson,
    );
  }

  static Future<ApiResponse<List<ChildProperty>>> getParentChildProperties(
    int parentPropertyId,
  ) async {
    return await ApiClient.getList(
      '/api/parentproperty/$parentPropertyId/children',
      ChildProperty.fromJson,
    );
  }

  // Create a new child property
  static Future<ApiResponse<ChildProperty>> createChildProperty({
    required int parentPropertyId,
    required String name,
    required String description,
    required String location,
    required String imageUrl,
    required int squareFeet,
    required int yearBuilt,
    bool isApproved = false,
    required int bedrooms,
    required int bathrooms,
    required PropertyType type,
    String status = 'NotApproved',
    int? projectId,
    String? phase,
    int? floorNumber,
    String? unitNumber,
    String? viewType,
    String? orientation,
    DateTime? deliveryDate,
    int? parkingSlots,
    bool? hasStorageRoom,
    double? buyingPrice,
    DateTime? buyingDate,
    int quantity = 1,
    bool? hasNannyRoom,
    bool? hasDriverRoom,
    bool? hasMaidRoom,
    bool? hasPrivatePool,
    bool? hasRoofAccess,
    bool? hasBalcony,
    bool? hasGarden,
    bool? hasClubhouse,
    bool? hasInfrastructure,
    bool? hasUndergroundParking,
    bool? hasMedicalCenter,
    bool? hasCommercialStrip,
    bool? hasBusinessHub,
    bool? hasOutdoorPools,
    bool? hasBicycleLanes,
    bool? hasJoggingTrail,
    bool? smartHome,
    bool? centralAC,
    bool? naturalGas,
    bool? hasGenerator,
    bool? seaView,
    bool? nileView,
    bool? pyramidView,
    bool? gardenView,
    bool? streetView,
  }) async {
    return await ApiClient.post('/api/property', {
      'parentPropertyId': parentPropertyId,
      'name': name,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'squareFeet': squareFeet,
      'yearBuilt': yearBuilt,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'type': type.displayName,
      'projectId': projectId,
      'phase': phase,
      'floorNumber': floorNumber,
      'unitNumber': unitNumber,
      'viewType': viewType,
      'orientation': orientation,
      'deliveryDate': deliveryDate?.toIso8601String(),
      'parkingSlots': parkingSlots,
      'hasStorageRoom': hasStorageRoom,
      'buyingPrice': buyingPrice,
      'buyingDate': buyingDate?.toIso8601String(),
      'quantity': quantity,
      'hasNannyRoom': hasNannyRoom,
      'hasDriverRoom': hasDriverRoom,
      'hasMaidRoom': hasMaidRoom,
      'hasPrivatePool': hasPrivatePool,
      'hasRoofAccess': hasRoofAccess,
      'hasBalcony': hasBalcony,
      'hasGarden': hasGarden,
      'hasClubhouse': hasClubhouse,
      'hasInfrastructure': hasInfrastructure,
      'hasUndergroundParking': hasUndergroundParking,
      'hasMedicalCenter': hasMedicalCenter,
      'hasCommercialStrip': hasCommercialStrip,
      'hasBusinessHub': hasBusinessHub,
      'hasOutdoorPools': hasOutdoorPools,
      'hasBicycleLanes': hasBicycleLanes,
      'hasJoggingTrail': hasJoggingTrail,
      'smartHome': smartHome,
      'centralAC': centralAC,
      'naturalGas': naturalGas,
      'hasGenerator': hasGenerator,
      'seaView': seaView,
      'nileView': nileView,
      'pyramidView': pyramidView,
      'gardenView': gardenView,
      'streetView': streetView,
    }, ChildProperty.fromJson);
  }

  // Update a child property
  static Future<ApiResponse<ChildProperty>> updateChildProperty({
    required int childPropertyId,
    required String name,
    required String description,
    required String location,
  }) async {
    return await ApiClient.put('/api/parentproperty/child/$childPropertyId', {
      'name': name,
      'description': description,
      'location': location,
    }, ChildProperty.fromJson);
  }

  static Future<void> _attemptSyncInstallmentSummary(
    int propertyId,
    InstallmentSummaryPayload? payload,
  ) async {
    if (payload == null || !payload.hasRequiredData) {
      return;
    }

    await upsertPropertyInstallmentSummary(propertyId, payload);
  }

  // Delete a child property
  static Future<ApiResponse<void>> deleteChildProperty(
    int childPropertyId,
  ) async {
    return await ApiClient.delete('/api/parentproperty/child/$childPropertyId');
  }

  // Upload images for child property
  static Future<ApiResponse<dynamic>> uploadChildPropertyImages(
    int childPropertyId,
    List<File> images, {
    String imageType = 'Gallery',
  }) async {
    return await ApiClient.postMultipart(
      '/api/parentproperty/child/$childPropertyId/images',
      images,
      fields: {'imageType': imageType},
      fileFieldName: 'images',
      fromJson: (json) => json,
    );
  }

  // Upload images for child property (PlatformFile)
  static Future<ApiResponse<dynamic>> uploadChildPropertyImagesPlatform(
    int childPropertyId,
    List<PlatformFile> images, {
    String imageType = 'Gallery',
  }) async {
    return await ApiClient.postMultipartPlatformFiles(
      '/api/parentproperty/child/$childPropertyId/images',
      images,
      fields: {'imageType': imageType},
      fileFieldName: 'images',
      fromJson: (json) => json,
    );
  }

  // Get images for child property
  static Future<ApiResponse<List<PropertyImage>>> getChildPropertyImages(
    int childPropertyId,
  ) async {
    return await ApiClient.getList(
      '/api/parentproperty/child/$childPropertyId/images',
      PropertyImage.fromJson,
    );
  }

  // Delete child property image
  static Future<ApiResponse<void>> deleteChildPropertyImage(
    int childPropertyId,
    int imageId,
  ) async {
    return await ApiClient.delete(
      '/api/parentproperty/child/$childPropertyId/images/$imageId',
    );
  }

  static Future<ApiResponse<PropertyMarketBundle>> getPropertyMarketBundle(
    int childPropertyId,
  ) async {
    try {
      final childResponse = await getChildProperty(childPropertyId);
      if (!childResponse.success || childResponse.data == null) {
        return ApiResponse<PropertyMarketBundle>(
          success: false,
          statusCode: childResponse.statusCode,
          error: childResponse.error ?? 'Property not found',
        );
      }

      final child = childResponse.data!;
      ParentProperty? parent;
      List<ChildProperty> siblings = [];
      PropertyPriceHistoryResponse? priceHistory;
      PropertyPriceStats? priceStats;

      if (child.parentPropertyId != null) {
        final parentResponse =
            await getParentProperty(child.parentPropertyId!);
        if (parentResponse.success && parentResponse.data != null) {
          parent = parentResponse.data;
        }

        final siblingsResponse =
            await getParentChildProperties(child.parentPropertyId!);
        if (siblingsResponse.success && siblingsResponse.data != null) {
          siblings = siblingsResponse.data!
              .where((sibling) => sibling.propertyId != child.propertyId)
              .toList();
        }

        try {
          priceHistory = await PriceHistoryService
              .getParentPropertyPriceHistory(child.parentPropertyId!);
        } catch (_) {
          priceHistory = null;
        }

        try {
          priceStats = await PriceHistoryService
              .getParentPropertyPriceStats(child.parentPropertyId!);
        } catch (_) {
          priceStats = null;
        }
      }

      final analytics = (priceHistory != null || priceStats != null)
          ? PropertyMarketAnalytics(
              priceHistory: priceHistory,
              priceStats: priceStats,
            )
          : null;

      final bundle = PropertyMarketBundle(
        property: child,
        parent: parent,
        siblings: siblings,
        marketAnalytics: analytics,
      );

      return ApiResponse<PropertyMarketBundle>.success(bundle);
    } catch (e) {
      return ApiResponse<PropertyMarketBundle>(
        success: false,
        statusCode: 500,
        error: 'Failed to load property market data: $e',
      );
    }
  }

  // ===== BACKWARD COMPATIBILITY METHODS =====

  // Get properties as ChildProperty and convert to Property for backward compatibility
  static Future<ApiResponse<List<Property>>>
  getPropertiesAsChildProperties() async {
    final childPropertiesResponse = await getChildProperties();
    if (childPropertiesResponse.success &&
        childPropertiesResponse.data != null) {
      final properties = childPropertiesResponse.data!
          .map((childProperty) => Property.fromChildProperty(childProperty))
          .toList();
      return ApiResponse<List<Property>>(
        success: true,
        data: properties,
        statusCode: 200,
      );
    }
    return ApiResponse<List<Property>>(
      success: false,
      data: [],
      statusCode: childPropertiesResponse.statusCode,
    );
  }

  // Get a specific property as ChildProperty and convert to Property
  static Future<ApiResponse<Property>> getPropertyAsChildProperty(
    int propertyId,
  ) async {
    final childPropertyResponse = await getChildProperty(propertyId);
    if (childPropertyResponse.success && childPropertyResponse.data != null) {
      final property = Property.fromChildProperty(childPropertyResponse.data!);
      return ApiResponse<Property>(
        success: true,
        data: property,
        statusCode: 200,
      );
    }
    return ApiResponse<Property>(
      success: false,
      data: Property(
        propertyId: 0,
        ownerId: 0,
        owner: null,
        projectId: null,
        project: null,
        name: '',
        description: '',
        location: '',
        listingType: ListingType.resale,
        type: PropertyType.other,
        status: PropertyStatus.notApproved,
        bedrooms: 0,
        bathrooms: 0,
        squareFeet: 0,
        yearBuilt: 0,
        imageUrl: '',
        createdAt: DateTime.now(),
        hasActiveAuction: false,
        propertyImages: const [],
      ),
      statusCode: childPropertyResponse.statusCode,
    );
  }
}

class PropertyMarketBundle {
  final ChildProperty property;
  final ParentProperty? parent;
  final List<ChildProperty> siblings;
  final PropertyMarketAnalytics? marketAnalytics;

  const PropertyMarketBundle({
    required this.property,
    required this.parent,
    required this.siblings,
    required this.marketAnalytics,
  });

  bool get hasParent => parent != null;
  bool get hasSiblings => siblings.isNotEmpty;
  bool get hasAnalytics => marketAnalytics?.hasData ?? false;
}

class PropertyMarketAnalytics {
  final PropertyPriceHistoryResponse? priceHistory;
  final PropertyPriceStats? priceStats;

  const PropertyMarketAnalytics({
    this.priceHistory,
    this.priceStats,
  });

  bool get hasData =>
      (priceHistory?.priceHistory.isNotEmpty ?? false) || priceStats != null;
}
