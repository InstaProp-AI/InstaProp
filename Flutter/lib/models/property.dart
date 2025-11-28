import 'user.dart';
import 'property_image.dart';
import 'parent_property.dart';
import 'child_property.dart';
import 'property_type.dart';
import 'installment_summary.dart';
import 'property_doc.dart';

enum ListingType { resale, primary }

enum PropertyStatus { notApproved, pending, approved }

class Property {
  final String propertyId;
  final String ownerId;
  final Account? owner;
  final String? projectId;
  final String? project;
  final String name;
  final String description;
  final String location;
  final ListingType listingType;
  final PropertyType type;
  final PropertyStatus status;
  final int bedrooms;
  final int bathrooms;
  final int squareFeet;
  final int yearBuilt;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool hasActiveAuction;
  final List<PropertyImage> propertyImages;
  final InstallmentSummary? installmentSummary;
  final List<PropertyDoc> propertyDocs;

  Property({
    required this.propertyId,
    required this.ownerId,
    this.owner,
    this.projectId,
    this.project,
    required this.name,
    required this.description,
    required this.location,
    required this.listingType,
    required this.type,
    required this.status,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareFeet,
    required this.yearBuilt,
    required this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.hasActiveAuction = false,
    this.propertyImages = const [],
    this.installmentSummary,
    this.propertyDocs = const [],
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    // Handle PropertyType parsing
    ListingType parseListingType() {
      final typeValue =
          json['listingType'] ?? json['ListingType'] ?? json['saleType'];
      if (typeValue == null) return ListingType.resale;

      if (typeValue is int) {
        return typeValue == 0 ? ListingType.resale : ListingType.primary;
      } else if (typeValue is String) {
        final typeStr = typeValue.toString().toLowerCase();
        if (typeStr == 'resale' || typeStr == '0') return ListingType.resale;
        if (typeStr == 'primary' || typeStr == '1') return ListingType.primary;
      }
      return ListingType.resale;
    }

    PropertyType parsePropertyType() {
      final rawType =
          (json['type'] ?? json['Type'] ?? json['propertyType'] ?? json['category'])
              ?.toString();
      return PropertyTypeX.fromString(rawType);
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

    return Property(
      propertyId: parseId(json['propertyId'] ?? json['PropertyId']),
      ownerId: parseId(json['ownerId'] ?? json['OwnerId']),
      owner: json['owner'] != null || json['Owner'] != null
          ? Account.fromJson({
              'accountId':
                  (json['owner'] ?? json['Owner'])['accountId'] ??
                  (json['owner'] ?? json['Owner'])['AccountId'] ??
                  '',
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
      projectId: parseOptionalId(json['projectId'] ?? json['ProjectId']),
      project: () {
        final projectValue = json['project'] ?? json['Project'];
        if (projectValue is Map) {
          return projectValue['name'] ??
              projectValue['Name'] ??
              projectValue['projectName'];
        }
        return json['projectName'] ?? projectValue;
      }(),
      name: json['name'] ?? json['Name'] ?? '',
      description: json['description'] ?? json['Description'] ?? '',
      location: json['location'] ?? json['Location'] ?? '',
      listingType: parseListingType(),
      type: parsePropertyType(),
      status: parsePropertyStatus(),
      bedrooms: _parseInt(json['bedrooms'] ?? json['Bedrooms'], defaultValue: 0),
      bathrooms: _parseInt(json['bathrooms'] ?? json['Bathrooms'], defaultValue: 0),
      squareFeet: _parseInt(json['squareFeet'] ?? json['SquareFeet'], defaultValue: 0),
      yearBuilt: _parseInt(json['yearBuilt'] ?? json['YearBuilt'], defaultValue: 0),
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
      installmentSummary: json['installmentSummary'] != null
          ? InstallmentSummary.fromJson(json['installmentSummary'])
          : null,
      propertyDocs: (json['propertyDocs'] ?? json['PropertyDocs'] ?? [])
          .map<PropertyDoc>((doc) => PropertyDoc.fromJson(doc))
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
      'listingType': listingType.index,
      'type': type.displayName,
      'status': status.index,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFeet': squareFeet,
      'yearBuilt': yearBuilt,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'propertyImages': propertyImages.map((img) => img.toJson()).toList(),
      if (installmentSummary != null)
        'installmentSummary': installmentSummary!.toJson(),
      'propertyDocs': propertyDocs.map((doc) => doc.toJson()).toList(),
    };
  }

  // Helper getters for backward compatibility and convenience
  bool get isEditable => status != PropertyStatus.approved;
  bool get canRequestAuction => status == PropertyStatus.approved;
  bool get isApproved => status == PropertyStatus.approved;
  bool get isPending => status == PropertyStatus.pending;
  bool get isNotApproved => status == PropertyStatus.notApproved;
  String get typeLabel => type.displayName;

  // Factory method to create Property from ChildProperty for backward compatibility
  factory Property.fromChildProperty(ChildProperty childProperty) {
    return Property(
      propertyId: childProperty.propertyId,
      ownerId: childProperty.ownerId ?? '',
      owner: null, // Will be populated if needed
      projectId: null, // ChildProperty doesn't have projectId directly
      project: childProperty.project,
      name: childProperty.name,
      description: childProperty.description,
      location: childProperty.location,
      listingType: ListingType.resale,
      type: childProperty.type,
      status: _convertPropertyStatus(childProperty.status),
      bedrooms: childProperty.bedrooms,
      bathrooms: childProperty.bathrooms,
      squareFeet: childProperty.squareFeet,
      yearBuilt: childProperty.yearBuilt,
      imageUrl: childProperty.imageUrl,
      createdAt: childProperty.createdAt,
      updatedAt: childProperty.updatedAt,
      hasActiveAuction: childProperty.hasActiveAuction,
      propertyImages: childProperty.propertyImages ?? [],
      installmentSummary: childProperty.installmentSummary,
    );
  }

  // Factory method to create Property from ParentProperty for backward compatibility
  factory Property.fromParentProperty(ParentProperty parentProperty) {
    return Property(
      propertyId: parentProperty.parentPropertyId,
      ownerId: '', // ParentProperty doesn't have owner
      owner: null,
      projectId: null, // ParentProperty doesn't have projectId directly
      project: parentProperty.displayProjectName,
      name: '${parentProperty.typeLabel} - ${parentProperty.bedrooms}BR',
      description:
          '${parentProperty.typeLabel} with ${parentProperty.bedrooms} bedrooms and ${parentProperty.bathrooms} bathrooms',
      location: parentProperty.displayProjectName,
      listingType: ListingType.resale,
      type: parentProperty.type,
      status: PropertyStatus.approved, // Assume approved for parent properties
      bedrooms: parentProperty.bedrooms,
      bathrooms: parentProperty.bathrooms,
      squareFeet: parentProperty.areaSqm,
      yearBuilt: 0,
      imageUrl: '', // ParentProperty doesn't have image
      createdAt: parentProperty.createdAt,
      updatedAt: parentProperty.updatedAt,
      hasActiveAuction: false, // ParentProperty doesn't have auctions directly
      propertyImages: [],
      installmentSummary: null,
    );
  }

  // Helper methods to convert between old and new property types
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

  // Helper to safely parse int from int or string
  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        print('⚠️ Failed to parse int from string: $value');
        return defaultValue;
      }
    }
    return defaultValue;
  }
}

