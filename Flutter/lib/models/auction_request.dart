class AuctionRequest {
  final int propertyId;
  final double startAt;
  final DateTime endAt;
  final int duration; // hours
  final double? buyNowPrice;

  AuctionRequest({
    required this.propertyId,
    required this.startAt,
    required this.endAt,
    required this.duration,
    this.buyNowPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'startAt': startAt,
      'endAt': endAt.toIso8601String(),
      'duration': duration,
      'buyNowPrice': buyNowPrice,
    };
  }

  factory AuctionRequest.fromJson(Map<String, dynamic> json) {
    return AuctionRequest(
      propertyId: json['propertyId'] ?? json['PropertyId'] ?? 0,
      startAt: (json['startAt'] ?? json['StartAt'] ?? 0).toDouble(),
      endAt: DateTime.parse(
        json['endAt'] ?? json['EndAt'] ?? DateTime.now().toIso8601String(),
      ),
      duration: json['duration'] ?? json['Duration'] ?? 0,
      buyNowPrice: json['buyNowPrice'] != null || json['BuyNowPrice'] != null
          ? (json['buyNowPrice'] ?? json['BuyNowPrice']).toDouble()
          : null,
    );
  }
}

class AuctionRequestResponse {
  final bool success;
  final String message;
  final int? auctionId;

  AuctionRequestResponse({
    required this.success,
    required this.message,
    this.auctionId,
  });

  factory AuctionRequestResponse.fromJson(Map<String, dynamic> json) {
    return AuctionRequestResponse(
      success: json['auctionId'] != null, // Success if auctionId is present
      message: json['message'] ?? '',
      auctionId: json['auctionId'],
    );
  }
}
