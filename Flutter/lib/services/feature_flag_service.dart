import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

/// Fetches feature flags from GET /api/flags on app startup.
/// If the request fails for any reason, returns an empty map —
/// AppState defaults missing keys to true, so the app runs normally.
class FeatureFlagService {
  static Future<Map<String, bool>> fetchFlags() async {
    try {
      final uri = Uri.parse('${ApiClient.baseUrl}/api/flags');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(key, value == true));
      }
      return {};
    } catch (_) {
      // Network error, timeout, or parse failure — safe default: empty map
      return {};
    }
  }
}
