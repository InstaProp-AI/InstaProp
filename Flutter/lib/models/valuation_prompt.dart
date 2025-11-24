class ValuationPrompt {
  final String? propertyId;
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
    // Helper to parse optional ID fields (handle both string GUID and int legacy formats)
    String? parseOptionalId(dynamic id) {
      if (id == null) return null;
      if (id is String) return id.isEmpty ? null : id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return ValuationPrompt(
      propertyId: parseOptionalId(json['propertyId']),
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

