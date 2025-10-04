using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PropertyFlipperAPI.Models
{
    public class Auction
    {
    [Key]
    public long AuctionId { get; set; }

    [Required]
    public long PropertyId { get; set; }

        [ForeignKey(nameof(PropertyId))]
        public Property Property { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal StartAt { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal CurrentPrice { get; set; }

        public DateTime EndAt { get; set; }

        public int Duration { get; set; } // hours or minutes

        [Column(TypeName = "decimal(18,2)")]
        public decimal? BuyNowPrice { get; set; }

        public int BidCount { get; set; } = 0;

        [Required]
        public string Status { get; set; } // Enum: Pending, Active, Closed, Cancelled

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // 🔗 Relations
        public ICollection<Bid> Bids { get; set; } = new List<Bid>();
    }
}