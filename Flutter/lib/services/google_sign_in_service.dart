import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../models/user.dart';

class GoogleSignInService {
  // Google OAuth 2.0 Client ID
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId:
        '278402764609-6lgm1herr8pjljb94fcmv6ea25fjeqe0.apps.googleusercontent.com',
  );

  // Sign in with Google
  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      // Attempt to sign in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return GoogleSignInResult.error('Sign-in cancelled by user');
      }

      // Get user details
      final String? email = googleUser.email;
      final String googleId = googleUser.id;
      final List<String> nameParts =
          googleUser.displayName?.split(' ') ?? ['', ''];
      final String firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final String lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      // Send to our backend
      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/api/account/google-auth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'googleId': googleId,
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] ?? data['Token'];
        final account = Account.fromJson(data['account'] ?? data['Account']);
        final requiresProfileCompletion =
            data['requiresProfileCompletion'] ?? false;

        // Save token
        await ApiClient.setToken(token);

        return GoogleSignInResult.success(
          account: account,
          token: token,
          requiresProfileCompletion: requiresProfileCompletion,
        );
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        return GoogleSignInResult.error(data['message'] ?? 'Account suspended');
      } else {
        return GoogleSignInResult.error(
          'Failed to authenticate: ${response.body}',
        );
      }
    } catch (e) {
      // Better error messages for common issues
      final errorMsg = e.toString();
      if (errorMsg.contains('CLIENT_ID') || errorMsg.contains('client')) {
        return GoogleSignInResult.error(
          'Google Sign-In not configured. Please add your OAuth Client ID in google_sign_in_service.dart',
        );
      } else if (errorMsg.contains('PlatformException')) {
        return GoogleSignInResult.error(
          'Platform configuration error. Check Google Sign-In setup for web.',
        );
      } else if (errorMsg.contains('network')) {
        return GoogleSignInResult.error(
          'Network error. Please check your internet connection.',
        );
      }
      return GoogleSignInResult.error('Sign-in failed: $errorMsg');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  // Check if user is signed in
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  // Get current user
  GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }
}

// Result class for Google Sign-In
class GoogleSignInResult {
  final bool success;
  final String? error;
  final Account? account;
  final String? token;
  final bool requiresProfileCompletion;

  GoogleSignInResult({
    required this.success,
    this.error,
    this.account,
    this.token,
    this.requiresProfileCompletion = false,
  });

  factory GoogleSignInResult.success({
    required Account account,
    required String token,
    bool requiresProfileCompletion = false,
  }) {
    return GoogleSignInResult(
      success: true,
      account: account,
      token: token,
      requiresProfileCompletion: requiresProfileCompletion,
    );
  }

  factory GoogleSignInResult.error(String error) {
    return GoogleSignInResult(success: false, error: error);
  }
}
