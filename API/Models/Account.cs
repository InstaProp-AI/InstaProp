using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public class Account
    {
        [Key]
        public long AccountId { get; set; }

        [MaxLength(100)]
        public string FirstName { get; set; } = string.Empty;

        [MaxLength(100)]
        public string LastName { get; set; } = string.Empty;

        [Required, Phone]
        public string PhoneNumber { get; set; } = string.Empty;

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public AccountType Type { get; set; } = AccountType.User;

        [Required]
        public string HashedPassword { get; set; } = string.Empty;

        public bool IsVerified { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        // 🔗 Relations
        public ICollection<Property> Properties { get; set; } = new List<Property>();
        public ICollection<Bid> Bids { get; set; } = new List<Bid>();
        public ICollection<Project> Projects { get; set; } = new List<Project>();
        public ICollection<UserDoc> UserDocs { get; set; } = new List<UserDoc>();
    }
}