using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Attributes;
using Microsoft.AspNetCore.Authorization;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DashboardController : ControllerBase
    {
        private readonly AppDbContext _context;

        public DashboardController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Dashboard/stats
        [HttpGet("stats")]
        [Authorize]
        [AdminAuthorize]
        public async Task<ActionResult<object>> GetDashboardStats()
        {
            try
            {
                var totalProperties = await _context.Properties.CountAsync();
                var totalAuctions = await _context.Auctions.CountAsync();
                var activeAuctions = await _context.Auctions.Where(a => a.Status == "Active").CountAsync();
                var totalBids = await _context.Bids.CountAsync();
                var totalAccounts = await _context.Accounts.CountAsync();
                var verifiedAccounts = await _context.Accounts.Where(a => a.IsVerified).CountAsync();
                var propertiesPendingApproval = await _context.Properties.Where(p => !p.IsApproved).CountAsync();

                var stats = new
                {
                    TotalProperties = totalProperties,
                    TotalAuctions = totalAuctions,
                    ActiveAuctions = activeAuctions,
                    TotalBids = totalBids,
                    TotalAccounts = totalAccounts,
                    VerifiedAccounts = verifiedAccounts,
                    PropertiesPendingApproval = propertiesPendingApproval
                };

                return Ok(stats);
            }
            catch (Exception ex)
            {
                return Ok(new
                {
                    TotalProperties = 0,
                    TotalAuctions = 0,
                    ActiveAuctions = 0,
                    TotalBids = 0,
                    TotalAccounts = 0,
                    VerifiedAccounts = 0,
                    PropertiesPendingApproval = 0,
                    Error = "Database not properly seeded"
                });
            }
        }

        // GET: api/Dashboard/analytics
        [HttpGet("analytics")]
        [AdminAuthorize]
        public async Task<ActionResult<object>> GetAnalytics()
        {
            var analytics = new
            {
                PropertyCategories = await _context.Properties
                    .GroupBy(p => p.Category)
                    .Select(g => new { Category = g.Key, Count = g.Count() })
                    .ToListAsync(),
                AuctionStatuses = await _context.Auctions
                    .GroupBy(a => a.Status)
                    .Select(g => new { Status = g.Key, Count = g.Count() })
                    .ToListAsync(),
                RecentActivity = await _context.Bids
                    .Include(b => b.Auction)
                    .ThenInclude(a => a.Property)
                    .OrderByDescending(b => b.CreatedAt)
                    .Take(10)
                    .Select(b => new
                    {
                        b.BidAmount,
                        b.CreatedAt,
                        PropertyName = b.Auction.Property.Name,
                        BidderId = b.BidderId
                    })
                    .ToListAsync()
            };

            return Ok(analytics);
        }
    }
}