using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BidController : ControllerBase
    {
        private readonly AppDbContext _context;

        public BidController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Bid
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Bid>>> GetBids()
        {
            return await _context.Bids
                .Include(b => b.Auction)
                .Include(b => b.Bidder)
                .ToListAsync();
        }

        // GET: api/Bid/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Bid>> GetBid(int id)
        {
            var bid = await _context.Bids
                .Include(b => b.Auction)
                .Include(b => b.Bidder)
                .FirstOrDefaultAsync(b => b.BidId == id);

            if (bid == null)
            {
                return NotFound();
            }

            return bid;
        }

        // POST: api/Bid
        [HttpPost]
        public async Task<ActionResult<Bid>> PostBid(CreateBidDto createBidDto)
        {
            // Get user ID from authentication (for now, we'll use a default user ID for testing)
            // In a real app, this would come from JWT token or session
            var userId = 9L; // Default test user ID - in production this would be from authentication

            // Check if auction is still active and get current bids
            var auction = await _context.Auctions
                .Include(a => a.Bids)
                .FirstOrDefaultAsync(a => a.AuctionId == createBidDto.AuctionId);
                
            if (auction == null)
            {
                return NotFound("Auction not found");
            }

            if (auction.Status != "Active")
            {
                return BadRequest("Auction is not active");
            }

            if (auction.EndAt <= DateTime.UtcNow)
            {
                return BadRequest("Auction has ended");
            }

            // Calculate the actual current price from bids
            var currentHighestBid = auction.Bids.Any() ? auction.Bids.Max(b => b.BidAmount) : auction.StartAt;

            // Check if bid amount is higher than current highest bid
            if (createBidDto.BidAmount <= currentHighestBid)
            {
                return BadRequest($"Bid amount must be higher than current highest bid of {currentHighestBid:C}");
            }

            // Create the bid
            var bid = new Bid
            {
                AuctionId = createBidDto.AuctionId,
                BidderId = userId,
                BidAmount = createBidDto.BidAmount,
                CreatedAt = DateTime.UtcNow
            };

            // Update auction current price and bid count
            auction.CurrentPrice = bid.BidAmount;
            auction.BidCount = auction.Bids.Count + 1;

            _context.Bids.Add(bid);
            _context.Entry(auction).State = EntityState.Modified;
            await _context.SaveChangesAsync();

            // Load the bid with related data for response
            await _context.Entry(bid)
                .Reference(b => b.Auction)
                .LoadAsync();
            await _context.Entry(bid)
                .Reference(b => b.Bidder)
                .LoadAsync();

            return CreatedAtAction("GetBid", new { id = bid.BidId }, bid);
        }

        // PUT: api/Bid/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutBid(int id, Bid bid)
        {
            if (id != bid.BidId)
            {
                return BadRequest();
            }

            _context.Entry(bid).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!BidExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return NoContent();
        }

        // DELETE: api/Bid/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteBid(int id)
        {
            var bid = await _context.Bids.FindAsync(id);
            if (bid == null)
            {
                return NotFound();
            }

            _context.Bids.Remove(bid);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // GET: api/Bid/auction/5
        [HttpGet("auction/{auctionId}")]
        public async Task<ActionResult<IEnumerable<Bid>>> GetAuctionBids(int auctionId)
        {
            return await _context.Bids
                .Where(b => b.AuctionId == auctionId)
                .Include(b => b.Bidder)
                .OrderByDescending(b => b.BidAmount)
                .ToListAsync();
        }

        // GET: api/Bid/user/5
        [HttpGet("user/{userId}")]
        public async Task<ActionResult<IEnumerable<Bid>>> GetUserBids(int userId)
        {
            return await _context.Bids
                .Where(b => b.BidderId == userId)
                .Include(b => b.Auction)
                .ThenInclude(a => a.Property)
                .OrderByDescending(b => b.CreatedAt)
                .ToListAsync();
        }

        // GET: api/Bid/auction/5/highest
        [HttpGet("auction/{auctionId}/highest")]
        public async Task<ActionResult<Bid>> GetHighestBid(int auctionId)
        {
            var bid = await _context.Bids
                .Where(b => b.AuctionId == auctionId)
                .Include(b => b.Bidder)
                .OrderByDescending(b => b.BidAmount)
                .FirstOrDefaultAsync();

            if (bid == null)
            {
                return NotFound();
            }

            return bid;
        }

        private bool BidExists(int id)
        {
            return _context.Bids.Any(e => e.BidId == id);
        }
    }
}
