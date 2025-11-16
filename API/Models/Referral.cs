using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class Referral
    {
        [Key]
        public long ReferralId { get; set; }

        [Required]
        public long ReferrerId { get; set; }

        [ForeignKey(nameof(ReferrerId))]
        public Account Referrer { get; set; } = null!;

        public long? ReferredUserId { get; set; } // Null until referred user signs up

        [ForeignKey(nameof(ReferredUserId))]
        public Account? ReferredUser { get; set; }

        [Required]
        [MaxLength(20)]
        public string ReferralCode { get; set; } = string.Empty;

        public bool IsConverted { get; set; } = false; // Did referred user make purchase?

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? ConvertedAt { get; set; }
    }
}

