/// Egyptian-specific property and auction filtering models
/// Designed specifically for the Egyptian real estate market

class EgyptianPropertyFilters {
  // Location Filters (Egyptian-specific)
  String? governorate; // Cairo, Giza, Alexandria, etc.
  String? district; // New Cairo, Maadi, Zamalek, etc.
  String? area; // Specific areas within districts
  bool? nearMetro; // Near Cairo Metro stations
  bool? nearMall; // Near major shopping malls
  bool? nearSchool; // Near international schools
  bool? nearHospital; // Near major hospitals

  // Property Type Filters (Egyptian market categories)
  String? propertyCategory; // Apartment, Villa, Townhouse, Studio, Penthouse
  String? propertySubCategory; // Duplex, Triplex, Garden Apartment, etc.
  bool? furnished; // Fully furnished, semi-furnished, unfurnished
  bool? hasBalcony;
  bool? hasGarden;
  bool? hasPool;
  bool? hasGym;
  bool? hasSecurity;
  bool? hasParking;

  // Size Filters (in square meters - Egyptian standard)
  int? minArea; // Minimum area in square meters
  int? maxArea; // Maximum area in square meters
  int? minBedrooms;
  int? maxBedrooms;
  int? minBathrooms;
  int? maxBathrooms;

  // Price Filters (in Egyptian Pounds)
  double? minPrice; // Minimum price in EGP
  double? maxPrice; // Maximum price in EGP
  String?
  priceRange; // Predefined ranges: "under-1m", "1m-3m", "3m-5m", "5m-10m", "over-10m"

  // Age Filters
  int? minYearBuilt;
  int? maxYearBuilt;
  String? propertyAge; // "new", "recent", "old", "heritage"

  // Developer Filters
  String? developerName; // Talaat Moustafa, Emaar, SODIC, etc.
  String? projectName; // Madinaty, New Capital, etc.
  String? projectType; // e.g., "Mixed-Use", "Residential", "Commercial"
  double? minDeveloperRating; // Minimum developer rating

  // Special Features (Egyptian market specific)
  bool? hasSeaView; // Sea view (North Coast, Red Sea)
  bool? hasNileView; // Nile view (Cairo, Giza)
  bool? hasPyramidView; // Pyramid view (Giza)
  bool? isGatedCommunity; // Gated community
  bool? isCompound; // Residential compound
  bool? isInvestment; // Investment property
  bool? isResidential; // Residential property

  // Availability Filters
  bool? isAvailable;
  bool? hasActiveAuction;
  DateTime? availableFrom;

  // Search and Sorting
  String? searchTerm; // General search term
  String?
  sortBy; // "price_asc", "price_desc", "area_asc", "area_desc", "newest", "oldest", "popularity"
  int page;
  int pageSize;

  EgyptianPropertyFilters({
    this.governorate,
    this.district,
    this.area,
    this.nearMetro,
    this.nearMall,
    this.nearSchool,
    this.nearHospital,
    this.propertyCategory,
    this.propertySubCategory,
    this.furnished,
    this.hasBalcony,
    this.hasGarden,
    this.hasPool,
    this.hasGym,
    this.hasSecurity,
    this.hasParking,
    this.minArea,
    this.maxArea,
    this.minBedrooms,
    this.maxBedrooms,
    this.minBathrooms,
    this.maxBathrooms,
    this.minPrice,
    this.maxPrice,
    this.priceRange,
    this.minYearBuilt,
    this.maxYearBuilt,
    this.propertyAge,
    this.developerName,
    this.projectName,
    this.projectType,
    this.minDeveloperRating,
    this.hasSeaView,
    this.hasNileView,
    this.hasPyramidView,
    this.isGatedCommunity,
    this.isCompound,
    this.isInvestment,
    this.isResidential,
    this.isAvailable,
    this.hasActiveAuction,
    this.availableFrom,
    this.searchTerm,
    this.sortBy,
    this.page = 1,
    this.pageSize = 20,
  });

  Map<String, dynamic> toJson() {
    return {
      'governorate': governorate,
      'district': district,
      'area': area,
      'nearMetro': nearMetro,
      'nearMall': nearMall,
      'nearSchool': nearSchool,
      'nearHospital': nearHospital,
      'propertyCategory': propertyCategory,
      'propertySubCategory': propertySubCategory,
      'furnished': furnished,
      'hasBalcony': hasBalcony,
      'hasGarden': hasGarden,
      'hasPool': hasPool,
      'hasGym': hasGym,
      'hasSecurity': hasSecurity,
      'hasParking': hasParking,
      'minArea': minArea,
      'maxArea': maxArea,
      'minBedrooms': minBedrooms,
      'maxBedrooms': maxBedrooms,
      'minBathrooms': minBathrooms,
      'maxBathrooms': maxBathrooms,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'priceRange': priceRange,
      'minYearBuilt': minYearBuilt,
      'maxYearBuilt': maxYearBuilt,
      'propertyAge': propertyAge,
      'developerName': developerName,
      'projectName': projectName,
      'projectType': projectType,
      'minDeveloperRating': minDeveloperRating,
      'hasSeaView': hasSeaView,
      'hasNileView': hasNileView,
      'hasPyramidView': hasPyramidView,
      'isGatedCommunity': isGatedCommunity,
      'isCompound': isCompound,
      'isInvestment': isInvestment,
      'isResidential': isResidential,
      'isAvailable': isAvailable,
      'hasActiveAuction': hasActiveAuction,
      'availableFrom': availableFrom?.toIso8601String(),
      'searchTerm': searchTerm,
      'sortBy': sortBy,
      'page': page,
      'pageSize': pageSize,
    };
  }

  factory EgyptianPropertyFilters.fromJson(Map<String, dynamic> json) {
    return EgyptianPropertyFilters(
      governorate: json['governorate'],
      district: json['district'],
      area: json['area'],
      nearMetro: json['nearMetro'],
      nearMall: json['nearMall'],
      nearSchool: json['nearSchool'],
      nearHospital: json['nearHospital'],
      propertyCategory: json['propertyCategory'],
      propertySubCategory: json['propertySubCategory'],
      furnished: json['furnished'],
      hasBalcony: json['hasBalcony'],
      hasGarden: json['hasGarden'],
      hasPool: json['hasPool'],
      hasGym: json['hasGym'],
      hasSecurity: json['hasSecurity'],
      hasParking: json['hasParking'],
      minArea: json['minArea'],
      maxArea: json['maxArea'],
      minBedrooms: json['minBedrooms'],
      maxBedrooms: json['maxBedrooms'],
      minBathrooms: json['minBathrooms'],
      maxBathrooms: json['maxBathrooms'],
      minPrice: json['minPrice']?.toDouble(),
      maxPrice: json['maxPrice']?.toDouble(),
      priceRange: json['priceRange'],
      minYearBuilt: json['minYearBuilt'],
      maxYearBuilt: json['maxYearBuilt'],
      propertyAge: json['propertyAge'],
      developerName: json['developerName'],
      projectName: json['projectName'],
      projectType: json['projectType'],
      minDeveloperRating: json['minDeveloperRating']?.toDouble(),
      hasSeaView: json['hasSeaView'],
      hasNileView: json['hasNileView'],
      hasPyramidView: json['hasPyramidView'],
      isGatedCommunity: json['isGatedCommunity'],
      isCompound: json['isCompound'],
      isInvestment: json['isInvestment'],
      isResidential: json['isResidential'],
      isAvailable: json['isAvailable'],
      hasActiveAuction: json['hasActiveAuction'],
      availableFrom: json['availableFrom'] != null
          ? DateTime.parse(json['availableFrom'])
          : null,
      searchTerm: json['searchTerm'],
      sortBy: json['sortBy'],
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
    );
  }

  EgyptianPropertyFilters copyWith({
    String? governorate,
    String? district,
    String? area,
    bool? nearMetro,
    bool? nearMall,
    bool? nearSchool,
    bool? nearHospital,
    String? propertyCategory,
    String? propertySubCategory,
    bool? furnished,
    bool? hasBalcony,
    bool? hasGarden,
    bool? hasPool,
    bool? hasGym,
    bool? hasSecurity,
    bool? hasParking,
    int? minArea,
    int? maxArea,
    int? minBedrooms,
    int? maxBedrooms,
    int? minBathrooms,
    int? maxBathrooms,
    double? minPrice,
    double? maxPrice,
    String? priceRange,
    int? minYearBuilt,
    int? maxYearBuilt,
    String? propertyAge,
    String? developerName,
    String? projectName,
    String? projectType,
    double? minDeveloperRating,
    bool? hasSeaView,
    bool? hasNileView,
    bool? hasPyramidView,
    bool? isGatedCommunity,
    bool? isCompound,
    bool? isInvestment,
    bool? isResidential,
    bool? isAvailable,
    bool? hasActiveAuction,
    DateTime? availableFrom,
    String? searchTerm,
    String? sortBy,
    int? page,
    int? pageSize,
  }) {
    return EgyptianPropertyFilters(
      governorate: governorate ?? this.governorate,
      district: district ?? this.district,
      area: area ?? this.area,
      nearMetro: nearMetro ?? this.nearMetro,
      nearMall: nearMall ?? this.nearMall,
      nearSchool: nearSchool ?? this.nearSchool,
      nearHospital: nearHospital ?? this.nearHospital,
      propertyCategory: propertyCategory ?? this.propertyCategory,
      propertySubCategory: propertySubCategory ?? this.propertySubCategory,
      furnished: furnished ?? this.furnished,
      hasBalcony: hasBalcony ?? this.hasBalcony,
      hasGarden: hasGarden ?? this.hasGarden,
      hasPool: hasPool ?? this.hasPool,
      hasGym: hasGym ?? this.hasGym,
      hasSecurity: hasSecurity ?? this.hasSecurity,
      hasParking: hasParking ?? this.hasParking,
      minArea: minArea ?? this.minArea,
      maxArea: maxArea ?? this.maxArea,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      maxBedrooms: maxBedrooms ?? this.maxBedrooms,
      minBathrooms: minBathrooms ?? this.minBathrooms,
      maxBathrooms: maxBathrooms ?? this.maxBathrooms,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      priceRange: priceRange ?? this.priceRange,
      minYearBuilt: minYearBuilt ?? this.minYearBuilt,
      maxYearBuilt: maxYearBuilt ?? this.maxYearBuilt,
      propertyAge: propertyAge ?? this.propertyAge,
      developerName: developerName ?? this.developerName,
      projectName: projectName ?? this.projectName,
      projectType: projectType ?? this.projectType,
      minDeveloperRating: minDeveloperRating ?? this.minDeveloperRating,
      hasSeaView: hasSeaView ?? this.hasSeaView,
      hasNileView: hasNileView ?? this.hasNileView,
      hasPyramidView: hasPyramidView ?? this.hasPyramidView,
      isGatedCommunity: isGatedCommunity ?? this.isGatedCommunity,
      isCompound: isCompound ?? this.isCompound,
      isInvestment: isInvestment ?? this.isInvestment,
      isResidential: isResidential ?? this.isResidential,
      isAvailable: isAvailable ?? this.isAvailable,
      hasActiveAuction: hasActiveAuction ?? this.hasActiveAuction,
      availableFrom: availableFrom ?? this.availableFrom,
      searchTerm: searchTerm ?? this.searchTerm,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class EgyptianAuctionFilters {
  // Location Filters (Egyptian-specific)
  String? governorate;
  String? district;
  String? area;
  bool? nearMetro;
  bool? nearMall;
  bool? nearSchool;
  bool? nearHospital;

  // Property Type Filters
  String? propertyCategory;
  String? propertySubCategory;
  bool? furnished;
  bool? hasBalcony;
  bool? hasGarden;
  bool? hasPool;
  bool? hasGym;
  bool? hasSecurity;
  bool? hasParking;

  // Size Filters
  int? minArea;
  int? maxArea;
  int? minBedrooms;
  int? maxBedrooms;
  int? minBathrooms;
  int? maxBathrooms;

  // Price Filters (in Egyptian Pounds)
  double? minStartPrice;
  double? maxStartPrice;
  double? minCurrentPrice;
  double? maxCurrentPrice;
  String? priceRange;

  // Auction Status Filters
  String? status; // "active", "upcoming", "ended", "cancelled"
  bool? isActive;
  bool? isUpcoming;
  bool? isEnded;

  // Time Filters
  DateTime? startDateFrom;
  DateTime? startDateTo;
  DateTime? endDateFrom;
  DateTime? endDateTo;
  int? minDurationHours;
  int? maxDurationHours;

  // Bidding Activity Filters
  int? minBidCount;
  int? maxBidCount;
  bool? hasBids;
  bool? noBids;

  // Developer Filters
  String? developerName;
  String? projectName;
  String? projectType; // e.g., "Mixed-Use", "Residential", "Commercial"
  double? minDeveloperRating;

  // Special Features
  bool? hasSeaView;
  bool? hasNileView;
  bool? hasPyramidView;
  bool? isGatedCommunity;
  bool? isCompound;
  bool? isInvestment;
  bool? isResidential;

  // Age Filters
  int? minYearBuilt;
  int? maxYearBuilt;
  String? propertyAge;

  // Search and Sorting
  String? searchTerm;
  String?
  sortBy; // "price_asc", "price_desc", "end_time_asc", "end_time_desc", "bid_count_desc", "newest", "popularity"
  int page;
  int pageSize;

  EgyptianAuctionFilters({
    this.governorate,
    this.district,
    this.area,
    this.nearMetro,
    this.nearMall,
    this.nearSchool,
    this.nearHospital,
    this.propertyCategory,
    this.propertySubCategory,
    this.furnished,
    this.hasBalcony,
    this.hasGarden,
    this.hasPool,
    this.hasGym,
    this.hasSecurity,
    this.hasParking,
    this.minArea,
    this.maxArea,
    this.minBedrooms,
    this.maxBedrooms,
    this.minBathrooms,
    this.maxBathrooms,
    this.minStartPrice,
    this.maxStartPrice,
    this.minCurrentPrice,
    this.maxCurrentPrice,
    this.priceRange,
    this.status,
    this.isActive,
    this.isUpcoming,
    this.isEnded,
    this.startDateFrom,
    this.startDateTo,
    this.endDateFrom,
    this.endDateTo,
    this.minDurationHours,
    this.maxDurationHours,
    this.minBidCount,
    this.maxBidCount,
    this.hasBids,
    this.noBids,
    this.developerName,
    this.projectName,
    this.projectType,
    this.minDeveloperRating,
    this.hasSeaView,
    this.hasNileView,
    this.hasPyramidView,
    this.isGatedCommunity,
    this.isCompound,
    this.isInvestment,
    this.isResidential,
    this.minYearBuilt,
    this.maxYearBuilt,
    this.propertyAge,
    this.searchTerm,
    this.sortBy,
    this.page = 1,
    this.pageSize = 20,
  });

  Map<String, dynamic> toJson() {
    return {
      'governorate': governorate,
      'district': district,
      'area': area,
      'nearMetro': nearMetro,
      'nearMall': nearMall,
      'nearSchool': nearSchool,
      'nearHospital': nearHospital,
      'propertyCategory': propertyCategory,
      'propertySubCategory': propertySubCategory,
      'furnished': furnished,
      'hasBalcony': hasBalcony,
      'hasGarden': hasGarden,
      'hasPool': hasPool,
      'hasGym': hasGym,
      'hasSecurity': hasSecurity,
      'hasParking': hasParking,
      'minArea': minArea,
      'maxArea': maxArea,
      'minBedrooms': minBedrooms,
      'maxBedrooms': maxBedrooms,
      'minBathrooms': minBathrooms,
      'maxBathrooms': maxBathrooms,
      'minStartPrice': minStartPrice,
      'maxStartPrice': maxStartPrice,
      'minCurrentPrice': minCurrentPrice,
      'maxCurrentPrice': maxCurrentPrice,
      'priceRange': priceRange,
      'status': status,
      'isActive': isActive,
      'isUpcoming': isUpcoming,
      'isEnded': isEnded,
      'startDateFrom': startDateFrom?.toIso8601String(),
      'startDateTo': startDateTo?.toIso8601String(),
      'endDateFrom': endDateFrom?.toIso8601String(),
      'endDateTo': endDateTo?.toIso8601String(),
      'minDurationHours': minDurationHours,
      'maxDurationHours': maxDurationHours,
      'minBidCount': minBidCount,
      'maxBidCount': maxBidCount,
      'hasBids': hasBids,
      'noBids': noBids,
      'developerName': developerName,
      'projectName': projectName,
      'minDeveloperRating': minDeveloperRating,
      'hasSeaView': hasSeaView,
      'hasNileView': hasNileView,
      'hasPyramidView': hasPyramidView,
      'isGatedCommunity': isGatedCommunity,
      'isCompound': isCompound,
      'isInvestment': isInvestment,
      'isResidential': isResidential,
      'minYearBuilt': minYearBuilt,
      'maxYearBuilt': maxYearBuilt,
      'propertyAge': propertyAge,
      'searchTerm': searchTerm,
      'sortBy': sortBy,
      'page': page,
      'pageSize': pageSize,
    };
  }

  factory EgyptianAuctionFilters.fromJson(Map<String, dynamic> json) {
    return EgyptianAuctionFilters(
      governorate: json['governorate'],
      district: json['district'],
      area: json['area'],
      nearMetro: json['nearMetro'],
      nearMall: json['nearMall'],
      nearSchool: json['nearSchool'],
      nearHospital: json['nearHospital'],
      propertyCategory: json['propertyCategory'],
      propertySubCategory: json['propertySubCategory'],
      furnished: json['furnished'],
      hasBalcony: json['hasBalcony'],
      hasGarden: json['hasGarden'],
      hasPool: json['hasPool'],
      hasGym: json['hasGym'],
      hasSecurity: json['hasSecurity'],
      hasParking: json['hasParking'],
      minArea: json['minArea'],
      maxArea: json['maxArea'],
      minBedrooms: json['minBedrooms'],
      maxBedrooms: json['maxBedrooms'],
      minBathrooms: json['minBathrooms'],
      maxBathrooms: json['maxBathrooms'],
      minStartPrice: json['minStartPrice']?.toDouble(),
      maxStartPrice: json['maxStartPrice']?.toDouble(),
      minCurrentPrice: json['minCurrentPrice']?.toDouble(),
      maxCurrentPrice: json['maxCurrentPrice']?.toDouble(),
      priceRange: json['priceRange'],
      status: json['status'],
      isActive: json['isActive'],
      isUpcoming: json['isUpcoming'],
      isEnded: json['isEnded'],
      startDateFrom: json['startDateFrom'] != null
          ? DateTime.parse(json['startDateFrom'])
          : null,
      startDateTo: json['startDateTo'] != null
          ? DateTime.parse(json['startDateTo'])
          : null,
      endDateFrom: json['endDateFrom'] != null
          ? DateTime.parse(json['endDateFrom'])
          : null,
      endDateTo: json['endDateTo'] != null
          ? DateTime.parse(json['endDateTo'])
          : null,
      minDurationHours: json['minDurationHours'],
      maxDurationHours: json['maxDurationHours'],
      minBidCount: json['minBidCount'],
      maxBidCount: json['maxBidCount'],
      hasBids: json['hasBids'],
      noBids: json['noBids'],
      developerName: json['developerName'],
      projectName: json['projectName'],
      projectType: json['projectType'],
      minDeveloperRating: json['minDeveloperRating']?.toDouble(),
      hasSeaView: json['hasSeaView'],
      hasNileView: json['hasNileView'],
      hasPyramidView: json['hasPyramidView'],
      isGatedCommunity: json['isGatedCommunity'],
      isCompound: json['isCompound'],
      isInvestment: json['isInvestment'],
      isResidential: json['isResidential'],
      minYearBuilt: json['minYearBuilt'],
      maxYearBuilt: json['maxYearBuilt'],
      propertyAge: json['propertyAge'],
      searchTerm: json['searchTerm'],
      sortBy: json['sortBy'],
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
    );
  }
}

/// Egyptian property categories
class EgyptianPropertyCategories {
  static const String apartment = "Apartment";
  static const String villa = "Villa";
  static const String townhouse = "Townhouse";
  static const String studio = "Studio";
  static const String penthouse = "Penthouse";
  static const String duplex = "Duplex";
  static const String triplex = "Triplex";
  static const String gardenApartment = "Garden Apartment";
  static const String groundFloor = "Ground Floor";
  static const String roofApartment = "Roof Apartment";
  static const String office = "Office";
  static const String shop = "Shop";
  static const String warehouse = "Warehouse";
  static const String land = "Land";

  static List<String> get all => [
    apartment,
    villa,
    townhouse,
    studio,
    penthouse,
    duplex,
    triplex,
    gardenApartment,
    groundFloor,
    roofApartment,
    office,
    shop,
    warehouse,
    land,
  ];
}

/// Egyptian locations (governorates and districts)
class EgyptianLocations {
  static const Map<String, List<String>> governorates = {
    "Cairo": [
      "New Cairo",
      "Maadi",
      "Zamalek",
      "Heliopolis",
      "Nasr City",
      "Dokki",
      "Giza",
      "6th October",
      "Sheikh Zayed",
      "Madinaty",
      "Rehab City",
      "El Shorouk",
      "Badr City",
      "New Administrative Capital",
    ],
    "Giza": [
      "Giza",
      "6th October",
      "Sheikh Zayed",
      "Agouza",
      "Dokki",
      "Imbaba",
      "Boulaq",
      "Faisal",
      "Haram",
      "Pyramids",
    ],
    "Alexandria": [
      "Alexandria",
      "North Coast",
      "Marina",
      "Sidi Abdel Rahman",
      "El Alamein",
      "Borg El Arab",
      "New Borg El Arab",
    ],
    "Red Sea": [
      "Hurghada",
      "Sharm El Sheikh",
      "Dahab",
      "Marsa Alam",
      "El Gouna",
      "Sahl Hasheesh",
      "Makadi Bay",
    ],
    "North Coast": [
      "Marina",
      "Sidi Abdel Rahman",
      "Ras El Hekma",
      "El Alamein",
      "New Alamein",
      "Sidi Heneish",
      "Marassi",
    ],
    "New Administrative Capital": [
      "Downtown",
      "Government District",
      "Financial District",
      "Residential District",
      "Green River",
      "Monorail",
    ],
  };

  static List<String> get allGovernorates => governorates.keys.toList();
  static List<String> get allDistricts =>
      governorates.values.expand((x) => x).toList();
}

/// Egyptian price ranges in EGP
class EgyptianPriceRanges {
  static const String under1M = "under-1m"; // Under 1,000,000 EGP
  static const String oneToThreeM = "1m-3m"; // 1,000,000 - 3,000,000 EGP
  static const String threeToFiveM = "3m-5m"; // 3,000,000 - 5,000,000 EGP
  static const String fiveToTenM = "5m-10m"; // 5,000,000 - 10,000,000 EGP
  static const String tenToTwentyM = "10m-20m"; // 10,000,000 - 20,000,000 EGP
  static const String overTwentyM = "over-20m"; // Over 20,000,000 EGP

  static const Map<String, (double, double)> ranges = {
    under1M: (0, 1000000),
    oneToThreeM: (1000000, 3000000),
    threeToFiveM: (3000000, 5000000),
    fiveToTenM: (5000000, 10000000),
    tenToTwentyM: (10000000, 20000000),
    overTwentyM: (20000000, double.infinity),
  };

  static List<String> get all => ranges.keys.toList();
}

/// Egyptian property sorting options
class EgyptianPropertySorting {
  static const String priceAscending = "price_asc";
  static const String priceDescending = "price_desc";
  static const String areaAscending = "area_asc";
  static const String areaDescending = "area_desc";
  static const String newest = "newest";
  static const String oldest = "oldest";
  static const String popularity = "popularity";

  static List<Map<String, String>> get sortOptions => [
    {"value": priceAscending, "label": "Price: Low to High"},
    {"value": priceDescending, "label": "Price: High to Low"},
    {"value": areaAscending, "label": "Area: Small to Large"},
    {"value": areaDescending, "label": "Area: Large to Small"},
    {"value": newest, "label": "Newest First"},
    {"value": oldest, "label": "Oldest First"},
    {"value": popularity, "label": "Most Popular"},
  ];
}

/// Egyptian auction sorting options
class EgyptianAuctionSorting {
  static const String priceAscending = "price_asc";
  static const String priceDescending = "price_desc";
  static const String currentPriceAscending = "current_price_asc";
  static const String currentPriceDescending = "current_price_desc";
  static const String endTimeAscending = "end_time_asc";
  static const String endTimeDescending = "end_time_desc";
  static const String startTimeAscending = "start_time_asc";
  static const String startTimeDescending = "start_time_desc";
  static const String bidCountDescending = "bid_count_desc";
  static const String bidCountAscending = "bid_count_asc";
  static const String areaAscending = "area_asc";
  static const String areaDescending = "area_desc";
  static const String newest = "newest";
  static const String oldest = "oldest";
  static const String popularity = "popularity";

  static List<Map<String, String>> get sortOptions => [
    {"value": priceAscending, "label": "Price: Low to High"},
    {"value": priceDescending, "label": "Price: High to Low"},
    {"value": currentPriceAscending, "label": "Current Price: Low to High"},
    {"value": currentPriceDescending, "label": "Current Price: High to Low"},
    {"value": endTimeAscending, "label": "Ending Soon"},
    {"value": endTimeDescending, "label": "Ending Later"},
    {"value": bidCountDescending, "label": "Most Bids"},
    {"value": bidCountAscending, "label": "Least Bids"},
    {"value": areaAscending, "label": "Area: Small to Large"},
    {"value": areaDescending, "label": "Area: Large to Small"},
    {"value": newest, "label": "Newest First"},
    {"value": popularity, "label": "Most Popular"},
  ];
}
