using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public class PostComment
    {
        [Key]
        public long CommentId { get; set; }

        [Required]
        public long PostId { get; set; }

        [ForeignKey(nameof(PostId))]
        public CommunityPost Post { get; set; } = null!;

        [Required]
        public long AuthorId { get; set; }

        [ForeignKey(nameof(AuthorId))]
        public Account Author { get; set; } = null!;

        [Required]
        public string Content { get; set; } = string.Empty;

        public long? ParentCommentId { get; set; } // For threading

        [ForeignKey(nameof(ParentCommentId))]
        public PostComment? ParentComment { get; set; }

        public int LikeCount { get; set; } = 0;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        // Relations
        public ICollection<PostComment> Replies { get; set; } = new List<PostComment>();
        public ICollection<CommentLike> Likes { get; set; } = new List<CommentLike>();
    }
}

