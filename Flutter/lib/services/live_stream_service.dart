import 'api_client.dart';
import '../models/live_stream.dart';

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
}

