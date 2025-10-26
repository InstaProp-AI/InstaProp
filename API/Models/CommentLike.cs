using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public class CommentLike
    {
        [Key]
        public long LikeId { get; set; }

        [Required]
        public long CommentId { get; set; }

        [ForeignKey(nameof(CommentId))]
        public PostComment Comment { get; set; } = null!;

        [Required]
        public long AccountId { get; set; }

        [ForeignKey(nameof(AccountId))]
        public Account Account { get; set; } = null!;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}

