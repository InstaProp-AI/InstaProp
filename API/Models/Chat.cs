using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public class Chat
    {
        [Key]
        public long ChatId { get; set; }

        [Required]
        public long UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public Account User { get; set; } = null!;

        [Required]
        public long DeveloperId { get; set; }

        [ForeignKey(nameof(DeveloperId))]
        public Account Developer { get; set; } = null!;

        public long? ProjectId { get; set; }

        [ForeignKey(nameof(ProjectId))]
        public Project? Project { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime LastMessageAt { get; set; } = DateTime.UtcNow;

        public bool IsActive { get; set; } = true;

        // 🔗 Relations
        public ICollection<ChatMessage> Messages { get; set; } = new List<ChatMessage>();
    }
}

