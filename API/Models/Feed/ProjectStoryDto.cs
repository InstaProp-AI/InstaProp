using System;

namespace InstapropAPI.Models.Feed
{
    public class ProjectStoryDto
    {
        public long ProjectId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Location { get; set; }
        public DateTime CreatedAt { get; set; }
        public int PropertyCount { get; set; }
        public int ActiveAuctionCount { get; set; }
        public int CompletedMilestones { get; set; }
        public int UpcomingMilestones { get; set; }
        public double AverageRoi { get; set; }
        public ProjectStoryMilestoneDto? LatestMilestone { get; set; }
    }

    public class ProjectStoryMilestoneDto
    {
        public string Title { get; set; } = string.Empty;
        public DateTime TargetDate { get; set; }
        public DateTime? CompletedDate { get; set; }
    }
}

