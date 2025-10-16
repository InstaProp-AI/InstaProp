using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public class PropertyView
    {
        [Key]
        public long ViewId { get; set; }

        [Required]
        public long PropertyId { get; set; }

        [ForeignKey(nameof(PropertyId))]
        public Property Property { get; set; } = null!;

        public long? UserId { get; set; } // Null for anonymous views

        [ForeignKey(nameof(UserId))]
        public Account? User { get; set; }

        public DateTime ViewedAt { get; set; } = DateTime.UtcNow;

        public string? UserLocation { get; set; } // Geographic location

        public int DurationSeconds { get; set; } = 0; // Time spent viewing

        public string? DeviceType { get; set; } // Mobile, Desktop, Tablet
    }
}

