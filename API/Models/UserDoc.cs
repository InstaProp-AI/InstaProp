using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public class UserDoc
    {
        [Key]
        public int DocId { get; set; }

        [Required]
        public int UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public User User { get; set; }

        [Required]
        public string DocType { get; set; } // Enum: NationalID, ProofOfAddress, etc.

        [Required]
        public string ImgUrl { get; set; }

        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    }
}