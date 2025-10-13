class PropertyImage {
  final int propertyImageId;
  final int propertyId;
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
    return PropertyImage(
      propertyImageId: json['propertyImageId'] ?? json['PropertyImageId'] ?? 0,
      propertyId: json['propertyId'] ?? json['PropertyId'] ?? 0,
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
