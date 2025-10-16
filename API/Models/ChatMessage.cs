using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public class ChatMessage
    {
        [Key]
        public long MessageId { get; set; }

        [Required]
        public long ChatId { get; set; }

        [ForeignKey(nameof(ChatId))]
        public Chat Chat { get; set; } = null!;

        [Required]
        public long SenderId { get; set; }

        [ForeignKey(nameof(SenderId))]
        public Account Sender { get; set; } = null!;

        [Required]
        public string Content { get; set; } = string.Empty;

        public long? PropertyId { get; set; }

        [ForeignKey(nameof(PropertyId))]
        public Property? Property { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public bool IsRead { get; set; } = false;

        public DateTime ExpiresAt { get; set; } = DateTime.UtcNow.AddDays(30);
    }
}

