class AuctionRequest {
  final String propertyId;
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
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return AuctionRequest(
      propertyId: parseId(json['propertyId'] ?? json['PropertyId']),
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
  final String? auctionId;

  AuctionRequestResponse({
    required this.success,
    required this.message,
    this.auctionId,
  });

  factory AuctionRequestResponse.fromJson(Map<String, dynamic> json) {
    // Helper to parse optional ID fields (handle both string GUID and int legacy formats)
    String? parseOptionalId(dynamic id) {
      if (id == null) return null;
      if (id is String) return id.isEmpty ? null : id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return AuctionRequestResponse(
      success: json['auctionId'] != null, // Success if auctionId is present
      message: json['message'] ?? '',
      auctionId: parseOptionalId(json['auctionId']),
    );
  }
}
