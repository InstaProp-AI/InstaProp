import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String baseUrl = 'http://localhost:5284';
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
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(
          fromJson(data),
          statusCode: response.statusCode,
        );
      } else {
        final errorMessage = data is Map<String, dynamic>
            ? (data['message'] ?? data['error'] ?? 'Unknown error')
            : 'Request failed with status ${response.statusCode}';
        return ApiResponse.error(errorMessage, statusCode: response.statusCode);
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
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> list = data is List ? data : [];
        final items = list
            .map((item) => fromJson(item as Map<String, dynamic>))
            .toList();
        return ApiResponse.success(items, statusCode: response.statusCode);
      } else {
        final errorMessage = data is Map<String, dynamic>
            ? (data['message'] ?? data['error'] ?? 'Unknown error')
            : 'Request failed with status ${response.statusCode}';
        return ApiResponse.error(errorMessage, statusCode: response.statusCode);
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

      print('GET $uri');

      final response = await http.get(uri, headers: headers).timeout(timeout);
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

      print('POST $uri with body: ${jsonEncode(body)}');

      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(timeout);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
