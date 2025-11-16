using System.ComponentModel.DataAnnotations;

namespace InstapropAPI.Models
{
    /// <summary>
    /// Egyptian-specific auction filtering and sorting options
    /// Designed for the Egyptian real estate auction market
    /// </summary>
    public class EgyptianAuctionFilters
    {
        // Location Filters (Egyptian-specific)
        public string? Governorate { get; set; }
        public string? District { get; set; }
        public string? Area { get; set; }
        public bool? NearMetro { get; set; }
        public bool? NearMall { get; set; }
        public bool? NearSchool { get; set; }
        public bool? NearHospital { get; set; }

        // Property Type Filters
        public string? PropertyType { get; set; }
        public string? PropertySubtype { get; set; }
        public bool? Furnished { get; set; }
        public bool? HasBalcony { get; set; }
        public bool? HasGarden { get; set; }
        public bool? HasPool { get; set; }
        public bool? HasGym { get; set; }
        public bool? HasSecurity { get; set; }
        public bool? HasParking { get; set; }

        // Size Filters
        public int? MinArea { get; set; }
        public int? MaxArea { get; set; }
        public int? MinBedrooms { get; set; }
        public int? MaxBedrooms { get; set; }
        public int? MinBathrooms { get; set; }
        public int? MaxBathrooms { get; set; }

        // Price Filters (in Egyptian Pounds)
        public decimal? MinStartPrice { get; set; }
        public decimal? MaxStartPrice { get; set; }
        public decimal? MinCurrentPrice { get; set; }
        public decimal? MaxCurrentPrice { get; set; }
        public string? PriceRange { get; set; }

        // Auction Status Filters
        public string? Status { get; set; } // "active", "upcoming", "ended", "cancelled"
        public bool? IsActive { get; set; }
        public bool? IsUpcoming { get; set; }
        public bool? IsEnded { get; set; }

        // Time Filters
        public DateTime? StartDateFrom { get; set; }
        public DateTime? StartDateTo { get; set; }
        public DateTime? EndDateFrom { get; set; }
        public DateTime? EndDateTo { get; set; }
        public int? MinDurationHours { get; set; }
        public int? MaxDurationHours { get; set; }

        // Bidding Activity Filters
        public int? MinBidCount { get; set; }
        public int? MaxBidCount { get; set; }
        public bool? HasBids { get; set; }
        public bool? NoBids { get; set; }

        // Developer Filters
        public string? DeveloperName { get; set; }
        public string? ProjectName { get; set; }
        public double? MinDeveloperRating { get; set; }

        // Special Features
        public bool? HasSeaView { get; set; }
        public bool? HasNileView { get; set; }
        public bool? HasPyramidView { get; set; }
        public bool? IsGatedCommunity { get; set; }
        public bool? IsCompound { get; set; }
        public bool? IsInvestment { get; set; }
        public bool? IsResidential { get; set; }

        // Age Filters
        public int? MinYearBuilt { get; set; }
        public int? MaxYearBuilt { get; set; }
        public string? PropertyAge { get; set; }

        // Search and Sorting
        public string? SearchTerm { get; set; }
        public string? SortBy { get; set; } // "price_asc", "price_desc", "end_time_asc", "end_time_desc", "bid_count_desc", "newest", "popularity"
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 20;
    }

    /// <summary>
    /// Egyptian auction sorting options
    /// </summary>
    public static class EgyptianAuctionSorting
    {
        public const string PriceAscending = "price_asc";
        public const string PriceDescending = "price_desc";
        public const string CurrentPriceAscending = "current_price_asc";
        public const string CurrentPriceDescending = "current_price_desc";
        public const string EndTimeAscending = "end_time_asc";
        public const string EndTimeDescending = "end_time_desc";
        public const string StartTimeAscending = "start_time_asc";
        public const string StartTimeDescending = "start_time_desc";
        public const string BidCountDescending = "bid_count_desc";
        public const string BidCountAscending = "bid_count_asc";
        public const string Newest = "newest";
        public const string Oldest = "oldest";
        public const string Popularity = "popularity";
        public const string AreaAscending = "area_asc";
        public const string AreaDescending = "area_desc";
        public const string DeveloperRating = "developer_rating";
    }

    /// <summary>
    /// Egyptian auction status options
    /// </summary>
    public static class EgyptianAuctionStatus
    {
        public const string Active = "active";
        public const string Upcoming = "upcoming";
        public const string Ended = "ended";
        public const string Cancelled = "cancelled";
        public const string Sold = "sold";
    }
}
