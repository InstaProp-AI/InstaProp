import 'api_client.dart';
import '../models/auction.dart';

class AuctionService {
  static Future<ApiResponse<List<Auction>>> getAuctions() async {
    return await ApiClient.getList('/api/auction', Auction.fromJson);
  }

  static Future<ApiResponse<Auction>> getAuction(int auctionId) async {
    return await ApiClient.get('/api/auction/$auctionId', Auction.fromJson);
  }

  static Future<ApiResponse<Auction>> createAuction({
    required int propertyId,
    required double startAt,
    required DateTime endAt,
    required int duration,
    double? buyNowPrice,
  }) async {
    return await ApiClient.post('/api/auction', {
      'propertyId': propertyId,
      'startAt': startAt,
      'endAt': endAt.toIso8601String(),
      'duration': duration,
      'buyNowPrice': buyNowPrice,
    }, Auction.fromJson);
  }

  static Future<ApiResponse<Auction>> updateAuction({
    required int auctionId,
    double? startAt,
    DateTime? endAt,
    int? duration,
    double? buyNowPrice,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (startAt != null) body['startAt'] = startAt;
    if (endAt != null) body['endAt'] = endAt.toIso8601String();
    if (duration != null) body['duration'] = duration;
    if (buyNowPrice != null) body['buyNowPrice'] = buyNowPrice;
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
}
