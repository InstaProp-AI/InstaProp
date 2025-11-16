using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class AIChat
    {
        [Key]
        public long AIChatId { get; set; }

        [Required]
        public long UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public Account User { get; set; } = null!;

        public DateTime StartedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [Required]
        [MaxLength(20)]
        public string Status { get; set; } = "Active"; // Active, Completed

        // Store collected preferences as JSON
        public string? UserPreferences { get; set; }

        // Navigation property
        public ICollection<AIChatMessage> Messages { get; set; } = new List<AIChatMessage>();
    }
}


