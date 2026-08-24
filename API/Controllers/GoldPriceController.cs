using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using Microsoft.AspNetCore.Authorization;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [AllowAnonymous]
    public class GoldPriceController : ControllerBase
    {
        private readonly AppDbContext _context;

        public GoldPriceController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("latest")]
        public async Task<IActionResult> GetLatestGoldPrice()
        {
            var latestPrice = await _context.GoldPrices
                .OrderByDescending(gp => gp.Date)
                .FirstOrDefaultAsync();

            if (latestPrice == null)
            {
                return NotFound(new { message = "No gold price data available" });
            }

            return Ok(new
            {
                latestPrice.GoldPriceId,
                latestPrice.Price,
                latestPrice.Date,
                latestPrice.Currency,
                latestPrice.Weight
            });
        }

        [HttpGet("history")]
        public async Task<IActionResult> GetGoldPriceHistory([FromQuery] GoldPriceHistoryFilters filters)
        {
            var query = _context.GoldPrices.AsQueryable();

            if (filters.StartDate.HasValue)
            {
                query = query.Where(gp => gp.Date >= filters.StartDate);
            }

            if (filters.EndDate.HasValue)
            {
                query = query.Where(gp => gp.Date <= filters.EndDate);
            }

            if (!string.IsNullOrEmpty(filters.Currency))
            {
                query = query.Where(gp => gp.Currency == filters.Currency);
            }

            if (!string.IsNullOrEmpty(filters.Weight) && decimal.TryParse(filters.Weight, out var weightValue))
            {
                query = query.Where(gp => gp.Weight == weightValue);
            }

            query = query.OrderByDescending(gp => gp.Date);

            var totalCount = await query.CountAsync();
            var prices = await query
                .Skip((filters.Page - 1) * filters.PageSize)
                .Take(filters.PageSize)
                .Select(gp => new
                {
                    gp.GoldPriceId,
                    gp.Price,
                    gp.Date,
                    gp.Currency,
                    gp.Weight
                })
                .ToListAsync();

            return Ok(new
            {
                Prices = prices,
                TotalCount = totalCount,
                Page = filters.Page,
                PageSize = filters.PageSize,
                TotalPages = (int)Math.Ceiling((double)totalCount / filters.PageSize)
            });
        }

        [HttpGet("stats")]
        public async Task<IActionResult> GetGoldPriceStats([FromQuery] GoldPriceStatsFilters filters)
        {
            var query = _context.GoldPrices.AsQueryable();

            if (filters.StartDate.HasValue)
            {
                query = query.Where(gp => gp.Date >= filters.StartDate);
            }

            if (filters.EndDate.HasValue)
            {
                query = query.Where(gp => gp.Date <= filters.EndDate);
            }

            if (!string.IsNullOrEmpty(filters.Currency))
            {
                query = query.Where(gp => gp.Currency == filters.Currency);
            }

            if (!string.IsNullOrEmpty(filters.Weight))
            {
                query = query.Where(gp => gp.Weight == decimal.Parse(filters.Weight));
            }

            var prices = await query
                .OrderBy(gp => gp.Date)
                .Select(gp => gp.Price)
                .ToListAsync();

            if (!prices.Any())
            {
                return NotFound(new { message = "No gold price data available for the specified period" });
            }

            var minPrice = prices.Min();
            var maxPrice = prices.Max();
            var avgPrice = prices.Average();
            var currentPrice = prices.Last();
            var firstPrice = prices.First();
            var priceChange = currentPrice - firstPrice;
            var priceChangePercent = firstPrice > 0 ? (priceChange / firstPrice) * 100 : 0;

            // Calculate volatility (standard deviation)
            var variance = prices.Select(p => Math.Pow((double)(p - avgPrice), 2)).Average();
            var volatility = Math.Sqrt(variance);

            // Calculate trend
            var trend = "stable";
            if (prices.Count >= 2)
            {
                var recentPrices = prices.TakeLast(5).ToList();
                if (recentPrices.Count >= 2)
                {
                    var recentTrend = recentPrices.Last() - recentPrices.First();
                    if (recentTrend > 0)
                        trend = "rising";
                    else if (recentTrend < 0)
                        trend = "falling";
                }
            }

            return Ok(new
            {
                CurrentPrice = currentPrice,
                MinPrice = minPrice,
                MaxPrice = maxPrice,
                AveragePrice = Math.Round(avgPrice, 2),
                PriceChange = Math.Round(priceChange, 2),
                PriceChangePercent = Math.Round(priceChangePercent, 2),
                Volatility = Math.Round(volatility, 2),
                Trend = trend,
                DataPoints = prices.Count,
                Period = new
                {
                    StartDate = filters.StartDate ?? DateTime.UtcNow.AddDays(-30),
                    EndDate = filters.EndDate ?? DateTime.UtcNow
                }
            });
        }

        [HttpGet("compare-property")]
        public async Task<IActionResult> CompareGoldWithProperty([FromQuery] Guid propertyId, [FromQuery] decimal? propertyPrice = null)
        {
            var latestGoldPrice = await _context.GoldPrices
                .OrderByDescending(gp => gp.Date)
                .FirstOrDefaultAsync();

            if (latestGoldPrice == null)
            {
                return NotFound(new { message = "No gold price data available" });
            }

            var property = await _context.Properties
                .Include(p => p.Project)
                .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

            if (property == null)
            {
                return NotFound(new { message = "Property not found" });
            }

            var comparisonPrice = propertyPrice ?? property.BuyingPrice ?? 0m;

            if (comparisonPrice <= 0)
            {
                return BadRequest(new { message = "No property price data available for comparison" });
            }

            // Calculate how much gold can be bought with property price
            var goldGrams = comparisonPrice / latestGoldPrice.Price;
            var goldOunces = goldGrams / 31.1035m; // Convert grams to ounces

            // Calculate property value in gold
            var propertyValueInGold = new
            {
                Grams = Math.Round(goldGrams, 2),
                Ounces = Math.Round(goldOunces, 2),
                Kilograms = Math.Round(goldGrams / 1000, 3)
            };

            // Get historical comparison (last 12 months)
            var twelveMonthsAgo = DateTime.UtcNow.AddMonths(-12);
            var historicalGoldPrice = await _context.GoldPrices
                .Where(gp => gp.Date >= twelveMonthsAgo)
                .OrderBy(gp => gp.Date)
                .FirstOrDefaultAsync();

            var goldPriceChange = latestGoldPrice.Price - (historicalGoldPrice?.Price ?? latestGoldPrice.Price);
            var goldPriceChangePercent = historicalGoldPrice != null ? 
                (goldPriceChange / historicalGoldPrice.Price) * 100 : 0;

            return Ok(new
            {
                GoldPrice = new
                {
                    latestGoldPrice.Price,
                    latestGoldPrice.Date,
                    latestGoldPrice.Currency,
                    latestGoldPrice.Weight
                },
                Property = new
                {
                    property.PropertyId,
                    Type = PropertyTypeHelper.ToDisplayName(property.Type),
                    property.Bedrooms,
                    property.Bathrooms,
                    SquareFeet = property.SquareFeet,
                    property.FinishingType,
                    Project = property.Project != null ? new
                    {
                        property.Project.Name,
                        property.Project.Location
                    } : null
                },
                Comparison = new
                {
                    PropertyPrice = comparisonPrice,
                    PropertyValueInGold = propertyValueInGold,
                    GoldPriceChange = Math.Round(goldPriceChange, 2),
                    GoldPriceChangePercent = Math.Round(goldPriceChangePercent, 2),
                    Recommendation = goldPriceChangePercent > 0 ? 
                        "Gold prices are rising - consider investing in gold" : 
                        "Gold prices are falling - consider investing in real estate"
                }
            });
        }

        [HttpGet("trends")]
        public async Task<IActionResult> GetGoldPriceTrends([FromQuery] GoldPriceTrendFilters filters)
        {
            var query = _context.GoldPrices.AsQueryable();

            if (filters.StartDate.HasValue)
            {
                query = query.Where(gp => gp.Date >= filters.StartDate);
            }

            if (filters.EndDate.HasValue)
            {
                query = query.Where(gp => gp.Date <= filters.EndDate);
            }

            if (!string.IsNullOrEmpty(filters.Currency))
            {
                query = query.Where(gp => gp.Currency == filters.Currency);
            }

            if (!string.IsNullOrEmpty(filters.Weight))
            {
                query = query.Where(gp => gp.Weight == decimal.Parse(filters.Weight));
            }

            var prices = await query
                .OrderBy(gp => gp.Date)
                .Select(gp => new { gp.Date, gp.Price })
                .ToListAsync();

            if (!prices.Any())
            {
                return NotFound(new { message = "No gold price data available for the specified period" });
            }

            // Calculate moving averages
            var movingAverages = new List<object>();
            var windowSize = Math.Min(filters.MovingAverageWindow ?? 7, prices.Count);

            for (int i = windowSize - 1; i < prices.Count; i++)
            {
                var window = prices.Skip(i - windowSize + 1).Take(windowSize);
                var avg = window.Average(p => p.Price);
                movingAverages.Add(new
                {
                    Date = prices[i].Date,
                    Price = prices[i].Price,
                    MovingAverage = Math.Round(avg, 2)
                });
            }

            // Calculate support and resistance levels
            var sortedPrices = prices.Select(p => p.Price).OrderBy(p => p).ToList();
            var supportLevel = sortedPrices.Take((int)(sortedPrices.Count * 0.1)).Average();
            var resistanceLevel = sortedPrices.TakeLast((int)(sortedPrices.Count * 0.1)).Average();

            return Ok(new
            {
                Prices = prices,
                MovingAverages = movingAverages,
                SupportLevel = Math.Round(supportLevel, 2),
                ResistanceLevel = Math.Round(resistanceLevel, 2),
                TrendAnalysis = new
                {
                    IsRising = prices.Last().Price > prices.First().Price,
                    PriceRange = new
                    {
                        Min = prices.Min(p => p.Price),
                        Max = prices.Max(p => p.Price)
                    },
                    Volatility = CalculateVolatility(prices.Select(p => p.Price).ToList())
                }
            });
        }

        private double CalculateVolatility(List<decimal> prices)
        {
            if (prices.Count < 2) return 0;

            var avg = prices.Average();
            var variance = prices.Select(p => Math.Pow((double)(p - avg), 2)).Average();
            return Math.Sqrt(variance);
        }
    }

    public class GoldPriceHistoryFilters
    {
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? Currency { get; set; } = "EGP";
        public string? Weight { get; set; } = "gram";
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 100;
    }

    public class GoldPriceStatsFilters
    {
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? Currency { get; set; } = "EGP";
        public string? Weight { get; set; } = "gram";
    }

    public class GoldPriceTrendFilters
    {
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? Currency { get; set; } = "EGP";
        public string? Weight { get; set; } = "gram";
        public int? MovingAverageWindow { get; set; } = 7;
    }
}
