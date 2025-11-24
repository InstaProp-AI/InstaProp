class PropertyDoc {
  final String docId;
  final String propertyId;
  final String docType;
  final String imgUrl;
  final String? deleteUrl;
  final DateTime uploadedAt;

  PropertyDoc({
    required this.docId,
    required this.propertyId,
    required this.docType,
    required this.imgUrl,
    this.deleteUrl,
    required this.uploadedAt,
  });

  factory PropertyDoc.fromJson(Map<String, dynamic> json) {
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return PropertyDoc(
      docId: parseId(json['docId']),
      propertyId: parseId(json['propertyId']),
      docType: json['docType'] ?? '',
      imgUrl: json['imgUrl'] ?? '',
      deleteUrl: json['deleteUrl'],
      uploadedAt: DateTime.parse(
        json['uploadedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docId': docId,
      'propertyId': propertyId,
      'docType': docType,
      'imgUrl': imgUrl,
      'deleteUrl': deleteUrl,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PropertyDoc && other.docId == docId;
  }

  @override
  int get hashCode => docId.hashCode;
}





