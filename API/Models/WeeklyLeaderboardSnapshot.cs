using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    /// <summary>
    /// Captures the locked-in standings for a completed leaderboard week.
    /// </summary>
    public class WeeklyLeaderboardSnapshot
    {
        [Key]
        public Guid SnapshotId { get; set; }

        [Required]
        public DateTime WeekStart { get; set; }

        [Required]
        public DateTime WeekEnd { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Indicates whether cashback payouts have been processed for this snapshot.
        /// </summary>
        public bool PayoutProcessed { get; set; } = false;

        public Guid? WinnerAccountId { get; set; }

        [ForeignKey(nameof(WinnerAccountId))]
        public AccountBase? WinnerAccount { get; set; }

        public int? WinnerPoints { get; set; }

        public Guid? SecondPlaceAccountId { get; set; }

        [ForeignKey(nameof(SecondPlaceAccountId))]
        public AccountBase? SecondPlaceAccount { get; set; }

        public int? SecondPlacePoints { get; set; }

        public Guid? ThirdPlaceAccountId { get; set; }

        [ForeignKey(nameof(ThirdPlaceAccountId))]
        public AccountBase? ThirdPlaceAccount { get; set; }

        public int? ThirdPlacePoints { get; set; }

        [MaxLength(250)]
        public string? HighlightHeadline { get; set; }

        [MaxLength(500)]
        public string? HighlightSummary { get; set; }

        public ICollection<LeaderboardStanding> Standings { get; set; } = new List<LeaderboardStanding>();
    }
}


