using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using Microsoft.AspNetCore.Authorization;

namespace PropertyFlipperAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AnalyticsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AnalyticsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/analytics/market-overview
        [HttpGet("market-overview")]
        public async Task<ActionResult<MarketOverviewResponse>> GetMarketOverview()
        {
            try
            {
                var totalProperties = await _context.ChildProperties.CountAsync();
                var activeAuctions = await _context.Auctions.CountAsync(a => a.Status == "Active");
                var totalDevelopers = await _context.Accounts.CountAsync(a => a.Type == Models.AccountType.Developer);

                // Average prices by area
                var areaPrices = await _context.ChildProperties
                    .Where(p => p.Auctions.Any())
                    .GroupBy(p => p.Location)
                    .Select(g => new AreaPriceData
                    {
                        Area = g.Key,
                        AveragePrice = g.Average(p => p.Auctions.First().CurrentPrice),
                        PropertyCount = g.Count()
                    })
                    .OrderByDescending(a => a.AveragePrice)
                    .Take(10)
                    .ToListAsync();

                // Property type distribution
                var typeDistribution = await _context.ChildProperties
                    .Where(p => p.Auctions.Any())
                    .GroupBy(p => p.PropertyType)
                    .Select(g => new PropertyTypeDistribution
                    {
                        PropertyType = g.Key,
                        Count = g.Count(),
                        Percentage = (double)g.Count() / totalProperties * 100
                    })
                    .OrderByDescending(t => t.Count)
                    .ToListAsync();

                // Recent price trends (last 6 months)
                var sixMonthsAgo = DateTime.UtcNow.AddMonths(-6);
                var recentPriceHistory = await _context.PropertyPriceHistories
                    .Where(ph => ph.PriceDate >= sixMonthsAgo)
                    .GroupBy(ph => ph.PriceDate.Month)
                    .Select(g => new PriceTrendData
                    {
                        Month = g.Key,
                        AveragePrice = g.Average(ph => ph.Price),
                        TransactionCount = g.Count()
                    })
                    .OrderBy(p => p.Month)
                    .ToListAsync();

                return Ok(new MarketOverviewResponse
                {
                    TotalProperties = totalProperties,
                    ActiveAuctions = activeAuctions,
                    TotalDevelopers = totalDevelopers,
                    AreaPrices = areaPrices,
                    PropertyTypeDistribution = typeDistribution,
                    RecentPriceTrends = recentPriceHistory
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // GET: api/analytics/price-trends
        [HttpGet("price-trends")]
        public async Task<ActionResult<IEnumerable<PriceTrendResponse>>> GetPriceTrends(
            [FromQuery] int? parentPropertyId,
            [FromQuery] string? propertyType,
            [FromQuery] string? location,
            [FromQuery] int months = 12)
        {
            try
            {
                var startDate = DateTime.UtcNow.AddMonths(-months);
                var query = _context.PropertyPriceHistories
                    .Where(ph => ph.PriceDate >= startDate);

                if (parentPropertyId.HasValue)
                {
                    query = query.Where(ph => ph.ParentPropertyId == parentPropertyId.Value);
                }

                if (!string.IsNullOrEmpty(propertyType))
                {
                    query = query.Where(ph => ph.ParentProperty.PropertyType == propertyType);
                }

                if (!string.IsNullOrEmpty(location))
                {
                    query = query.Where(ph => ph.ParentProperty.ProjectName.Contains(location));
                }

                var priceHistory = await query
                    .OrderBy(ph => ph.PriceDate)
                    .Select(ph => new PriceTrendResponse
                    {
                        Date = ph.PriceDate,
                        Price = ph.Price,
                        Source = ph.Source,
                        ParentPropertyId = ph.ParentPropertyId,
                        ProjectName = ph.ParentProperty.ProjectName,
                        PropertyType = ph.ParentProperty.PropertyType
                    })
                    .ToListAsync();

                return Ok(priceHistory);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // GET: api/analytics/gold-comparison
        [HttpGet("gold-comparison")]
        public async Task<ActionResult<GoldComparisonResponse>> GetGoldComparison(
            [FromQuery] int months = 12)
        {
            try
            {
                var startDate = DateTime.UtcNow.AddMonths(-months);
                
                // Get property price trends
                var propertyPrices = await _context.PropertyPriceHistories
                    .Where(ph => ph.PriceDate >= startDate)
                    .OrderBy(ph => ph.PriceDate)
                    .Select(ph => new { ph.PriceDate, ph.Price })
                    .ToListAsync();

                // Get gold price trends
                var goldPrices = await _context.GoldPrices
                    .Where(gp => gp.Date >= startDate)
                    .OrderBy(gp => gp.Date)
                    .Select(gp => new { gp.Date, gp.PricePerGram })
                    .ToListAsync();

                // Calculate returns
                var propertyReturn = 0.0;
                var goldReturn = 0.0;

                if (propertyPrices.Count >= 2)
                {
                    var firstPropertyPrice = propertyPrices.First().Price;
                    var lastPropertyPrice = propertyPrices.Last().Price;
                    propertyReturn = (double)((lastPropertyPrice - firstPropertyPrice) / firstPropertyPrice * 100);
                }

                if (goldPrices.Count >= 2)
                {
                    var firstGoldPrice = goldPrices.First().PricePerGram;
                    var lastGoldPrice = goldPrices.Last().PricePerGram;
                    goldReturn = (double)((lastGoldPrice - firstGoldPrice) / firstGoldPrice * 100);
                }

                return Ok(new GoldComparisonResponse
                {
                    PeriodMonths = months,
                    PropertyReturnPercentage = propertyReturn,
                    GoldReturnPercentage = goldReturn,
                    BetterInvestment = propertyReturn > goldReturn ? "Property" : "Gold",
                    ReturnDifference = Math.Abs(propertyReturn - goldReturn),
                    PropertyDataPoints = propertyPrices.Count,
                    GoldDataPoints = goldPrices.Count
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // GET: api/analytics/developer-rankings
        [HttpGet("developer-rankings")]
        public async Task<ActionResult<IEnumerable<DeveloperRankingResponse>>> GetDeveloperRankings()
        {
            try
            {
                var rankings = await _context.Accounts
                    .Where(a => a.Type == Models.AccountType.Developer)
                    .Select(developer => new DeveloperRankingResponse
                    {
                        DeveloperId = developer.AccountId,
                        DeveloperName = "Unknown Developer", // Will be updated to use company name
                        ProjectCount = _context.Projects.Count(p => p.DeveloperId == developer.AccountId),
                        TotalProperties = _context.ChildProperties.Count(p => p.Project.DeveloperId == developer.AccountId),
                        AveragePropertyPrice = _context.ChildProperties
                            .Where(p => p.Project.DeveloperId == developer.AccountId && p.Auctions.Any())
                            .Average(p => p.Auctions.First().CurrentPrice),
                        AverageRating = _context.DeveloperRatings
                            .Where(r => r.DeveloperId == developer.AccountId)
                            .Average(r => r.Rating)
                    })
                    .OrderByDescending(d => d.ProjectCount)
                    .ThenByDescending(d => d.AverageRating)
                    .Take(10)
                    .ToListAsync();

                return Ok(rankings);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // GET: api/analytics/best-investments
        [HttpGet("best-investments")]
        public async Task<ActionResult<IEnumerable<BestInvestmentResponse>>> GetBestInvestments(
            [FromQuery] int limit = 10)
        {
            try
            {
                var investments = await _context.ChildProperties
                    .Where(p => p.Auctions.Any())
                    .Include(p => p.ParentProperty)
                    .Include(p => p.Auctions)
                    .Select(property => new BestInvestmentResponse
                    {
                        PropertyId = property.PropertyId,
                        PropertyName = property.Name,
                        Location = property.Location,
                        PropertyType = property.PropertyType,
                        CurrentPrice = property.Auctions.First().CurrentPrice,
                        PricePerSqm = property.Auctions.First().CurrentPrice / property.SquareFeet,
                        ProjectName = property.ParentProperty.ProjectName,
                        Bedrooms = property.Bedrooms,
                        Bathrooms = property.Bathrooms,
                        SquareFeet = property.SquareFeet,
                        PriceHistoryCount = _context.PropertyPriceHistories.Count(ph => ph.ParentPropertyId == property.ParentPropertyId),
                        AveragePriceHistory = _context.PropertyPriceHistories
                            .Where(ph => ph.ParentPropertyId == property.ParentPropertyId)
                            .Average(ph => ph.Price),
                        PriceTrend = _context.PropertyPriceHistories
                            .Where(ph => ph.ParentPropertyId == property.ParentPropertyId)
                            .OrderBy(ph => ph.PriceDate)
                            .Select(ph => ph.Price)
                            .ToList()
                    })
                    .OrderByDescending(p => p.PriceHistoryCount)
                    .ThenByDescending(p => p.PriceTrend.Count > 1 ? 
                        (p.PriceTrend.Last() - p.PriceTrend.First()) / p.PriceTrend.First() * 100 : 0)
                    .Take(limit)
                    .ToListAsync();

                return Ok(investments);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // GET: api/analytics/portfolio/{userId}
        [HttpGet("portfolio/{userId}")]
        [Authorize]
        public async Task<ActionResult<PortfolioAnalyticsResponse>> GetPortfolioAnalytics(long userId)
        {
            try
            {
                var userProperties = await _context.ChildProperties
                    .Where(p => p.OwnerId == userId)
                    .Include(p => p.ParentProperty)
                    .Include(p => p.Auctions)
                    .ToListAsync();

                if (!userProperties.Any())
                {
                    return NotFound("No properties found for this user");
                }

                var totalInvested = userProperties.Sum(p => p.BuyingPrice ?? 0);
                var currentValues = new List<decimal>();
                var rois = new List<double>();

                foreach (var property in userProperties)
                {
                    // Get current market value from price history or auction
                    var currentValue = 0m;
                    
                    if (property.Auctions.Any())
                    {
                        currentValue = property.Auctions.First().CurrentPrice;
                    }
                    else
                    {
                        // Get latest price from price history
                        var latestPrice = await _context.PropertyPriceHistories
                            .Where(ph => ph.ParentPropertyId == property.ParentPropertyId)
                            .OrderByDescending(ph => ph.PriceDate)
                            .FirstOrDefaultAsync();
                        
                        if (latestPrice != null)
                        {
                            currentValue = latestPrice.Price;
                        }
                    }

                    currentValues.Add(currentValue);
                    
                    if (property.BuyingPrice.HasValue && property.BuyingPrice > 0)
                    {
                        var roi = (double)((currentValue - property.BuyingPrice.Value) / property.BuyingPrice.Value * 100);
                        rois.Add(roi);
                    }
                }

                var totalCurrentValue = currentValues.Sum();
                var totalROI = totalInvested > 0 ? (double)((totalCurrentValue - totalInvested) / totalInvested * 100) : 0;
                var averageROI = rois.Any() ? rois.Average() : 0;

                return Ok(new PortfolioAnalyticsResponse
                {
                    UserId = userId,
                    TotalProperties = userProperties.Count,
                    TotalInvested = totalInvested,
                    TotalCurrentValue = totalCurrentValue,
                    TotalProfitLoss = totalCurrentValue - totalInvested,
                    TotalROIPercentage = totalROI,
                    AverageROIPercentage = averageROI,
                    BestPerformingProperty = userProperties
                        .Where(p => p.BuyingPrice.HasValue)
                        .OrderByDescending(p => p.BuyingPrice > 0 ? 
                            (currentValues[userProperties.IndexOf(p)] - p.BuyingPrice.Value) / p.BuyingPrice.Value : 0)
                        .FirstOrDefault()?.Name ?? "N/A",
                    PropertyBreakdown = userProperties.Select(p => new PropertyPerformanceData
                    {
                        PropertyId = p.PropertyId,
                        PropertyName = p.Name,
                        Location = p.Location,
                        PropertyType = p.PropertyType,
                        InvestedAmount = p.BuyingPrice ?? 0,
                        CurrentValue = currentValues[userProperties.IndexOf(p)],
                        ROI = p.BuyingPrice.HasValue && p.BuyingPrice > 0 ? 
                            (double)((currentValues[userProperties.IndexOf(p)] - p.BuyingPrice.Value) / p.BuyingPrice.Value * 100) : 0
                    }).ToList()
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
    }

    // Response Models
    public class MarketOverviewResponse
    {
        public int TotalProperties { get; set; }
        public int ActiveAuctions { get; set; }
        public int TotalDevelopers { get; set; }
        public List<AreaPriceData> AreaPrices { get; set; } = new();
        public List<PropertyTypeDistribution> PropertyTypeDistribution { get; set; } = new();
        public List<PriceTrendData> RecentPriceTrends { get; set; } = new();
    }

    public class AreaPriceData
    {
        public string Area { get; set; } = string.Empty;
        public decimal AveragePrice { get; set; }
        public int PropertyCount { get; set; }
    }

    public class PropertyTypeDistribution
    {
        public string PropertyType { get; set; } = string.Empty;
        public int Count { get; set; }
        public double Percentage { get; set; }
    }

    public class PriceTrendData
    {
        public int Month { get; set; }
        public decimal AveragePrice { get; set; }
        public int TransactionCount { get; set; }
    }

    public class PriceTrendResponse
    {
        public DateTime Date { get; set; }
        public decimal Price { get; set; }
        public string Source { get; set; } = string.Empty;
        public int ParentPropertyId { get; set; }
        public string ProjectName { get; set; } = string.Empty;
        public string PropertyType { get; set; } = string.Empty;
    }

    public class GoldComparisonResponse
    {
        public int PeriodMonths { get; set; }
        public double PropertyReturnPercentage { get; set; }
        public double GoldReturnPercentage { get; set; }
        public string BetterInvestment { get; set; } = string.Empty;
        public double ReturnDifference { get; set; }
        public int PropertyDataPoints { get; set; }
        public int GoldDataPoints { get; set; }
    }

    public class DeveloperRankingResponse
    {
        public long DeveloperId { get; set; }
        public string DeveloperName { get; set; } = string.Empty;
        public int ProjectCount { get; set; }
        public int TotalProperties { get; set; }
        public decimal AveragePropertyPrice { get; set; }
        public double AverageRating { get; set; }
    }

    public class BestInvestmentResponse
    {
        public int PropertyId { get; set; }
        public string PropertyName { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public string PropertyType { get; set; } = string.Empty;
        public decimal CurrentPrice { get; set; }
        public decimal PricePerSqm { get; set; }
        public string ProjectName { get; set; } = string.Empty;
        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public int SquareFeet { get; set; }
        public int PriceHistoryCount { get; set; }
        public decimal AveragePriceHistory { get; set; }
        public List<decimal> PriceTrend { get; set; } = new();
    }

    public class PortfolioAnalyticsResponse
    {
        public long UserId { get; set; }
        public int TotalProperties { get; set; }
        public decimal TotalInvested { get; set; }
        public decimal TotalCurrentValue { get; set; }
        public decimal TotalProfitLoss { get; set; }
        public double TotalROIPercentage { get; set; }
        public double AverageROIPercentage { get; set; }
        public string BestPerformingProperty { get; set; } = string.Empty;
        public List<PropertyPerformanceData> PropertyBreakdown { get; set; } = new();
    }

    public class PropertyPerformanceData
    {
        public int PropertyId { get; set; }
        public string PropertyName { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public string PropertyType { get; set; } = string.Empty;
        public decimal InvestedAmount { get; set; }
        public decimal CurrentValue { get; set; }
        public double ROI { get; set; }
    }
}