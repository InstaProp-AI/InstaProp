using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public enum LeaderboardPeriod
    {
        ThisWeek = 0,
        LastWeek = 1,
        AllTime = 2
    }

    public class LeaderboardStanding
    {
        [Key]
        public long StandingId { get; set; }

        public long? SnapshotId { get; set; }

        [ForeignKey(nameof(SnapshotId))]
        public WeeklyLeaderboardSnapshot? Snapshot { get; set; }

        [Required]
        public long AccountId { get; set; }

        [ForeignKey(nameof(AccountId))]
        public Account Account { get; set; } = null!;

        [Required]
        public LeaderboardPeriod Period { get; set; } = LeaderboardPeriod.ThisWeek;

        [Required]
        public int Rank { get; set; }

        [Required]
        public int Points { get; set; }

        /// <summary>
        /// The total value of rewards or benefits attributed to this standing, in the local currency.
        /// </summary>
        [Column(TypeName = "decimal(18,2)")]
        public decimal CashbackAwarded { get; set; }

        /// <summary>
        /// Composite engagement score derived from reward activity types.
        /// </summary>
        public double? EngagementScore { get; set; }

        /// <summary>
        /// Number of consecutive weeks the account has appeared in the top standings.
        /// </summary>
        public int StreakWeeks { get; set; }

        [MaxLength(250)]
        public string? RewardSummary { get; set; }

        public DateTime ComputedAt { get; set; } = DateTime.UtcNow;
    }
}


