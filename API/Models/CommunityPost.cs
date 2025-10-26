using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public enum PostType
    {
        Regular = 0,
        Announcement = 1,
        Poll = 2
    }

    public class CommunityPost
    {
        [Key]
        public long PostId { get; set; }

        [Required]
        public long CommunityId { get; set; }

        [ForeignKey(nameof(CommunityId))]
        public Community Community { get; set; } = null!;

        [Required]
        public long AuthorId { get; set; }

        [ForeignKey(nameof(AuthorId))]
        public Account Author { get; set; } = null!;

        [Required]
        public string Content { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? ImageUrl { get; set; }

        [Required]
        public PostType PostType { get; set; } = PostType.Regular;

        public bool IsPinned { get; set; } = false;

        public int LikeCount { get; set; } = 0;
        public int CommentCount { get; set; } = 0;
        public int ViewCount { get; set; } = 0;                // Times viewed
        public double TrendingScore { get; set; } = 0;          // Hot algorithm score
        public DateTime LastActivityAt { get; set; } = DateTime.UtcNow; // Last comment/engagement

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        // Relations
        public ICollection<PostComment> Comments { get; set; } = new List<PostComment>();
        public ICollection<PostLike> Likes { get; set; } = new List<PostLike>();
        public ICollection<PostCategory> Categories { get; set; } = new List<PostCategory>();
        public ICollection<PostBookmark> Bookmarks { get; set; } = new List<PostBookmark>();
        public Poll? Poll { get; set; }

        // Calculate trending score (updated periodically or on-demand)
        public void CalculateTrendingScore()
        {
            var hoursSinceCreation = (DateTime.UtcNow - CreatedAt).TotalHours;
            var hoursSinceActivity = (DateTime.UtcNow - LastActivityAt).TotalHours;
            
            // Hot algorithm: engagement over time with recency boost
            TrendingScore = (LikeCount * 1.0) + 
                          (CommentCount * 2.0) + 
                          (ViewCount * 0.1) +
                          (1.0 / Math.Max(hoursSinceCreation, 1)) * 2.0 +  // Recency bonus
                          (1.0 / Math.Max(hoursSinceActivity, 0.1)) * 1.5; // Activity recency
        }
    }
}

