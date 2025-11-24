using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class DeveloperProfile
    {
        [Key]
        public Guid ProfileId { get; set; }

        [Required]
        public Guid AccountId { get; set; }

        [ForeignKey(nameof(AccountId))]
        public DeveloperAccount Account { get; set; } = null!;

        public string? Bio { get; set; }

        [MaxLength(200)]
        public string? CompanyName { get; set; }

        public string? ProfileImageUrl { get; set; }

        [Column(TypeName = "decimal(3,2)")]
        public decimal Rating { get; set; } = 0.0m;

        public int TotalRatings { get; set; } = 0;

        public string? PortfolioDescription { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }
    }
}

