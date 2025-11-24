using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    /// <summary>
    /// Abstract base class for all account types.
    /// Implements IAccount interface and provides shared properties.
    /// Cannot be instantiated directly - only through derived types.
    /// </summary>
    public abstract class AccountBase : IAccount
    {
        [Key]
        public Guid AccountId { get; set; }

        [MaxLength(100)]
        public string FirstName { get; set; } = string.Empty;

        [MaxLength(100)]
        public string LastName { get; set; } = string.Empty;

        [Required, Phone]
        public string PhoneNumber { get; set; } = string.Empty;

        [Required, EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public Guid RoleId { get; set; }

        public Role? Role { get; set; }

        public string? HashedPassword { get; set; }

        [Required]
        public VerificationStatus Status { get; set; } = VerificationStatus.NotVerified;

        public bool EmailVerified { get; set; } = false;
        public bool PhoneVerified { get; set; } = false;
        
        [MaxLength(6)]
        public string? EmailVerificationPin { get; set; }
        
        [MaxLength(6)]
        public string? PhoneVerificationPin { get; set; }

        public DateTime? EmailVerificationPinExpiry { get; set; }
        public DateTime? PhoneVerificationPinExpiry { get; set; }

        public bool RequiresPasswordChange { get; set; } = false;
        
        [EmailAddress]
        public string? PasswordResetRequestedEmail { get; set; }
        public DateTime? PasswordResetTokenExpiry { get; set; }

        [MaxLength(100)]
        public string? PreviousEmail { get; set; }
        
        [Phone]
        public string? PreviousPhoneNumber { get; set; }

        public bool IsSuspended { get; set; } = false;
        public DateTime? SuspendedUntil { get; set; }
        public string? SuspensionReason { get; set; }

        public int FailedLoginAttempts { get; set; } = 0;
        public DateTime? LockedUntil { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        // Timezone preference for user
        [MaxLength(100)]
        public string? TimeZone { get; set; }

        // Rewards System
        public int TotalEarnedPoints { get; set; } = 0;
        public int CurrentPoints { get; set; } = 0;

        // Navigation properties
        public ICollection<Bid> Bids { get; set; } = new List<Bid>();
        public ICollection<Project> Projects { get; set; } = new List<Project>();
        public ICollection<UserDoc> UserDocs { get; set; } = new List<UserDoc>();
    }
}

