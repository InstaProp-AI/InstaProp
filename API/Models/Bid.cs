using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class Bid
    {
    [Key]
    public Guid BidId { get; set; }

    [Required]
    public Guid AuctionId { get; set; }

    [ForeignKey(nameof(AuctionId))]
    public Auction Auction { get; set; }

    [Required]
    public Guid BidderId { get; set; }

        [ForeignKey(nameof(BidderId))]
        public AccountBase Bidder { get; set; } = null!;

        [Column(TypeName = "decimal(18,2)")]
        public decimal BidAmount { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}