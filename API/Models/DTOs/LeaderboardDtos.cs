using System;
using System.Collections.Generic;

namespace InstapropAPI.Models
{
    public class LeaderboardActivitySliceDto
    {
        public string Category { get; set; } = string.Empty;
        public int Count { get; set; }
        public int Points { get; set; }
    }

    public class LeaderboardEntryDto
    {
        public Guid AccountId { get; set; }
        public string DisplayName { get; set; } = string.Empty;
        public string? AvatarInitials { get; set; }
        public int Rank { get; set; }
        public int Points { get; set; }
        public int TotalRewards { get; set; }
        public decimal CashbackAwarded { get; set; }
        public decimal PotentialCashback { get; set; }
        public double? EngagementScore { get; set; }
        public int StreakWeeks { get; set; }
        public string? RewardSummary { get; set; }
        public bool IsRequester { get; set; }
        public DateTime? LastRewardAt { get; set; }
        public int? PointsToNextRank { get; set; }
        public List<LeaderboardActivitySliceDto> Activity { get; set; } = new();
        public Dictionary<string, int> RewardTypeCounts { get; set; } = new(StringComparer.OrdinalIgnoreCase);
    }

    public class LeaderboardResponseDto
    {
        public LeaderboardPeriod Period { get; set; }
        public DateTime RangeStart { get; set; }
        public DateTime RangeEnd { get; set; }
        public string Headline { get; set; } = string.Empty;
        public string Subheading { get; set; } = string.Empty;
        public List<LeaderboardEntryDto> Entries { get; set; } = new();
        public LeaderboardEntryDto? PersonalEntry { get; set; }
        public List<string> MomentumTips { get; set; } = new();
    }

    public class LeaderboardHighlightDto
    {
        public DateTime RangeStart { get; set; }
        public DateTime RangeEnd { get; set; }
        public string? Headline { get; set; }
        public string? Summary { get; set; }
        public LeaderboardEntryDto? First { get; set; }
        public LeaderboardEntryDto? Second { get; set; }
        public LeaderboardEntryDto? Third { get; set; }
    }

    public class LeaderboardHighlightsResponseDto
    {
        public LeaderboardHighlightDto? LastWeek { get; set; }
        public LeaderboardHighlightDto? ThisWeek { get; set; }
        public LeaderboardEntryDto? PersonalThisWeek { get; set; }
        public List<string> ActionablePrompts { get; set; } = new();
    }
}


