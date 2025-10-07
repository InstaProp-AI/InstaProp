import 'api_client.dart';
import '../models/property.dart';

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
    required String imageUrl,
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
      'imageUrl': imageUrl,
    }, Property.fromJson);
  }

  static Future<ApiResponse<Property>> updateProperty({
    required int propertyId,
    String? name,
    String? description,
    String? location,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (location != null) body['location'] = location;

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
    required String imageUrl,
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
      'imageUrl': imageUrl,
    }, Property.fromJson);
  }

  static Future<ApiResponse<List<Property>>> getMyProperties() async {
    return await ApiClient.getList(
      '/api/property/my-properties',
      Property.fromJson,
    );
  }
}
