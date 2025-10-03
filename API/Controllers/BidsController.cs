using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using System.Linq;
using System.Threading.Tasks;

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
        public async Task<IActionResult> CreateBid([FromBody] Bid bid)
        {
            var auction = await _context.Auctions.FindAsync(bid.AuctionId);
            if (auction == null || auction.Status != "Active")
            {
                return BadRequest("Auction not found or not active.");
            }
            _context.Bids.Add(bid);
            await _context.SaveChangesAsync();
            return Ok(bid);
        }
    }
}


