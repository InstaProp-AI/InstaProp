class AuctionRequest {
  final int propertyId;
  final double startPrice;
  final DateTime startAt;
  final int duration; // hours

  AuctionRequest({
    required this.propertyId,
    required this.startPrice,
    required this.startAt,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'startPrice': startPrice,
      'startAt': startAt.toIso8601String(),
      'duration': duration,
    };
  }

  factory AuctionRequest.fromJson(Map<String, dynamic> json) {
    return AuctionRequest(
      propertyId: json['propertyId'] ?? json['PropertyId'] ?? 0,
      startPrice: (json['startPrice'] ?? json['StartPrice'] ?? 0).toDouble(),
      startAt: DateTime.parse(
        json['startAt'] ?? json['StartAt'] ?? DateTime.now().toIso8601String(),
      ),
      duration: json['duration'] ?? json['Duration'] ?? 0,
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
