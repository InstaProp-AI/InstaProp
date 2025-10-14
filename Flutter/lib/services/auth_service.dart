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
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/api/account/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 403) {
        // Account is suspended
        final errorData = jsonDecode(response.body);
        _isLoading = false;
        notifyListeners();
        return ApiResponse.error(
          errorData['message'] ?? 'Account is suspended',
          statusCode: 403,
          data: errorData,
        );
      }

      if (response.statusCode == 423) {
        // Account is locked
        final errorData = jsonDecode(response.body);
        _isLoading = false;
        notifyListeners();
        return ApiResponse.error(
          errorData['message'] ??
              'Account is locked. Please try again later or reset your password.',
          statusCode: 423,
          data: errorData,
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'] ?? data['Token'];
        _user = Account.fromJson(data['account'] ?? data['Account']);
        await ApiClient.setToken(_token);

        _isLoading = false;
        notifyListeners();
        return ApiResponse.success(_user!);
      }

      // Handle other error responses by parsing JSON
      _isLoading = false;
      notifyListeners();

      try {
        final errorData = jsonDecode(response.body);
        String errorMessage =
            errorData['message'] ?? 'Invalid email or password';

        // Check for attempts remaining
        if (errorData['attemptsRemaining'] != null ||
            errorData['AttemptsRemaining'] != null) {
          final attempts =
              errorData['attemptsRemaining'] ?? errorData['AttemptsRemaining'];
          if (attempts is int && attempts > 0) {
            errorMessage =
                '$errorMessage. $attempts attempt${attempts > 1 ? 's' : ''} remaining.';
          }
        }

        return ApiResponse.error(errorMessage, statusCode: response.statusCode);
      } catch (e) {
        // If JSON parsing fails, return generic error
        return ApiResponse.error(
          'Invalid email or password',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse.error(
        'Login failed. Please check your connection and try again.',
      );
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

  // KYC document upload is now handled by KycService
  // This keeps auth_service focused on authentication only

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

  Future<ApiResponse<String>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/api/account/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: data['message'] ?? 'Password reset email sent',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          'Failed to send password reset email',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Error: $e', statusCode: 500);
    }
  }

  Future<ApiResponse<String>> forceChangePassword({
    String? oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final token = await ApiClient.getToken();
      if (token == null) {
        return ApiResponse.error('Not authenticated', statusCode: 401);
      }

      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/api/account/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (oldPassword != null) 'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );

      if (response.statusCode == 200) {
        // Update user to reflect password change
        if (_user != null) {
          final userResponse = await ApiClient.get(
            '/api/account/me',
            Account.fromJson,
          );
          if (userResponse.success && userResponse.data != null) {
            _user = userResponse.data;
            notifyListeners();
          }
        }

        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: data['message'] ?? 'Password changed successfully',
          statusCode: response.statusCode,
        );
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse.error(
          data['message'] ?? 'Failed to change password',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Error: $e', statusCode: 500);
    }
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

  Future<ApiResponse<bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_user == null) {
      return ApiResponse.error('User not logged in');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.put('/api/account/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }, (data) => true);

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse.error('Password change failed: $e');
    }
  }
}
