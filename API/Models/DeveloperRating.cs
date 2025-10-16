using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public enum RatingType
    {
        Chat = 0,
        Purchase = 1
    }

    public class DeveloperRating
    {
        [Key]
        public long RatingId { get; set; }

        [Required]
        public long DeveloperId { get; set; }

        [ForeignKey(nameof(DeveloperId))]
        public Account Developer { get; set; } = null!;

        [Required]
        public long UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public Account User { get; set; } = null!;

        [Required]
        [Range(1, 5)]
        public int Rating { get; set; }

        public string? Comment { get; set; }

        [Required]
        public RatingType RatingType { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}

