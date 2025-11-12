import 'parent_property.dart';
import 'property_image.dart';
import 'property_doc.dart';
import 'auction.dart';
import 'property_type.dart';
import 'installment_summary.dart';

class ChildProperty {
  final int propertyId; // Keep same name for compatibility
  final int? parentPropertyId;
  final ParentProperty? parent; // Embedded parent data
  final int? ownerId;

  // Phase information (moved from parent to child)
  final String? phase; // "Phase 1", "Phase 2", "Phase 3", "Phase 4"

  // Unit-specific details
  final int? floorNumber;
  final String? unitNumber;
  final String? viewType;
  final String? orientation;
  final DateTime? deliveryDate;
  final int? parkingSlots;
  final bool? hasStorageRoom;

  // Purchase information
  final double? buyingPrice;
  final DateTime? buyingDate;
  final int quantity; // For developers, default 1

  // Unit-specific amenities
  final bool? hasNannyRoom;
  final bool? hasDriverRoom;
  final bool? hasMaidRoom;
  final bool? hasPrivatePool;
  final bool? hasRoofAccess;
  final bool? hasBalcony;
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
  final bool? smartHome;
  final bool? centralAC;
  final bool? naturalGas;
  final bool? hasGenerator;

  // View-specific flags
  final bool? seaView;
  final bool? nileView;
  final bool? pyramidView;
  final bool? gardenView;
  final bool? streetView;

  // Legacy fields (populated from parent)
  final String name;
  final String description;
  final String location;
  final String imageUrl; // Main image URL
  final int squareFeet;
  final int yearBuilt;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Properties inherited from ParentProperty for compatibility
  final int bedrooms; // From parent
  final int bathrooms; // From parent
  final PropertyType type; // Primary property type
  final String? project; // Project name
  final String? status; // Property status
  final bool canRequestAuction; // Computed property
  final bool hasActiveAuction; // Computed property

  // Navigation properties
  final List<PropertyImage>? propertyImages;
  final List<PropertyDoc>? propertyDocs;
  final List<Auction>? auctions;
  final InstallmentSummary? installmentSummary;

  String get typeLabel => type.displayName;
  String get propertyType => type.displayName;

  ChildProperty({
    required this.propertyId,
    this.parentPropertyId,
    this.parent,
    this.ownerId,
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
    this.hasNannyRoom,
    this.hasDriverRoom,
    this.hasMaidRoom,
    this.hasPrivatePool,
    this.hasRoofAccess,
    this.hasBalcony,
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
    this.smartHome,
    this.centralAC,
    this.naturalGas,
    this.hasGenerator,
    this.seaView,
    this.nileView,
    this.pyramidView,
    this.gardenView,
    this.streetView,
    required this.name,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.squareFeet,
    required this.yearBuilt,
    this.isApproved = false,
    required this.createdAt,
    required this.updatedAt,
    // Additional properties
    required this.bedrooms,
    required this.bathrooms,
    required this.type,
    this.project,
    this.status,
    this.canRequestAuction = false,
    this.hasActiveAuction = false,
    this.propertyImages,
    this.propertyDocs,
    this.auctions,
    this.installmentSummary,
  });

  factory ChildProperty.fromJson(Map<String, dynamic> json) {
    return ChildProperty(
      propertyId: json['propertyId'] ?? 0,
      parentPropertyId: json['parentPropertyId'],
      parent: json['parent'] != null
          ? ParentProperty.fromJson(json['parent'])
          : null,
      ownerId: json['ownerId'],
      phase: json['phase'],
      floorNumber: json['floorNumber'],
      unitNumber: json['unitNumber'],
      viewType: json['viewType'],
      orientation: json['orientation'],
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'])
          : null,
      parkingSlots: json['parkingSlots'],
      hasStorageRoom: json['hasStorageRoom'],
      buyingPrice: json['buyingPrice']?.toDouble(),
      buyingDate: json['buyingDate'] != null
          ? DateTime.parse(json['buyingDate'])
          : null,
      quantity: json['quantity'] ?? 1,
      hasNannyRoom: json['hasNannyRoom'],
      hasDriverRoom: json['hasDriverRoom'],
      hasMaidRoom: json['hasMaidRoom'],
      hasPrivatePool: json['hasPrivatePool'],
      hasRoofAccess: json['hasRoofAccess'],
      hasBalcony: json['hasBalcony'],
      hasGarden: json['hasGarden'],
      hasClubhouse: json['hasClubhouse'],
      hasInfrastructure: json['hasInfrastructure'],
      hasUndergroundParking: json['hasUndergroundParking'],
      hasMedicalCenter: json['hasMedicalCenter'],
      hasCommercialStrip: json['hasCommercialStrip'],
      hasBusinessHub: json['hasBusinessHub'],
      hasOutdoorPools: json['hasOutdoorPools'],
      hasBicycleLanes: json['hasBicycleLanes'],
      hasJoggingTrail: json['hasJoggingTrail'],
      smartHome: json['smartHome'],
      centralAC: json['centralAC'],
      naturalGas: json['naturalGas'],
      hasGenerator: json['hasGenerator'],
      seaView: json['seaView'],
      nileView: json['nileView'],
      pyramidView: json['pyramidView'],
      gardenView: json['gardenView'],
      streetView: json['streetView'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      squareFeet: json['squareFeet'] ?? 0,
      yearBuilt: json['yearBuilt'] ?? 0,
      isApproved: json['isApproved'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      // Additional properties
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      project: () {
        final projectValue = json['project'];
        if (projectValue is Map) {
          return projectValue['name']?.toString() ??
              projectValue['Name']?.toString();
        }
        return (json['projectName'] ?? projectValue)?.toString();
      }(),
      type: PropertyTypeX.fromString(
        (json['type'] ?? json['propertyType'])?.toString(),
      ),
      status: json['status']?.toString(),
      canRequestAuction: json['canRequestAuction'] ?? false,
      hasActiveAuction: json['hasActiveAuction'] ?? false,
      propertyImages: (json['propertyImages'] as List<dynamic>?)
          ?.map((e) => PropertyImage.fromJson(e))
          .toList(),
      propertyDocs: (json['propertyDocs'] as List<dynamic>?)
          ?.map((e) => PropertyDoc.fromJson(e))
          .toList(),
      auctions: (json['auctions'] as List<dynamic>?)
          ?.map((e) => Auction.fromJson(e))
          .toList(),
      installmentSummary: json['installmentSummary'] != null
          ? InstallmentSummary.fromJson(json['installmentSummary'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'parentPropertyId': parentPropertyId,
      'parent': parent?.toJson(),
      'ownerId': ownerId,
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
      'hasNannyRoom': hasNannyRoom,
      'hasDriverRoom': hasDriverRoom,
      'hasMaidRoom': hasMaidRoom,
      'hasPrivatePool': hasPrivatePool,
      'hasRoofAccess': hasRoofAccess,
      'hasBalcony': hasBalcony,
      'hasGarden': hasGarden,
      'hasClubhouse': hasClubhouse,
      'hasInfrastructure': hasInfrastructure,
      'hasUndergroundParking': hasUndergroundParking,
      'hasMedicalCenter': hasMedicalCenter,
      'hasCommercialStrip': hasCommercialStrip,
      'hasBusinessHub': hasBusinessHub,
      'hasOutdoorPools': hasOutdoorPools,
      'hasBicycleLanes': hasBicycleLanes,
      'hasJoggingTrail': hasJoggingTrail,
      'smartHome': smartHome,
      'centralAC': centralAC,
      'naturalGas': naturalGas,
      'hasGenerator': hasGenerator,
      'seaView': seaView,
      'nileView': nileView,
      'pyramidView': pyramidView,
      'gardenView': gardenView,
      'streetView': streetView,
      'name': name,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'squareFeet': squareFeet,
      'yearBuilt': yearBuilt,
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'project': project,
      'type': type.displayName,
      'status': status,
      'canRequestAuction': canRequestAuction,
      'hasActiveAuction': hasActiveAuction,
      'propertyImages': propertyImages?.map((e) => e.toJson()).toList(),
      'propertyDocs': propertyDocs?.map((e) => e.toJson()).toList(),
      'auctions': auctions?.map((e) => e.toJson()).toList(),
      if (installmentSummary != null)
        'installmentSummary': installmentSummary!.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChildProperty && other.propertyId == propertyId;
  }

  @override
  int get hashCode => propertyId.hashCode;

}
