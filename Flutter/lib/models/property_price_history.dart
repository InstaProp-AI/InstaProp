class PropertyPriceHistory {
  final int priceHistoryId;
  final int parentPropertyId;
  final double price;
  final DateTime priceDate;
  final String source;
  final int? auctionId;
  final int? childPropertyId;
  final DateTime createdAt;

  PropertyPriceHistory({
    required this.priceHistoryId,
    required this.parentPropertyId,
    required this.price,
    required this.priceDate,
    required this.source,
    this.auctionId,
    this.childPropertyId,
    required this.createdAt,
  });

  factory PropertyPriceHistory.fromJson(Map<String, dynamic> json) {
    return PropertyPriceHistory(
      priceHistoryId: json['priceHistoryId'] ?? 0,
      parentPropertyId: json['parentPropertyId'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      priceDate: DateTime.parse(
        json['priceDate'] ?? DateTime.now().toIso8601String(),
      ),
      source: json['source'] ?? '',
      auctionId: json['auctionId'],
      childPropertyId: json['childPropertyId'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'priceHistoryId': priceHistoryId,
      'parentPropertyId': parentPropertyId,
      'price': price,
      'priceDate': priceDate.toIso8601String(),
      'source': source,
      'auctionId': auctionId,
      'childPropertyId': childPropertyId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PropertyPriceHistory &&
        other.priceHistoryId == priceHistoryId;
  }

  @override
  int get hashCode => priceHistoryId.hashCode;

  static const String auctionWin = 'AuctionWin';
  static const String listing = 'Listing';
  static const String directSale = 'DirectSale';
}

