import 'property.dart';
import 'bid.dart';

class Auction {
  final int auctionId;
  final int propertyId;
  final Property? property;
  final double startAt;
  final double currentPrice;
  final DateTime endAt;
  final int duration;
  final double? buyNowPrice;
  final int bidCount;
  final String status;
  final DateTime createdAt;
  final List<Bid> bids;

  Auction({
    required this.auctionId,
    required this.propertyId,
    this.property,
    required this.startAt,
    required this.currentPrice,
    required this.endAt,
    required this.duration,
    this.buyNowPrice,
    required this.bidCount,
    required this.status,
    required this.createdAt,
    this.bids = const [],
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    return Auction(
      auctionId: json['auctionId'] ?? json['AuctionId'] ?? 0,
      propertyId: json['propertyId'] ?? json['PropertyId'] ?? 0,
      property: json['property'] != null || json['Property'] != null
          ? Property.fromJson(json['property'] ?? json['Property'])
          : null,
      startAt: (json['startAt'] ?? json['StartAt'] ?? 0).toDouble(),
      currentPrice: (json['currentPrice'] ?? json['CurrentPrice'] ?? 0)
          .toDouble(),
      endAt: DateTime.parse(
        json['endAt'] ?? json['EndAt'] ?? DateTime.now().toIso8601String(),
      ),
      duration: json['duration'] ?? json['Duration'] ?? 0,
      buyNowPrice: json['buyNowPrice'] != null || json['BuyNowPrice'] != null
          ? (json['buyNowPrice'] ?? json['BuyNowPrice']).toDouble()
          : null,
      bidCount: json['bidCount'] ?? json['BidCount'] ?? 0,
      status: json['status'] ?? json['Status'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ??
            json['CreatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
      bids: (json['bids'] ?? json['Bids'] ?? [])
          .map<Bid>((bid) => Bid.fromJson(bid))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auctionId': auctionId,
      'propertyId': propertyId,
      'property': property?.toJson(),
      'startAt': startAt,
      'currentPrice': currentPrice,
      'endAt': endAt.toIso8601String(),
      'duration': duration,
      'buyNowPrice': buyNowPrice,
      'bidCount': bidCount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'bids': bids.map((bid) => bid.toJson()).toList(),
    };
  }

  bool get isActive => status == 'Active' && DateTime.now().isBefore(endAt);

  bool get isEnded => DateTime.now().isAfter(endAt);

  String get timeRemaining {
    if (isEnded) return 'Ended';
    final remaining = endAt.difference(DateTime.now());
    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else {
      return '${remaining.inMinutes}m';
    }
  }
}
