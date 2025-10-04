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
    required double startingPrice,
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
      'startingPrice': startingPrice,
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
    double? startingPrice,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (location != null) body['location'] = location;
    if (startingPrice != null) body['startingPrice'] = startingPrice;

    return await ApiClient.put(
      '/api/property/$propertyId',
      body,
      Property.fromJson,
    );
  }

  static Future<ApiResponse<void>> deleteProperty(int propertyId) async {
    return await ApiClient.delete('/api/property/$propertyId');
  }

  static Future<ApiResponse<List<Property>>> getUserProperties() async {
    return await ApiClient.getList('/api/user/properties', Property.fromJson);
  }
}
