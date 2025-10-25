import 'user.dart';
import 'property_image.dart';
import 'child_property.dart';
import 'parent_property.dart';

enum PropertyType { resale, primary }

enum PropertyStatus { notApproved, pending, approved }

class Property {
  final int propertyId;
  final int ownerId;
  final Account? owner;
  final int? projectId;
  final String? project;
  final String name;
  final String description;
  final String location;
  final PropertyType type;
  final PropertyStatus status;
  final int bedrooms;
  final int bathrooms;
  final int squareFeet;
  final int yearBuilt;
  final String category;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool hasActiveAuction;
  final List<PropertyImage> propertyImages;

  Property({
    required this.propertyId,
    required this.ownerId,
    this.owner,
    this.projectId,
    this.project,
    required this.name,
    required this.description,
    required this.location,
    required this.type,
    required this.status,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareFeet,
    required this.yearBuilt,
    required this.category,
    required this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.hasActiveAuction = false,
    this.propertyImages = const [],
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    // Handle PropertyType parsing
    PropertyType parsePropertyType() {
      final typeValue = json['type'] ?? json['Type'];
      if (typeValue == null) return PropertyType.resale;

      // Handle both string and integer type values
      if (typeValue is int) {
        return typeValue == 0 ? PropertyType.resale : PropertyType.primary;
      } else if (typeValue is String) {
        final typeStr = typeValue.toString().toLowerCase();
        if (typeStr == 'resale' || typeStr == '0') return PropertyType.resale;
        if (typeStr == 'primary' || typeStr == '1') return PropertyType.primary;
      }
      return PropertyType.resale;
    }

    // Handle PropertyStatus parsing
    PropertyStatus parsePropertyStatus() {
      final statusValue = json['status'] ?? json['Status'];

      // BACKWARD COMPATIBILITY: If status field doesn't exist (old API format),
      // try to infer from old isVerified/isApproved fields
      if (statusValue == null) {
        final isVerified = json['isVerified'] ?? json['IsVerified'] ?? false;
        final isApproved = json['isApproved'] ?? json['IsApproved'] ?? false;

        // If both true, it's approved
        if (isVerified && isApproved) {
          return PropertyStatus.approved;
        }

        // Default to notApproved for old data
        return PropertyStatus.notApproved;
      }

      // Handle both string and integer status values
      if (statusValue is int) {
        switch (statusValue) {
          case 0:
            return PropertyStatus.notApproved;
          case 1:
            return PropertyStatus.pending;
          case 2:
            return PropertyStatus.approved;
          default:
            return PropertyStatus.notApproved;
        }
      } else if (statusValue is String) {
        switch (statusValue.toLowerCase()) {
          case 'notapproved':
          case '0':
            return PropertyStatus.notApproved;
          case 'pending':
          case '1':
            return PropertyStatus.pending;
          case 'approved':
          case '2':
            return PropertyStatus.approved;
          default:
            return PropertyStatus.notApproved;
        }
      }
      return PropertyStatus.notApproved;
    }

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
              'status':
                  (json['owner'] ?? json['Owner'])['status'] ??
                  (json['owner'] ?? json['Owner'])['Status'] ??
                  0,
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
      project: json['project'] ?? json['Project'],
      name: json['name'] ?? json['Name'] ?? '',
      description: json['description'] ?? json['Description'] ?? '',
      location: json['location'] ?? json['Location'] ?? '',
      type: parsePropertyType(),
      status: parsePropertyStatus(),
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
      hasActiveAuction:
          json['hasActiveAuction'] ?? json['HasActiveAuction'] ?? false,
      propertyImages: (json['propertyImages'] ?? json['PropertyImages'] ?? [])
          .map<PropertyImage>((img) => PropertyImage.fromJson(img))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'ownerId': ownerId,
      'owner': owner?.toJson(),
      'projectId': projectId,
      'project': project,
      'name': name,
      'description': description,
      'location': location,
      'type': type.index,
      'status': status.index,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFeet': squareFeet,
      'yearBuilt': yearBuilt,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'propertyImages': propertyImages.map((img) => img.toJson()).toList(),
    };
  }

  // Helper getters for backward compatibility and convenience
  bool get isEditable => status != PropertyStatus.approved;
  bool get canRequestAuction => status == PropertyStatus.approved;
  bool get isApproved => status == PropertyStatus.approved;
  bool get isPending => status == PropertyStatus.pending;
  bool get isNotApproved => status == PropertyStatus.notApproved;

  // Factory method to create Property from ChildProperty for backward compatibility
  factory Property.fromChildProperty(ChildProperty childProperty) {
    return Property(
      propertyId: childProperty.propertyId,
      ownerId: childProperty.ownerId ?? 0,
      owner: null, // Will be populated if needed
      projectId: null, // ChildProperty doesn't have projectId directly
      project: childProperty.project,
      name: childProperty.name,
      description: childProperty.description,
      location: childProperty.location,
      type: _convertPropertyTypeFromString(childProperty.propertyType),
      status: _convertPropertyStatus(childProperty.status),
      bedrooms: childProperty.bedrooms,
      bathrooms: childProperty.bathrooms,
      squareFeet: childProperty.squareFeet,
      yearBuilt: childProperty.yearBuilt,
      category: childProperty.category,
      imageUrl: childProperty.imageUrl,
      createdAt: childProperty.createdAt,
      updatedAt: childProperty.updatedAt,
      hasActiveAuction: childProperty.hasActiveAuction,
      propertyImages: childProperty.propertyImages ?? [],
    );
  }

  // Factory method to create Property from ParentProperty for backward compatibility
  factory Property.fromParentProperty(ParentProperty parentProperty) {
    return Property(
      propertyId: parentProperty.parentPropertyId,
      ownerId: 0, // ParentProperty doesn't have owner
      owner: null,
      projectId: null, // ParentProperty doesn't have projectId directly
      project: parentProperty.projectName,
      name: '${parentProperty.propertyType} - ${parentProperty.bedrooms}BR',
      description:
          '${parentProperty.propertyType} with ${parentProperty.bedrooms} bedrooms and ${parentProperty.bathrooms} bathrooms',
      location: parentProperty.projectName,
      type: _convertPropertyTypeFromString(parentProperty.propertyType),
      status: PropertyStatus.approved, // Assume approved for parent properties
      bedrooms: parentProperty.bedrooms,
      bathrooms: parentProperty.bathrooms,
      squareFeet: parentProperty.areaSqm,
      yearBuilt: 0,
      category: parentProperty.propertyType,
      imageUrl: '', // ParentProperty doesn't have image
      createdAt: parentProperty.createdAt,
      updatedAt: parentProperty.updatedAt,
      hasActiveAuction: false, // ParentProperty doesn't have auctions directly
      propertyImages: [],
    );
  }

  // Helper methods to convert between old and new property types
  static PropertyType _convertPropertyType(String? typeString) {
    if (typeString == null) return PropertyType.resale;

    switch (typeString.toLowerCase()) {
      case 'apartment':
      case 'villa':
      case 'townhouse':
      case 'penthouse':
      case 'studio':
      case 'duplex':
        return PropertyType.primary;
      default:
        return PropertyType.resale;
    }
  }

  static PropertyStatus _convertPropertyStatus(String? statusString) {
    if (statusString == null) return PropertyStatus.notApproved;

    switch (statusString.toLowerCase()) {
      case 'approved':
        return PropertyStatus.approved;
      case 'pending':
        return PropertyStatus.pending;
      default:
        return PropertyStatus.notApproved;
    }
  }

  static PropertyType _convertPropertyTypeFromString(String? typeString) {
    if (typeString == null) return PropertyType.resale;

    switch (typeString.toLowerCase()) {
      case 'apartment':
      case 'villa':
      case 'townhouse':
      case 'penthouse':
      case 'studio':
      case 'duplex':
        return PropertyType.primary;
      default:
        return PropertyType.resale;
    }
  }
}
