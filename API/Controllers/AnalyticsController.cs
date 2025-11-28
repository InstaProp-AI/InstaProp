using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Caching.Memory;
using InstapropAPI.Attributes;

namespace InstapropAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
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
            public static string PriceTrends(Guid? parentPropertyId, string? propertyType, string? location, int months) =>
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
        [AllowAnonymous]
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
            try
            {
                var totalProperties = await _context.ChildProperties.CountAsync();
                var activeAuctions = await _context.Auctions.CountAsync(a => a.Status == "Active");
                var totalDevelopers = await _context.Accounts.CountAsync(a => a.RoleId == Role.DEVELOPER_ROLE_ID);

                var areaPrices = await _context.ChildProperties
                    .Where(p => p.Auctions.Any() && !string.IsNullOrWhiteSpace(p.Location))
                    .GroupBy(p => p.Location!)
                    .Select(g => new AreaPriceData
                    {
                        Area = g.Key ?? "Unknown",
                        AveragePrice = g.Where(p => p.Auctions.Any()).Average(p => (decimal?)p.Auctions.First().CurrentPrice) ?? 0,
                        PropertyCount = g.Count()
                    })
                    .Where(a => a.AveragePrice > 0)
                    .OrderByDescending(a => a.AveragePrice)
                    .Take(10)
                    .ToListAsync();

                var safeTotalProperties = Math.Max(totalProperties, 1);

                var typeDistribution = await _context.ChildProperties
                    .Where(p => p.Auctions.Any())
                    .GroupBy(p => PropertyTypeHelper.ToDisplayName(p.Type))
                    .Select(g => new PropertyTypeDistribution
                    {
                        PropertyType = g.Key ?? "Other",
                        Count = g.Count(),
                        Percentage = safeTotalProperties > 0
                            ? Math.Round((double)g.Count() / safeTotalProperties * 100, 2)
                            : 0
                    })
                    .OrderByDescending(t => t.Count)
                    .ToListAsync();

                var sixMonthsAgo = DateTime.UtcNow.AddMonths(-6);
                var recentPriceHistory = await _context.PropertyPriceHistories
                    .Where(ph => ph.PriceDate >= sixMonthsAgo && ph.Price > 0)
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
            catch (Exception ex)
            {
                Console.WriteLine($"Error building market overview: {ex.Message}");
                // Return empty overview instead of throwing
                return new MarketOverviewResponse
                {
                    TotalProperties = 0,
                    ActiveAuctions = 0,
                    TotalDevelopers = 0,
                    AreaPrices = new List<AreaPriceData>(),
                    PropertyTypeDistribution = new List<PropertyTypeDistribution>(),
                    RecentPriceTrends = new List<PriceTrendData>(),
                    GeneratedAtUtc = DateTime.UtcNow,
                    HasData = false,
                    Message = "Unable to load market overview at this time."
                };
            }
        }

        // GET: api/analytics/price-trends
        [HttpGet("price-trends")]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<PriceTrendResponse>>> GetPriceTrends(
            [FromQuery] Guid? parentPropertyId,
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
            Guid? parentPropertyId,
            string? propertyType,
            string? location,
            int months)
        {
            try
            {
                var startDate = DateTime.UtcNow.AddMonths(-months);
                var query = _context.PropertyPriceHistories
                    .Include(ph => ph.ParentProperty)
                    .Where(ph => ph.PriceDate >= startDate);

                if (parentPropertyId.HasValue)
                {
                    query = query.Where(ph => ph.ParentPropertyId == parentPropertyId);
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
                        Source = ph.Source ?? "Unknown",
                        ParentPropertyId = ph.ParentPropertyId.ToString(),
                        ProjectName = ph.ParentProperty != null && !string.IsNullOrWhiteSpace(ph.ParentProperty.ProjectName)
                            ? ph.ParentProperty.ProjectName
                            : "N/A",
                        PropertyType = ph.ParentProperty != null && !string.IsNullOrWhiteSpace(ph.ParentProperty.Type)
                            ? ph.ParentProperty.Type
                            : PropertyTypeHelper.ToDisplayName(PropertyType.Other)
                    })
                    .ToListAsync();

                return priceHistory;
            }
            catch (Exception ex)
            {
                // Log error and return empty list instead of throwing
                Console.WriteLine($"Error building price trends: {ex.Message}");
                return new List<PriceTrendResponse>();
            }
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
        [AllowAnonymous]
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
        [AllowAnonymous]
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
                Console.WriteLine($"Error in GetDeveloperRankings: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"Inner exception: {ex.InnerException.Message}");
                }
                return StatusCode(500, new { error = $"Internal server error: {ex.Message}", details = ex.StackTrace });
            }
        }

        // GET: api/analytics/best-investments
        [HttpGet("best-investments")]
        [AllowAnonymous]
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
        public async Task<ActionResult<PortfolioAnalyticsResponse>> GetPortfolioAnalytics(Guid userId)
        {
            try
            {
                // Get current user ID from claims
                var accountIdClaim = User.FindFirst("uid");
                if (accountIdClaim == null || !Guid.TryParse(accountIdClaim.Value, out var currentUserId))
                {
                    return Unauthorized("User not authenticated");
                }

                // Get user role to check if admin
                var roleIdClaim = User.FindFirst("roleId");
                var isAdmin = roleIdClaim != null && Guid.TryParse(roleIdClaim.Value, out var roleId) && roleId == Role.ADMIN_ROLE_ID;

                // Users can only access their own portfolio, unless they're admin
                if (!isAdmin && currentUserId != userId)
                {
                    return Forbid("You can only access your own portfolio analytics");
                }

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
                    UserId = userId.ToString(),
                    TotalProperties = userProperties.Count(),
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
                        PropertyId = p.PropertyId.ToString(),
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
            try
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
            catch (Exception ex)
            {
                Console.WriteLine($"Error calculating hero metrics: {ex.Message}");
                return new HeroMetrics
                {
                    MarketRoi30Days = 0,
                    AverageCapRate = 0,
                    DataPoints = 0
                };
            }
        }

        private async Task<MarketPulseMetrics> CalculateMarketPulseAsync()
        {
            try
            {
                var cutoff = DateTime.UtcNow.AddDays(-30);
                var auctions = await _context.Auctions
                    .Where(a => a.StartAt >= cutoff && a.StartAt != null)
                    .Select(a => new { a.CurrentPrice, a.Duration })
                    .ToListAsync();

                decimal avgSalePrice = 0;
                var pricedAuctions = auctions.Where(a => a.CurrentPrice > 0).ToList();
                if (pricedAuctions.Any())
                {
                    avgSalePrice = pricedAuctions.Average(a => a.CurrentPrice);
                }

                var transactionVolume = auctions.Count;
                var liquidityDays = auctions.Any() && auctions.All(a => a.Duration > 0)
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
            catch (Exception ex)
            {
                Console.WriteLine($"Error calculating market pulse: {ex.Message}");
                return new MarketPulseMetrics
                {
                    AverageSalePrice = 0,
                    TransactionVolume = 0,
                    LiquidityDays = 0,
                    Sentiment = "Neutral"
                };
            }
        }

        private async Task<List<MonthlyPricePoint>> CalculatePriceMomentumAsync(int months)
        {
            try
            {
                var cutoff = DateTime.UtcNow.AddMonths(-months);

                var monthly = await _context.PropertyPriceHistories
                    .Where(ph => ph.PriceDate >= cutoff && ph.Price > 0)
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
            catch (Exception ex)
            {
                Console.WriteLine($"Error calculating price momentum: {ex.Message}");
                return new List<MonthlyPricePoint>();
            }
        }

        private async Task<double> CalculateMarketRoiAsync(int days = 30)
        {
            try
            {
                var cutoff = DateTime.UtcNow.AddDays(-days);
                var prices = await _context.PropertyPriceHistories
                    .Where(ph => ph.PriceDate >= cutoff && ph.Price > 0)
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
            catch (Exception ex)
            {
                Console.WriteLine($"Error calculating market ROI: {ex.Message}");
                return 0;
            }
        }

        private async Task<double> CalculateCapRateAsync(int months = 12)
        {
            try
            {
                var cutoff = DateTime.UtcNow.AddMonths(-months);

                var grouped = await _context.PropertyPriceHistories
                    .Where(ph => ph.PriceDate >= cutoff && ph.ParentPropertyId != null && ph.Price > 0)
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
            catch (Exception ex)
            {
                Console.WriteLine($"Error calculating cap rate: {ex.Message}");
                return 0;
            }
        }

        private async Task<List<DeveloperRankingResponse>> LoadDeveloperRankingsAsync(int limit = 10)
        {
            try
            {
                // Load developers with their profiles separately to avoid LINQ translation issues
                var developers = await _context.Accounts
                    .Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID)
                    .Include(a => a.Projects)
                    .ToListAsync();

            var developerIds = developers.Select(d => d.AccountId).ToList();

            // Load profiles separately
            var profiles = await _context.DeveloperProfiles
                .Where(p => developerIds.Contains(p.AccountId))
                .ToDictionaryAsync(p => p.AccountId);

            // Load ratings separately
            var ratings = await _context.DeveloperRatings
                .Where(r => developerIds.Contains(r.DeveloperId))
                .GroupBy(r => r.DeveloperId)
                .Select(g => new
                {
                    DeveloperId = g.Key,
                    AverageRating = g.Average(r => (double)r.Rating)
                })
                .ToDictionaryAsync(r => r.DeveloperId);

            // Load property counts separately
            var propertyCounts = await _context.ChildProperties
                .Where(p => p.Project != null && developerIds.Contains(p.Project.DeveloperId))
                .GroupBy(p => p.Project!.DeveloperId)
                .Select(g => new
                {
                    DeveloperId = g.Key,
                    Count = g.Count()
                })
                .ToDictionaryAsync(p => p.DeveloperId);

            // Load average property prices separately
            var averagePrices = await _context.Auctions
                .Include(ac => ac.Property)
                    .ThenInclude(p => p.Project)
                .Where(ac => ac.Property != null && ac.Property.Project != null && developerIds.Contains(ac.Property.Project.DeveloperId))
                .GroupBy(ac => ac.Property.Project!.DeveloperId)
                .Select(g => new
                {
                    DeveloperId = g.Key,
                    AveragePrice = g.Average(ac => (decimal?)ac.CurrentPrice) ?? 0
                })
                .ToDictionaryAsync(ap => ap.DeveloperId);

            var rankings = developers
                .Select(d =>
                {
                    var profile = profiles.GetValueOrDefault(d.AccountId);
                    var rating = ratings.GetValueOrDefault(d.AccountId);
                    var propertyCount = propertyCounts.GetValueOrDefault(d.AccountId);
                    var avgPrice = averagePrices.GetValueOrDefault(d.AccountId);

                    var companyName = profile?.CompanyName?.Trim();
                    var fullName = $"{d.FirstName} {d.LastName}".Trim();
                    var displayName = !string.IsNullOrWhiteSpace(companyName)
                        ? companyName!
                        : !string.IsNullOrWhiteSpace(fullName)
                            ? fullName
                            : $"Developer #{d.AccountId}";

                    return new DeveloperRankingResponse
                    {
                        DeveloperId = d.AccountId.ToString(),
                        DeveloperName = displayName,
                        ProjectCount = d.Projects.Count,
                        TotalProperties = propertyCount?.Count ?? 0,
                        AveragePropertyPrice = avgPrice?.AveragePrice ?? 0,
                        AverageRating = rating?.AverageRating ?? 0
                    };
                })
                .OrderByDescending(d => d.ProjectCount)
                .ThenByDescending(d => d.AverageRating)
                .ThenBy(d => d.DeveloperName)
                .Take(limit)
                .ToList();

                return rankings;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading developer rankings: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                // Return empty list instead of throwing
                return new List<DeveloperRankingResponse>();
            }
        }

        private async Task<List<BestInvestmentResponse>> LoadBestInvestmentsAsync(int limit = 10)
        {
            try
            {
                // Load properties with auctions first
                var properties = await _context.ChildProperties
                    .Where(p => p.Auctions.Any() && p.Auctions.First().CurrentPrice > 0)
                    .Include(p => p.ParentProperty)
                    .Include(p => p.Auctions)
                    .ToListAsync();

                var parentPropertyIds = properties
                    .Where(p => p.ParentPropertyId.HasValue)
                    .Select(p => p.ParentPropertyId!.Value)
                    .Distinct()
                    .ToList();

                // Load price histories separately
                var priceHistories = await _context.PropertyPriceHistories
                    .Where(ph => parentPropertyIds.Contains(ph.ParentPropertyId))
                    .GroupBy(ph => ph.ParentPropertyId)
                    .ToDictionaryAsync(
                        g => g.Key,
                        g => new
                        {
                            Count = g.Count(),
                            Average = g.Average(ph => ph.Price),
                            Prices = g.OrderBy(ph => ph.PriceDate).Select(ph => ph.Price).ToList()
                        }
                    );

                var investments = properties
                    .Select(property =>
                    {
                        var auction = property.Auctions.First();
                        var priceHistory = property.ParentPropertyId.HasValue && priceHistories.ContainsKey(property.ParentPropertyId.Value)
                            ? priceHistories[property.ParentPropertyId.Value]
                            : null;

                        return new BestInvestmentResponse
                        {
                            PropertyId = property.PropertyId.ToString(),
                            PropertyName = !string.IsNullOrWhiteSpace(property.Name) ? property.Name : "Unnamed Property",
                            Location = !string.IsNullOrWhiteSpace(property.Location) ? property.Location : "Unknown",
                            PropertyType = PropertyTypeHelper.ToDisplayName(property.Type),
                            CurrentPrice = auction.CurrentPrice,
                            PricePerSqm = property.SquareFeet > 0
                                ? auction.CurrentPrice / property.SquareFeet
                                : 0,
                            ProjectName = property.ParentProperty != null && !string.IsNullOrWhiteSpace(property.ParentProperty.ProjectName)
                                ? property.ParentProperty.ProjectName
                                : "N/A",
                            Bedrooms = property.Bedrooms,
                            Bathrooms = property.Bathrooms,
                            SquareFeet = property.SquareFeet,
                            PriceHistoryCount = priceHistory?.Count ?? 0,
                            AveragePriceHistory = priceHistory?.Average ?? 0,
                            PriceTrend = priceHistory?.Prices ?? new List<decimal>()
                        };
                    })
                    .OrderByDescending(p => p.PriceHistoryCount)
                    .ThenByDescending(p =>
                        p.PriceTrend.Count > 1 && p.PriceTrend.First() > 0
                            ? (p.PriceTrend.Last() - p.PriceTrend.First()) / p.PriceTrend.First() * 100
                            : 0)
                    .Take(limit)
                    .ToList();

                return investments;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading best investments: {ex.Message}");
                return new List<BestInvestmentResponse>();
            }
        }

        private async Task<GoldComparisonResponse> CalculateGoldComparisonAsync(int months)
        {
            try
            {
                var startDate = DateTime.UtcNow.AddMonths(-months);

                var propertyPrices = await _context.PropertyPriceHistories
                    .Where(ph => ph.PriceDate >= startDate && ph.Price > 0)
                    .OrderBy(ph => ph.PriceDate)
                    .Select(ph => ph.Price)
                    .ToListAsync();

                var goldPrices = await _context.GoldPrices
                    .Where(gp => gp.Date >= startDate && gp.PricePerGram > 0)
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
            catch (Exception ex)
            {
                Console.WriteLine($"Error calculating gold comparison: {ex.Message}");
                return new GoldComparisonResponse
                {
                    PeriodMonths = months,
                    PropertyReturnPercentage = 0,
                    GoldReturnPercentage = 0,
                    BetterInvestment = "Neutral",
                    ReturnDifference = 0,
                    PropertyDataPoints = 0,
                    GoldDataPoints = 0,
                    Message = "Error calculating comparison",
                    GeneratedAtUtc = DateTime.UtcNow
                };
            }
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
        public string ParentPropertyId { get; set; } = string.Empty;
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
        public string DeveloperId { get; set; } = string.Empty;
        public string DeveloperName { get; set; } = string.Empty;
        public int ProjectCount { get; set; }
        public int TotalProperties { get; set; }
        public decimal AveragePropertyPrice { get; set; }
        public double AverageRating { get; set; }
    }

    public class BestInvestmentResponse
    {
        public string PropertyId { get; set; } = string.Empty;
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
        public string UserId { get; set; } = string.Empty;
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
        public string PropertyId { get; set; } = string.Empty;
        public string PropertyName { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public string PropertyType { get; set; } = string.Empty;
        public decimal InvestedAmount { get; set; }
        public decimal CurrentValue { get; set; }
        public double ROI { get; set; }
    }
}