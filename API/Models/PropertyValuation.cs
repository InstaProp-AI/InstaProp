using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    /// <summary>
    /// Property Valuation - Stores AI-generated and manual property valuations
    /// Used for caching valuations to avoid repeated AI calls and for historical analysis
    /// </summary>
    public class PropertyValuation
    {
        [Key]
        public int ValuationId { get; set; }

        [Required]
        [ForeignKey("ChildProperty")]
        public int PropertyId { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal EstimatedValue { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal? Confidence { get; set; } // 0-100 confidence percentage

        [Required]
        public DateTime CalculatedAt { get; set; } = DateTime.UtcNow;

        [Required]
        [MaxLength(20)]
        public string ValuationSource { get; set; } = "AI"; // "AI" or "Manual"

        [MaxLength(2000)]
        public string? AIReasoning { get; set; } // AI's reasoning for the valuation

        public int? ComparablesCount { get; set; } // Number of comparable properties used

        [Column(TypeName = "decimal(18,2)")]
        public decimal? PriceRangeLow { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal? PriceRangeHigh { get; set; }

        [MaxLength(1000)]
        public string? MarketTrends { get; set; } // AI's market trend analysis

        // Navigation properties
        public virtual ChildProperty Property { get; set; } = null!;
    }

    /// <summary>
    /// Valuation source types
    /// </summary>
    public static class ValuationSource
    {
        public const string AI = "AI";
        public const string Manual = "Manual";
    }
}
