using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class NewsImage
    {
        [Key]
        public Guid NewsImageId { get; set; }

        [Required]
        public Guid NewsArticleId { get; set; }

        [ForeignKey(nameof(NewsArticleId))]
        public NewsArticle NewsArticle { get; set; } = null!;

        [Required]
        [MaxLength(500)]
        public string ImageUrl { get; set; } = string.Empty;

        public int DisplayOrder { get; set; } = 0;
    }
}
