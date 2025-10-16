using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public class ProjectMilestone
    {
        [Key]
        public long MilestoneId { get; set; }

        [Required]
        public long ProjectId { get; set; }

        [ForeignKey(nameof(ProjectId))]
        public Project Project { get; set; } = null!;

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        public string? Description { get; set; }

        [Required]
        public DateTime TargetDate { get; set; }

        public DateTime? CompletedDate { get; set; }

        [Range(0, 100)]
        public int CompletionPercentage { get; set; } = 0;

        [Required]
        public MilestoneStatus Status { get; set; } = MilestoneStatus.Pending;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }
    }

    public enum MilestoneStatus
    {
        Pending = 0,
        InProgress = 1,
        Completed = 2,
        Cancelled = 3
    }
}

