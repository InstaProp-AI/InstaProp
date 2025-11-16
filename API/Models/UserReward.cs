using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class UserReward
    {
        [Key]
        public long RewardId { get; set; }

        [Required]
        public long AccountId { get; set; }

        [ForeignKey(nameof(AccountId))]
        public Account Account { get; set; } = null!;

        [Required]
        public int Points { get; set; }

        [Required]
        [MaxLength(100)]
        public string RewardType { get; set; } = string.Empty; // PropertyView, FirstBid, Purchase, Referral, etc.

        public string? Description { get; set; }

        public long? RelatedPropertyId { get; set; }

        public DateTime EarnedAt { get; set; } = DateTime.UtcNow;
    }
}

