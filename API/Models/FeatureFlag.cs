using System.ComponentModel.DataAnnotations;

namespace InstapropAPI.Models
{
    public class FeatureFlag
    {
        [Key]
        public Guid FeatureFlagId { get; set; }

        [Required]
        [MaxLength(100)]
        public string FeatureKey { get; set; } = string.Empty;

        public bool IsEnabled { get; set; }

        [MaxLength(300)]
        public string Description { get; set; } = string.Empty;

        public DateTime LastUpdatedAt { get; set; } = DateTime.UtcNow;

        public Guid? UpdatedByAdminId { get; set; }
    }
}
