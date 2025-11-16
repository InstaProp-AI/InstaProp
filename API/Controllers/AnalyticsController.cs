using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Caching.Memory;

namespace InstapropAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AnalyticsController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IMemoryCache _cache;
        private static readonly TimeSpan DefaultCacheDuration = TimeSpan.FromMinutes(10);
        private static readonly TimeSpan ShortCacheDuration = TimeSpan.FromMinutes(3);
        private static readonly TimeSpan LongCacheDuration = TimeSpan.FromMinutes(30);

        public AnalyticsController(AppDbContext context, IMemoryCache cache)
        {
            _context = context;
            _cache = cache;
        }

        private static class CacheKeys
        {
            public const string MarketOverview = "analytics:market-overview";
            public const string DeveloperRankings = "analytics:developer-rankings";
            public static string BestInvestments(int limit) => $"analytics:best-investments:{limit}";
            public static string GoldComparison(int months) => $"analytics:gold-comparison:{months}";
            public static string PriceTrends(int? parentPropertyId, string? propertyType, string? location, int months) =>
                $"analytics:price-trends:{parentPropertyId?.ToString() ?? "any"}:{propertyType ?? "any"}:{location ?? "any"}:{months}";
        }

        private Task<T> GetOrCreateAsync<T>(string cacheKey, Func<Task<T>> factory, TimeSpan? duration = null)
        {
            return _cache.GetOrCreateAsync(cacheKey, async entry =>
            {
                entry.AbsoluteExpirationRelativeToNow = duration ?? DefaultCacheDuration;
                entry.SlidingExpiration = duration ?? DefaultCacheDuration;
                entry.Priority = CacheItemPriority.High;
                return await factory();
            });
        }

        // GET: api/analytics/market-overview
        [HttpGet("market-overview")]
        public async Task<ActionResult<MarketOverviewResponse>> GetMarketOverview()
        {
            try
            {
                var overview = await GetOrCreateAsync(
                    CacheKeys.MarketOverview,
                    BuildMarketOverviewAsync,
                    ShortCacheDuration);

                return Ok(overview);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        private async Task<MarketOverviewResponse> BuildMarketOverviewAsync()
        {
            var totalProperties = await _context.ChildProperties.CountAsync();
            var activeAuctions = await _context.Auctions.CountAsync(a => a.Status == "Active");
            var totalDevelopers = await _context.Accounts.CountAsync(a => a.Type == Models.AccountType.Developer);

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

            var safeTotalProperties = Math.Max(totalProperties, 1);

            var typeDistribution = await _context.ChildProperties
                .Where(p => p.Auctions.Any())
                .GroupBy(p => PropertyTypeHelper.ToDisplayName(p.Type))
                .Select(g => new PropertyTypeDistribution
                {
                    PropertyType = g.Key,
                    Count = g.Count(),
                    Percentage = safeTotalProperties > 0
                        ? Math.Round((double)g.Count() / safeTotalProperties * 100, 2)
                        : 0
                })
                .OrderByDescending(t => t.Count)
                .ToListAsync();

            var sixMonthsAgo = DateTime.UtcNow.AddMonths(-6);
            var recentPriceHistory = await _context.PropertyPriceHistories
                .Where(ph => ph.PriceDate >= sixMonthsAgo)
                .GroupBy(ph => ph.PriceDate.Month)
                .Select(g => new PriceTrendData
                {
                    Month = g.Key,
                    AveragePrice = Math.Round(g.Average(ph => ph.Price), 2),
                    TransactionCount = g.Count()
                })
                .OrderBy(p => p.Month)
                .ToListAsync();

            var overview = new MarketOverviewResponse
            {
                TotalProperties = totalProperties,
                ActiveAuctions = activeAuctions,
                TotalDevelopers = totalDevelopers,
                AreaPrices = areaPrices,
                PropertyTypeDistribution = typeDistribution,
                RecentPriceTrends = recentPriceHistory,
                GeneratedAtUtc = DateTime.UtcNow
            };

            overview.HasData = totalProperties > 0 &&
                (areaPrices.Any() || typeDistribution.Any() || recentPriceHistory.Any());

            if (!overview.HasData)
            {
                overview.Message =
                    "We need a few live transactions before we can build the market overview. Check back soon!";
            }

            return overview;
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
                var cacheKey = CacheKeys.PriceTrends(parentPropertyId, propertyType, location, months);
                var priceHistory = await GetOrCreateAsync(
                    cacheKey,
                    () => BuildPriceTrendsAsync(parentPropertyId, propertyType, location, months),
                    ShortCacheDuration);

                return Ok(priceHistory);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        private async Task<List<PriceTrendResponse>> BuildPriceTrendsAsync(
            int? parentPropertyId,
            string? propertyType,
            string? location,
            int months)
        {
            var startDate = DateTime.UtcNow.AddMonths(-months);
            var query = _context.PropertyPriceHistories
                .Where(ph => ph.PriceDate >= startDate);

            if (parentPropertyId.HasValue)
            {
                query = query.Where(ph => ph.ParentPropertyId == parentPropertyId.Value);
            }

            if (!string.IsNullOrWhiteSpace(propertyType))
            {
                query = query.Where(ph =>
                    ph.ParentProperty != null &&
                    ph.ParentProperty.Type != null &&
                    ph.ParentProperty.Type.Equals(propertyType, StringComparison.OrdinalIgnoreCase));
            }

            if (!string.IsNullOrWhiteSpace(location))
            {
                query = query.Where(ph =>
                    ph.ParentProperty != null &&
                    ph.ParentProperty.ProjectName != null &&
                    ph.ParentProperty.ProjectName.Contains(location));
            }

            var priceHistory = await query
                .OrderBy(ph => ph.PriceDate)
                .Select(ph => new PriceTrendResponse
                {
                    Date = ph.PriceDate,
                    Price = ph.Price,
                    Source = ph.Source,
                    ParentPropertyId = ph.ParentPropertyId,
                    ProjectName = ph.ParentProperty != null
                        ? (string.IsNullOrWhiteSpace(ph.ParentProperty.ProjectName) ? "N/A" : ph.ParentProperty.ProjectName)
                        : "N/A",
                    PropertyType = ph.ParentProperty != null
                        ? (string.IsNullOrWhiteSpace(ph.ParentProperty.Type) ? PropertyTypeHelper.ToDisplayName(PropertyType.Other) : ph.ParentProperty.Type)
                        : PropertyTypeHelper.ToDisplayName(PropertyType.Other)
                })
                .ToListAsync();

            return priceHistory;
        }

        // GET: api/analytics/dashboard
        [HttpGet("dashboard")]
        [AllowAnonymous]
        public async Task<ActionResult<MarketDashboardResponse>> GetMarketDashboard([FromQuery] int months = 12)
        {
            try
            {
                var hero = await CalculateHeroMetricsAsync();
                var pulse = await CalculateMarketPulseAsync();
                var priceMomentum = await CalculatePriceMomentumAsync(months);
                var developers = await LoadDeveloperRankingsAsync(limit: 5);
                var opportunities = await LoadBestInvestmentsAsync(limit: 6);
                var goldComparison = await CalculateGoldComparisonAsync(months);

                var response = new MarketDashboardResponse
                {
                    Hero = hero,
                    Pulse = pulse,
                    PriceMomentum = priceMomentum,
                    DeveloperLeaderboard = developers,
                    Opportunities = opportunities,
                    GoldComparison = goldComparison
                };

                return Ok(response);
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
                var comparison = await GetOrCreateAsync(
                    CacheKeys.GoldComparison(months),
                    () => CalculateGoldComparisonAsync(months),
                    LongCacheDuration);

                return Ok(comparison);
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
                var rankings = await GetOrCreateAsync(
                    CacheKeys.DeveloperRankings,
                    () => LoadDeveloperRankingsAsync(),
                    LongCacheDuration);
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
                var investments = await GetOrCreateAsync(
                    CacheKeys.BestInvestments(limit),
                    () => LoadBestInvestmentsAsync(limit),
                    TimeSpan.FromMinutes(15));
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
                        PropertyType = PropertyTypeHelper.ToDisplayName(p.Type),
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
        private async Task<HeroMetrics> CalculateHeroMetricsAsync()
        {
            var marketRoi = await CalculateMarketRoiAsync();
            var capRate = await CalculateCapRateAsync();
            var dataPoints = await _context.PropertyPriceHistories
                .CountAsync(ph => ph.PriceDate >= DateTime.UtcNow.AddDays(-30));

            return new HeroMetrics
            {
                MarketRoi30Days = Math.Round(marketRoi, 2),
                AverageCapRate = Math.Round(capRate, 2),
                DataPoints = dataPoints
            };
        }

        private async Task<MarketPulseMetrics> CalculateMarketPulseAsync()
        {
            var cutoff = DateTime.UtcNow.AddDays(-30);
            var auctions = await _context.Auctions
                .Where(a => a.StartAt >= cutoff)
                .Select(a => new { a.CurrentPrice, a.Duration })
                .ToListAsync();

            decimal avgSalePrice = 0;
            var pricedAuctions = auctions.Where(a => a.CurrentPrice > 0).ToList();
            if (pricedAuctions.Any())
            {
                avgSalePrice = pricedAuctions.Average(a => a.CurrentPrice);
            }

            var transactionVolume = auctions.Count;
            var liquidityDays = auctions.Any()
                ? auctions.Average(a => a.Duration / 24.0)
                : 0;

            var roi30 = await CalculateMarketRoiAsync();

            return new MarketPulseMetrics
            {
                AverageSalePrice = Math.Round(avgSalePrice, 2),
                TransactionVolume = transactionVolume,
                LiquidityDays = Math.Round(liquidityDays, 2),
                Sentiment = DetermineSentiment(roi30)
            };
        }

        private async Task<List<MonthlyPricePoint>> CalculatePriceMomentumAsync(int months)
        {
            var cutoff = DateTime.UtcNow.AddMonths(-months);

            var monthly = await _context.PropertyPriceHistories
                .Where(ph => ph.PriceDate >= cutoff)
                .GroupBy(ph => new { ph.PriceDate.Year, ph.PriceDate.Month })
                .Select(g => new MonthlyPricePoint
                {
                    Month = new DateTime(g.Key.Year, g.Key.Month, 1),
                    AveragePrice = g.Average(ph => ph.Price),
                    TransactionCount = g.Count()
                })
                .OrderBy(point => point.Month)
                .ToListAsync();

            return monthly;
        }

        private async Task<double> CalculateMarketRoiAsync(int days = 30)
        {
            var cutoff = DateTime.UtcNow.AddDays(-days);
            var prices = await _context.PropertyPriceHistories
                .Where(ph => ph.PriceDate >= cutoff)
                .OrderBy(ph => ph.PriceDate)
                .Select(ph => ph.Price)
                .ToListAsync();

            if (prices.Count < 2)
            {
                return 0;
            }

            var first = prices.First();
            var last = prices.Last();
            if (first <= 0)
            {
                return 0;
            }

            return (double)((last - first) / first * 100);
        }

        private async Task<double> CalculateCapRateAsync(int months = 12)
        {
            var cutoff = DateTime.UtcNow.AddMonths(-months);

            var grouped = await _context.PropertyPriceHistories
                .Where(ph => ph.PriceDate >= cutoff && ph.ParentPropertyId != null)
                .GroupBy(ph => ph.ParentPropertyId)
                .Select(g => new
                {
                    FirstPrice = g.OrderBy(ph => ph.PriceDate).Select(ph => ph.Price).FirstOrDefault(),
                    LastPrice = g.OrderByDescending(ph => ph.PriceDate).Select(ph => ph.Price).FirstOrDefault()
                })
                .ToListAsync();

            var rois = grouped
                .Where(g => g.FirstPrice > 0 && g.LastPrice > 0)
                .Select(g => (double)((g.LastPrice - g.FirstPrice) / g.FirstPrice * 100))
                .ToList();

            if (!rois.Any())
            {
                return 0;
            }

            return rois.Average();
        }

        private async Task<List<DeveloperRankingResponse>> LoadDeveloperRankingsAsync(int limit = 10)
        {
            var developerStats = await _context.Accounts
                .Where(a => a.Type == Models.AccountType.Developer)
                .Select(a => new
                {
                    a.AccountId,
                    a.FirstName,
                    a.LastName,
                    Profile = _context.DeveloperProfiles.FirstOrDefault(dp => dp.AccountId == a.AccountId),
                    ProjectCount = a.Projects.Count(),
                    TotalProperties = _context.ChildProperties.Count(p =>
                        p.Project != null && p.Project.DeveloperId == a.AccountId),
                    AveragePropertyPrice = _context.Auctions
                        .Where(ac => ac.Property.Project != null && ac.Property.Project.DeveloperId == a.AccountId)
                        .Select(ac => (decimal?)ac.CurrentPrice)
                        .DefaultIfEmpty(0)
                        .Average() ?? 0,
                    AverageRating = _context.DeveloperRatings
                        .Where(r => r.DeveloperId == a.AccountId)
                        .Select(r => (double?)r.Rating)
                        .DefaultIfEmpty(0)
                        .Average() ?? 0
                })
                .ToListAsync();

            var rankings = developerStats
                .Select(stat =>
                {
                    var companyName = stat.Profile?.CompanyName?.Trim();
                    var fullName = $"{stat.FirstName} {stat.LastName}".Trim();
                    var displayName = !string.IsNullOrWhiteSpace(companyName)
                        ? companyName!
                        : !string.IsNullOrWhiteSpace(fullName)
                            ? fullName
                            : $"Developer #{stat.AccountId}";

                    return new DeveloperRankingResponse
                    {
                        DeveloperId = stat.AccountId,
                        DeveloperName = displayName,
                        ProjectCount = stat.ProjectCount,
                        TotalProperties = stat.TotalProperties,
                        AveragePropertyPrice = stat.AveragePropertyPrice,
                        AverageRating = stat.AverageRating
                    };
                })
                .OrderByDescending(d => d.ProjectCount)
                .ThenByDescending(d => d.AverageRating)
                .ThenBy(d => d.DeveloperName)
                .Take(limit)
                .ToList();

            return rankings;
        }

        private async Task<List<BestInvestmentResponse>> LoadBestInvestmentsAsync(int limit = 10)
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
                    PropertyType = PropertyTypeHelper.ToDisplayName(property.Type),
                    CurrentPrice = property.Auctions.First().CurrentPrice,
                    PricePerSqm = property.SquareFeet > 0
                        ? property.Auctions.First().CurrentPrice / property.SquareFeet
                        : 0,
                    ProjectName = property.ParentProperty != null
                        ? (string.IsNullOrWhiteSpace(property.ParentProperty.ProjectName)
                            ? "N/A"
                            : property.ParentProperty.ProjectName)
                        : "N/A",
                    Bedrooms = property.Bedrooms,
                    Bathrooms = property.Bathrooms,
                    SquareFeet = property.SquareFeet,
                    PriceHistoryCount = property.ParentPropertyId != null
                        ? _context.PropertyPriceHistories.Count(ph => ph.ParentPropertyId == property.ParentPropertyId)
                        : 0,
                    AveragePriceHistory = property.ParentPropertyId != null
                        ? _context.PropertyPriceHistories
                            .Where(ph => ph.ParentPropertyId == property.ParentPropertyId)
                            .Select(ph => (decimal?)ph.Price)
                            .DefaultIfEmpty()
                            .Average() ?? 0
                        : 0,
                    PriceTrend = property.ParentPropertyId != null
                        ? _context.PropertyPriceHistories
                            .Where(ph => ph.ParentPropertyId == property.ParentPropertyId)
                            .OrderBy(ph => ph.PriceDate)
                            .Select(ph => ph.Price)
                            .ToList()
                        : new List<decimal>()
                })
                .OrderByDescending(p => p.PriceHistoryCount)
                .ThenByDescending(p =>
                    p.PriceTrend.Count > 1 && p.PriceTrend.First() > 0
                        ? (p.PriceTrend.Last() - p.PriceTrend.First()) / p.PriceTrend.First() * 100
                        : 0)
                .Take(limit)
                .ToListAsync();

            return investments;
        }

        private async Task<GoldComparisonResponse> CalculateGoldComparisonAsync(int months)
        {
            var startDate = DateTime.UtcNow.AddMonths(-months);

            var propertyPrices = await _context.PropertyPriceHistories
                .Where(ph => ph.PriceDate >= startDate)
                .OrderBy(ph => ph.PriceDate)
                .Select(ph => ph.Price)
                .ToListAsync();

            var goldPrices = await _context.GoldPrices
                .Where(gp => gp.Date >= startDate)
                .OrderBy(gp => gp.Date)
                .Select(gp => gp.PricePerGram)
                .ToListAsync();

            var propertyReturn = 0.0;
            var goldReturn = 0.0;

            if (propertyPrices.Count >= 2 && propertyPrices.First() > 0)
            {
                propertyReturn = (double)((propertyPrices.Last() - propertyPrices.First()) / propertyPrices.First() * 100);
            }

            if (goldPrices.Count >= 2 && goldPrices.First() > 0)
            {
                goldReturn = (double)((goldPrices.Last() - goldPrices.First()) / goldPrices.First() * 100);
            }

            var notices = new List<string>();
            if (propertyPrices.Count < 2)
            {
                notices.Add("We need at least two tracked property prices to calculate real estate ROI.");
            }
            if (goldPrices.Count < 2)
            {
                notices.Add("We need more gold price snapshots to compare performance.");
            }

            string betterInvestment;
            if (propertyPrices.Count < 2 && goldPrices.Count < 2)
            {
                betterInvestment = "Tied";
            }
            else if (Math.Abs(propertyReturn - goldReturn) < 0.01)
            {
                betterInvestment = "Tied";
            }
            else
            {
                betterInvestment = propertyReturn > goldReturn ? "Property" : "Gold";
            }

            return new GoldComparisonResponse
            {
                PeriodMonths = months,
                PropertyReturnPercentage = Math.Round(propertyReturn, 2),
                GoldReturnPercentage = Math.Round(goldReturn, 2),
                BetterInvestment = betterInvestment,
                ReturnDifference = Math.Round(Math.Abs(propertyReturn - goldReturn), 2),
                PropertyDataPoints = propertyPrices.Count,
                GoldDataPoints = goldPrices.Count,
                Message = notices.Count > 0 ? string.Join(" ", notices) : null,
                GeneratedAtUtc = DateTime.UtcNow
            };
        }

        private string DetermineSentiment(double roiValue)
        {
            if (roiValue >= 12) return "Bullish";
            if (roiValue >= 2) return "Positive";
            if (roiValue <= -8) return "Bearish";
            if (roiValue < 0) return "Cooling";
            return "Neutral";
        }

    }

    public class MarketDashboardResponse
    {
        public HeroMetrics Hero { get; set; } = new();
        public MarketPulseMetrics Pulse { get; set; } = new();
        public List<MonthlyPricePoint> PriceMomentum { get; set; } = new();
        public List<DeveloperRankingResponse> DeveloperLeaderboard { get; set; } = new();
        public List<BestInvestmentResponse> Opportunities { get; set; } = new();
        public GoldComparisonResponse? GoldComparison { get; set; }
    }

    public class HeroMetrics
    {
        public double MarketRoi30Days { get; set; }
        public double AverageCapRate { get; set; }
        public int DataPoints { get; set; }
    }

    public class MarketPulseMetrics
    {
        public decimal AverageSalePrice { get; set; }
        public int TransactionVolume { get; set; }
        public double LiquidityDays { get; set; }
        public string Sentiment { get; set; } = string.Empty;
    }

    public class MonthlyPricePoint
    {
        public DateTime Month { get; set; }
        public decimal AveragePrice { get; set; }
        public int TransactionCount { get; set; }
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
        public bool HasData { get; set; }
        public string? Message { get; set; }
        public DateTime GeneratedAtUtc { get; set; }
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
        public string? Message { get; set; }
        public DateTime GeneratedAtUtc { get; set; }
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