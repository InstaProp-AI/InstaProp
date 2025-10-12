import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';
import 'document_service.dart';

/// Clean, simple KYC service
/// Handles document uploads and status checking
class KycService {
  /// Upload a single KYC document
  ///
  /// [file] - XFile from image picker
  /// [docType] - One of: 'ID_Front', 'ID_Back', 'Passport'
  /// [email] - Required for public upload (during registration, no auth)
  ///
  /// Returns the uploaded document URL or null on failure
  static Future<ApiResponse<String>> uploadDocument({
    required XFile file,
    required String docType,
    String? email, // For public upload during registration
  }) async {
    try {
      // Validate document type
      const validTypes = ['ID_Front', 'ID_Back', 'Passport'];
      if (!validTypes.contains(docType)) {
        return ApiResponse.error('Invalid document type: $docType');
      }

      print('📤 Uploading KYC document: $docType');

      // Call document service to upload
      ApiResponse<Map<String, dynamic>> result;

      if (kIsWeb) {
        // Web: read bytes from XFile
        final bytes = await file.readAsBytes();
        result = await DocumentService.uploadUserDocument(
          fileBytes: bytes,
          fileName: file.name,
          docType: docType,
          email: email,
        );
      } else {
        // Mobile: use file path
        result = await DocumentService.uploadUserDocument(
          filePath: file.path,
          fileName: file.name,
          docType: docType,
          email: email,
        );
      }

      if (result.success && result.data != null) {
        final url = result.data!['url'] as String?;
        if (url != null) {
          print('✅ KYC document uploaded: $url');
          return ApiResponse.success(url);
        }
      }

      return ApiResponse.error(
        result.error ?? 'Failed to upload document',
        statusCode: result.statusCode,
      );
    } catch (e) {
      print('❌ Error uploading KYC document: $e');
      return ApiResponse.error('Failed to upload document: $e');
    }
  }

  /// Get all KYC documents for the current user
  static Future<ApiResponse<List<KycDocument>>> getMyDocuments() async {
    try {
      final response = await DocumentService.getMyDocuments();

      if (response.success && response.data != null) {
        final documents = response.data!.map((doc) {
          return KycDocument(
            docType: doc['docType'] ?? doc['DocType'] ?? '',
            imageUrl: doc['imgUrl'] ?? doc['ImgUrl'] ?? '',
            uploadedAt: DateTime.parse(
              doc['uploadedAt'] ??
                  doc['UploadedAt'] ??
                  DateTime.now().toIso8601String(),
            ),
          );
        }).toList();

        return ApiResponse.success(documents);
      }

      return ApiResponse.error(
        response.error ?? 'Failed to get documents',
        statusCode: response.statusCode,
      );
    } catch (e) {
      print('❌ Error getting KYC documents: $e');
      return ApiResponse.error('Failed to get documents: $e');
    }
  }

  /// Delete a KYC document
  static Future<ApiResponse<void>> deleteDocument(int docId) async {
    try {
      return await DocumentService.deleteUserDocument(docId);
    } catch (e) {
      print('❌ Error deleting KYC document: $e');
      return ApiResponse.error('Failed to delete document: $e');
    }
  }

  /// Check if user has uploaded sufficient documents
  /// Returns a map with:
  /// - hasID: bool (both front and back)
  /// - hasPassport: bool
  /// - hasAnyDocument: bool
  static Future<Map<String, bool>> checkDocumentStatus() async {
    try {
      final response = await getMyDocuments();

      if (response.success && response.data != null) {
        final docs = response.data!;
        final docTypes = docs.map((d) => d.docType).toList();

        return {
          'hasID':
              docTypes.contains('ID_Front') && docTypes.contains('ID_Back'),
          'hasPassport': docTypes.contains('Passport'),
          'hasAnyDocument': docs.isNotEmpty,
        };
      }

      return {'hasID': false, 'hasPassport': false, 'hasAnyDocument': false};
    } catch (e) {
      print('❌ Error checking document status: $e');
      return {'hasID': false, 'hasPassport': false, 'hasAnyDocument': false};
    }
  }
}

/// Simple KYC document model
class KycDocument {
  final String docType;
  final String imageUrl;
  final DateTime uploadedAt;

  KycDocument({
    required this.docType,
    required this.imageUrl,
    required this.uploadedAt,
  });

  String get displayName {
    switch (docType) {
      case 'ID_Front':
        return 'ID Card (Front)';
      case 'ID_Back':
        return 'ID Card (Back)';
      case 'Passport':
        return 'Passport';
      default:
        return docType;
    }
  }
}
