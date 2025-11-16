using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class Redemption
    {
        [Key]
        public long RedemptionId { get; set; }
        
        [Required]
        public long AccountId { get; set; }
        
        [ForeignKey(nameof(AccountId))]
        public Account Account { get; set; } = null!;
        
        [Required]
        [MaxLength(100)]
        public string RewardType { get; set; } = string.Empty; // "Starbucks", "Restaurant", "Gas Station", "Amazon"
        
        [Required]
        public int PointsSpent { get; set; }
        
        [Required]
        [MaxLength(5)]
        public string PromoCode { get; set; } = string.Empty; // 5-digit alphanumeric code
        
        public bool IsUsed { get; set; } = false;
        
        public DateTime? UsedAt { get; set; }
        
        public DateTime RedeemedAt { get; set; } = DateTime.UtcNow;
    }
}
