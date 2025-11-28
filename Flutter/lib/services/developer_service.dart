import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/developer_profile.dart';

class DeveloperService {
  final String baseUrl;
  final String? token;

  DeveloperService(this.baseUrl, {this.token});

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // Get developer profile by ID
  Future<DeveloperProfile> getDeveloperProfile(String developerId) async {
    try {
      // Validate GUID format
      if (developerId.isEmpty) {
        throw Exception('Developer ID cannot be empty');
      }
      
      // Try to parse as GUID to validate format
      try {
        // Remove any whitespace
        final cleanId = developerId.trim();
        // Check if it looks like a GUID (has dashes or is 32 hex chars)
        if (!RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
            .hasMatch(cleanId) && 
            !RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(cleanId)) {
          print('Warning: Developer ID does not appear to be a valid GUID: $cleanId');
        }
      } catch (e) {
        print('Warning: Could not validate GUID format: $e');
      }
      
      print('Fetching developer profile for ID: $developerId');
      final url = Uri.parse('$baseUrl/api/developer/profile/${Uri.encodeComponent(developerId.trim())}');
      print('Request URL: $url');
      
      final response = await http.get(
        url,
        headers: headers,
      );

      print('Developer profile response status: ${response.statusCode}');
      print('Developer profile response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('Developer profile response body length: ${responseBody.length}');
        return DeveloperProfile.fromJson(json.decode(responseBody));
      } else if (response.statusCode == 404) {
        final errorBody = response.body;
        print('Developer profile 404 error response: $errorBody');
        throw Exception('Developer not found. The developer profile may not exist or the ID may be incorrect.');
      } else {
        final errorBody = response.body;
        print('Developer profile error response (${response.statusCode}): $errorBody');
        throw Exception(
          'Failed to load developer profile: ${response.statusCode}. ${errorBody.isNotEmpty ? errorBody : ""}',
        );
      }
    } catch (e) {
      print('Error fetching developer profile: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to load developer profile: ${e.toString()}');
    }
  }

  // Get featured developers
  Future<List<FeaturedDeveloper>> getFeaturedDevelopers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/developer/featured'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => FeaturedDeveloper.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load featured developers: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching featured developers: $e');
      throw Exception('Failed to load featured developers');
    }
  }

  // Rate a developer
  Future<void> rateDeveloper({
    required String developerId,
    required int rating,
    String? comment,
    required String ratingType, // "Chat" or "Purchase"
  }) async {
    if (token == null) {
      throw Exception('Authentication required to rate developer');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/developer/rating'),
        headers: headers,
        body: json.encode({
          'developerId': developerId,
          'rating': rating,
          'comment': comment,
          'ratingType': ratingType == 'Purchase' ? 1 : 0,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to rate developer');
      }
    } catch (e) {
      print('Error rating developer: $e');
      throw Exception(e.toString());
    }
  }

  // Update developer profile (for developers only)
  Future<void> updateProfile({
    String? bio,
    String? companyName,
    String? profileImageUrl,
    String? portfolioDescription,
  }) async {
    if (token == null) {
      throw Exception('Authentication required to update profile');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/developer/profile'),
        headers: headers,
        body: json.encode({
          'bio': bio,
          'companyName': companyName,
          'profileImageUrl': profileImageUrl,
          'portfolioDescription': portfolioDescription,
        }),
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating developer profile: $e');
      throw Exception('Failed to update profile');
    }
  }

  // Get developer analytics (for developers only)
  Future<Map<String, dynamic>> getDeveloperAnalytics() async {
    if (token == null) {
      throw Exception('Authentication required to get analytics');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/developer/analytics'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load analytics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching developer analytics: $e');
      throw Exception('Failed to load analytics');
    }
  }
}
