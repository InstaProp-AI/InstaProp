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

        public decimal StartingPrice { get; set; }

        [Required]
        public PropertyType Type { get; set; } = PropertyType.Resale;

        public bool IsApproved { get; set; } = false; // set by admin
        
        public bool IsVerified { get; set; } = false; // KYC and docs verified by admin
        
        public bool IsEditable { get; set; } = true; // Can be edited only before verification

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
        public ICollection<Auction> Auctions { get; set; } = new List<Auction>();
    }
}