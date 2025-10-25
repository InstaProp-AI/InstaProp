using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace PropertyFlipperAPI.Models
{
    public class PropertyImage
    {
        [Key]
        public long PropertyImageId { get; set; }

        [Required]
        public int PropertyId { get; set; }

        [ForeignKey(nameof(PropertyId))]
        [JsonIgnore]
        public ChildProperty? Property { get; set; }

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
