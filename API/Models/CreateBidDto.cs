using System.ComponentModel.DataAnnotations;

namespace PropertyFlipperAPI.Models
{
    public class CreateBidDto
    {
        [Required]
        public long AuctionId { get; set; }

        [Required]
        [Range(0.01, double.MaxValue, ErrorMessage = "Bid amount must be greater than 0")]
        public decimal BidAmount { get; set; }
    }
}
