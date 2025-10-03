using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public class User
    {
        [Key]
        public int UserId { get; set; }

        [MaxLength(100)]
        public string FirstName { get; set; }

        [MaxLength(100)]
        public string LastName { get; set; }

        [Required, Phone]
        public string PhoneNumber { get; set; }

        [Required, EmailAddress]
        public string Email { get; set; }

        [Required]
        public string Gender { get; set; } // Enum: Male/Female/Other

        [Required]
        public string HashedPassword { get; set; }

        public bool IsVerified { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        // 🔗 Relations
        public ICollection<Property> Properties { get; set; } = new List<Property>();
        public ICollection<Bid> Bids { get; set; } = new List<Bid>();
        public ICollection<UserDoc> UserDocs { get; set; } = new List<UserDoc>();
    }
}