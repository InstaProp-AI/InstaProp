using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class UserDoc
    {
    [Key]
    public Guid DocId { get; set; }

    [Required]
    public Guid UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public AccountBase User { get; set; } = null!;

        [Required]
        public string DocType { get; set; } // Enum: ID_Front, ID_Back, Passport_Front, Passport_Back, ProofOfAddress, etc.

        [Required]
        public string ImgUrl { get; set; }

        public string? DeleteUrl { get; set; } // ImgBB delete URL for document removal

        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    }
}