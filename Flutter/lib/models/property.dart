import 'user.dart';
import 'property_image.dart';
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
  final String? projectName;
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
  final String? finishingType;
  final String? phase;
  final int? floorNumber;
  final String? unitNumber;
  final String? viewType;
  final String? orientation;
  final DateTime? deliveryDate;
  final int? parkingSlots;
  final bool? hasStorageRoom;
  final double? buyingPrice;
  final DateTime? buyingDate;
  final int quantity;
  final bool hasPool;
  final bool hasGym;
  final bool hasSecurity;
  final bool hasParking;
  final bool hasPlayground;
  final bool? hasGarden;
  final bool? hasClubhouse;
  final bool? hasInfrastructure;
  final bool? hasUndergroundParking;
  final bool? hasMedicalCenter;
  final bool? hasCommercialStrip;
  final bool? hasBusinessHub;
  final bool? hasOutdoorPools;
  final bool? hasBicycleLanes;
  final bool? hasJoggingTrail;
  final bool? hasNannyRoom;
  final bool? hasDriverRoom;
  final bool? hasMaidRoom;
  final bool? hasPrivatePool;
  final bool? hasRoofAccess;
  final bool? hasBalcony;
  final bool? smartHome;
  final bool? centralAC;
  final bool? naturalGas;
  final bool? hasGenerator;
  final bool? seaView;
  final bool? nileView;
  final bool? pyramidView;
  final bool? gardenView;
  final bool? streetView;
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
    this.projectName,
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
    this.finishingType,
    this.phase,
    this.floorNumber,
    this.unitNumber,
    this.viewType,
    this.orientation,
    this.deliveryDate,
    this.parkingSlots,
    this.hasStorageRoom,
    this.buyingPrice,
    this.buyingDate,
    this.quantity = 1,
    this.hasPool = false,
    this.hasGym = false,
    this.hasSecurity = false,
    this.hasParking = false,
    this.hasPlayground = false,
    this.hasGarden,
    this.hasClubhouse,
    this.hasInfrastructure,
    this.hasUndergroundParking,
    this.hasMedicalCenter,
    this.hasCommercialStrip,
    this.hasBusinessHub,
    this.hasOutdoorPools,
    this.hasBicycleLanes,
    this.hasJoggingTrail,
    this.hasNannyRoom,
    this.hasDriverRoom,
    this.hasMaidRoom,
    this.hasPrivatePool,
    this.hasRoofAccess,
    this.hasBalcony,
    this.smartHome,
    this.centralAC,
    this.naturalGas,
    this.hasGenerator,
    this.seaView,
    this.nileView,
    this.pyramidView,
    this.gardenView,
    this.streetView,
    required this.createdAt,
    this.updatedAt,
    this.hasActiveAuction = false,
    this.propertyImages = const [],
    this.installmentSummary,
    this.propertyDocs = const [],
  });

  factory Property.fromJson(Map<String, dynamic> json) {
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
      final rawType = (json['type'] ??
              json['Type'] ??
              json['propertyType'] ??
              json['category'])
          ?.toString();
      return PropertyTypeX.fromString(rawType);
    }

    PropertyStatus parsePropertyStatus() {
      final statusValue = json['status'] ?? json['Status'];

      if (statusValue == null) {
        final isVerified = json['isVerified'] ?? json['IsVerified'] ?? false;
        final isApproved = json['isApproved'] ?? json['IsApproved'] ?? false;
        if (isVerified && isApproved) {
          return PropertyStatus.approved;
        }
        return PropertyStatus.notApproved;
      }

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

    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString();
      return id.toString();
    }

    String? parseOptionalId(dynamic id) {
      if (id == null) return null;
      if (id is String) return id.isEmpty ? null : id;
      if (id is int) return id.toString();
      return id.toString();
    }

    bool parseBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return defaultValue;
    }

    bool? parseOptionalBool(dynamic value) {
      if (value == null) return null;
      return parseBool(value);
    }

    double? parseOptionalDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int? parseOptionalInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    DateTime? parseOptionalDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final auctions = json['auctions'] ?? json['Auctions'];
    final hasActiveAuctionFromAuctions = auctions is List &&
        auctions.any((auction) {
          final status = (auction['status'] ?? auction['Status'] ?? '')
              .toString()
              .toLowerCase();
          return status == 'active';
        });

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
      projectName: json['projectName'] ?? json['ProjectName'],
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
      bedrooms: _parseInt(json['bedrooms'] ?? json['Bedrooms']),
      bathrooms: _parseInt(json['bathrooms'] ?? json['Bathrooms']),
      squareFeet: _parseInt(json['squareFeet'] ?? json['SquareFeet']),
      yearBuilt: _parseInt(json['yearBuilt'] ?? json['YearBuilt']),
      imageUrl: json['imageUrl'] ?? json['ImageUrl'] ?? '',
      finishingType: json['finishingType'] ?? json['FinishingType'],
      phase: json['phase'] ?? json['Phase'],
      floorNumber: parseOptionalInt(json['floorNumber'] ?? json['FloorNumber']),
      unitNumber: json['unitNumber'] ?? json['UnitNumber'],
      viewType: json['viewType'] ?? json['ViewType'],
      orientation: json['orientation'] ?? json['Orientation'],
      deliveryDate: parseOptionalDate(json['deliveryDate'] ?? json['DeliveryDate']),
      parkingSlots: parseOptionalInt(json['parkingSlots'] ?? json['ParkingSlots']),
      hasStorageRoom:
          parseOptionalBool(json['hasStorageRoom'] ?? json['HasStorageRoom']),
      buyingPrice: parseOptionalDouble(json['buyingPrice'] ?? json['BuyingPrice']),
      buyingDate: parseOptionalDate(json['buyingDate'] ?? json['BuyingDate']),
      quantity: _parseInt(json['quantity'] ?? json['Quantity'], defaultValue: 1),
      hasPool: parseBool(json['hasPool'] ?? json['HasPool']),
      hasGym: parseBool(json['hasGym'] ?? json['HasGym']),
      hasSecurity: parseBool(json['hasSecurity'] ?? json['HasSecurity']),
      hasParking: parseBool(json['hasParking'] ?? json['HasParking']),
      hasPlayground: parseBool(json['hasPlayground'] ?? json['HasPlayground']),
      hasGarden: parseOptionalBool(json['hasGarden'] ?? json['HasGarden']),
      hasClubhouse: parseOptionalBool(json['hasClubhouse'] ?? json['HasClubhouse']),
      hasInfrastructure:
          parseOptionalBool(json['hasInfrastructure'] ?? json['HasInfrastructure']),
      hasUndergroundParking: parseOptionalBool(
        json['hasUndergroundParking'] ?? json['HasUndergroundParking'],
      ),
      hasMedicalCenter:
          parseOptionalBool(json['hasMedicalCenter'] ?? json['HasMedicalCenter']),
      hasCommercialStrip: parseOptionalBool(
        json['hasCommercialStrip'] ?? json['HasCommercialStrip'],
      ),
      hasBusinessHub:
          parseOptionalBool(json['hasBusinessHub'] ?? json['HasBusinessHub']),
      hasOutdoorPools:
          parseOptionalBool(json['hasOutdoorPools'] ?? json['HasOutdoorPools']),
      hasBicycleLanes:
          parseOptionalBool(json['hasBicycleLanes'] ?? json['HasBicycleLanes']),
      hasJoggingTrail:
          parseOptionalBool(json['hasJoggingTrail'] ?? json['HasJoggingTrail']),
      hasNannyRoom: parseOptionalBool(json['hasNannyRoom'] ?? json['HasNannyRoom']),
      hasDriverRoom:
          parseOptionalBool(json['hasDriverRoom'] ?? json['HasDriverRoom']),
      hasMaidRoom: parseOptionalBool(json['hasMaidRoom'] ?? json['HasMaidRoom']),
      hasPrivatePool:
          parseOptionalBool(json['hasPrivatePool'] ?? json['HasPrivatePool']),
      hasRoofAccess:
          parseOptionalBool(json['hasRoofAccess'] ?? json['HasRoofAccess']),
      hasBalcony: parseOptionalBool(json['hasBalcony'] ?? json['HasBalcony']),
      smartHome: parseOptionalBool(json['smartHome'] ?? json['SmartHome']),
      centralAC: parseOptionalBool(json['centralAC'] ?? json['CentralAC']),
      naturalGas: parseOptionalBool(json['naturalGas'] ?? json['NaturalGas']),
      hasGenerator:
          parseOptionalBool(json['hasGenerator'] ?? json['HasGenerator']),
      seaView: parseOptionalBool(json['seaView'] ?? json['SeaView']),
      nileView: parseOptionalBool(json['nileView'] ?? json['NileView']),
      pyramidView: parseOptionalBool(json['pyramidView'] ?? json['PyramidView']),
      gardenView: parseOptionalBool(json['gardenView'] ?? json['GardenView']),
      streetView: parseOptionalBool(json['streetView'] ?? json['StreetView']),
      createdAt: DateTime.parse(
        json['createdAt'] ??
            json['CreatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
      updatedAt: parseOptionalDate(json['updatedAt'] ?? json['UpdatedAt']),
      hasActiveAuction: json['hasActiveAuction'] ??
          json['HasActiveAuction'] ??
          hasActiveAuctionFromAuctions,
      propertyImages: (json['propertyImages'] ?? json['PropertyImages'] ?? [])
          .map<PropertyImage>((img) => PropertyImage.fromJson(img))
          .toList(),
      installmentSummary: json['installmentSummary'] != null ||
              json['InstallmentSummary'] != null
          ? InstallmentSummary.fromJson(
              json['installmentSummary'] ?? json['InstallmentSummary'],
            )
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
      'projectName': projectName ?? project,
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
      'finishingType': finishingType,
      'phase': phase,
      'floorNumber': floorNumber,
      'unitNumber': unitNumber,
      'viewType': viewType,
      'orientation': orientation,
      'deliveryDate': deliveryDate?.toIso8601String(),
      'parkingSlots': parkingSlots,
      'hasStorageRoom': hasStorageRoom,
      'buyingPrice': buyingPrice,
      'buyingDate': buyingDate?.toIso8601String(),
      'quantity': quantity,
      'hasPool': hasPool,
      'hasGym': hasGym,
      'hasSecurity': hasSecurity,
      'hasParking': hasParking,
      'hasPlayground': hasPlayground,
      'hasGarden': hasGarden,
      'hasClubhouse': hasClubhouse,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'propertyImages': propertyImages.map((img) => img.toJson()).toList(),
      if (installmentSummary != null)
        'installmentSummary': installmentSummary!.toJson(),
      'propertyDocs': propertyDocs.map((doc) => doc.toJson()).toList(),
    };
  }

  bool get isEditable => status != PropertyStatus.approved;
  bool get canRequestAuction => status == PropertyStatus.approved;
  bool get isApproved => status == PropertyStatus.approved;
  bool get isPending => status == PropertyStatus.pending;
  bool get isNotApproved => status == PropertyStatus.notApproved;
  String get typeLabel => type.displayName;
  String get displayProjectName => projectName ?? project ?? 'Unknown Project';

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    if (value is num) return value.toInt();
    return defaultValue;
  }
}
