using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public class PropertyDoc
    {
        [Key]
        public int DocId { get; set; }

        [Required]
        public int PropertyId { get; set; }

        [ForeignKey(nameof(PropertyId))]
        public Property Property { get; set; }

        [Required]
        public string DocType { get; set; } // Enum: Ownership, Legal, FloorPlan, etc.

        [Required]
        public string ImgUrl { get; set; }

        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    }
}