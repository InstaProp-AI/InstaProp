import 'api_client.dart';
import '../models/auction.dart';
import '../models/auction_request.dart';

class AuctionService {
  static Future<ApiResponse<List<Auction>>> getAuctions() async {
    return await ApiClient.getList('/api/auction', Auction.fromJson);
  }

  static Future<ApiResponse<Auction>> getAuction(int auctionId) async {
    return await ApiClient.get('/api/auction/$auctionId', Auction.fromJson);
  }

  static Future<ApiResponse<Auction>> createAuction({
    required int propertyId,
    required double startPrice,
    required DateTime startAt,
    required int duration,
  }) async {
    return await ApiClient.post('/api/auction', {
      'propertyId': propertyId,
      'startPrice': startPrice,
      'startAt': startAt.toIso8601String(),
      'duration': duration,
    }, Auction.fromJson);
  }

  static Future<ApiResponse<Auction>> updateAuction({
    required int auctionId,
    double? startPrice,
    DateTime? startAt,
    int? duration,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (startPrice != null) body['startPrice'] = startPrice;
    if (startAt != null) body['startAt'] = startAt.toIso8601String();
    if (duration != null) body['duration'] = duration;
    if (status != null) body['status'] = status;

    return await ApiClient.put(
      '/api/auction/$auctionId',
      body,
      Auction.fromJson,
    );
  }

  static Future<ApiResponse<void>> deleteAuction(int auctionId) async {
    return await ApiClient.delete('/api/auction/$auctionId');
  }

  static Future<ApiResponse<List<Auction>>> getActiveAuctions() async {
    return await ApiClient.getList('/api/auction/active', Auction.fromJson);
  }

  static Future<ApiResponse<List<Auction>>> getUserAuctions() async {
    return await ApiClient.getList('/api/user/auctions', Auction.fromJson);
  }

  static Future<ApiResponse<AuctionRequestResponse>> requestAuction(
    AuctionRequest request,
  ) async {
    return await ApiClient.post(
      '/api/auction/request',
      request.toJson(),
      (data) => AuctionRequestResponse.fromJson(data),
    );
  }

  // Buy now - Purchase property immediately at buy now price
  static Future<ApiResponse<Map<String, dynamic>>> buyNow(int auctionId) async {
    return await ApiClient.post(
      '/api/auction/$auctionId/buynow',
      {},
      (data) => data,
    );
  }
}
