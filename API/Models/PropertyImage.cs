using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace InstapropAPI.Models
{
    public class PropertyImage
    {
        [Key]
        public Guid PropertyImageId { get; set; }

        [Required]
        public Guid PropertyId { get; set; }

        [ForeignKey(nameof(PropertyId))]
        [JsonIgnore]
        public Property? Property { get; set; }

        [Required]
        public string ImageUrl { get; set; } = string.Empty;

        [Required]
        public string ImageType { get; set; } = string.Empty; // Main, Gallery, Exterior, Interior, etc.

        public bool IsMainImage { get; set; } = false;

        public int DisplayOrder { get; set; } = 0;

        public string? DeleteUrl { get; set; } // ImgBB delete URL for image removal

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
