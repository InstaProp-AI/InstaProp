class PropertyPriceHistory {
  final String priceHistoryId;
  final String parentPropertyId;
  final double price;
  final DateTime priceDate;
  final String source;
  final String? auctionId;
  final String? childPropertyId;
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
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    String? parseOptionalId(dynamic id) {
      if (id == null) return null;
      if (id is String) return id.isEmpty ? null : id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return PropertyPriceHistory(
      priceHistoryId: parseId(json['priceHistoryId']),
      parentPropertyId: parseId(json['parentPropertyId']),
      price: (json['price'] ?? 0).toDouble(),
      priceDate: DateTime.parse(
        json['priceDate'] ?? DateTime.now().toIso8601String(),
      ),
      source: json['source'] ?? '',
      auctionId: parseOptionalId(json['auctionId']),
      childPropertyId: parseOptionalId(json['childPropertyId']),
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

