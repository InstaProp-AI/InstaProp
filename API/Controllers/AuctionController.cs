using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuctionController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AuctionController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Auction
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Auction>>> GetAuctions()
        {
            return await _context.Auctions
                .Include(a => a.Property)
                .Include(a => a.Bids)
                .ThenInclude(b => b.Bidder)
                .ToListAsync();
        }

        // GET: api/Auction/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Auction>> GetAuction(int id)
        {
            var auction = await _context.Auctions
                .Include(a => a.Property)
                .Include(a => a.Bids)
                .ThenInclude(b => b.Bidder)
                .FirstOrDefaultAsync(a => a.AuctionId == id);

            if (auction == null)
            {
                return NotFound();
            }

            return auction;
        }

        // POST: api/Auction
        [HttpPost]
        public async Task<ActionResult<Auction>> PostAuction(Auction auction)
        {
            _context.Auctions.Add(auction);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetAuction", new { id = auction.AuctionId }, auction);
        }

        // PUT: api/Auction/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutAuction(int id, Auction auction)
        {
            if (id != auction.AuctionId)
            {
                return BadRequest();
            }

            _context.Entry(auction).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!AuctionExists(id))
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

        // DELETE: api/Auction/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteAuction(int id)
        {
            var auction = await _context.Auctions.FindAsync(id);
            if (auction == null)
            {
                return NotFound();
            }

            _context.Auctions.Remove(auction);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // GET: api/Auction/active
        [HttpGet("active")]
        public async Task<ActionResult<IEnumerable<Auction>>> GetActiveAuctions()
        {
            var now = DateTime.UtcNow;
            return await _context.Auctions
                .Where(a => a.EndAt >= now && a.Status == "Active")
                .Include(a => a.Property)
                .Include(a => a.Bids)
                .ToListAsync();
        }

        // GET: api/Auction/featured
        [HttpGet("featured")]
        public async Task<ActionResult<IEnumerable<Auction>>> GetFeaturedAuctions()
        {
            return await _context.Auctions
                .Where(a => a.Status == "Active")
                .Include(a => a.Property)
                .Include(a => a.Bids)
                .OrderByDescending(a => a.CurrentPrice)
                .Take(5)
                .ToListAsync();
        }

        // GET: api/Auction/property/5
        [HttpGet("property/{propertyId}")]
        public async Task<ActionResult<IEnumerable<Auction>>> GetPropertyAuctions(int propertyId)
        {
            return await _context.Auctions
                .Where(a => a.PropertyId == propertyId)
                .Include(a => a.Property)
                .Include(a => a.Bids)
                .ToListAsync();
        }

        // PUT: api/Auction/5/start
        [HttpPut("{id}/start")]
        public async Task<IActionResult> StartAuction(int id)
        {
            var auction = await _context.Auctions.FindAsync(id);
            if (auction == null)
            {
                return NotFound();
            }

            auction.Status = "Active";
            auction.CurrentPrice = auction.StartAt;
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // PUT: api/Auction/5/end
        [HttpPut("{id}/end")]
        public async Task<IActionResult> EndAuction(int id)
        {
            var auction = await _context.Auctions.FindAsync(id);
            if (auction == null)
            {
                return NotFound();
            }

            auction.Status = "Ended";
            auction.EndAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private bool AuctionExists(int id)
        {
            return _context.Auctions.Any(e => e.AuctionId == id);
        }
    }
}
