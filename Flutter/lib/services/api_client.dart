import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
  });

  factory ApiResponse.success(T data, {int statusCode = 200}) {
    return ApiResponse(success: true, data: data, statusCode: statusCode);
  }

  factory ApiResponse.error(String error, {int statusCode = 400}) {
    return ApiResponse(success: false, error: error, statusCode: statusCode);
  }
}

class ApiClient {
  // Automatically detect the correct base URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      // For web, use localhost or your deployed backend URL
      return 'http://localhost:5284';
    } else if (Platform.isAndroid) {
      // Android emulator: 10.0.2.2 maps to host's localhost
      // Physical Android device: use your computer's IP address
      // To detect if running on emulator, we'll try to use the environment
      // For now, defaulting to physical device IP
      return 'http://192.168.33.214:5284';
    } else if (Platform.isIOS) {
      // iOS Simulator can use localhost directly
      // Physical iOS device: use your computer's IP address
      return 'http://192.168.33.214:5284';
    } else {
      return 'http://localhost:5284';
    }
  }

  static const Duration timeout = Duration(seconds: 30);

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> setToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove('auth_token');
    } else {
      await prefs.setString('auth_token', token);
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<ApiResponse<T>> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        // Ensure data is a Map before calling fromJson
        if (data is! Map<String, dynamic>) {
          return ApiResponse.error(
            'Invalid response format: expected object, got ${data.runtimeType}',
            statusCode: response.statusCode,
          );
        }

        return ApiResponse.success(
          fromJson(data),
          statusCode: response.statusCode,
        );
      } else {
        // Handle error responses
        try {
          final data = jsonDecode(response.body);
          final errorMessage = data is Map<String, dynamic>
              ? (data['message'] ?? data['error'] ?? 'Unknown error')
              : (data is String
                    ? data
                    : 'Request failed with status ${response.statusCode}');
          return ApiResponse.error(
            errorMessage,
            statusCode: response.statusCode,
          );
        } catch (e) {
          // If JSON decode fails, use response body as error message
          return ApiResponse.error(
            response.body.isNotEmpty ? response.body : 'Request failed',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to parse response: $e',
        statusCode: response.statusCode,
      );
    }
  }

  static Future<ApiResponse<List<T>>> _handleListResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        if (data is! List) {
          print('❌ Expected List but got ${data.runtimeType}');
          return ApiResponse.error(
            'Invalid response format: expected array, got ${data.runtimeType}',
            statusCode: response.statusCode,
          );
        }

        final List<dynamic> list = data;
        final items = <T>[];

        for (int i = 0; i < list.length; i++) {
          try {
            final item = list[i];
            if (item is! Map<String, dynamic>) {
              print('❌ Item $i is not a Map: ${item.runtimeType}');
              continue;
            }
            items.add(fromJson(item));
          } catch (e) {
            print('❌ Error parsing item $i: $e');
            // Continue parsing other items
          }
        }

        return ApiResponse.success(items, statusCode: response.statusCode);
      } else {
        // Handle error responses
        try {
          final data = jsonDecode(response.body);
          final errorMessage = data is Map<String, dynamic>
              ? (data['message'] ?? data['error'] ?? 'Unknown error')
              : (data is String
                    ? data
                    : 'Request failed with status ${response.statusCode}');
          return ApiResponse.error(
            errorMessage,
            statusCode: response.statusCode,
          );
        } catch (e) {
          return ApiResponse.error(
            response.body.isNotEmpty ? response.body : 'Request failed',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to parse response: $e',
        statusCode: response.statusCode,
      );
    }
  }

  static Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      print('🌐 GET $uri');
      print('📡 Base URL: $baseUrl');

      final response = await http.get(uri, headers: headers).timeout(timeout);
      print('✅ Response status: ${response.statusCode}');
      return _handleResponse(response, fromJson);
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      return ApiResponse.error(
        'Cannot connect to server. Please check if backend is running at $baseUrl',
      );
    } on HttpException catch (e) {
      print('❌ HttpException: $e');
      return ApiResponse.error('HTTP error occurred: $e');
    } on FormatException catch (e) {
      print('❌ FormatException: $e');
      return ApiResponse.error('Invalid response format: $e');
    } catch (e) {
      print('❌ Unexpected error: $e');
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  static Future<ApiResponse<List<T>>> getList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      print('GET $uri');
      print('Headers: $headers');

      final response = await http.get(uri, headers: headers).timeout(timeout);
      print('Response status: ${response.statusCode}');
      print(
        'Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
      );

      return _handleListResponse(response, fromJson);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } on HttpException {
      return ApiResponse.error('HTTP error occurred');
    } on FormatException {
      return ApiResponse.error('Invalid response format');
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  static Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      print('🌐 POST $uri');
      print('📡 Base URL: $baseUrl');
      print('📤 Body: ${jsonEncode(body)}');

      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(timeout);

      print('✅ Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      return _handleResponse(response, fromJson);
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      return ApiResponse.error(
        'Cannot connect to server. Please check if backend is running at $baseUrl',
      );
    } on HttpException catch (e) {
      print('❌ HttpException: $e');
      return ApiResponse.error('HTTP error occurred: $e');
    } on FormatException catch (e) {
      print('❌ FormatException: $e');
      return ApiResponse.error('Invalid response format: $e');
    } catch (e) {
      print('❌ Unexpected error: $e');
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  static Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      print('PUT $uri with body: ${jsonEncode(body)}');

      final response = await http
          .put(uri, headers: headers, body: jsonEncode(body))
          .timeout(timeout);

      return _handleResponse(response, fromJson);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } on HttpException {
      return ApiResponse.error('HTTP error occurred');
    } on FormatException {
      return ApiResponse.error('Invalid response format');
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  static Future<ApiResponse<void>> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      print('DELETE $uri');

      final response = await http
          .delete(uri, headers: headers)
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(null, statusCode: response.statusCode);
      } else {
        final data = jsonDecode(response.body);
        final errorMessage = data is Map<String, dynamic>
            ? (data['message'] ?? data['error'] ?? 'Unknown error')
            : 'Request failed with status ${response.statusCode}';
        return ApiResponse.error(errorMessage, statusCode: response.statusCode);
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } on HttpException {
      return ApiResponse.error('HTTP error occurred');
    } on FormatException {
      return ApiResponse.error('Invalid response format');
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }
}
