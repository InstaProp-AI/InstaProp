import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'api_client.dart';
import '../models/property.dart';
import '../models/property_image.dart';
import '../models/property_type.dart';
import '../models/installment_summary.dart';

class PropertyService {
  static Future<ApiResponse<List<Property>>> getProperties() async {
    return ApiClient.getList('/api/Property', Property.fromJson);
  }

  static Future<ApiResponse<Property>> getProperty(String propertyId) async {
    return ApiClient.get('/api/Property/$propertyId', Property.fromJson);
  }

  static Future<ApiResponse<InstallmentSummary>> getPropertyInstallmentSummary(
    String propertyId,
  ) async {
    return ApiClient.get(
      '/api/property/$propertyId/installment-summary',
      InstallmentSummary.fromJson,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getPropertyFinancials(
    String propertyId, {
    double? marketValue,
  }) async {
    final queryParams =
        marketValue != null ? '?marketValue=$marketValue' : '';
    return ApiClient.get(
      '/api/property/$propertyId/financials$queryParams',
      (json) => json as Map<String, dynamic>,
    );
  }

  static Future<ApiResponse<InstallmentSummary>> upsertPropertyInstallmentSummary(
    String propertyId,
    InstallmentSummaryPayload payload,
  ) async {
    return ApiClient.put(
      '/api/property/$propertyId/installment-summary',
      payload.toJson(),
      InstallmentSummary.fromJson,
    );
  }

  static Future<ApiResponse<Property>> createProperty({
    required String description,
    required String location,
    required int bedrooms,
    required int bathrooms,
    required int squareFeet,
    required int yearBuilt,
    required PropertyType type,
    String? imageUrl,
    String? projectName,
    String? projectId,
    String? finishingType,
    bool hasPool = false,
    bool hasGym = false,
    bool hasSecurity = false,
    bool hasParking = false,
    bool hasGarden = false,
    bool hasPlayground = false,
    bool hasClubhouse = false,
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
    final response = await ApiClient.post('/api/property', {
      'description': description,
      'location': location,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFeet': squareFeet,
      'yearBuilt': yearBuilt,
      'type': type.displayName,
      'imageUrl': imageUrl ?? '',
      'projectName': projectName ?? _extractProjectNameFromLocation(location),
      'projectId': projectId,
      'finishingType': finishingType ?? 'Finished',
      'hasPool': hasPool,
      'hasGym': hasGym,
      'hasSecurity': hasSecurity,
      'hasParking': hasParking,
      'hasGarden': hasGardenUnit ?? hasGarden,
      'hasPlayground': hasPlayground,
      'hasClubhouse': hasClubhouseUnit ?? hasClubhouse,
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
    }, Property.fromJson);

    if (response.success && response.data != null) {
      await _attemptSyncInstallmentSummary(
        response.data!.propertyId,
        installmentSummary,
      );
      if (installmentSummary != null && installmentSummary.hasRequiredData) {
        return getProperty(response.data!.propertyId);
      }
    }

    return response;
  }

  static String _extractProjectNameFromLocation(String location) {
    final parts = location.split(',');
    return parts.isNotEmpty ? parts.first.trim() : location;
  }

  static Future<ApiResponse<Property>> updateProperty({
    required String propertyId,
    required String name,
    required String description,
    required String location,
    InstallmentSummaryPayload? installmentSummary,
  }) async {
    final response = await ApiClient.put('/api/Property/$propertyId', {
      'name': name,
      'description': description,
      'location': location,
    }, Property.fromJson);

    if (response.success && response.data != null) {
      await _attemptSyncInstallmentSummary(propertyId, installmentSummary);
      if (installmentSummary != null && installmentSummary.hasRequiredData) {
        return getProperty(propertyId);
      }
    }

    return response;
  }

  static Future<ApiResponse<void>> deleteProperty(String propertyId) async {
    return ApiClient.delete('/api/Property/$propertyId');
  }

  static Future<ApiResponse<List<Property>>> getAllProperties() async {
    return ApiClient.getList('/api/Property/all', Property.fromJson);
  }

  static Future<ApiResponse<List<Property>>> getUserProperties() async {
    return ApiClient.getList('/api/user/properties', Property.fromJson);
  }

  static Future<ApiResponse<List<Property>>> getMyProperties() async {
    return ApiClient.getList('/api/Property/my-properties', Property.fromJson);
  }

  static Future<ApiResponse<Property>> createPropertySkipDocuments({
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
        return getProperty(response.data!.propertyId);
      }
    }

    return response;
  }

  static Future<ApiResponse<dynamic>> uploadPropertyImages(
    String propertyId,
    List<File> images, {
    String imageType = 'Gallery',
  }) async {
    return ApiClient.postMultipart(
      '/api/property/$propertyId/images',
      images,
      fields: {'imageType': imageType},
      fileFieldName: 'images',
      fromJson: (json) => json,
    );
  }

  static Future<ApiResponse<dynamic>> uploadPropertyImagesPlatform(
    String propertyId,
    List<PlatformFile> images, {
    String imageType = 'Gallery',
  }) async {
    return ApiClient.postMultipartPlatformFiles(
      '/api/property/$propertyId/images',
      images,
      fields: {'imageType': imageType},
      fileFieldName: 'images',
      fromJson: (json) => json,
    );
  }

  static Future<ApiResponse<List<PropertyImage>>> getPropertyImages(
    String propertyId,
  ) async {
    return ApiClient.getList(
      '/api/property/$propertyId/images',
      PropertyImage.fromJson,
    );
  }

  static Future<ApiResponse<void>> deletePropertyImage(
    String propertyId,
    String imageId,
  ) async {
    return ApiClient.delete('/api/property/$propertyId/images/$imageId');
  }

  static Future<ApiResponse<void>> setMainImage(
    String propertyId,
    String imageId,
  ) async {
    return ApiClient.put(
      '/api/property/$propertyId/images/$imageId/set-main',
      {},
      (json) => null,
    );
  }

  static Future<void> _attemptSyncInstallmentSummary(
    String propertyId,
    InstallmentSummaryPayload? payload,
  ) async {
    if (payload == null || !payload.hasRequiredData) {
      return;
    }

    await upsertPropertyInstallmentSummary(propertyId, payload);
  }
}
