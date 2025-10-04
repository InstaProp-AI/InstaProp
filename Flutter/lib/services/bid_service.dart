import 'api_client.dart';
import '../models/bid.dart';

class BidService {
  static Future<ApiResponse<List<Bid>>> getBids(int auctionId) async {
    return await ApiClient.getList(
      '/api/auction/$auctionId/bids',
      Bid.fromJson,
    );
  }

  static Future<ApiResponse<Bid>> placeBid({
    required int auctionId,
    required double bidAmount,
  }) async {
    return await ApiClient.post('/api/bid', {
      'auctionId': auctionId,
      'bidAmount': bidAmount,
    }, Bid.fromJson);
  }

  static Future<ApiResponse<List<Bid>>> getUserBids() async {
    return await ApiClient.getList('/api/user/bids', Bid.fromJson);
  }

  static Future<ApiResponse<Bid>> getBid(int bidId) async {
    return await ApiClient.get('/api/bid/$bidId', Bid.fromJson);
  }

  static Future<ApiResponse<void>> retractBid(int bidId) async {
    return await ApiClient.delete('/api/bid/$bidId');
  }
}
