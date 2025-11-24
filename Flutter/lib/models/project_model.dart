class ProjectModel {
  final String projectId;
  final String name;
  final String? description;
  final String? location;
  final String? country; // ISO 3166-1 alpha-2 country code
  final DateTime createdAt;
  final int propertiesCount;
  final String? featuredImageUrl;
  final String developerId;
  final String developerName;
  final String? developerCompany;
  final double developerRating;
  final String? developerProfileImage;

  ProjectModel({
    required this.projectId,
    required this.name,
    this.description,
    this.location,
    this.country,
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
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return ProjectModel(
      projectId: parseId(json['projectId']),
      name: json['name'] ?? '',
      description: json['description'],
      location: json['location'],
      country: json['country'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      propertiesCount: json['propertiesCount'] ?? 0,
      featuredImageUrl: json['featuredImageUrl'],
      developerId: parseId(json['developerId']),
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
      'country': country,
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
  final String projectId;
  final String name;
  final String? description;
  final String? location;
  final String? country; // ISO 3166-1 alpha-2 country code
  final DateTime createdAt;
  final String developerId;
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
    this.country,
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
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return ProjectDetailsModel(
      projectId: parseId(json['projectId']),
      name: json['name'] ?? '',
      description: json['description'],
      location: json['location'],
      country: json['country'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      developerId: parseId(json['developerId']),
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
  final String propertyId;
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
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return ProjectProperty(
      propertyId: parseId(json['propertyId']),
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
