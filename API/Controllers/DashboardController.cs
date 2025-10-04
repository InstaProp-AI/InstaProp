using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;

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
        public async Task<ActionResult<object>> GetDashboardStats()
        {
            var totalProperties = await _context.Properties.CountAsync();
            var activeAuctions = await _context.Auctions.CountAsync(a => a.Status == "Active");
            var totalBids = await _context.Bids.CountAsync();
            var totalUsers = await _context.Users.CountAsync();

            var stats = new
            {
                TotalProperties = totalProperties,
                ActiveAuctions = activeAuctions,
                TotalBids = totalBids,
                TotalUsers = totalUsers,
                AverageBidAmount = await _context.Bids.AverageAsync(b => b.BidAmount),
                HighestBid = await _context.Bids.MaxAsync(b => b.BidAmount),
                PropertiesThisMonth = await _context.Properties
                    .CountAsync(p => p.CreatedAt >= DateTime.UtcNow.AddDays(-30)),
                AuctionsThisMonth = await _context.Auctions
                    .CountAsync(a => a.CreatedAt >= DateTime.UtcNow.AddDays(-30))
            };

            return Ok(stats);
        }

        // GET: api/Dashboard/analytics
        [HttpGet("analytics")]
        public async Task<ActionResult<object>> GetAnalytics()
        {
            var monthlyData = await GetMonthlyData();
            var categoryData = await GetCategoryData();
            var locationData = await GetLocationData();

            var analytics = new
            {
                MonthlyData = monthlyData,
                CategoryData = categoryData,
                LocationData = locationData,
                MarketTrends = GetMarketTrends(),
                TopPerformers = await GetTopPerformers()
            };

            return Ok(analytics);
        }

        // GET: api/Dashboard/user/{userId}
        [HttpGet("user/{userId}")]
        public async Task<ActionResult<object>> GetUserDashboard(int userId)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
            {
                return NotFound();
            }

            var userProperties = await _context.Properties
                .Where(p => p.OwnerId == userId)
                .CountAsync();

            var userBids = await _context.Bids
                .Where(b => b.BidderId == userId)
                .CountAsync();

            var userWinningBids = await _context.Bids
                .Where(b => b.BidderId == userId)
                .Include(b => b.Auction)
                .Where(b => b.Auction.Status == "Ended" && b.BidAmount == b.Auction.CurrentPrice)
                .CountAsync();

            var totalBidAmount = await _context.Bids
                .Where(b => b.BidderId == userId)
                .SumAsync(b => b.BidAmount);

            var recentActivity = await _context.Bids
                .Where(b => b.BidderId == userId)
                .Include(b => b.Auction)
                .ThenInclude(a => a.Property)
                .OrderByDescending(b => b.CreatedAt)
                .Take(5)
                .Select(b => new
                {
                    b.BidAmount,
                    b.CreatedAt,
                    PropertyName = b.Auction.Property.Name,
                    AuctionStatus = b.Auction.Status
                })
                .ToListAsync();

            var dashboard = new
            {
                User = new
                {
                    user.UserId,
                    user.FirstName,
                    user.LastName,
                    user.Email,
                    user.IsVerified
                },
                Stats = new
                {
                    Properties = userProperties,
                    TotalBids = userBids,
                    WinningBids = userWinningBids,
                    TotalBidAmount = totalBidAmount,
                    SuccessRate = userBids > 0 ? (double)userWinningBids / userBids * 100 : 0
                },
                RecentActivity = recentActivity
            };

            return Ok(dashboard);
        }

        // GET: api/Dashboard/auctions/trending
        [HttpGet("auctions/trending")]
        public async Task<ActionResult<IEnumerable<object>>> GetTrendingAuctions()
        {
            var trending = await _context.Auctions
                .Where(a => a.Status == "Active")
                .Include(a => a.Property)
                .Include(a => a.Bids)
                .OrderByDescending(a => a.BidCount)
                .Take(10)
                .Select(a => new
                {
                    a.AuctionId,
                    a.Property.Name,
                    a.Property.Location,
                    a.CurrentPrice,
                    a.BidCount,
                    a.StartAt,
                    a.EndAt,
                    TimeRemaining = a.EndAt - DateTime.UtcNow,
                    ImageUrl = a.Property.ImageUrl
                })
                .ToListAsync();

            return Ok(trending);
        }

        // GET: api/Dashboard/properties/featured
        [HttpGet("properties/featured")]
        public async Task<ActionResult<IEnumerable<object>>> GetFeaturedProperties()
        {
            var featured = await _context.Properties
                .Where(p => p.IsApproved)
                .Include(p => p.Owner)
                .OrderByDescending(p => p.StartingPrice)
                .Take(8)
                .Select(p => new
                {
                    p.PropertyId,
                    p.Name,
                    p.Location,
                    p.Bedrooms,
                    p.Bathrooms,
                    p.SquareFeet,
                    p.StartingPrice,
                    p.ImageUrl,
                    Owner = new
                    {
                        p.Owner.FirstName,
                        p.Owner.LastName
                    }
                })
                .ToListAsync();

            return Ok(featured);
        }

        private async Task<List<object>> GetMonthlyData()
        {
            var data = new List<object>();
            var months = 12;

            for (int i = months - 1; i >= 0; i--)
            {
                var date = DateTime.UtcNow.AddMonths(-i);
                var startOfMonth = new DateTime(date.Year, date.Month, 1);
                var endOfMonth = startOfMonth.AddMonths(1).AddDays(-1);

                var properties = await _context.Properties
                    .CountAsync(p => p.CreatedAt >= startOfMonth && p.CreatedAt <= endOfMonth);

                var auctions = await _context.Auctions
                    .CountAsync(a => a.CreatedAt >= startOfMonth && a.CreatedAt <= endOfMonth);

                var bids = await _context.Bids
                    .CountAsync(b => b.CreatedAt >= startOfMonth && b.CreatedAt <= endOfMonth);

                data.Add(new
                {
                    Month = startOfMonth.ToString("MMM yyyy"),
                    Properties = properties,
                    Auctions = auctions,
                    Bids = bids
                });
            }

            return data;
        }

        private async Task<List<object>> GetCategoryData()
        {
            var categories = await _context.Properties
                .Where(p => p.IsApproved)
                .GroupBy(p => p.Category)
                .Select(g => new
                {
                    Category = g.Key,
                    Count = g.Count(),
                    AveragePrice = g.Average(p => p.StartingPrice)
                })
                .ToListAsync();

            return categories.Cast<object>().ToList();
        }

        private async Task<List<object>> GetLocationData()
        {
            var locations = await _context.Properties
                .Where(p => p.IsApproved)
                .GroupBy(p => p.Location)
                .Select(g => new
                {
                    Location = g.Key,
                    Count = g.Count(),
                    AveragePrice = g.Average(p => p.StartingPrice)
                })
                .OrderByDescending(x => x.Count)
                .Take(10)
                .ToListAsync();

            return locations.Cast<object>().ToList();
        }

        private object GetMarketTrends()
        {
            return new
            {
                AveragePrice = 450000,
                PriceChange = 5.2,
                DaysOnMarket = 45,
                InventoryLevel = "Low",
                MarketCondition = "Seller's Market",
                PricePerSqFt = 250,
                InterestRate = 6.5
            };
        }

        private async Task<List<object>> GetTopPerformers()
        {
            var topBidders = await _context.Bids
                .Include(b => b.Bidder)
                .GroupBy(b => b.BidderId)
                .Select(g => new
                {
                    UserId = g.Key,
                    FirstName = g.First().Bidder.FirstName,
                    LastName = g.First().Bidder.LastName,
                    TotalBids = g.Count(),
                    TotalAmount = g.Sum(b => b.BidAmount),
                    WinningBids = g.Count(b => b.Auction.Status == "Ended" && b.BidAmount == b.Auction.CurrentPrice)
                })
                .OrderByDescending(x => x.TotalAmount)
                .Take(5)
                .ToListAsync();

            return topBidders.Cast<object>().ToList();
        }
    }
}
