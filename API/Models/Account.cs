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

        // Nullable for OAuth users who don't have a password
        public string? HashedPassword { get; set; }

        // OAuth Support
        [MaxLength(255)]
        public string? GoogleId { get; set; }
        
        [MaxLength(50)]
        public string? AuthProvider { get; set; } // "google", "email", etc.

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

        // Account Lockout (for failed login attempts)
        public int FailedLoginAttempts { get; set; } = 0;
        public DateTime? LockedUntil { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        // Rewards System - Dual Point Tracking
        public int TotalEarnedPoints { get; set; } = 0;  // Lifetime achievement
        public int CurrentPoints { get; set; } = 0;      // Spendable balance

        // Community Reputation & Activity
        public int ReputationPoints { get; set; } = 0;    // Community contribution score
        public int PostCount { get; set; } = 0;           // Total posts created
        public int CommentCount { get; set; } = 0;       // Total comments created
        public int LikesReceived { get; set; } = 0;      // Total likes received on posts/comments
        public DateTime? LastActiveAt { get; set; }       // Last community activity
        public bool ShowInDirectory { get; set; } = true; // Allow public profile viewing

        // 🔗 Relations
        // Properties navigation removed - using ChildProperty system now
        public ICollection<Bid> Bids { get; set; } = new List<Bid>();
        public ICollection<Project> Projects { get; set; } = new List<Project>();
        public ICollection<UserDoc> UserDocs { get; set; } = new List<UserDoc>();
        public ICollection<PostBookmark> BookmarkedPosts { get; set; } = new List<PostBookmark>();
    }
}