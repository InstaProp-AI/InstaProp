import 'user.dart';

enum PropertyType { resale, primary }

class Property {
  final int propertyId;
  final int ownerId;
  final Account? owner;
  final int? projectId;
  final String name;
  final String description;
  final String location;
  final double startingPrice;
  final PropertyType type;
  final bool isApproved;
  final int bedrooms;
  final int bathrooms;
  final int squareFeet;
  final int yearBuilt;
  final String category;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Property({
    required this.propertyId,
    required this.ownerId,
    this.owner,
    this.projectId,
    required this.name,
    required this.description,
    required this.location,
    required this.startingPrice,
    required this.type,
    required this.isApproved,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareFeet,
    required this.yearBuilt,
    required this.category,
    required this.imageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      propertyId: json['propertyId'] ?? json['PropertyId'] ?? 0,
      ownerId: json['ownerId'] ?? json['OwnerId'] ?? 0,
      owner: json['owner'] != null || json['Owner'] != null
          ? Account.fromJson({
              'accountId':
                  (json['owner'] ?? json['Owner'])['accountId'] ??
                  (json['owner'] ?? json['Owner'])['AccountId'] ??
                  0,
              'firstName':
                  (json['owner'] ?? json['Owner'])['firstName'] ??
                  (json['owner'] ?? json['Owner'])['FirstName'] ??
                  '',
              'lastName':
                  (json['owner'] ?? json['Owner'])['lastName'] ??
                  (json['owner'] ?? json['Owner'])['LastName'] ??
                  '',
              'phoneNumber':
                  (json['owner'] ?? json['Owner'])['phoneNumber'] ??
                  (json['owner'] ?? json['Owner'])['PhoneNumber'] ??
                  '',
              'email':
                  (json['owner'] ?? json['Owner'])['email'] ??
                  (json['owner'] ?? json['Owner'])['Email'] ??
                  '',
              'type':
                  (json['owner'] ?? json['Owner'])['type'] ??
                  (json['owner'] ?? json['Owner'])['Type'] ??
                  'user',
              'isVerified':
                  (json['owner'] ?? json['Owner'])['isVerified'] ??
                  (json['owner'] ?? json['Owner'])['IsVerified'] ??
                  false,
              'createdAt':
                  (json['owner'] ?? json['Owner'])['createdAt'] ??
                  (json['owner'] ?? json['Owner'])['CreatedAt'] ??
                  DateTime.now().toIso8601String(),
              'updatedAt':
                  (json['owner'] ?? json['Owner'])['updatedAt'] ??
                  (json['owner'] ?? json['Owner'])['UpdatedAt'],
            })
          : null,
      projectId: json['projectId'] ?? json['ProjectId'],
      name: json['name'] ?? json['Name'] ?? '',
      description: json['description'] ?? json['Description'] ?? '',
      location: json['location'] ?? json['Location'] ?? '',
      startingPrice: (json['startingPrice'] ?? json['StartingPrice'] ?? 0)
          .toDouble(),
      type: PropertyType.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            (json['type'] ?? json['Type'] ?? 'resale'),
        orElse: () => PropertyType.resale,
      ),
      isApproved: json['isApproved'] ?? json['IsApproved'] ?? false,
      bedrooms: json['bedrooms'] ?? json['Bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? json['Bathrooms'] ?? 0,
      squareFeet: json['squareFeet'] ?? json['SquareFeet'] ?? 0,
      yearBuilt: json['yearBuilt'] ?? json['YearBuilt'] ?? 0,
      category: json['category'] ?? json['Category'] ?? 'Residential',
      imageUrl: json['imageUrl'] ?? json['ImageUrl'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ??
            json['CreatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updatedAt'] != null || json['UpdatedAt'] != null
          ? DateTime.parse(json['updatedAt'] ?? json['UpdatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'ownerId': ownerId,
      'owner': owner?.toJson(),
      'projectId': projectId,
      'name': name,
      'description': description,
      'location': location,
      'startingPrice': startingPrice,
      'type': type.toString().split('.').last,
      'isApproved': isApproved,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFeet': squareFeet,
      'yearBuilt': yearBuilt,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
