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
        public async Task<IActionResult> DeleteAuction(long id)
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
        public async Task<ActionResult<IEnumerable<AuctionDto>>> GetActiveAuctions()
        {
            var now = DateTime.UtcNow;
            var auctions = await _context.Auctions
                .Include(a => a.Property)
                .ToListAsync();

            // Filter active auctions (must have started and not ended)
            // Active only if: Status is Active, StartAt has passed, and EndAt hasn't passed
            var activeAuctions = auctions
                .Where(a => a.Status == "Active" && 
                           a.StartAt <= now &&  // Has started
                           a.StartAt.AddHours(a.Duration) >= now)  // Hasn't ended
                .ToList();

            // Convert to DTOs with calculated values
            var auctionDtos = activeAuctions.Select(AuctionDto.FromAuction).ToList();

            return auctionDtos;
        }

        // POST: api/Auction (Admin only - direct creation)
        [HttpPost]
        [Authorize]
        [AdminAuthorize]
        public async Task<ActionResult<Auction>> CreateAuction([FromBody] CreateAuctionDto auctionDto)
        {
            // Check if property exists
            var property = await _context.Properties.FindAsync(auctionDto.PropertyId);
            if (property == null)
                return NotFound("Property not found");

            // Check if property already has an active auction
            var existingAuction = await _context.Auctions
                .FirstOrDefaultAsync(a => a.PropertyId == auctionDto.PropertyId && 
                    (a.Status == "Requested" || a.Status == "Active"));

            if (existingAuction != null)
                return BadRequest(new { message = "Property already has an auction request or active auction" });

            // Create auction directly as Active
            var auction = new Auction
            {
                PropertyId = auctionDto.PropertyId,
                StartPrice = auctionDto.StartPrice,
                CurrentPrice = auctionDto.StartPrice,
                StartAt = auctionDto.StartAt,
                Duration = auctionDto.Duration,
                BuyNowPrice = auctionDto.BuyNowPrice,
                Status = "Active",
                BidCount = 0,
                CreatedAt = DateTime.UtcNow
            };

            _context.Auctions.Add(auction);
            await _context.SaveChangesAsync();

            // Load the property for the response
            await _context.Entry(auction).Reference(a => a.Property).LoadAsync();

            return CreatedAtAction(nameof(GetAuction), new { id = auction.AuctionId }, auction);
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
                return BadRequest(new { message = "You can only request auctions for your own properties" });

            // For testing: skip verification check
            // if (!property.IsVerified)
            //     return BadRequest(new { message = "Property must be verified before auction can be requested" });

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
                StartPrice = requestDto.StartPrice,
                CurrentPrice = requestDto.StartPrice,
                StartAt = requestDto.StartAt,
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

        // POST: api/Auction/{id}/relist
        [HttpPost("{id}/relist")]
        [Authorize]
        [AdminAuthorize]
        public async Task<ActionResult> RelistAuction(long id, [FromBody] RelistAuctionDto relistDto)
        {
            var auction = await _context.Auctions
                .Include(a => a.Property)
                .FirstOrDefaultAsync(a => a.AuctionId == id);
            
            if (auction == null)
                return NotFound(new { message = "Auction not found" });

            // Check if auction has ended
            var endTime = auction.StartAt.AddHours(auction.Duration);
            if (endTime >= DateTime.UtcNow && auction.Status == "Active")
                return BadRequest(new { message = "Can only relist ended auctions" });

            // Update auction to relist
            auction.StartAt = relistDto.StartAt ?? DateTime.UtcNow;
            auction.Duration = relistDto.Duration > 0 ? relistDto.Duration : auction.Duration;
            auction.Status = "Active";
            auction.CurrentPrice = relistDto.ResetPrice ? auction.StartPrice : auction.CurrentPrice;
            auction.BidCount = relistDto.ResetBids ? 0 : auction.BidCount;

            // Optionally reset bids
            if (relistDto.ResetBids)
            {
                var bids = await _context.Bids.Where(b => b.AuctionId == id).ToListAsync();
                _context.Bids.RemoveRange(bids);
            }

            await _context.SaveChangesAsync();

            return Ok(new { 
                message = "Auction relisted successfully", 
                auction = AuctionDto.FromAuction(auction)
            });
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
        public decimal StartPrice { get; set; }
        public DateTime StartAt { get; set; }
        public int Duration { get; set; } // hours
        public decimal? BuyNowPrice { get; set; }
    }

    public class AuctionStatusUpdateDto
    {
        public string Status { get; set; } = string.Empty; // "Approved" or "Rejected"
    }

    public class CreateAuctionDto
    {
        public long PropertyId { get; set; }
        public decimal StartPrice { get; set; }
        public DateTime StartAt { get; set; }
        public int Duration { get; set; } // hours
        public decimal? BuyNowPrice { get; set; }
    }

    public class RelistAuctionDto
    {
        public DateTime? StartAt { get; set; } // If null, starts immediately
        public int Duration { get; set; } // New duration in hours (if 0, keeps existing duration)
        public bool ResetPrice { get; set; } // If true, resets current price to start price
        public bool ResetBids { get; set; } // If true, removes all existing bids
    }
}
