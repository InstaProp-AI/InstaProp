using System;
using System.Collections.Generic;
using System.Linq;

namespace PropertyFlipperAPI.Models
{
    public class AuctionDto
    {
        public long AuctionId { get; set; }
        public long PropertyId { get; set; }
        public Property Property { get; set; }
        public decimal StartPrice { get; set; }
        public decimal CurrentPrice { get; set; }
        public DateTime StartAt { get; set; }
        public DateTime EndAt { get; set; } // Calculated: StartAt + Duration
        public int Duration { get; set; }
        public decimal? BuyNowPrice { get; set; }
        public int BidCount { get; set; }
        public string Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public List<Bid> Bids { get; set; } = new List<Bid>();

        public static AuctionDto FromAuction(Auction auction)
        {
            // Use the database values directly instead of calculating from bids collection
            return new AuctionDto
            {
                AuctionId = auction.AuctionId,
                PropertyId = auction.PropertyId,
                Property = auction.Property,
                StartPrice = auction.StartPrice,
                CurrentPrice = auction.CurrentPrice, // Use database value
                StartAt = auction.StartAt,
                EndAt = auction.StartAt.AddHours(auction.Duration), // Calculated
                Duration = auction.Duration,
                BuyNowPrice = auction.BuyNowPrice,
                BidCount = auction.BidCount, // Use database value
                Status = auction.Status,
                CreatedAt = auction.CreatedAt,
                Bids = auction.Bids.ToList()
            };
        }
    }
}
