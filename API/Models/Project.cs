using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class Project
    {
        [Key]
        public Guid ProjectId { get; set; }

        [Required]
        public Guid DeveloperId { get; set; }

        [ForeignKey(nameof(DeveloperId))]
        public DeveloperAccount Developer { get; set; } = null!;

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        [MaxLength(200)]
        public string? Location { get; set; }

        [MaxLength(2)]
        public string? Country { get; set; } // ISO 3166-1 alpha-2 country code

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public bool IsActive { get; set; } = true;

        // 🔗 Relations
        // Properties are linked via Properties/Properties table through Property.ProjectId
    }
}

