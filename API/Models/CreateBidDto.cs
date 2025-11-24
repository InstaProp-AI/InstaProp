using System.ComponentModel.DataAnnotations;

namespace InstapropAPI.Models
{
    public class CreateBidDto
    {
        [Required]
        public Guid AuctionId { get; set; }

        [Required]
        [Range(0.01, double.MaxValue, ErrorMessage = "Bid amount must be greater than 0")]
        public decimal BidAmount { get; set; }
    }
}
