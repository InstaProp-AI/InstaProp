import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  Account? _user;
  bool _isLoading = false;

  String? get token => _token;
  Account? get user => _user;
  bool get isLoggedIn => _token != null && _user != null;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _token = await ApiClient.getToken();
    if (_token != null) {
      // Try to get user profile to validate token
      final response = await ApiClient.get('/api/account/me', Account.fromJson);
      if (response.success && response.data != null) {
        _user = response.data;
      } else {
        // Token is invalid, clear it
        await logout();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<ApiResponse<Account>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        '/api/account/login',
        {'email': email, 'password': password},
        (data) {
          _token = data['token'] ?? data['Token'];
          _user = Account.fromJson(data['account'] ?? data['Account']);
          return _user!;
        },
      );

      if (response.success) {
        await ApiClient.setToken(_token);
        notifyListeners();
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse.error('Login failed: $e');
    }
  }

  Future<ApiResponse<Account>> signup({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        '/api/account/signup',
        {
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
          'email': email,
          'password': password,
          'type': 0, // User AccountType enum value
        },
        (data) {
          _token = data['token'] ?? data['Token'];
          _user = Account.fromJson(data['account'] ?? data['Account']);
          return _user!;
        },
      );

      if (response.success) {
        await ApiClient.setToken(_token);
        notifyListeners();
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse.error('Signup failed: $e');
    }
  }

  Future<ApiResponse<String>> uploadKycFile({
    required String filePath,
    required String docType,
  }) async {
    try {
      final uri = Uri.parse('${ApiClient.baseUrl}/api/account/upload-file');
      final token = await ApiClient.getToken();

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['docType'] = docType;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data['url'] as String);
      } else {
        return ApiResponse.error('Upload failed: ${response.body}');
      }
    } catch (e) {
      return ApiResponse.error('Failed to upload file: $e');
    }
  }

  Future<ApiResponse<bool>> uploadKycDocuments({
    required List<Map<String, String>> kycDocuments,
  }) async {
    try {
      final response = await ApiClient.post('/api/account/upload-kyc', {
        'kycDocuments': kycDocuments,
      }, (data) => true);
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to upload KYC documents: $e');
    }
  }

  Future<ApiResponse<Account>> getCurrentUser() async {
    try {
      final response = await ApiClient.get('/api/account/me', Account.fromJson);
      if (response.success && response.data != null) {
        _user = response.data;
        notifyListeners();
      }
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get current user: $e');
    }
  }

  Future<ApiResponse<bool>> checkEmailExists(String email) async {
    try {
      final response = await ApiClient.get(
        '/api/account/check-email?email=${Uri.encodeComponent(email)}',
        (data) => data['exists'] as bool,
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to check email: $e');
    }
  }

  Future<ApiResponse<bool>> checkPhoneExists(String phone) async {
    try {
      final response = await ApiClient.get(
        '/api/account/check-phone?phone=${Uri.encodeComponent(phone)}',
        (data) => data['exists'] as bool,
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to check phone: $e');
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await ApiClient.setToken(null);
    notifyListeners();
  }

  Future<ApiResponse<Account>> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
  }) async {
    if (_user == null) {
      return ApiResponse.error('User not logged in');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.put('/api/account/current', {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'email': email,
      }, Account.fromJson);

      if (response.success && response.data != null) {
        _user = response.data;
        notifyListeners();
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse.error('Profile update failed: $e');
    }
  }
}
