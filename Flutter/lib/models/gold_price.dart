class GoldPrice {
  final int goldPriceId;
  final double pricePerGram;
  final int month;
  final int year;
  final DateTime date;
  final String source;
  final DateTime createdAt;

  GoldPrice({
    required this.goldPriceId,
    required this.pricePerGram,
    required this.month,
    required this.year,
    required this.date,
    required this.source,
    required this.createdAt,
  });

  factory GoldPrice.fromJson(Map<String, dynamic> json) {
    return GoldPrice(
      goldPriceId: json['goldPriceId'] ?? 0,
      pricePerGram: (json['pricePerGram'] ?? 0).toDouble(),
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      source: json['source'] ?? 'Manual',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goldPriceId': goldPriceId,
      'pricePerGram': pricePerGram,
      'month': month,
      'year': year,
      'date': date.toIso8601String(),
      'source': source,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoldPrice && other.goldPriceId == goldPriceId;
  }

  @override
  int get hashCode => goldPriceId.hashCode;

  static const String api = 'API';
  static const String manual = 'Manual';
  static const String simulated = 'Simulated';
}
