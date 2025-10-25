enum PropertyType {
  primary,
  secondary,
  apartment,
  villa,
  townhouse,
  penthouse,
  studio,
  duplex,
  triplex,
  commercial,
  office,
  retail,
  warehouse,
  land,
  other;

  static PropertyType? fromString(String? typeString) {
    if (typeString == null) return null;

    switch (typeString.toLowerCase()) {
      case 'primary':
        return PropertyType.primary;
      case 'secondary':
        return PropertyType.secondary;
      case 'apartment':
        return PropertyType.apartment;
      case 'villa':
        return PropertyType.villa;
      case 'townhouse':
        return PropertyType.townhouse;
      case 'penthouse':
        return PropertyType.penthouse;
      case 'studio':
        return PropertyType.studio;
      case 'duplex':
        return PropertyType.duplex;
      case 'triplex':
        return PropertyType.triplex;
      case 'commercial':
        return PropertyType.commercial;
      case 'office':
        return PropertyType.office;
      case 'retail':
        return PropertyType.retail;
      case 'warehouse':
        return PropertyType.warehouse;
      case 'land':
        return PropertyType.land;
      case 'other':
        return PropertyType.other;
      default:
        return PropertyType.other;
    }
  }

  String get displayName {
    switch (this) {
      case PropertyType.primary:
        return 'Primary';
      case PropertyType.secondary:
        return 'Secondary';
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.villa:
        return 'Villa';
      case PropertyType.townhouse:
        return 'Townhouse';
      case PropertyType.penthouse:
        return 'Penthouse';
      case PropertyType.studio:
        return 'Studio';
      case PropertyType.duplex:
        return 'Duplex';
      case PropertyType.triplex:
        return 'Triplex';
      case PropertyType.commercial:
        return 'Commercial';
      case PropertyType.office:
        return 'Office';
      case PropertyType.retail:
        return 'Retail';
      case PropertyType.warehouse:
        return 'Warehouse';
      case PropertyType.land:
        return 'Land';
      case PropertyType.other:
        return 'Other';
    }
  }
}
