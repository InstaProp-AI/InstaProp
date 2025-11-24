import 'property.dart';
import 'bid.dart';

class Auction {
  final String auctionId;
  final String propertyId;
  final Property? property;
  final double startPrice;
  final double currentPrice;
  final DateTime startAt;
  final int duration;
  final int bidCount;
  final String status;
  final DateTime createdAt;
  final List<Bid> bids;
  final double? cashToClose;
  final String? masterPlanUrl;

  Auction({
    required this.auctionId,
    required this.propertyId,
    this.property,
    required this.startPrice,
    required this.currentPrice,
    required this.startAt,
    required this.duration,
    required this.bidCount,
    required this.status,
    required this.createdAt,
    this.bids = const [],
    this.cashToClose,
    this.masterPlanUrl,
  });

  // Calculated property: EndAt = StartAt + Duration
  DateTime get endAt => startAt.add(Duration(hours: duration));

  factory Auction.fromJson(Map<String, dynamic> json) {
    Property? parseProperty() {
      try {
        if (json['property'] != null || json['Property'] != null) {
          final propertyData = json['property'] ?? json['Property'];
          if (propertyData is Map<String, dynamic>) {
            return Property.fromJson(propertyData);
          }
        }
      } catch (e) {
        print('⚠️ Error parsing property in auction: $e');
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

    return Auction(
      auctionId: parseId(json['auctionId'] ?? json['AuctionId']),
      propertyId: parseId(json['propertyId'] ?? json['PropertyId']),
      property: parseProperty(),
      startPrice: (json['startPrice'] ?? json['StartPrice'] ?? 0).toDouble(),
      currentPrice: (json['currentPrice'] ?? json['CurrentPrice'] ?? 0)
          .toDouble(),
      startAt: DateTime.parse(
        json['startAt'] ?? json['StartAt'] ?? DateTime.now().toIso8601String(),
      ),
      duration: json['duration'] ?? json['Duration'] ?? 0,
      bidCount: json['bidCount'] ?? json['BidCount'] ?? 0,
      status: json['status'] ?? json['Status'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ??
            json['CreatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
      bids: (() {
        final dynamic raw = json['bids'] ?? json['Bids'] ?? [];
        if (raw is List) {
          return raw
              .where((e) => e is Map<String, dynamic>)
              .map<Bid>((e) => Bid.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <Bid>[];
      })(),
      cashToClose: _parseOptionalNumber(json['cashToClose'] ?? json['CashToClose']),
      masterPlanUrl: json['masterPlanUrl'] ?? json['MasterPlanUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auctionId': auctionId,
      'propertyId': propertyId,
      'property': property?.toJson(),
      'startPrice': startPrice,
      'currentPrice': currentPrice,
      'startAt': startAt.toIso8601String(),
      'duration': duration,
      'bidCount': bidCount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'bids': bids.map((bid) => bid.toJson()).toList(),
      if (cashToClose != null) 'cashToClose': cashToClose,
      if (masterPlanUrl != null) 'masterPlanUrl': masterPlanUrl,
    };
  }

  // Auction is active only if: status is Active, has started, and hasn't ended
  bool get isActive =>
      status == 'Active' &&
      DateTime.now().isAfter(startAt) &&
      DateTime.now().isBefore(endAt);

  // Auction is upcoming if: approved and hasn't started yet
  bool get isUpcoming =>
      (status == 'Active' || status == 'Approved') &&
      DateTime.now().isBefore(startAt);

  bool get isEnded => DateTime.now().isAfter(endAt);

  String get timeRemaining {
    if (isEnded) return 'Ended';

    // For upcoming auctions, show time until start
    if (isUpcoming) {
      final untilStart = startAt.difference(DateTime.now());
      if (untilStart.inDays > 0) {
        return 'Starts in ${untilStart.inDays}d ${untilStart.inHours % 24}h';
      } else if (untilStart.inHours > 0) {
        return 'Starts in ${untilStart.inHours}h ${untilStart.inMinutes % 60}m';
      } else if (untilStart.inMinutes > 0) {
        return 'Starts in ${untilStart.inMinutes}m';
      } else {
        return 'Starting soon';
      }
    }

    // For active auctions, show time until end
    final remaining = endAt.difference(DateTime.now());

    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m ${remaining.inSeconds % 60}s';
    } else {
      return '${remaining.inSeconds}s';
    }
  }

  Auction copyWith({
    String? auctionId,
    String? propertyId,
    Property? property,
    double? startPrice,
    double? currentPrice,
    DateTime? startAt,
    int? duration,
    int? bidCount,
    String? status,
    DateTime? createdAt,
    List<Bid>? bids,
    double? cashToClose,
    String? masterPlanUrl,
  }) {
    return Auction(
      auctionId: auctionId ?? this.auctionId,
      propertyId: propertyId ?? this.propertyId,
      property: property ?? this.property,
      startPrice: startPrice ?? this.startPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      startAt: startAt ?? this.startAt,
      duration: duration ?? this.duration,
      bidCount: bidCount ?? this.bidCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      bids: bids ?? this.bids,
      cashToClose: cashToClose ?? this.cashToClose,
      masterPlanUrl: masterPlanUrl ?? this.masterPlanUrl,
    );
  }

  static double? _parseOptionalNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }
}
