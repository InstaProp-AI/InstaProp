using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    /// <summary>
    /// Property Price History - Tracks price changes over time per property.
    /// </summary>
    public class PropertyPriceHistory
    {
        [Key]
        public Guid PriceHistoryId { get; set; }

        [Required]
        [ForeignKey("Property")]
        public Guid PropertyId { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }

        [Required]
        public DateTime PriceDate { get; set; }

        public DateTime Date => PriceDate;
        public string? Notes { get; set; }

        [Required]
        [MaxLength(50)]
        public string Source { get; set; } = string.Empty;

        [ForeignKey("Auction")]
        public Guid? AuctionId { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public virtual Property? Property { get; set; }
        public virtual Auction? Auction { get; set; }
    }

    public static class PriceSource
    {
        public const string AuctionWin = "AuctionWin";
        public const string Listing = "Listing";
        public const string DirectSale = "DirectSale";
    }
}
