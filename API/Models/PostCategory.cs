using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public class PostCategory
    {
        [Key]
        public long CategoryId { get; set; }

        [Required]
        public long PostId { get; set; }

        [ForeignKey(nameof(PostId))]
        public CommunityPost Post { get; set; } = null!;

        [Required]
        [MaxLength(50)]
        public string CategoryName { get; set; } = string.Empty; // Maintenance, Events, BuySell, Tips, General, or custom
    }
}

