using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace PropertyFlipperAPI.Models
{
    public class Event
    {
        [Key]
        public long EventId { get; set; }

        [Required]
        public long UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        [JsonIgnore]
        public Account? User { get; set; }

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        public string? Description { get; set; }

        [Required]
        public DateTime EventDate { get; set; }

        [Required]
        public EventType Type { get; set; }

        [MaxLength(50)]
        public string? Location { get; set; }

        public bool IsAllDay { get; set; } = false;

        public DateTime? StartTime { get; set; }

        public DateTime? EndTime { get; set; }

        public bool IsCompleted { get; set; } = false;

        public bool IsReminderSet { get; set; } = false;

        public int? ReminderMinutes { get; set; } // Minutes before event to remind

        public bool IsPublic { get; set; } = false; // Public events visible to all users

        // Recurring event fields
        public bool IsRecurring { get; set; } = false;
        public RecurrencePattern? RecurrencePattern { get; set; }
        public int? RecurrenceInterval { get; set; } // How often it repeats (e.g., every 2 days, every 3 weeks)
        public DateTime? RecurrenceEndDate { get; set; }
        public int? RecurrenceCount { get; set; } // How many occurrences (alternative to EndDate)
        public long? ParentEventId { get; set; } // For recurring event instances, reference to the parent

        // Amount field for payment-related events
        public decimal? Amount { get; set; }

        // Related entity IDs (optional)
        public long? PropertyId { get; set; }
        public long? AuctionId { get; set; }
        public long? BidId { get; set; }

        // Payment schedule metadata
        public string? ScheduleImageUrl { get; set; }
        public string? ScheduleGroupId { get; set; }
        public decimal? ScheduleBuyingPrice { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }
    }

    public enum EventType
    {
        Installment = 0,           // Payment due dates
        AuctionStart = 1,          // Auction starting dates
        AuctionEnd = 2,            // Auction ending dates
        PropertyInspection = 3,    // Property viewing/inspection
        PropertyValuation = 4,     // Property appraisal dates
        ContractSigning = 5,       // Legal document signing
        MoveInDate = 6,            // Moving into property
        MoveOutDate = 7,           // Moving out of property
        Maintenance = 8,           // Property maintenance
        Meeting = 9,               // General meetings
        Other = 10                 // Custom events
    }

    public enum RecurrencePattern
    {
        Daily = 0,
        Weekly = 1,
        Monthly = 2,
        Yearly = 3
    }
}
