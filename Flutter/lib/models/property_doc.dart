class PropertyDoc {
  final int docId;
  final int propertyId;
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
    return PropertyDoc(
      docId: json['docId'] ?? 0,
      propertyId: json['propertyId'] ?? 0,
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


