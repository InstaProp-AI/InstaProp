using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace PropertyFlipperAPI.Models
{
    /// <summary>
    /// Parent Property - Template for similar properties
    /// Groups properties by: Project + Bedrooms + Bathrooms + Area + Type + Finishing
    /// </summary>
    public class ParentProperty
    {
        [Key]
        public int ParentPropertyId { get; set; }

        [Required]
        [MaxLength(200)]
        public string ProjectName { get; set; } = string.Empty;

        [Required]
        public int Bedrooms { get; set; }

        [Required]
        public int Bathrooms { get; set; }

        [Required]
        public int AreaSqm { get; set; } // Area in square meters

        [Required]
        [MaxLength(100)]
        public string PropertyType { get; set; } = string.Empty; // Apartment, Villa, Townhouse, Duplex, Penthouse, etc.

        [Required]
        [MaxLength(100)]
        public string FinishingType { get; set; } = string.Empty; // Finished, Semi-Finished, Core&Shell

        // Compound/Project-level Amenities
        public bool HasPool { get; set; }
        public bool HasGym { get; set; }
        public bool HasSecurity { get; set; }
        public bool HasParking { get; set; }
        public bool HasGarden { get; set; }
        public bool HasPlayground { get; set; }
        public bool HasClubhouse { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Project relationship
        public long? ProjectId { get; set; }
        public virtual Project? Project { get; set; }

        // Navigation properties
        public virtual ICollection<ChildProperty> ChildProperties { get; set; } = new List<ChildProperty>();
        public virtual ICollection<PropertyPriceHistory> PriceHistories { get; set; } = new List<PropertyPriceHistory>();
    }
}

