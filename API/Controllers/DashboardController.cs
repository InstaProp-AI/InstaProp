using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Attributes;
using Microsoft.AspNetCore.Authorization;

namespace InstapropAPI.Controllers
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

        // GET: api/Dashboard/public-stats (No auth required)
        [HttpGet("public-stats")]
        public async Task<ActionResult<object>> GetPublicStats()
        {
            try
            {
                var now = DateTime.UtcNow;
                var oneWeekAgo = now.AddDays(-7);
                var today = now.Date;

                var totalUsers = await _context.Accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).CountAsync();
                var activeAuctions = await _context.Auctions.Where(a => a.Status == "Active").CountAsync();
                var totalBids = await _context.Bids.CountAsync();
                var bidsLastWeek = await _context.Bids.Where(b => b.CreatedAt >= oneWeekAgo).CountAsync();
                var bidsToday = await _context.Bids.Where(b => b.CreatedAt >= today).CountAsync();
                
                // Total auction volume (sum of all current prices)
                var allActiveAuctions = await _context.Auctions
                    .Where(a => a.Status == "Active")
                    .ToListAsync();
                var totalVolume = allActiveAuctions.Sum(a => a.CurrentPrice);

                // Average bid per auction
                var avgBidsPerAuction = activeAuctions > 0 
                    ? Math.Round((double)totalBids / activeAuctions, 1)
                    : 0;

                // Auctions ending today
                var endOfDay = today.AddDays(1);
                
                // Calculate auctions ending today (EndAt = StartAt + Duration)
                var auctionsEndingToday = allActiveAuctions
                    .Count(a => 
                    {
                        var endAt = a.StartAt.AddHours(a.Duration);
                        return endAt >= today && endAt < endOfDay;
                    });

                // Total properties
                var totalProperties = await _context.ChildProperties.CountAsync();

                var stats = new
                {
                    TotalUsers = totalUsers,
                    ActiveAuctions = activeAuctions,
                    TotalBids = totalBids,
                    BidsLastWeek = bidsLastWeek,
                    BidsToday = bidsToday,
                    TotalVolume = totalVolume,
                    AverageBidsPerAuction = avgBidsPerAuction,
                    AuctionsEndingToday = auctionsEndingToday,
                    TotalProperties = totalProperties
                };

                return Ok(stats);
            }
            catch (Exception ex)
            {
                return Ok(new
                {
                    TotalUsers = 0,
                    ActiveAuctions = 0,
                    TotalBids = 0,
                    BidsLastWeek = 0,
                    BidsToday = 0,
                    TotalVolume = 0.0,
                    AverageBidsPerAuction = 0.0,
                    AuctionsEndingToday = 0,
                    TotalProperties = 0,
                    Error = ex.Message
                });
            }
        }

        // GET: api/Dashboard/stats
        [HttpGet("stats")]
        [Authorize]
        [AdminAuthorize]
        public async Task<ActionResult<object>> GetDashboardStats()
        {
            try
            {
                var totalProperties = await _context.ChildProperties.CountAsync();
                var totalAuctions = await _context.Auctions.CountAsync();
                var activeAuctions = await _context.Auctions.Where(a => a.Status == "Active").CountAsync();
                var endedAuctions = await _context.Auctions.Where(a => a.Status == "Closed" || a.Status == "Completed" || a.Status == "Ended").CountAsync();
                var totalBids = await _context.Bids.CountAsync();
                var totalUsers = await _context.Accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).CountAsync();
                var totalAccounts = await _context.Accounts.CountAsync();

                // Calculate average bid value
                var averageBidValue = totalBids > 0 
                    ? await _context.Bids.AverageAsync(b => (double?)b.BidAmount) ?? 0
                    : 0;

                // Monthly revenue (last 30 days from ended auctions)
                // Use CreatedAt since Auction model doesn't have UpdatedAt
                // For ended auctions, we use the creation date as a proxy for when they ended
                var last30Days = DateTime.UtcNow.AddDays(-30);
                var monthlyRevenue = await _context.Auctions
                    .Where(a => (a.Status == "Closed" || a.Status == "Completed" || a.Status == "Ended") 
                        && a.CreatedAt >= last30Days)
                    .SumAsync(a => (decimal?)a.CurrentPrice) ?? 0;

                // Match frontend expected structure
                var stats = new
                {
                    properties = new
                    {
                        total = totalProperties
                    },
                    auctions = new
                    {
                        total = totalAuctions,
                        active = activeAuctions,
                        ended = endedAuctions
                    },
                    bids = new
                    {
                        total = totalBids,
                        averageValue = Math.Round(averageBidValue, 2)
                    },
                    users = new
                    {
                        total = totalUsers
                    },
                    revenue = new
                    {
                        monthly = (double)monthlyRevenue
                    }
                };

                return Ok(stats);
            }
            catch (Exception ex)
            {
                return Ok(new
                {
                    properties = new { total = 0 },
                    auctions = new { total = 0, active = 0, ended = 0 },
                    bids = new { total = 0, averageValue = 0.0 },
                    users = new { total = 0 },
                    revenue = new { monthly = 0.0 },
                    Error = ex.Message
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
                PropertyTypes = await _context.ChildProperties
                    .GroupBy(p => PropertyTypeHelper.ToDisplayName(p.Type))
                    .Select(g => new { Type = g.Key, Count = g.Count() })
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