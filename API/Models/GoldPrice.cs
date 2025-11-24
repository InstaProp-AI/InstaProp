using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    /// <summary>
    /// Gold Price - Monthly gold prices for investment comparison
    /// Tracks Egyptian gold market prices over 5 years (60 months)
    /// </summary>
    public class GoldPrice
    {
        [Key]
        public Guid GoldPriceId { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal PricePerGram { get; set; } // Price in EGP per gram

        // Additional properties for controller compatibility
        public decimal Price => PricePerGram;
        public string Currency => "EGP";
        public decimal Weight => 1.0m; // 1 gram

        [Required]
        public int Month { get; set; } // 1-12

        [Required]
        public int Year { get; set; }

        [Required]
        public DateTime Date { get; set; } // First day of the month

        [Required]
        [MaxLength(50)]
        public string Source { get; set; } = "Manual"; // "API" or "Manual"

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }

    /// <summary>
    /// Gold price source types
    /// </summary>
    public static class GoldPriceSource
    {
        public const string API = "API";
        public const string Manual = "Manual";
    }
}

