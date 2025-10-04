using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using System.Linq;
using System.Threading.Tasks;
using System.Security.Claims;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BidsController : ControllerBase
    {
        private readonly AppDbContext _context;
        public BidsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/bids/by-auction/{auctionId}
        [HttpGet("by-auction/{auctionId}")]
        public async Task<IActionResult> GetBidsForAuction(long auctionId)
        {
            var bids = await _context.Bids
                .Include(b => b.Bidder)
                .Where(b => b.AuctionId == auctionId)
                .OrderByDescending(b => b.CreatedAt)
                .ToListAsync();
            return Ok(bids);
        }

        // POST: api/bids
        [HttpPost]
        [Authorize]
        public async Task<IActionResult> CreateBid([FromBody] CreateBidDto bidDto)
        {
            try
            {
                // Get the current user ID from the JWT token
                var userIdClaim = User.FindFirst("uid");
                if (userIdClaim == null || !long.TryParse(userIdClaim.Value, out long userId))
                {
                    return Unauthorized("User not authenticated");
                }

                var auction = await _context.Auctions.FindAsync(bidDto.AuctionId);
                if (auction == null)
                {
                    return BadRequest("Auction not found.");
                }

                if (auction.Status != "Active")
                {
                    return BadRequest("Auction is not active.");
                }

                // Check if bid amount is higher than current price
                var currentPrice = await GetCurrentPrice(bidDto.AuctionId);
                if (bidDto.BidAmount <= currentPrice)
                {
                    return BadRequest("Bid amount must be higher than current price.");
                }

                var bid = new Bid
                {
                    AuctionId = bidDto.AuctionId,
                    BidderId = userId,
                    BidAmount = (decimal)bidDto.BidAmount,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Bids.Add(bid);
                await _context.SaveChangesAsync();

                // Return the bid with bidder information
                var createdBid = await _context.Bids
                    .Include(b => b.Bidder)
                    .FirstAsync(b => b.BidId == bid.BidId);

                return Ok(createdBid);
            }
            catch (Exception ex)
            {
                return BadRequest($"Error creating bid: {ex.Message}");
            }
        }

        // GET: api/bids/user
        [HttpGet("user")]
        [Authorize]
        public async Task<IActionResult> GetUserBids()
        {
            var userIdClaim = User.FindFirst("uid");
            if (userIdClaim == null || !long.TryParse(userIdClaim.Value, out long userId))
            {
                return Unauthorized("User not authenticated");
            }

            var bids = await _context.Bids
                .Include(b => b.Auction)
                .Include(b => b.Bidder)
                .Where(b => b.BidderId == userId)
                .OrderByDescending(b => b.CreatedAt)
                .ToListAsync();

            return Ok(bids);
        }

        // GET: api/bids/{bidId}
        [HttpGet("{bidId}")]
        public async Task<IActionResult> GetBid(long bidId)
        {
            var bid = await _context.Bids
                .Include(b => b.Bidder)
                .Include(b => b.Auction)
                .FirstOrDefaultAsync(b => b.BidId == bidId);

            if (bid == null)
            {
                return NotFound("Bid not found");
            }

            return Ok(bid);
        }

        // DELETE: api/bids/{bidId}
        [HttpDelete("{bidId}")]
        [Authorize]
        public async Task<IActionResult> DeleteBid(long bidId)
        {
            var userIdClaim = User.FindFirst("uid");
            if (userIdClaim == null || !long.TryParse(userIdClaim.Value, out long userId))
            {
                return Unauthorized("User not authenticated");
            }

            var bid = await _context.Bids
                .Include(b => b.Auction)
                .FirstOrDefaultAsync(b => b.BidId == bidId);

            if (bid == null)
            {
                return NotFound("Bid not found");
            }

            if (bid.BidderId != userId)
            {
                return Forbid("You can only delete your own bids");
            }

            // Check if auction is still active
            if (bid.Auction.Status != "Active")
            {
                return BadRequest("Cannot delete bid from inactive auction");
            }

            _context.Bids.Remove(bid);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Bid deleted successfully" });
        }

        private async Task<decimal> GetCurrentPrice(long auctionId)
        {
            var highestBid = await _context.Bids
                .Where(b => b.AuctionId == auctionId)
                .OrderByDescending(b => b.BidAmount)
                .FirstOrDefaultAsync();

            if (highestBid != null)
            {
                return highestBid.BidAmount;
            }

            // If no bids, return the starting price
            var auction = await _context.Auctions.FindAsync(auctionId);
            return auction?.StartAt ?? 0;
        }
    }

    public class CreateBidDto
    {
        public long AuctionId { get; set; }
        public double BidAmount { get; set; }
    }
}


