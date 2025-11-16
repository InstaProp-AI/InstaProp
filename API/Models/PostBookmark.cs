using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class PostBookmark
    {
        [Key]
        public long BookmarkId { get; set; }

        [Required]
        public long PostId { get; set; }

        [ForeignKey(nameof(PostId))]
        public CommunityPost Post { get; set; } = null!;

        [Required]
        public long AccountId { get; set; }

        [ForeignKey(nameof(AccountId))]
        public Account Account { get; set; } = null!;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}

