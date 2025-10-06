import 'account.dart';

class Bid {
  final int bidId;
  final int auctionId;
  final int bidderId;
  final Account? bidder;
  final double bidAmount;
  final DateTime createdAt;

  Bid({
    required this.bidId,
    required this.auctionId,
    required this.bidderId,
    this.bidder,
    required this.bidAmount,
    required this.createdAt,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      bidId: json['bidId'] ?? json['BidId'] ?? 0,
      auctionId: json['auctionId'] ?? json['AuctionId'] ?? 0,
      bidderId: json['bidderId'] ?? json['BidderId'] ?? 0,
      bidder: json['bidder'] != null || json['Bidder'] != null
          ? Account.fromJson(json['bidder'] ?? json['Bidder'])
          : null,
      bidAmount: (json['bidAmount'] ?? json['BidAmount'] ?? 0).toDouble(),
      createdAt: DateTime.parse(
        json['createdAt'] ??
            json['CreatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
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
    };
  }
}
