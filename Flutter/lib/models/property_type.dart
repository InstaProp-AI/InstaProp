enum PropertyType {
  apartment,
  villa,
  townhouse,
  twinhouse,
  duplex,
  penthouse,
  studio,
  chalet,
  servicedApartment,
  servicedStudio,
  office,
  retail,
  clinic,
  pharmacy,
  cabin,
  brandedApartment,
  brandedVilla,
  luxuryApartment,
  ultraLuxuryApartment,
  ultraLuxuryVilla,
  oneStoryVilla,
  loft,
  other,
}

extension PropertyTypeX on PropertyType {
  static const Map<PropertyType, String> _displayNames = {
    PropertyType.apartment: 'Apartment',
    PropertyType.villa: 'Villa',
    PropertyType.townhouse: 'Townhouse',
    PropertyType.twinhouse: 'Twinhouse',
    PropertyType.duplex: 'Duplex',
    PropertyType.penthouse: 'Penthouse',
    PropertyType.studio: 'Studio',
    PropertyType.chalet: 'Chalet',
    PropertyType.servicedApartment: 'Serviced Apartment',
    PropertyType.servicedStudio: 'Serviced Studio',
    PropertyType.office: 'Office',
    PropertyType.retail: 'Retail',
    PropertyType.clinic: 'Clinic',
    PropertyType.pharmacy: 'Pharmacy',
    PropertyType.cabin: 'Cabin',
    PropertyType.brandedApartment: 'Branded Apartment',
    PropertyType.brandedVilla: 'Branded Villa',
    PropertyType.luxuryApartment: 'Luxury Apartment',
    PropertyType.ultraLuxuryApartment: 'Ultra Luxury Apartment',
    PropertyType.ultraLuxuryVilla: 'Ultra Luxury Villa',
    PropertyType.oneStoryVilla: 'One-story Villa',
    PropertyType.loft: 'Loft',
    PropertyType.other: 'Other',
  };

  static const List<PropertyType> orderedValues = [
    PropertyType.apartment,
    PropertyType.villa,
    PropertyType.townhouse,
    PropertyType.twinhouse,
    PropertyType.duplex,
    PropertyType.penthouse,
    PropertyType.studio,
    PropertyType.chalet,
    PropertyType.servicedApartment,
    PropertyType.servicedStudio,
    PropertyType.office,
    PropertyType.retail,
    PropertyType.clinic,
    PropertyType.pharmacy,
    PropertyType.cabin,
    PropertyType.brandedApartment,
    PropertyType.brandedVilla,
    PropertyType.luxuryApartment,
    PropertyType.ultraLuxuryApartment,
    PropertyType.ultraLuxuryVilla,
    PropertyType.oneStoryVilla,
    PropertyType.loft,
    PropertyType.other,
  ];

  String get displayName => _displayNames[this] ?? 'Other';

  static PropertyType fromString(String? value) {
    if (value == null || value.isEmpty) return PropertyType.other;

    final normalized = value
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .replaceAll('_', '');

    for (final entry in _displayNames.entries) {
      final keyNormalized =
          entry.value.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
      if (normalized == entry.key.name.toLowerCase() ||
          normalized == keyNormalized) {
        return entry.key;
      }
    }

    return PropertyType.other;
  }
}

