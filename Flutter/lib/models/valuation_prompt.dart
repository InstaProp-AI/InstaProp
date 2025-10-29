class ValuationPrompt {
  final int? propertyId;
  final String? propertyName;
  final String? propertyImageUrl;
  final bool isGeneric;

  ValuationPrompt({
    this.propertyId,
    this.propertyName,
    this.propertyImageUrl,
    required this.isGeneric,
  });

  factory ValuationPrompt.fromJson(Map<String, dynamic> json) {
    return ValuationPrompt(
      propertyId: json['propertyId'],
      propertyName: json['propertyName'],
      propertyImageUrl: json['propertyImageUrl'],
      isGeneric: json['isGeneric'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'propertyName': propertyName,
      'propertyImageUrl': propertyImageUrl,
      'isGeneric': isGeneric,
    };
  }
}

