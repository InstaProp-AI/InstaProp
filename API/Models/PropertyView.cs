using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class PropertyView
    {
        [Key]
        public Guid ViewId { get; set; }

        [Required]
        public Guid PropertyId { get; set; }

        [ForeignKey(nameof(PropertyId))]
        public ChildProperty Property { get; set; } = null!;

        public Guid? UserId { get; set; } // Null for anonymous views

        [ForeignKey(nameof(UserId))]
        public AccountBase? User { get; set; }

        public DateTime ViewedAt { get; set; } = DateTime.UtcNow;

        public string? UserLocation { get; set; } // Geographic location

        public int DurationSeconds { get; set; } = 0; // Time spent viewing

        public string? DeviceType { get; set; } // Mobile, Desktop, Tablet
    }
}

