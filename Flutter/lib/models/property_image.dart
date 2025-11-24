class PropertyImage {
  final String propertyImageId;
  final String propertyId;
  final String imageUrl;
  final String imageType;
  final bool isMainImage;
  final int displayOrder;
  final String? deleteUrl;
  final DateTime createdAt;

  PropertyImage({
    required this.propertyImageId,
    required this.propertyId,
    required this.imageUrl,
    required this.imageType,
    required this.isMainImage,
    required this.displayOrder,
    this.deleteUrl,
    required this.createdAt,
  });

  factory PropertyImage.fromJson(Map<String, dynamic> json) {
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return PropertyImage(
      propertyImageId: parseId(json['propertyImageId'] ?? json['PropertyImageId']),
      propertyId: parseId(json['propertyId'] ?? json['PropertyId']),
      imageUrl: json['imageUrl'] ?? json['ImageUrl'] ?? '',
      imageType: json['imageType'] ?? json['ImageType'] ?? 'Gallery',
      isMainImage: json['isMainImage'] ?? json['IsMainImage'] ?? false,
      displayOrder: json['displayOrder'] ?? json['DisplayOrder'] ?? 0,
      deleteUrl: json['deleteUrl'] ?? json['DeleteUrl'],
      createdAt: DateTime.parse(
        json['createdAt'] ??
            json['CreatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyImageId': propertyImageId,
      'propertyId': propertyId,
      'imageUrl': imageUrl,
      'imageType': imageType,
      'isMainImage': isMainImage,
      'displayOrder': displayOrder,
      'deleteUrl': deleteUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
