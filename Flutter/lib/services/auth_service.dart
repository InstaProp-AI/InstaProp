import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  User? _user;
  bool _isLoading = false;

  String? get token => _token;
  User? get user => _user;
  bool get isLoggedIn => _token != null && _user != null;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _token = await ApiClient.getToken();
    if (_token != null) {
      // Try to get user profile to validate token
      final response = await ApiClient.get('/api/User/profile', User.fromJson);
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

  Future<ApiResponse<User>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        '/api/User/login',
        {'email': email, 'password': password},
        (data) {
          _token = data['token'] ?? data['Token'];
          _user = User.fromJson(data['user'] ?? data['User']);
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

  Future<ApiResponse<User>> signup({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String gender,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        '/api/User/signup',
        {
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
          'email': email,
          'gender': gender,
          'hashedPassword': password,
        },
        (data) {
          _token = data['token'] ?? data['Token'];
          _user = User.fromJson(data['user'] ?? data['User']);
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

  Future<void> logout() async {
    _token = null;
    _user = null;
    await ApiClient.setToken(null);
    notifyListeners();
  }

  Future<ApiResponse<User>> updateProfile({
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
      final response = await ApiClient.put('/api/User/${_user!.userId}', {
        'firstName': firstName ?? _user!.firstName,
        'lastName': lastName ?? _user!.lastName,
        'phoneNumber': phoneNumber ?? _user!.phoneNumber,
        'email': email ?? _user!.email,
      }, User.fromJson);

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
