import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;
  final Map<String, dynamic>? errorData;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
    this.errorData,
  });

  factory ApiResponse.success(T data, {int statusCode = 200}) {
    return ApiResponse(success: true, data: data, statusCode: statusCode);
  }

  factory ApiResponse.error(
    String error, {
    int statusCode = 400,
    Map<String, dynamic>? data,
  }) {
    return ApiResponse(
      success: false,
      error: error,
      statusCode: statusCode,
      errorData: data,
    );
  }
}

class ApiClient {
  // ⚙️ CONFIGURATION - Change this one line based on your setup:
  // For physical phone on same network: use your computer's IP (run: ifconfig | grep "inet ")
  // For Android emulator: use 'http://10.0.2.2:5284'
  // For iOS simulator or localhost: use 'http://localhost:5284'

  // 🔧 Auto-detect best URL based on platform
  static String get baseUrl {
    // Check if running on physical device or emulator
    if (kIsWeb) {
      return 'http://localhost:5284';
    } else if (Platform.isAndroid) {
      // Try to detect if it's emulator or physical device
      // For physical device, use Mac's IP
      return 'http://192.168.1.16:5284';
      // For emulator, uncomment: return 'http://10.0.2.2:5284';
    } else if (Platform.isIOS) {
      // For iOS simulator
      return 'http://localhost:5284';
      // For physical iOS device, use: return 'http://192.168.1.16:5284';
    }
    return 'http://localhost:5284';
  }

  // Quick reference:
  // Physical device (same WiFi): 'http://192.168.1.235:5284'
  // Android emulator:            'http://10.0.2.2:5284'
  // iOS simulator/localhost:     'http://localhost:5284'

  static const Duration timeout = Duration(seconds: 60);

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
        // Handle empty response body (e.g., 204 No Content)
        if (response.body.isEmpty || response.statusCode == 204) {
          return ApiResponse.success(
            fromJson({}),
            statusCode: response.statusCode,
          );
        }

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

  // Upload files with multipart/form-data
  static Future<ApiResponse<T>> postMultipart<T>(
    String endpoint,
    List<File> files, {
    Map<String, String>? fields,
    String fileFieldName = 'images',
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final token = await getToken();

      print('🌐 POST (Multipart) $uri');
      print('📡 Base URL: $baseUrl');
      print('📤 Files count: ${files.length}');

      var request = http.MultipartRequest('POST', uri);

      // Add authorization header
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add files
      for (var file in files) {
        var stream = http.ByteStream(file.openRead());
        var length = await file.length();
        var multipartFile = http.MultipartFile(
          fileFieldName,
          stream,
          length,
          filename: file.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      // Add additional fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      var streamedResponse = await request.send().timeout(timeout);
      var response = await http.Response.fromStream(streamedResponse);

      print('✅ Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (fromJson != null) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            return ApiResponse.success(
              fromJson(data),
              statusCode: response.statusCode,
            );
          }
        }
        return ApiResponse.success(null as T, statusCode: response.statusCode);
      } else {
        final data = jsonDecode(response.body);
        final errorMessage = data is Map<String, dynamic>
            ? (data['message'] ?? data['error'] ?? 'Unknown error')
            : 'Request failed with status ${response.statusCode}';
        return ApiResponse.error(errorMessage, statusCode: response.statusCode);
      }
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

  // Upload a file using bytes (works on both web and mobile)
  static Future<ApiResponse<T>> uploadFileBytes<T>(
    String endpoint,
    String fieldName,
    List<int> fileBytes,
    String fileName, {
    Map<String, String>? additionalFields,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final token = await getToken();

      print('🌐 POST (Upload File Bytes) $uri');
      print('📡 Base URL: $baseUrl');
      print('📤 File: $fileName (${fileBytes.length} bytes)');

      var request = http.MultipartRequest('POST', uri);

      // Add authorization header
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add file from bytes
      request.files.add(
        http.MultipartFile.fromBytes(fieldName, fileBytes, filename: fileName),
      );

      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      var streamedResponse = await request.send().timeout(timeout);
      var response = await http.Response.fromStream(streamedResponse);

      print('✅ Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return ApiResponse.success(
            fromJson(data),
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.error(
          'Invalid response format',
          statusCode: response.statusCode,
        );
      } else {
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

  // Upload PlatformFiles with multipart/form-data (works on both web and mobile)
  static Future<ApiResponse<T>> postMultipartPlatformFiles<T>(
    String endpoint,
    List<PlatformFile> files, {
    Map<String, String>? fields,
    String fileFieldName = 'images',
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final token = await getToken();

      print('🌐 POST (Multipart) $uri');
      print('📡 Base URL: $baseUrl');
      print('📤 Files count: ${files.length}');

      var request = http.MultipartRequest('POST', uri);

      // Add authorization header
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add files - handle both web and mobile
      for (var file in files) {
        if (kIsWeb) {
          // For web, use bytes
          if (file.bytes != null) {
            var multipartFile = http.MultipartFile.fromBytes(
              fileFieldName,
              file.bytes!,
              filename: file.name,
            );
            request.files.add(multipartFile);
          }
        } else {
          // For mobile, use path
          if (file.path != null) {
            var multipartFile = await http.MultipartFile.fromPath(
              fileFieldName,
              file.path!,
              filename: file.name,
            );
            request.files.add(multipartFile);
          }
        }
      }

      // Add additional fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      var streamedResponse = await request.send().timeout(timeout);
      var response = await http.Response.fromStream(streamedResponse);

      print('✅ Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (fromJson != null) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            return ApiResponse.success(
              fromJson(data),
              statusCode: response.statusCode,
            );
          }
        }
        return ApiResponse.success(null as T, statusCode: response.statusCode);
      } else {
        final data = jsonDecode(response.body);
        final errorMessage = data is Map<String, dynamic>
            ? (data['message'] ?? data['error'] ?? 'Unknown error')
            : 'Request failed with status ${response.statusCode}';
        return ApiResponse.error(errorMessage, statusCode: response.statusCode);
      }
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
}
