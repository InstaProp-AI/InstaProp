using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    /// <summary>
    /// Property Price History - Tracks price changes over time for parent properties
    /// Records come from: Auction wins, Listings, Direct sales
    /// </summary>
    public class PropertyPriceHistory
    {
        [Key]
        public int PriceHistoryId { get; set; }

        [Required]
        [ForeignKey("ParentProperty")]
        public int ParentPropertyId { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }

        [Required]
        public DateTime PriceDate { get; set; }

        // Additional properties for controller compatibility
        public DateTime Date => PriceDate;
        public string? Notes { get; set; }

        [Required]
        [MaxLength(50)]
        public string Source { get; set; } = string.Empty; // "AuctionWin", "Listing", "DirectSale"

        // Optional: Link to specific auction if source is AuctionWin
        [ForeignKey("Auction")]
        public long? AuctionId { get; set; }

        // Optional: Which specific child property this price is for
        [ForeignKey("ChildProperty")]
        public int? ChildPropertyId { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual ParentProperty? ParentProperty { get; set; }
        public virtual Auction? Auction { get; set; }
        public virtual ChildProperty? ChildProperty { get; set; }
    }

    /// <summary>
    /// Price source types
    /// </summary>
    public static class PriceSource
    {
        public const string AuctionWin = "AuctionWin";
        public const string Listing = "Listing";
        public const string DirectSale = "DirectSale";
    }
}

