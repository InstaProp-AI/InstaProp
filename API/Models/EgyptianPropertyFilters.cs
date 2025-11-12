using System.ComponentModel.DataAnnotations;

namespace PropertyFlipperAPI.Models
{
    /// <summary>
    /// Egyptian-specific property filtering and sorting options
    /// Designed specifically for the Egyptian real estate market
    /// </summary>
    public class EgyptianPropertyFilters
    {
        // Location Filters (Egyptian-specific)
        public string? Governorate { get; set; } // Cairo, Giza, Alexandria, etc.
        public string? District { get; set; } // New Cairo, Maadi, Zamalek, etc.
        public string? Area { get; set; } // Specific areas within districts
        public bool? NearMetro { get; set; } // Near Cairo Metro stations
        public bool? NearMall { get; set; } // Near major shopping malls
        public bool? NearSchool { get; set; } // Near international schools
        public bool? NearHospital { get; set; } // Near major hospitals

        // Property Type Filters (Egyptian market categories)
        public string? PropertyType { get; set; } // Apartment, Villa, Townhouse, Studio, Penthouse
        public string? PropertySubtype { get; set; } // Duplex, Triplex, Garden Apartment, etc.
        public bool? Furnished { get; set; } // Fully furnished, semi-furnished, unfurnished
        public bool? HasBalcony { get; set; }
        public bool? HasGarden { get; set; }
        public bool? HasPool { get; set; }
        public bool? HasGym { get; set; }
        public bool? HasSecurity { get; set; }
        public bool? HasParking { get; set; }

        // Size Filters (in square meters - Egyptian standard)
        public int? MinArea { get; set; } // Minimum area in square meters
        public int? MaxArea { get; set; } // Maximum area in square meters
        public int? MinBedrooms { get; set; }
        public int? MaxBedrooms { get; set; }
        public int? MinBathrooms { get; set; }
        public int? MaxBathrooms { get; set; }

        // Price Filters (in Egyptian Pounds)
        public decimal? MinPrice { get; set; } // Minimum price in EGP
        public decimal? MaxPrice { get; set; } // Maximum price in EGP
        public string? PriceRange { get; set; } // Predefined ranges: "under-1m", "1m-3m", "3m-5m", "5m-10m", "over-10m"

        // Age Filters
        public int? MinYearBuilt { get; set; }
        public int? MaxYearBuilt { get; set; }
        public string? PropertyAge { get; set; } // "new", "recent", "old", "heritage"

        // Developer Filters
        public string? DeveloperName { get; set; } // Talaat Moustafa, Emaar, SODIC, etc.
        public string? ProjectName { get; set; } // Madinaty, New Capital, etc.
        public double? MinDeveloperRating { get; set; } // Minimum developer rating

        // Special Features (Egyptian market specific)
        public bool? HasSeaView { get; set; } // Sea view (North Coast, Red Sea)
        public bool? HasNileView { get; set; } // Nile view (Cairo, Giza)
        public bool? HasPyramidView { get; set; } // Pyramid view (Giza)
        public bool? IsGatedCommunity { get; set; } // Gated community
        public bool? IsCompound { get; set; } // Residential compound
        public bool? IsInvestment { get; set; } // Investment property
        public bool? IsResidential { get; set; } // Residential property

        // Availability Filters
        public bool? IsAvailable { get; set; }
        public bool? HasActiveAuction { get; set; }
        public DateTime? AvailableFrom { get; set; }

        // Search and Sorting
        public string? SearchTerm { get; set; } // General search term
        public string? SortBy { get; set; } // "price_asc", "price_desc", "area_asc", "area_desc", "newest", "oldest", "popularity"
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 20;
    }

    /// <summary>
    /// Egyptian property sorting options
    /// </summary>
    public static class EgyptianPropertySorting
    {
        public const string PriceAscending = "price_asc";
        public const string PriceDescending = "price_desc";
        public const string AreaAscending = "area_asc";
        public const string AreaDescending = "area_desc";
        public const string Newest = "newest";
        public const string Oldest = "oldest";
        public const string Popularity = "popularity";
        public const string DeveloperRating = "developer_rating";
        public const string DistanceFromCenter = "distance_center";
    }

    /// <summary>
    /// Egyptian property types
    /// </summary>
    public static class EgyptianPropertyTypes
    {
        // Main Categories
        public const string Apartment = "Apartment";
        public const string Villa = "Villa";
        public const string Townhouse = "Townhouse";
        public const string Studio = "Studio";
        public const string Penthouse = "Penthouse";
        public const string Duplex = "Duplex";
        public const string Triplex = "Triplex";
        public const string GardenApartment = "Garden Apartment";
        public const string GroundFloor = "Ground Floor";
        public const string RoofApartment = "Roof Apartment";

        // Commercial
        public const string Office = "Office";
        public const string Shop = "Shop";
        public const string Warehouse = "Warehouse";
        public const string Land = "Land";
    }

    /// <summary>
    /// Egyptian governorates and major districts
    /// </summary>
    public static class EgyptianLocations
    {
        public static readonly Dictionary<string, List<string>> Governorates = new()
        {
            ["Cairo"] = new List<string>
            {
                "New Cairo", "Maadi", "Zamalek", "Heliopolis", "Nasr City", 
                "Dokki", "Giza", "6th October", "Sheikh Zayed", "Madinaty",
                "Rehab City", "El Shorouk", "Badr City", "New Administrative Capital"
            },
            ["Giza"] = new List<string>
            {
                "Giza", "6th October", "Sheikh Zayed", "Agouza", "Dokki",
                "Imbaba", "Boulaq", "Faisal", "Haram", "Pyramids"
            },
            ["Alexandria"] = new List<string>
            {
                "Alexandria", "North Coast", "Marina", "Sidi Abdel Rahman",
                "El Alamein", "Borg El Arab", "New Borg El Arab"
            },
            ["Red Sea"] = new List<string>
            {
                "Hurghada", "Sharm El Sheikh", "Dahab", "Marsa Alam",
                "El Gouna", "Sahl Hasheesh", "Makadi Bay"
            },
            ["North Coast"] = new List<string>
            {
                "Marina", "Sidi Abdel Rahman", "Ras El Hekma", "El Alamein",
                "New Alamein", "Sidi Heneish", "Marassi"
            },
            ["New Administrative Capital"] = new List<string>
            {
                "Downtown", "Government District", "Financial District",
                "Residential District", "Green River", "Monorail"
            }
        };

        public static readonly List<string> AllGovernorates = Governorates.Keys.ToList();
        public static readonly List<string> AllDistricts = Governorates.Values.SelectMany(x => x).ToList();
    }

    /// <summary>
    /// Egyptian price ranges in EGP
    /// </summary>
    public static class EgyptianPriceRanges
    {
        public const string Under1M = "under-1m";      // Under 1,000,000 EGP
        public const string OneToThreeM = "1m-3m";     // 1,000,000 - 3,000,000 EGP
        public const string ThreeToFiveM = "3m-5m";    // 3,000,000 - 5,000,000 EGP
        public const string FiveToTenM = "5m-10m";     // 5,000,000 - 10,000,000 EGP
        public const string TenToTwentyM = "10m-20m";  // 10,000,000 - 20,000,000 EGP
        public const string OverTwentyM = "over-20m";  // Over 20,000,000 EGP

        public static readonly Dictionary<string, (decimal Min, decimal Max)> Ranges = new()
        {
            [Under1M] = (0, 1_000_000),
            [OneToThreeM] = (1_000_000, 3_000_000),
            [ThreeToFiveM] = (3_000_000, 5_000_000),
            [FiveToTenM] = (5_000_000, 10_000_000),
            [TenToTwentyM] = (10_000_000, 20_000_000),
            [OverTwentyM] = (20_000_000, decimal.MaxValue)
        };
    }
}
