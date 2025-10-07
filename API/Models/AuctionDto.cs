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
        public decimal StartAt { get; set; }
        public decimal CurrentPrice { get; set; }
        public DateTime EndAt { get; set; }
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
                StartAt = auction.StartAt,
                CurrentPrice = auction.CurrentPrice, // Use database value
                EndAt = auction.EndAt,
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
