import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../models/live_stream.dart';
import '../models/stream_chat_message.dart';

class LiveStreamService {
  static Future<ApiResponse<List<LiveStream>>> getActiveStreams() async {
    return ApiClient.getList<LiveStream>(
      '/api/livestream/active',
      LiveStream.fromJson,
    );
  }

  static Future<ApiResponse<LiveStream>> getStream(int streamId) async {
    return ApiClient.get<LiveStream>(
      '/api/livestream/$streamId',
      LiveStream.fromJson,
    );
  }

  static Future<ApiResponse<LiveStream>> startStream({
    required String title,
    String? description,
    required String streamUrl,
    String? thumbnailUrl,
  }) async {
    return ApiClient.post<LiveStream>(
      '/api/livestream/start',
      {
        'title': title,
        'description': description,
        'streamUrl': streamUrl,
        'thumbnailUrl': thumbnailUrl,
      },
      LiveStream.fromJson,
    );
  }

  static Future<ApiResponse<void>> endStream(int streamId) async {
    return ApiClient.post<void>(
      '/api/livestream/end/$streamId',
      {},
      (json) => null,
    );
  }

  static Future<ApiResponse<void>> joinStream(String streamId) async {
    return ApiClient.post<void>(
      '/api/livestream/$streamId/join',
      {},
      (json) => null,
    );
  }

  static Future<ApiResponse<void>> leaveStream(String streamId) async {
    return ApiClient.post<void>(
      '/api/livestream/$streamId/leave',
      {},
      (json) => null,
    );
  }

  static Future<ApiResponse<StreamChatMessage>> sendChatMessage(
    String streamId,
    String message,
  ) async {
    return ApiClient.post<StreamChatMessage>(
      '/api/livestream/$streamId/chat',
      {'message': message},
      StreamChatMessage.fromJson,
    );
  }

  static Future<ApiResponse<List<StreamChatMessage>>> getChatMessages(
    String streamId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    return ApiClient.getList<StreamChatMessage>(
      '/api/livestream/$streamId/chat?page=$page&pageSize=$pageSize',
      StreamChatMessage.fromJson,
    );
  }

  /// Get count of live streams
  static Future<ApiResponse<int>> getLiveStreamCount() async {
    try {
      final token = await ApiClient.getToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final uri = Uri.parse('${ApiClient.baseUrl}/api/livestream/count');
      final response = await http.get(uri, headers: headers).timeout(ApiClient.timeout);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Backend returns int - could be direct number or JSON number
        int count = 0;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is int) {
            count = decoded;
          } else if (decoded is Map<String, dynamic>) {
            count = decoded['data'] as int? ?? decoded['value'] as int? ?? 0;
          } else {
            // Try parsing as direct string
            count = int.tryParse(response.body) ?? 0;
          }
        } catch (e) {
          // If JSON decode fails, try parsing as direct int
          count = int.tryParse(response.body) ?? 0;
        }
        return ApiResponse.success(count, statusCode: response.statusCode);
      } else {
        return ApiResponse.error(
          'Failed to get live stream count',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to get live stream count: $e');
    }
  }

  /// Get all live streams (not just active)
  static Future<ApiResponse<List<LiveStream>>> getAllStreams() async {
    return ApiClient.getList<LiveStream>(
      '/api/livestream/all',
      LiveStream.fromJson,
    );
  }
}

