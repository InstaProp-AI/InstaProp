using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class NewsArticle
    {
        [Key]
        public long NewsArticleId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        public string Content { get; set; } = string.Empty;

        [MaxLength(50)]
        public string? Category { get; set; }

        public DateTime PublishedDate { get; set; } = DateTime.UtcNow;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public bool IsPublished { get; set; } = true;

        // Developer assignment (nullable - null means admin post)
        public long? DeveloperId { get; set; }

        [ForeignKey(nameof(DeveloperId))]
        public virtual Account? Developer { get; set; }

        // Navigation property for images
        public virtual ICollection<NewsImage> Images { get; set; } = new List<NewsImage>();
    }
}
