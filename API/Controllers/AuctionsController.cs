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
    public class AuctionsController : ControllerBase
    {
        private readonly AppDbContext _context;
        public AuctionsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/auctions
        [HttpGet]
        public async Task<IActionResult> GetAuctions()
        {
            try
            {
                var auctions = await _context.Auctions
                    .Include(a => a.Property)
                    .Include(a => a.Bids)
                    .OrderByDescending(a => a.CreatedAt)
                    .ToListAsync();
                return Ok(auctions);
            }
            catch (Exception ex)
            {
                // Return empty list if tables don't exist yet
                return Ok(new List<Auction>());
            }
        }

        // GET: api/auctions/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetAuction(long id)
        {
            var auction = await _context.Auctions
                .Include(a => a.Property)
                .Include(a => a.Bids)
                .ThenInclude(b => b.Bidder)
                .FirstOrDefaultAsync(a => a.AuctionId == id);
            if (auction == null) return NotFound();
            return Ok(auction);
        }
    }
}


