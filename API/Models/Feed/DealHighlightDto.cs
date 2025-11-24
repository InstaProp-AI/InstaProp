using System;

namespace InstapropAPI.Models.Feed
{
    public class DealHighlightDto
    {
        public Guid AuctionId { get; set; }
        public Guid PropertyId { get; set; }
        public string PropertyName { get; set; } = string.Empty;
        public string? Location { get; set; }
        public string? ImageUrl { get; set; }
        public decimal StartPrice { get; set; }
        public decimal CurrentPrice { get; set; }
        public double RoiPercentage { get; set; }
        public DateTime EndAt { get; set; }
        public int BidCount { get; set; }
        public bool IsEndingSoon { get; set; }
    }
}

