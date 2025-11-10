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

  static Future<ApiResponse<void>> joinStream(int streamId) async {
    return ApiClient.post<void>(
      '/api/livestream/$streamId/join',
      {},
      (json) => null,
    );
  }

  static Future<ApiResponse<void>> leaveStream(int streamId) async {
    return ApiClient.post<void>(
      '/api/livestream/$streamId/leave',
      {},
      (json) => null,
    );
  }

  static Future<ApiResponse<StreamChatMessage>> sendChatMessage(
    int streamId,
    String message,
  ) async {
    return ApiClient.post<StreamChatMessage>(
      '/api/livestream/$streamId/chat',
      {'message': message},
      StreamChatMessage.fromJson,
    );
  }

  static Future<ApiResponse<List<StreamChatMessage>>> getChatMessages(
    int streamId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    return ApiClient.getList<StreamChatMessage>(
      '/api/livestream/$streamId/chat?page=$page&pageSize=$pageSize',
      StreamChatMessage.fromJson,
    );
  }
}

