using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;
using System.Text.Json.Serialization;

namespace PropertyFlipperAPI.Models
{
    public class Property
    {
        [Key]
        public long PropertyId { get; set; }

        [Required]
        public long OwnerId { get; set; }

        [ForeignKey(nameof(OwnerId))]
        [JsonIgnore]
        public Account? Owner { get; set; }

        public long? ProjectId { get; set; }

        [ForeignKey(nameof(ProjectId))]
        [JsonIgnore]
        public Project? Project { get; set; }

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        public string? Location { get; set; } // could be address or lat-long string

        [Required]
        public PropertyType Type { get; set; } = PropertyType.Resale;

        [Required]
        public PropertyStatus Status { get; set; } = PropertyStatus.NotApproved;

        public int Bedrooms { get; set; }

        public int Bathrooms { get; set; }

        public int SquareFeet { get; set; }

        public int YearBuilt { get; set; }

        public string? Category { get; set; } = "Residential";

        public string ImageUrl { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        // 🔗 Relations
        public ICollection<PropertyDoc> PropertyDocs { get; set; } = new List<PropertyDoc>();
        public ICollection<PropertyImage> PropertyImages { get; set; } = new List<PropertyImage>();
        public ICollection<Auction> Auctions { get; set; } = new List<Auction>();

        // Helper property to check if property has an active auction
        [NotMapped]
        public bool HasActiveAuction => Auctions.Any(a => 
            a.Status == "Active" || 
            a.Status == "Requested" || 
            a.Status == "Approved");
    }
}