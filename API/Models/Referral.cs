using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class Referral
    {
        [Key]
        public Guid ReferralId { get; set; }

        [Required]
        public Guid ReferrerId { get; set; }

        [ForeignKey(nameof(ReferrerId))]
        public AccountBase Referrer { get; set; } = null!;

        public Guid? ReferredUserId { get; set; } // Null until referred user signs up

        [ForeignKey(nameof(ReferredUserId))]
        public AccountBase? ReferredUser { get; set; }

        [Required]
        [MaxLength(20)]
        public string ReferralCode { get; set; } = string.Empty;

        public bool IsConverted { get; set; } = false; // Did referred user make purchase?

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? ConvertedAt { get; set; }
    }
}

