using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class PropertyDoc
    {
    [Key]
    public Guid DocId { get; set; }

    [Required]
    public Guid PropertyId { get; set; }

        [ForeignKey(nameof(PropertyId))]
        public Property Property { get; set; }

        [Required]
        public string DocType { get; set; } // Enum: Ownership, Legal, FloorPlan, etc.

        [Required]
        public string ImgUrl { get; set; }

        public string? DeleteUrl { get; set; } // ImgBB delete URL for document removal

        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    }
}