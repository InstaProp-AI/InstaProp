using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class Notification
    {
        [Key]
        public Guid NotificationId { get; set; }

        // For individual notifications, UserId is set
        // For bulk notifications, UserId is null and Recipients is used
        public Guid? UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public AccountBase? User { get; set; }

        [Required]
        [MaxLength(100)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [MaxLength(500)]
        public string Message { get; set; } = string.Empty;

        [Required]
        public NotificationType Type { get; set; }

        // For individual notifications (backward compatibility)
        public bool IsRead { get; set; } = false;

        // Bulk notification recipients (comma-separated)
        // Examples: "all_users", "all_users_including_guests", "guests_only", "logged_in_users",
        //           "property_owners", "auction_owners", "bidders", "verified_users", "unverified_users"
        // For specific users: "specific:1,2,3,4" (userId list)
        [MaxLength(500)]
        public string? Recipients { get; set; }

        // Track which users have read this notification (for bulk messages)
        // Format: "1,2,3,4" (comma-separated user IDs)
        public string? ReadByUsers { get; set; }

        // Related entity IDs (optional - for navigation)
        public Guid? AuctionId { get; set; }
        public Guid? BidId { get; set; }
        public Guid? PropertyId { get; set; }
        public Guid? EventId { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? ReadAt { get; set; }

        // Check if this is a bulk notification
        public bool IsBulkNotification => !string.IsNullOrEmpty(Recipients);

        // Helper method to check if user has read this notification
        public bool IsReadByUser(Guid userId)
        {
            if (IsBulkNotification)
            {
                return ReadByUsers?.Split(',', StringSplitOptions.RemoveEmptyEntries)
                    .Contains(userId.ToString()) ?? false;
            }
            return IsRead;
        }

        // Helper method to mark as read for a user
        public void MarkAsReadByUser(Guid userId)
        {
            if (IsBulkNotification)
            {
                var readUsers = ReadByUsers?.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList() ?? new List<string>();
                if (!readUsers.Contains(userId.ToString()))
                {
                    readUsers.Add(userId.ToString());
                    ReadByUsers = string.Join(",", readUsers);
                }
            }
            else
            {
                IsRead = true;
                ReadAt = DateTime.UtcNow;
            }
        }
    }

    public enum NotificationType
    {
        BidPlaced = 0,           // Someone placed a bid on your auction
        Outbid = 1,              // Someone placed a higher bid than yours
        AuctionStarted = 2,      // New auction started
        AuctionEnding = 3,       // Auction ending soon
        AuctionWon = 4,          // You won an auction
        AuctionLost = 5,         // You lost an auction
        EventReminder = 6,       // Calendar event reminder
        PublicEvent = 7,         // New public event added
        AuctionApproved = 8,     // Your auction request was approved
        AuctionRejected = 9,     // Your auction request was rejected
        General = 10,            // General notifications
        AuctionEnded = 11        // Auction has ended (for seller)
    }
}

