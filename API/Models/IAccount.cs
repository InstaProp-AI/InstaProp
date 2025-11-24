using System;
using System.Collections.Generic;

namespace InstapropAPI.Models
{
    /// <summary>
    /// Base interface for all account types in the system.
    /// All account types (User, Developer, Admin, Sales) implement this interface.
    /// </summary>
    public interface IAccount
    {
        Guid AccountId { get; set; }
        string FirstName { get; set; }
        string LastName { get; set; }
        string PhoneNumber { get; set; }
        string Email { get; set; }
        Guid RoleId { get; set; }
        Role? Role { get; set; }
        string? HashedPassword { get; set; }
        VerificationStatus Status { get; set; }
        bool EmailVerified { get; set; }
        bool PhoneVerified { get; set; }
        string? EmailVerificationPin { get; set; }
        string? PhoneVerificationPin { get; set; }
        DateTime? EmailVerificationPinExpiry { get; set; }
        DateTime? PhoneVerificationPinExpiry { get; set; }
        bool RequiresPasswordChange { get; set; }
        string? PasswordResetRequestedEmail { get; set; }
        DateTime? PasswordResetTokenExpiry { get; set; }
        string? PreviousEmail { get; set; }
        string? PreviousPhoneNumber { get; set; }
        bool IsSuspended { get; set; }
        DateTime? SuspendedUntil { get; set; }
        string? SuspensionReason { get; set; }
        int FailedLoginAttempts { get; set; }
        DateTime? LockedUntil { get; set; }
        DateTime CreatedAt { get; set; }
        DateTime? UpdatedAt { get; set; }
        
        // Rewards System - Shared across all account types
        int TotalEarnedPoints { get; set; }
        int CurrentPoints { get; set; }
        
        // Navigation properties
        ICollection<Bid> Bids { get; set; }
        ICollection<Project> Projects { get; set; }
        ICollection<UserDoc> UserDocs { get; set; }
    }
}

