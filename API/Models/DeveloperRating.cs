using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public enum RatingType
    {
        Chat = 0,
        Purchase = 1
    }

    public class DeveloperRating
    {
        [Key]
        public Guid RatingId { get; set; }

        [Required]
        public Guid DeveloperId { get; set; }

        [ForeignKey(nameof(DeveloperId))]
        public DeveloperAccount Developer { get; set; } = null!;

        [Required]
        public Guid UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public UserAccount User { get; set; } = null!;

        [Required]
        [Range(1, 5)]
        public int Rating { get; set; }

        public string? Comment { get; set; }

        [Required]
        public RatingType RatingType { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}

