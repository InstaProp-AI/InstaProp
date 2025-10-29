using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public class LiveStream
    {
        [Key]
        public long StreamId { get; set; }

        [Required]
        public long DeveloperId { get; set; }

        [ForeignKey(nameof(DeveloperId))]
        public Account Developer { get; set; } = null!;

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        public string? Description { get; set; }

        [Required]
        [MaxLength(500)]
        public string StreamUrl { get; set; } = string.Empty; // Firebase Realtime Database URL or WebRTC

        [MaxLength(500)]
        public string? ThumbnailUrl { get; set; }

        [Required]
        [MaxLength(20)]
        public string Status { get; set; } = "Scheduled"; // "Live", "Ended", "Scheduled"

        public int ViewerCount { get; set; } = 0;

        [Required]
        public DateTime StartTime { get; set; }

        public DateTime? EndTime { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Relations
        public ICollection<StreamViewer> Viewers { get; set; } = new List<StreamViewer>();
    }

    public class StreamViewer
    {
        [Key]
        public long ViewerId { get; set; }

        [Required]
        public long StreamId { get; set; }

        [ForeignKey(nameof(StreamId))]
        public LiveStream Stream { get; set; } = null!;

        [Required]
        public long UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public Account User { get; set; } = null!;

        [Required]
        public DateTime JoinedAt { get; set; } = DateTime.UtcNow;

        public DateTime? LeftAt { get; set; }
    }
}

