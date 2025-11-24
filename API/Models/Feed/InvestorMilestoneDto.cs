using System;

namespace InstapropAPI.Models.Feed
{
    public class InvestorMilestoneDto
    {
        public Guid AchievementId { get; set; }
        public Guid AccountId { get; set; }
        public string InvestorName { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime EarnedAt { get; set; }
        public int PointsAwarded { get; set; }
        public int PortfolioCount { get; set; }
        public decimal TotalBuyInValue { get; set; }
        // ReputationPoints removed (community feature)
        public string Initials { get; set; } = string.Empty;
    }
}

