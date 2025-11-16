using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public enum ReactionType
    {
        Like = 0,
        Celebrate = 1,
        Insightful = 2,
        Helpful = 3,
        Love = 4,
        ThankYou = 5
    }

    public class PostReaction
    {
        [Key]
        public long ReactionId { get; set; }

        [Required]
        public long PostId { get; set; }

        [ForeignKey(nameof(PostId))]
        public CommunityPost Post { get; set; } = null!;

        [Required]
        public long AccountId { get; set; }

        [ForeignKey(nameof(AccountId))]
        public Account Account { get; set; } = null!;

        [Required]
        public ReactionType ReactionType { get; set; } = ReactionType.Like;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    public class CommentReaction
    {
        [Key]
        public long ReactionId { get; set; }

        [Required]
        public long CommentId { get; set; }

        [ForeignKey(nameof(CommentId))]
        public PostComment Comment { get; set; } = null!;

        [Required]
        public long AccountId { get; set; }

        [ForeignKey(nameof(AccountId))]
        public Account Account { get; set; } = null!;

        [Required]
        public ReactionType ReactionType { get; set; } = ReactionType.Like;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}

