using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class DeveloperPermission
    {
        [Key]
        public long DeveloperPermissionId { get; set; }

        [Required]
        public long DeveloperId { get; set; }

        [Required]
        [MaxLength(50)]
        public string FeatureName { get; set; } = string.Empty;

        [Required]
        public bool IsEnabled { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        // Navigation property
        [ForeignKey("DeveloperId")]
        public Account? Developer { get; set; }
    }
}

