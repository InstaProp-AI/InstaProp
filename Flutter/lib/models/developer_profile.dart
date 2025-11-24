class DeveloperProfile {
  final String developerId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? bio;
  final String? companyName;
  final String? profileImageUrl;
  final double rating;
  final int totalRatings;
  final String? portfolioDescription;
  final int activeProjectsCount;
  final int totalPropertiesCount;
  final int soldPropertiesCount;
  final List<DeveloperProjectSummary> projects;
  final List<DeveloperPropertySummary> properties;
  final List<DeveloperRatingModel> ratings;

  DeveloperProfile({
    required this.developerId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.bio,
    this.companyName,
    this.profileImageUrl,
    required this.rating,
    required this.totalRatings,
    this.portfolioDescription,
    required this.activeProjectsCount,
    required this.totalPropertiesCount,
    required this.soldPropertiesCount,
    this.projects = const [],
    this.properties = const [],
    required this.ratings,
  });

  String get fullName => '$firstName $lastName';

  factory DeveloperProfile.fromJson(Map<String, dynamic> json) {
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return DeveloperProfile(
      developerId: parseId(json['developerId']),
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      bio: json['bio'],
      companyName: json['companyName'],
      profileImageUrl: json['profileImageUrl'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      portfolioDescription: json['portfolioDescription'],
      activeProjectsCount: json['activeProjectsCount'] ?? 0,
      totalPropertiesCount: json['totalPropertiesCount'] ?? 0,
      soldPropertiesCount: json['soldPropertiesCount'] ?? 0,
      projects: (json['projects'] as List<dynamic>?)
              ?.map((p) => DeveloperProjectSummary.fromJson(p))
              .toList() ??
          [],
      properties: (json['properties'] as List<dynamic>?)
              ?.map((p) => DeveloperPropertySummary.fromJson(p))
              .toList() ??
          [],
      ratings:
          (json['ratings'] as List<dynamic>?)
              ?.map((r) => DeveloperRatingModel.fromJson(r))
              .toList() ??
          [],
    );
  }
}

class DeveloperProjectSummary {
  final String projectId;
  final String name;
  final String? location;
  final int propertiesCount;
  final String? coverImageUrl;
  final DateTime createdAt;

  DeveloperProjectSummary({
    required this.projectId,
    required this.name,
    this.location,
    required this.propertiesCount,
    this.coverImageUrl,
    required this.createdAt,
  });

  factory DeveloperProjectSummary.fromJson(Map<String, dynamic> json) {
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

    return DeveloperProjectSummary(
      projectId: parseId(json['projectId']),
      name: json['name'] ?? '',
      location: json['location'],
      propertiesCount: json['propertiesCount'] ?? 0,
      coverImageUrl: json['coverImageUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class DeveloperPropertySummary {
  final String propertyId;
  final String? projectId;
  final String name;
  final String? location;
  final String imageUrl;
  final String status;
  final String type;
  final int bedrooms;
  final int bathrooms;
  final int squareFeet;

  DeveloperPropertySummary({
    required this.propertyId,
    this.projectId,
    required this.name,
    this.location,
    required this.imageUrl,
    required this.status,
    required this.type,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareFeet,
  });

  factory DeveloperPropertySummary.fromJson(Map<String, dynamic> json) {
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

    return DeveloperPropertySummary(
      propertyId: parseId(json['propertyId']),
      projectId: parseOptionalId(json['projectId']),
      name: json['name'] ?? '',
      location: json['location'],
      imageUrl: json['imageUrl'] ?? '',
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      squareFeet: json['squareFeet'] ?? 0,
    );
  }
}

class DeveloperRatingModel {
  final String ratingId;
  final String userId;
  final String userName;
  final int rating;
  final String? comment;
  final String ratingType;
  final DateTime createdAt;

  DeveloperRatingModel({
    required this.ratingId,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.ratingType,
    required this.createdAt,
  });

  factory DeveloperRatingModel.fromJson(Map<String, dynamic> json) {
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return DeveloperRatingModel(
      ratingId: parseId(json['ratingId']),
      userId: parseId(json['userId']),
      userName: json['userName'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      ratingType: json['ratingType'] ?? 'Chat',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class FeaturedDeveloper {
  final String developerId;
  final String firstName;
  final String lastName;
  final String? companyName;
  final String? profileImageUrl;
  final double rating;
  final int totalRatings;
  final String? bio;
  final int activeProjectsCount;

  FeaturedDeveloper({
    required this.developerId,
    required this.firstName,
    required this.lastName,
    this.companyName,
    this.profileImageUrl,
    required this.rating,
    required this.totalRatings,
    this.bio,
    required this.activeProjectsCount,
  });

  String get fullName => '$firstName $lastName';

  factory FeaturedDeveloper.fromJson(Map<String, dynamic> json) {
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return FeaturedDeveloper(
      developerId: parseId(json['developerId']),
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      companyName: json['companyName'],
      profileImageUrl: json['profileImageUrl'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      bio: json['bio'],
      activeProjectsCount: json['activeProjectsCount'] ?? 0,
    );
  }
}
