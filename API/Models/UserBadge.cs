using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class UserBadge
    {
        [Key]
        public Guid BadgeId { get; set; }

        [Required]
        public Guid AccountId { get; set; }

        [ForeignKey(nameof(AccountId))]
        public AccountBase Account { get; set; } = null!;

        [Required]
        [MaxLength(100)]
        public string BadgeName { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string BadgeIcon { get; set; } = string.Empty; // Emoji or icon name

        public string? Description { get; set; }

        public DateTime AwardedAt { get; set; } = DateTime.UtcNow;
    }
}

