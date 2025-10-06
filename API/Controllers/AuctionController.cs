using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using PropertyFlipperAPI.Attributes;
using Microsoft.AspNetCore.Authorization;

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
        [Authorize]
        public async Task<ActionResult<IEnumerable<AuctionDto>>> GetAuctions()
        {
            var auctions = await _context.Auctions
                .Include(a => a.Property)
                .ToListAsync();

            // Convert to DTOs with calculated values
            var auctionDtos = auctions.Select(AuctionDto.FromAuction).ToList();

            return auctionDtos;
        }

        // GET: api/Auction/5
        [HttpGet("{id}")]
        [Authorize]
        public async Task<ActionResult<AuctionDto>> GetAuction(int id)
        {
            var auction = await _context.Auctions
                .Include(a => a.Property)
                .FirstOrDefaultAsync(a => a.AuctionId == id);

            if (auction == null)
            {
                return NotFound();
            }

            // Convert to DTO to avoid circular references
            var auctionDto = AuctionDto.FromAuction(auction);
            return auctionDto;
        }



        // PUT: api/Auction/5
        [HttpPut("{id}")]
        [Authorize]
        [AdminAuthorize]
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
        [Authorize]
        [AdminAuthorize]
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
        [Authorize]
        public async Task<ActionResult<IEnumerable<AuctionDto>>> GetActiveAuctions()
        {
            var now = DateTime.UtcNow;
            var auctions = await _context.Auctions
                .Where(a => a.EndAt >= now && a.Status == "Active")
                .Include(a => a.Property)
                .ToListAsync();

            // Convert to DTOs with calculated values
            var auctionDtos = auctions.Select(AuctionDto.FromAuction).ToList();

            return auctionDtos;
        }

        // POST: api/Auction/request
        [HttpPost("request")]
        [Authorize]
        public async Task<ActionResult> RequestAuction([FromBody] AuctionRequestDto requestDto)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            // Check if property exists and belongs to user
            var property = await _context.Properties.FindAsync(requestDto.PropertyId);
            if (property == null)
                return NotFound("Property not found");

            if (property.OwnerId != accountId)
                return Forbid("You can only request auctions for your own properties");

            // Check if property is verified
            if (!property.IsVerified)
                return BadRequest(new { message = "Property must be verified before auction can be requested" });

            // Check if property already has an active auction request
            var existingAuction = await _context.Auctions
                .FirstOrDefaultAsync(a => a.PropertyId == requestDto.PropertyId && 
                    (a.Status == "Requested" || a.Status == "Active"));

            if (existingAuction != null)
                return BadRequest(new { message = "Property already has an auction request or active auction" });

            // Create auction request
            var auction = new Auction
            {
                PropertyId = requestDto.PropertyId,
                StartAt = requestDto.StartAt,
                CurrentPrice = requestDto.StartAt,
                EndAt = requestDto.EndAt,
                Duration = requestDto.Duration,
                BuyNowPrice = requestDto.BuyNowPrice,
                Status = "Requested",
                CreatedAt = DateTime.UtcNow
            };

            _context.Auctions.Add(auction);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Auction request submitted successfully", auctionId = auction.AuctionId });
        }

        // PUT: api/Auction/{id}/status
        [HttpPut("{id}/status")]
        [Authorize]
        [AdminAuthorize]
        public async Task<ActionResult> UpdateAuctionStatus(long id, [FromBody] AuctionStatusUpdateDto statusDto)
        {
            var auction = await _context.Auctions.FindAsync(id);
            if (auction == null)
                return NotFound();

            if (auction.Status != "Requested")
                return BadRequest(new { message = "Only requested auctions can have their status updated" });

            if (statusDto.Status != "Approved" && statusDto.Status != "Rejected")
                return BadRequest(new { message = "Status must be either 'Approved' or 'Rejected'" });

            // Update auction status
            if (statusDto.Status == "Approved")
            {
                auction.Status = "Active";
                await _context.SaveChangesAsync();
                return Ok(new { message = "Auction approved and activated successfully" });
            }
            else
            {
                auction.Status = "Cancelled";
                await _context.SaveChangesAsync();
                return Ok(new { message = "Auction request rejected" });
            }
        }

        // GET: api/Auction/requests
        [HttpGet("requests")]
        [Authorize]
        [AdminAuthorize]
        public async Task<ActionResult<IEnumerable<AuctionDto>>> GetAuctionRequests()
        {
            var auctions = await _context.Auctions
                .Where(a => a.Status == "Requested")
                .Include(a => a.Property)
                .ToListAsync();

            var auctionDtos = auctions.Select(AuctionDto.FromAuction).ToList();
            return auctionDtos;
        }






        private bool AuctionExists(int id)
        {
            return _context.Auctions.Any(e => e.AuctionId == id);
        }

        private long? GetCurrentAccountId()
        {
            var uidClaim = User.FindFirst("uid");
            return uidClaim != null ? long.Parse(uidClaim.Value) : null;
        }
    }

    public class AuctionRequestDto
    {
        public long PropertyId { get; set; }
        public decimal StartAt { get; set; }
        public DateTime EndAt { get; set; }
        public int Duration { get; set; } // hours
        public decimal? BuyNowPrice { get; set; }
    }

    public class AuctionStatusUpdateDto
    {
        public string Status { get; set; } = string.Empty; // "Approved" or "Rejected"
    }
}
