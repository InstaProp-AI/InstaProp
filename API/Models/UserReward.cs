using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class UserReward
    {
        [Key]
        public Guid RewardId { get; set; }

        [Required]
        public Guid AccountId { get; set; }

        [ForeignKey(nameof(AccountId))]
        public AccountBase Account { get; set; } = null!;

        [Required]
        public int Points { get; set; }

        [Required]
        [MaxLength(100)]
        public string RewardType { get; set; } = string.Empty; // PropertyView, FirstBid, Purchase, Referral, etc.

        public string? Description { get; set; }

        public Guid? RelatedPropertyId { get; set; }

        public DateTime EarnedAt { get; set; } = DateTime.UtcNow;
    }
}

