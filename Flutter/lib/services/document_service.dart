import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'file_reader_stub.dart'
    if (dart.library.io) 'file_reader_mobile.dart'
    if (dart.library.html) 'file_reader_web.dart';

/// Service for handling document uploads using the new DocumentController API
/// All documents are uploaded directly to ImgBB via the backend
class DocumentService {
  /// Upload a user KYC document (PUBLIC - for registration)
  ///
  /// [filePath] - Path to the file to upload
  /// [fileBytes] - Bytes of the file (for web)
  /// [fileName] - Name of the file
  /// [docType] - Type of document (ID_Front, ID_Back, Passport_Front, Passport_Back, ProofOfAddress, etc.)
  /// [email] - User's email (required for public upload during registration)
  ///
  /// Returns the uploaded document details including URL
  static Future<ApiResponse<Map<String, dynamic>>> uploadUserDocument({
    String? filePath,
    List<int>? fileBytes,
    required String fileName,
    required String docType,
    String? email,
  }) async {
    try {
      print('🔄 Starting document upload: $docType');
      print('📁 File path: $filePath');
      print('📄 File name: $fileName');
      print('📧 Email: $email');

      // Use public endpoint if email is provided (registration), otherwise use authenticated endpoint
      final isPublicUpload = email != null && email.isNotEmpty;
      final endpoint = isPublicUpload
          ? '/api/document/public/upload'
          : '/api/document/user/upload';
      final uri = Uri.parse('${ApiClient.baseUrl}$endpoint');

      print(
        isPublicUpload
            ? '🌍 Using PUBLIC upload (registration)'
            : '🔒 Using AUTHENTICATED upload',
      );

      var request = http.MultipartRequest('POST', uri);

      // Add auth header only for authenticated uploads
      if (!isPublicUpload) {
        final token = await ApiClient.getToken();
        if (token == null) {
          print('❌ No authentication token found');
          return ApiResponse.error('Authentication token not found');
        }
        request.headers['Authorization'] = 'Bearer $token';
        print('🔑 Token added to request');
      } else {
        // Add email for public uploads
        request.fields['email'] = email;
        print('📧 Email added to request');
      }

      request.fields['docType'] = docType;

      // Add file from either path or bytes
      if (fileBytes != null) {
        // Prefer bytes if provided (works on all platforms)
        print('📤 Uploading from bytes...');
        print('✅ File size: ${fileBytes.length} bytes');
        request.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );
      } else if (filePath != null) {
        // Use file path on mobile/desktop (not web)
        print('📤 Uploading from file path...');
        try {
          final fileData = await FileReader.readBytes(filePath);
          print('✅ File read successfully, size: ${fileData.length} bytes');
          request.files.add(
            http.MultipartFile.fromBytes('file', fileData, filename: fileName),
          );
        } catch (e) {
          print('❌ Error reading file: $e');
          return ApiResponse.error('Failed to read file: $e');
        }
      } else {
        print('❌ No file provided');
        return ApiResponse.error('No file provided');
      }

      print('🌐 Sending request to: $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Upload successful: ${data['url']}');
        return ApiResponse.success(data);
      } else {
        print('❌ Upload failed: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          return ApiResponse.error(
            errorData['message'] ?? 'Upload failed: ${response.statusCode}',
          );
        } catch (e) {
          return ApiResponse.error(
            'Upload failed: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('❌ Exception during upload: $e');
      return ApiResponse.error('Failed to upload document: $e');
    }
  }

  /// Get user's uploaded KYC documents
  static Future<ApiResponse<List<Map<String, dynamic>>>>
  getMyDocuments() async {
    try {
      final response = await ApiClient.getList(
        '/api/document/user/my-documents',
        (json) => json,
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get documents: $e');
    }
  }

  /// Delete a user document
  static Future<ApiResponse<void>> deleteUserDocument(int docId) async {
    return await ApiClient.delete('/api/document/user/$docId');
  }

  /// Upload a property document
  ///
  /// [propertyId] - ID of the property
  /// [filePath] - Path to the file to upload
  /// [fileBytes] - Bytes of the file (for web)
  /// [fileName] - Name of the file
  /// [docType] - Type of document (Ownership, Legal, FloorPlan, etc.)
  ///
  /// Returns the uploaded document details including URL
  static Future<ApiResponse<Map<String, dynamic>>> uploadPropertyDocument({
    required int propertyId,
    String? filePath,
    List<int>? fileBytes,
    required String fileName,
    required String docType,
  }) async {
    try {
      print(
        '🔄 Starting property document upload: $docType for property $propertyId',
      );
      // Use the updated PropertyController endpoint which now accepts file uploads
      final uri = Uri.parse(
        '${ApiClient.baseUrl}/api/Property/$propertyId/documents',
      );
      final token = await ApiClient.getToken();

      if (token == null) {
        print('❌ No authentication token found');
        return ApiResponse.error('Authentication token not found');
      }

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['docType'] = docType;

      // Add file from either path or bytes
      if (fileBytes != null) {
        // Prefer bytes if provided (works on all platforms)
        print('📤 Uploading from bytes...');
        print('✅ File size: ${fileBytes.length} bytes');
        request.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );
      } else if (filePath != null) {
        // Use file path on mobile/desktop (not web)
        print('📤 Uploading from file path...');
        try {
          final fileData = await FileReader.readBytes(filePath);
          print('✅ File read successfully, size: ${fileData.length} bytes');
          request.files.add(
            http.MultipartFile.fromBytes('file', fileData, filename: fileName),
          );
        } catch (e) {
          print('❌ Error reading file: $e');
          return ApiResponse.error('Failed to read file: $e');
        }
      } else {
        print('❌ No file provided');
        return ApiResponse.error('No file provided');
      }

      print('🌐 Sending request to: $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Upload successful');
        return ApiResponse.success(data);
      } else {
        print('❌ Upload failed: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          return ApiResponse.error(
            errorData['message'] ?? 'Upload failed: ${response.statusCode}',
          );
        } catch (e) {
          return ApiResponse.error(
            'Upload failed: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('❌ Exception during upload: $e');
      return ApiResponse.error('Failed to upload document: $e');
    }
  }

  /// Get property documents
  static Future<ApiResponse<List<Map<String, dynamic>>>> getPropertyDocuments(
    int propertyId,
  ) async {
    try {
      final response = await ApiClient.getList(
        '/api/Property/$propertyId/documents',
        (json) => json,
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get property documents: $e');
    }
  }

  /// Delete a property document
  static Future<ApiResponse<void>> deletePropertyDocument(int docId) async {
    return await ApiClient.delete('/api/document/property/document/$docId');
  }

  /// Upload a property image
  ///
  /// [propertyId] - ID of the property
  /// [filePath] - Path to the file to upload
  /// [fileBytes] - Bytes of the file (for web)
  /// [fileName] - Name of the file
  /// [imageType] - Type of image (Main, Exterior, Interior, Kitchen, etc.)
  /// [isMainImage] - Whether this should be the main property image
  /// [displayOrder] - Display order for gallery
  ///
  /// Returns the uploaded image details including URL
  static Future<ApiResponse<Map<String, dynamic>>> uploadPropertyImage({
    required int propertyId,
    String? filePath,
    List<int>? fileBytes,
    required String fileName,
    required String imageType,
    bool isMainImage = false,
    int displayOrder = 0,
  }) async {
    try {
      print(
        '🔄 Starting property image upload: $imageType for property $propertyId',
      );
      final uri = Uri.parse(
        '${ApiClient.baseUrl}/api/document/property/$propertyId/upload-image',
      );
      final token = await ApiClient.getToken();

      if (token == null) {
        print('❌ No authentication token found');
        return ApiResponse.error('Authentication token not found');
      }

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['imageType'] = imageType;
      request.fields['isMainImage'] = isMainImage.toString();
      request.fields['displayOrder'] = displayOrder.toString();

      // Add file from either path or bytes
      if (fileBytes != null) {
        // Prefer bytes if provided (works on all platforms)
        print('📤 Uploading from bytes...');
        print('✅ File size: ${fileBytes.length} bytes');
        request.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );
      } else if (filePath != null) {
        // Use file path on mobile/desktop (not web)
        print('📤 Uploading from file path...');
        try {
          final fileData = await FileReader.readBytes(filePath);
          print('✅ File read successfully, size: ${fileData.length} bytes');
          request.files.add(
            http.MultipartFile.fromBytes('file', fileData, filename: fileName),
          );
        } catch (e) {
          print('❌ Error reading file: $e');
          return ApiResponse.error('Failed to read file: $e');
        }
      } else {
        print('❌ No file provided');
        return ApiResponse.error('No file provided');
      }

      print('🌐 Sending request to: $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Upload successful');
        return ApiResponse.success(data);
      } else {
        print('❌ Upload failed: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          return ApiResponse.error(
            errorData['message'] ?? 'Upload failed: ${response.statusCode}',
          );
        } catch (e) {
          return ApiResponse.error(
            'Upload failed: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('❌ Exception during upload: $e');
      return ApiResponse.error('Failed to upload image: $e');
    }
  }

  /// Get property images
  static Future<ApiResponse<List<Map<String, dynamic>>>> getPropertyImages(
    int propertyId,
  ) async {
    try {
      final response = await ApiClient.getList(
        '/api/document/property/$propertyId/images',
        (json) => json,
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get property images: $e');
    }
  }

  /// Delete a property image
  static Future<ApiResponse<void>> deletePropertyImage(int imageId) async {
    return await ApiClient.delete('/api/document/property/image/$imageId');
  }

  /// Get document statistics (Admin only)
  static Future<ApiResponse<Map<String, dynamic>>>
  getDocumentStatistics() async {
    try {
      final response = await ApiClient.get(
        '/api/document/statistics',
        (json) => json,
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get statistics: $e');
    }
  }
}
