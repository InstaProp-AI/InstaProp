import 'api_client.dart';
import '../models/bid.dart';

class BidService {
  static Future<ApiResponse<List<Bid>>> getBids(int auctionId) async {
    return await ApiClient.getList(
      '/api/bids/by-auction/$auctionId',
      Bid.fromJson,
    );
  }

  static Future<ApiResponse<Bid>> placeBid({
    required int auctionId,
    required double bidAmount,
  }) async {
    return await ApiClient.post('/api/bids', {
      'auctionId': auctionId,
      'bidAmount': bidAmount,
    }, Bid.fromJson);
  }

  static Future<ApiResponse<List<Bid>>> getUserBids() async {
    return await ApiClient.getList('/api/bids/user', Bid.fromJson);
  }

  static Future<ApiResponse<Bid>> getBid(int bidId) async {
    return await ApiClient.get('/api/bids/$bidId', Bid.fromJson);
  }

  static Future<ApiResponse<void>> retractBid(int bidId) async {
    return await ApiClient.delete('/api/bids/$bidId');
  }
}
