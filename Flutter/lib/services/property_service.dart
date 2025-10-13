import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'api_client.dart';
import '../models/property.dart';
import '../models/property_image.dart';

class PropertyService {
  static Future<ApiResponse<List<Property>>> getProperties() async {
    return await ApiClient.getList('/api/property', Property.fromJson);
  }

  static Future<ApiResponse<Property>> getProperty(int propertyId) async {
    return await ApiClient.get('/api/property/$propertyId', Property.fromJson);
  }

  static Future<ApiResponse<Property>> createProperty({
    required String name,
    required String description,
    required String location,
    required int bedrooms,
    required int bathrooms,
    required int squareFeet,
    required int yearBuilt,
    required String category,
    String? imageUrl,
  }) async {
    return await ApiClient.post('/api/property', {
      'name': name,
      'description': description,
      'location': location,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFeet': squareFeet,
      'yearBuilt': yearBuilt,
      'category': category,
      'imageUrl': imageUrl ?? '',
    }, Property.fromJson);
  }

  static Future<ApiResponse<Property>> updateProperty({
    required int propertyId,
    required String name,
    required String description,
    required String location,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'description': description,
      'location': location,
    };

    return await ApiClient.put(
      '/api/property/$propertyId',
      body,
      Property.fromJson,
    );
  }

  static Future<ApiResponse<void>> deleteProperty(int propertyId) async {
    return await ApiClient.delete('/api/property/$propertyId');
  }

  static Future<ApiResponse<List<Property>>> getAllProperties() async {
    return await ApiClient.getList('/api/property/all', Property.fromJson);
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
    required String category,
    String? imageUrl,
  }) async {
    return await ApiClient.post('/api/property/skip-documents', {
      'name': name,
      'description': description,
      'location': location,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFeet': squareFeet,
      'yearBuilt': yearBuilt,
      'category': category,
      'imageUrl': imageUrl ?? '',
    }, Property.fromJson);
  }

  static Future<ApiResponse<List<Property>>> getMyProperties() async {
    return await ApiClient.getList(
      '/api/property/my-properties',
      Property.fromJson,
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
}
