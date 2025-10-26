using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public enum AchievementType
    {
        FirstPost = 0,
        TenPosts = 1,
        HundredLikes = 2,
        HelpfulMember = 3,
        PopularPost = 4,
        CommunityContributor = 5,
        TopRated = 6,
        PropertyExpert = 7,
        ActiveMember = 8,
        ValuableInsight = 9
    }

    public class UserAchievement
    {
        [Key]
        public long AchievementId { get; set; }

        [Required]
        public long AccountId { get; set; }

        [ForeignKey(nameof(AccountId))]
        public Account Account { get; set; } = null!;

        [Required]
        public AchievementType AchievementType { get; set; }

        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? Description { get; set; }

        public DateTime EarnedAt { get; set; } = DateTime.UtcNow;

        public int PointsAwarded { get; set; } = 0;
    }
}

