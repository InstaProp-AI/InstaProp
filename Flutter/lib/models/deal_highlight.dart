class DealHighlight {
  final int auctionId;
  final int propertyId;
  final String propertyName;
  final String? location;
  final String? imageUrl;
  final double startPrice;
  final double currentPrice;
  final double roiPercentage;
  final DateTime endAt;
  final int bidCount;
  final bool isEndingSoon;

  DealHighlight({
    required this.auctionId,
    required this.propertyId,
    required this.propertyName,
    required this.location,
    required this.imageUrl,
    required this.startPrice,
    required this.currentPrice,
    required this.roiPercentage,
    required this.endAt,
    required this.bidCount,
    required this.isEndingSoon,
  });

  factory DealHighlight.fromJson(Map<String, dynamic> json) {
    return DealHighlight(
      auctionId: (json['auctionId'] ?? 0) as int,
      propertyId: (json['propertyId'] ?? 0) as int,
      propertyName: (json['propertyName'] ?? '') as String,
      location: json['location'] as String?,
      imageUrl: json['imageUrl'] as String?,
      startPrice: (json['startPrice'] ?? 0).toDouble(),
      currentPrice: (json['currentPrice'] ?? 0).toDouble(),
      roiPercentage: (json['roiPercentage'] ?? 0).toDouble(),
      endAt: DateTime.parse(
        json['endAt'] ?? DateTime.now().toIso8601String(),
      ),
      bidCount: (json['bidCount'] ?? 0) as int,
      isEndingSoon: (json['isEndingSoon'] ?? false) as bool,
    );
  }
}

