import 'api_client.dart';

class VerificationService {
  // Send Email Verification PIN
  Future<ApiResponse<bool>> sendEmailVerification() async {
    try {
      final response = await ApiClient.post(
        '/api/Account/send-email-verification',
        {},
        (data) => true,
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to send email verification: $e');
    }
  }

  // Verify Email with PIN
  Future<ApiResponse<bool>> verifyEmail(String pin) async {
    try {
      final response = await ApiClient.post<bool>(
        '/api/Account/verify-email',
        {'pin': pin},
        (data) => data['emailVerified'] as bool? ?? true,
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to verify email: $e');
    }
  }

  // Send Phone Verification PIN
  Future<ApiResponse<bool>> sendPhoneVerification() async {
    try {
      final response = await ApiClient.post(
        '/api/Account/send-phone-verification',
        {},
        (data) => true,
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to send phone verification: $e');
    }
  }

  // Verify Phone with PIN
  Future<ApiResponse<bool>> verifyPhone(String pin) async {
    try {
      final response = await ApiClient.post<bool>(
        '/api/Account/verify-phone',
        {'pin': pin},
        (data) => data['phoneVerified'] as bool? ?? true,
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to verify phone: $e');
    }
  }
}
