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

        [Required]
        public VerificationStatus Status { get; set; } = VerificationStatus.NotVerified;

        // Email & Phone Verification
        public bool EmailVerified { get; set; } = false;
        public bool PhoneVerified { get; set; } = false;
        
        [MaxLength(6)]
        public string? EmailVerificationPin { get; set; }
        
        [MaxLength(6)]
        public string? PhoneVerificationPin { get; set; }
        
        public DateTime? EmailVerificationPinExpiry { get; set; }
        public DateTime? PhoneVerificationPinExpiry { get; set; }

        // Password Reset
        public bool RequiresPasswordChange { get; set; } = false;
        
        [EmailAddress]
        public string? PasswordResetRequestedEmail { get; set; }
        public DateTime? PasswordResetTokenExpiry { get; set; }

        // Store previous values to detect changes
        [MaxLength(100)]
        public string? PreviousEmail { get; set; }
        
        [Phone]
        public string? PreviousPhoneNumber { get; set; }

        // Account Suspension
        public bool IsSuspended { get; set; } = false;
        public DateTime? SuspendedUntil { get; set; }
        public string? SuspensionReason { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        // 🔗 Relations
        public ICollection<Property> Properties { get; set; } = new List<Property>();
        public ICollection<Bid> Bids { get; set; } = new List<Bid>();
        public ICollection<Project> Projects { get; set; } = new List<Project>();
        public ICollection<UserDoc> UserDocs { get; set; } = new List<UserDoc>();
    }
}