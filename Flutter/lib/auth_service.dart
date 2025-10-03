import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class AuthState extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;

  bool get isLoggedIn => _token != null;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  Future<void> init() async {
    _token = await api.getToken();
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    try {
      final res = await api.post('/api/User/login', {
        'email': email,
        'password': password,
      });

      print('Login response status: ${res.statusCode}');
      print('Login response body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _token = data['token'] as String?;
        _user = data['user'] as Map<String, dynamic>?;
        await api.setToken(_token);
        notifyListeners();
        return _token;
      } else {
        print('Login failed with status: ${res.statusCode}');
        return null;
      }
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<String?> signup(Map<String, dynamic> payload) async {
    try {
      final res = await api.post('/api/User/signup', payload);

      print('Signup response status: ${res.statusCode}');
      print('Signup response body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _token = data['token'] as String?;
        _user = data['user'] as Map<String, dynamic>?;
        await api.setToken(_token);
        notifyListeners();
        return _token;
      } else {
        print('Signup failed with status: ${res.statusCode}');
        return null;
      }
    } catch (e) {
      print('Signup error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await api.setToken(null);
    notifyListeners();
  }
}

final authState = AuthState();
