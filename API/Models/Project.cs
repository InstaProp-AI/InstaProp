using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public class Project
    {
        [Key]
        public long ProjectId { get; set; }

        [Required]
        public long DeveloperId { get; set; }

        [ForeignKey(nameof(DeveloperId))]
        public Account Developer { get; set; } = null!;

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        [MaxLength(200)]
        public string? Location { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public bool IsActive { get; set; } = true;

        // 🔗 Relations
        // Properties navigation removed - using ChildProperty system now
    }
}

