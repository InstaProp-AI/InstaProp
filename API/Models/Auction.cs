using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class Auction
    {
    [Key]
    public Guid AuctionId { get; set; }

    [Required]
    public Guid PropertyId { get; set; }

        [ForeignKey(nameof(PropertyId))]
        public Property Property { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal StartPrice { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal CurrentPrice { get; set; }

        public DateTime StartAt { get; set; }

        public int Duration { get; set; } // hours


        public int BidCount { get; set; } = 0;

        [Required]
        public string Status { get; set; } // Enum: Requested, Approved, Active, Closed, Cancelled

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// Deposit amount the winner must pay to confirm their win.
        /// Null means no deposit required. Set by admin when approving/creating the auction.
        /// This amount is tracked in the financial database as a pending transaction.
        /// </summary>
        [Column(TypeName = "decimal(18,2)")]
        public decimal? WinPreservingPrice { get; set; }

        // 🔗 Relations
        public ICollection<Bid> Bids { get; set; } = new List<Bid>();
    }
}