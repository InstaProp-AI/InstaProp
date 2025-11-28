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
      bidAmount: _parseDouble(json['bidAmount'] ?? json['BidAmount'], defaultValue: 0.0),
      createdAt: _parseDateTime(
        json['createdAt'] ?? json['CreatedAt'],
        defaultValue: DateTime.now(),
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

  // Helper to safely parse double from double, int, or string
  static double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('⚠️ Failed to parse double from string: $value');
        return defaultValue;
      }
    }
    return defaultValue;
  }

  // Helper to safely parse DateTime from string or DateTime
  static DateTime _parseDateTime(dynamic value, {required DateTime defaultValue}) {
    if (value == null) return defaultValue;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('⚠️ Failed to parse DateTime from string: $value');
        return defaultValue;
      }
    }
    return defaultValue;
  }
}
