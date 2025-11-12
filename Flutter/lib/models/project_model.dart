class ProjectModel {
  final int projectId;
  final String name;
  final String? description;
  final String? location;
  final DateTime createdAt;
  final int propertiesCount;
  final String? featuredImageUrl;
  final int developerId;
  final String developerName;
  final String? developerCompany;
  final double developerRating;
  final String? developerProfileImage;

  ProjectModel({
    required this.projectId,
    required this.name,
    this.description,
    this.location,
    required this.createdAt,
    required this.propertiesCount,
    this.featuredImageUrl,
    required this.developerId,
    required this.developerName,
    this.developerCompany,
    required this.developerRating,
    this.developerProfileImage,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      projectId: json['projectId'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      location: json['location'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      propertiesCount: json['propertiesCount'] ?? 0,
      featuredImageUrl: json['featuredImageUrl'],
      developerId: json['developerId'] ?? 0,
      developerName: json['developerName'] ?? '',
      developerCompany: json['developerCompany'],
      developerRating: (json['developerRating'] ?? 0.0).toDouble(),
      developerProfileImage: json['developerProfileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'name': name,
      'description': description,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'propertiesCount': propertiesCount,
      'featuredImageUrl': featuredImageUrl,
      'developerId': developerId,
      'developerName': developerName,
      'developerCompany': developerCompany,
      'developerRating': developerRating,
      'developerProfileImage': developerProfileImage,
    };
  }
}

class ProjectDetailsModel {
  final int projectId;
  final String name;
  final String? description;
  final String? location;
  final DateTime createdAt;
  final int developerId;
  final String developerName;
  final String? developerCompany;
  final double developerRating;
  final String? developerProfileImage;
  final String? developerBio;
  final List<ProjectProperty> properties;

  ProjectDetailsModel({
    required this.projectId,
    required this.name,
    this.description,
    this.location,
    required this.createdAt,
    required this.developerId,
    required this.developerName,
    this.developerCompany,
    required this.developerRating,
    this.developerProfileImage,
    this.developerBio,
    required this.properties,
  });

  factory ProjectDetailsModel.fromJson(Map<String, dynamic> json) {
    return ProjectDetailsModel(
      projectId: json['projectId'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      location: json['location'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      developerId: json['developerId'] ?? 0,
      developerName: json['developerName'] ?? '',
      developerCompany: json['developerCompany'],
      developerRating: (json['developerRating'] ?? 0.0).toDouble(),
      developerProfileImage: json['developerProfileImage'],
      developerBio: json['developerBio'],
      properties:
          (json['properties'] as List<dynamic>?)
              ?.map((p) => ProjectProperty.fromJson(p))
              .toList() ??
          [],
    );
  }
}

class ProjectProperty {
  final int propertyId;
  final String name;
  final String? description;
  final String? location;
  final int bedrooms;
  final int bathrooms;
  final int squareFeet;
  final String type;
  final String imageUrl;
  final List<String> images;
  final bool hasActiveAuction;
  final double? auctionPrice;

  ProjectProperty({
    required this.propertyId,
    required this.name,
    this.description,
    this.location,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareFeet,
    required this.type,
    required this.imageUrl,
    required this.images,
    required this.hasActiveAuction,
    this.auctionPrice,
  });

  factory ProjectProperty.fromJson(Map<String, dynamic> json) {
    return ProjectProperty(
      propertyId: json['propertyId'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      location: json['location'],
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      squareFeet: json['squareFeet'] ?? 0,
      type: json['type'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      images:
          (json['images'] as List<dynamic>?)
              ?.map((i) => i.toString())
              .toList() ??
          [],
      hasActiveAuction: json['hasActiveAuction'] ?? false,
      auctionPrice: json['auctionPrice']?.toDouble(),
    );
  }
}
