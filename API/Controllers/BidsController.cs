using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using PropertyFlipperAPI.Services;
using System.Linq;
using System.Threading.Tasks;
using System.Security.Claims;
using PropertyFlipperAPI.Attributes;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BidsController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly AuctionWebSocketManager _webSocketManager;
        
        public BidsController(AppDbContext context, AuctionWebSocketManager webSocketManager)
        {
            _context = context;
            _webSocketManager = webSocketManager;
        }

        // GET: api/bids/by-auction/{auctionId} (Public - No auth required)
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

        // GET: api/bids/bidders/{auctionId} (Public - Get unique bidders for an auction)
        [HttpGet("bidders/{auctionId}")]
        public async Task<IActionResult> GetBiddersForAuction(long auctionId)
        {
            var bidders = await _context.Bids
                .Where(b => b.AuctionId == auctionId)
                .Include(b => b.Bidder)
                .Select(b => new
                {
                    b.Bidder.AccountId,
                    b.Bidder.FirstName,
                    b.Bidder.LastName,
                    BidCount = _context.Bids.Count(x => x.AuctionId == auctionId && x.BidderId == b.BidderId),
                    LatestBidAmount = _context.Bids
                        .Where(x => x.AuctionId == auctionId && x.BidderId == b.BidderId)
                        .Max(x => (double)x.BidAmount)
                })
                .Distinct()
                .OrderByDescending(b => b.LatestBidAmount)
                .ToListAsync();

            return Ok(bidders);
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
                    return Unauthorized(new { message = "User not authenticated" });
                }

                var auction = await _context.Auctions
                    .Include(a => a.Property)
                    .FirstOrDefaultAsync(a => a.AuctionId == bidDto.AuctionId);
                if (auction == null)
                {
                    return BadRequest(new { message = "Auction not found." });
                }

                if (auction.Status != "Active")
                {
                    return BadRequest(new { message = "Auction is not active." });
                }

                // Check if user is trying to bid on their own property
                if (auction.Property?.OwnerId == userId)
                {
                    return BadRequest(new { message = "You cannot bid on your own property." });
                }

                // Check if bid amount is higher than current price
                var currentPrice = await GetCurrentPrice(bidDto.AuctionId);
                if ((decimal)bidDto.BidAmount <= currentPrice)
                {
                    return BadRequest(new { message = "Bid amount must be higher than current price." });
                }

                var bid = new Bid
                {
                    AuctionId = bidDto.AuctionId,
                    BidderId = userId,
                    BidAmount = (decimal)bidDto.BidAmount,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Bids.Add(bid);
                await _context.SaveChangesAsync(); // Save the bid first
                
                // Update auction current price and bid count
                if (auction != null)
                {
                    auction.CurrentPrice = (decimal)bidDto.BidAmount;
                    // Count all bids for this auction
                    auction.BidCount = await _context.Bids.CountAsync(b => b.AuctionId == bidDto.AuctionId);
                    await _context.SaveChangesAsync(); // Save the auction update
                }

                // Return the bid with bidder information
                var createdBid = await _context.Bids
                    .Include(b => b.Bidder)
                    .FirstAsync(b => b.BidId == bid.BidId);

                // Broadcast the bid update to all connected clients
                await _webSocketManager.BroadcastBidUpdateAsync(bidDto.AuctionId.ToString(), createdBid);
                
                // Broadcast the auction update (new price and bid count)
                var updatedAuction = await _context.Auctions
                    .Include(a => a.Property)
                    .FirstAsync(a => a.AuctionId == bidDto.AuctionId);
                await _webSocketManager.BroadcastAuctionUpdateAsync(bidDto.AuctionId.ToString(), updatedAuction);
                
                // Also broadcast to general feed for auction list pages
                await _webSocketManager.BroadcastToGeneralFeedAsync(createdBid, "new_bid");
                await _webSocketManager.BroadcastToGeneralFeedAsync(updatedAuction, "auction_update");

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
                return Unauthorized(new { message = "User not authenticated" });
            }

            var bids = await _context.Bids
                .Include(b => b.Auction)
                    .ThenInclude(a => a.Property)
                .Include(b => b.Bidder)
                .Where(b => b.BidderId == userId)
                .OrderByDescending(b => b.CreatedAt)
                .ToListAsync();

            return Ok(bids);
        }

        // GET: api/bids/{bidId}
        [HttpGet("{bidId}")]
        [Authorize]
        public async Task<IActionResult> GetBid(long bidId)
        {
            var bid = await _context.Bids
                .Include(b => b.Bidder)
                .Include(b => b.Auction)
                .FirstOrDefaultAsync(b => b.BidId == bidId);

            if (bid == null)
            {
                return NotFound(new { message = "Bid not found" });
            }

            return Ok(bid);
        }

        // DELETE: api/bids/{bidId}
        [HttpDelete("{bidId}")]
        [Authorize]
        [AdminAuthorize]
        public async Task<IActionResult> DeleteBid(long bidId)
        {
            var userIdClaim = User.FindFirst("uid");
            if (userIdClaim == null || !long.TryParse(userIdClaim.Value, out long userId))
            {
                return Unauthorized(new { message = "User not authenticated" });
            }

            var bid = await _context.Bids
                .Include(b => b.Auction)
                .FirstOrDefaultAsync(b => b.BidId == bidId);

            if (bid == null)
            {
                return NotFound(new { message = "Bid not found" });
            }

            if (bid.BidderId != userId)
            {
                return StatusCode(403, new { message = "You can only delete your own bids" });
            }

            // Check if auction is still active
            if (bid.Auction.Status != "Active")
            {
                return BadRequest(new { message = "Cannot delete bid from inactive auction" });
            }

            _context.Bids.Remove(bid);
            
            // Recalculate auction current price and bid count
            var auction = bid.Auction;
            var remainingBids = await _context.Bids
                .Where(b => b.AuctionId == auction.AuctionId)
                .OrderByDescending(b => (double)b.BidAmount)
                .ToListAsync();
                
            if (remainingBids.Any())
            {
                auction.CurrentPrice = remainingBids.First().BidAmount;
                auction.BidCount = remainingBids.Count;
            }
            else
            {
                auction.CurrentPrice = auction.StartPrice;
                auction.BidCount = 0;
            }
            
            await _context.SaveChangesAsync();

            return Ok(new { message = "Bid deleted successfully" });
        }

        private async Task<decimal> GetCurrentPrice(long auctionId)
        {
            var highestBid = await _context.Bids
                .Where(b => b.AuctionId == auctionId)
                .OrderByDescending(b => (double)b.BidAmount)
                .FirstOrDefaultAsync();

            if (highestBid != null)
            {
                return highestBid.BidAmount;
            }

            // If no bids, return the starting price
            var auction = await _context.Auctions.FindAsync(auctionId);
            return auction?.StartPrice ?? 0;
        }
    }

    public class CreateBidDto
    {
        public long AuctionId { get; set; }
        public double BidAmount { get; set; }
    }
}


