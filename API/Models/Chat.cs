using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class Chat
    {
        [Key]
        public Guid ChatId { get; set; }

        [Required]
        public Guid UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public AccountBase User { get; set; } = null!;

        [Required]
        public Guid DeveloperId { get; set; }

        [ForeignKey(nameof(DeveloperId))]
        public DeveloperAccount Developer { get; set; } = null!;

        public Guid? ProjectId { get; set; }

        [ForeignKey(nameof(ProjectId))]
        public Project? Project { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime LastMessageAt { get; set; } = DateTime.UtcNow;

        public bool IsActive { get; set; } = true;

        public bool IsSupportChat { get; set; } = false;

        public Guid? SalesMemberId { get; set; }

        [ForeignKey(nameof(SalesMemberId))]
        public SalesAccount? SalesMember { get; set; }

        // 🔗 Relations
        public ICollection<ChatMessage> Messages { get; set; } = new List<ChatMessage>();
    }
}

