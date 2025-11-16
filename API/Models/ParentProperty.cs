using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace InstapropAPI.Models
{
    /// <summary>
    /// Parent Property - Template for similar properties
    /// Groups properties by: Project + Bedrooms + Bathrooms + Area + Type + Finishing
    /// </summary>
    public class ParentProperty
    {
        [Key]
        public int ParentPropertyId { get; set; }

        [MaxLength(200)]
        public string? ProjectName { get; set; }

        [Required]
        public int Bedrooms { get; set; }

        [Required]
        public int Bathrooms { get; set; }

        [Required]
        public int AreaSqm { get; set; } // Area in square meters

        [Required]
        [MaxLength(100)]
        public string Type { get; set; } = PropertyTypeHelper.ToDisplayName(PropertyType.Apartment);

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

