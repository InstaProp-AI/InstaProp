class DeveloperProfile {
  final int developerId;
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
    return DeveloperProfile(
      developerId: json['developerId'] ?? 0,
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
  final int projectId;
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
    return DeveloperProjectSummary(
      projectId: json['projectId'] ?? 0,
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
  final int propertyId;
  final int? projectId;
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
    return DeveloperPropertySummary(
      propertyId: json['propertyId'] ?? 0,
      projectId: json['projectId'],
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
  final int ratingId;
  final int userId;
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
    return DeveloperRatingModel(
      ratingId: json['ratingId'] ?? 0,
      userId: json['userId'] ?? 0,
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
  final int developerId;
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
    return FeaturedDeveloper(
      developerId: json['developerId'] ?? 0,
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
