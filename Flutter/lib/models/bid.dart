import 'user.dart';
import 'auction.dart';

class Bid {
  final String bidId;
  final String auctionId;
  final String bidderId;
  final Account? bidder;
  final double bidAmount;
  final DateTime createdAt;
  final Auction? auction;

  Bid({
    required this.bidId,
    required this.auctionId,
    required this.bidderId,
    this.bidder,
    required this.bidAmount,
    required this.createdAt,
    this.auction,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    Auction? parseAuction() {
      try {
        final dynamic auctionData = json['auction'] ?? json['Auction'];
        if (auctionData is Map<String, dynamic>) {
          return Auction.fromJson(auctionData);
        }
      } catch (e) {
        print('⚠️ Error parsing auction in bid: $e');
      }
      return null;
    }

    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return Bid(
      bidId: parseId(json['bidId'] ?? json['BidId']),
      auctionId: parseId(json['auctionId'] ?? json['AuctionId']),
      bidderId: parseId(json['bidderId'] ?? json['BidderId']),
      bidder: json['bidder'] != null || json['Bidder'] != null
          ? Account.fromJson(json['bidder'] ?? json['Bidder'])
          : null,
      bidAmount: (json['bidAmount'] ?? json['BidAmount'] ?? 0).toDouble(),
      createdAt: DateTime.parse(
        json['createdAt'] ??
            json['CreatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
      auction: parseAuction(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bidId': bidId,
      'auctionId': auctionId,
      'bidderId': bidderId,
      'bidder': bidder?.toJson(),
      'bidAmount': bidAmount,
      'createdAt': createdAt.toIso8601String(),
      'auction': auction?.toJson(),
    };
  }
}
