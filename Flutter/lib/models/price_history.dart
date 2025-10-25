class PropertyPriceHistory {
  final int priceHistoryId;
  final int parentPropertyId;
  final double price;
  final DateTime priceDate;
  final String source; // "AuctionWin", "Listing", "DirectSale"
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

  PropertyPriceHistory copyWith({
    int? priceHistoryId,
    int? parentPropertyId,
    double? price,
    DateTime? priceDate,
    String? source,
    int? auctionId,
    int? childPropertyId,
    DateTime? createdAt,
  }) {
    return PropertyPriceHistory(
      priceHistoryId: priceHistoryId ?? this.priceHistoryId,
      parentPropertyId: parentPropertyId ?? this.parentPropertyId,
      price: price ?? this.price,
      priceDate: priceDate ?? this.priceDate,
      source: source ?? this.source,
      auctionId: auctionId ?? this.auctionId,
      childPropertyId: childPropertyId ?? this.childPropertyId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'PropertyPriceHistory(priceHistoryId: $priceHistoryId, parentPropertyId: $parentPropertyId, price: $price, priceDate: $priceDate, source: $source)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PropertyPriceHistory &&
        other.priceHistoryId == priceHistoryId;
  }

  @override
  int get hashCode => priceHistoryId.hashCode;
}

// Price source constants
class PriceSource {
  static const String auctionWin = 'AuctionWin';
  static const String listing = 'Listing';
  static const String directSale = 'DirectSale';
}
