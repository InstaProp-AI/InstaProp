using System;

namespace InstapropAPI.Models.Feed
{
    public class InvestorMilestoneDto
    {
        public long AchievementId { get; set; }
        public long AccountId { get; set; }
        public string InvestorName { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime EarnedAt { get; set; }
        public int PointsAwarded { get; set; }
        public int PortfolioCount { get; set; }
        public decimal TotalBuyInValue { get; set; }
        public int ReputationPoints { get; set; }
        public string Initials { get; set; } = string.Empty;
    }
}

