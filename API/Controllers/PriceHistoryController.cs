using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using Microsoft.AspNetCore.Authorization;
using InstapropAPI.Attributes;

namespace InstapropAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [FeaturePermissionAttribute("PriceHistory")]
    public class PriceHistoryController : ControllerBase
    {
        private readonly AppDbContext _context;

        public PriceHistoryController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("{propertyId}")]
        public async Task<ActionResult<IEnumerable<PropertyPriceHistory>>> GetPriceHistoryForProperty(Guid propertyId)
        {
            var priceHistory = await _context.PropertyPriceHistories
                .Where(ph => ph.PropertyId == propertyId)
                .Include(ph => ph.Auction)
                .OrderBy(ph => ph.PriceDate)
                .ToListAsync();

            if (!priceHistory.Any())
            {
                return NotFound($"No price history found for property ID {propertyId}.");
            }

            return Ok(priceHistory);
        }

        [HttpGet("{propertyId}/stats")]
        public async Task<IActionResult> GetPropertyPriceStatistics(Guid propertyId)
        {
            var history = await _context.PropertyPriceHistories
                .Where(ph => ph.PropertyId == propertyId)
                .OrderBy(ph => ph.PriceDate)
                .ToListAsync();

            var statistics = BuildPriceStatistics(history);
            var distribution = BuildPriceDistribution(history);
            var timeRange = BuildTimeRange(history);

            return Ok(new
            {
                PropertyId = propertyId,
                Message = history.Any() ? null : "No price history available",
                Statistics = statistics,
                PriceDistribution = distribution,
                TimeRange = timeRange
            });
        }

        [HttpGet("{propertyId}/bundle")]
        public async Task<IActionResult> GetPropertyPriceHistoryBundle(Guid propertyId)
        {
            var history = await _context.PropertyPriceHistories
                .Where(ph => ph.PropertyId == propertyId)
                .OrderBy(ph => ph.PriceDate)
                .ToListAsync();

            return Ok(new
            {
                PropertyId = propertyId,
                PriceHistory = history.Select(ph => new
                {
                    ph.PriceHistoryId,
                    ph.PropertyId,
                    ph.Price,
                    PriceDate = ph.PriceDate.ToString("o"),
                    ph.Source,
                    ph.AuctionId,
                    CreatedAt = ph.CreatedAt.ToString("o")
                }),
                Statistics = BuildPriceStatistics(history)
            });
        }

        [HttpPost]
        [Authorize]
        public async Task<ActionResult<PropertyPriceHistory>> RecordPriceHistory([FromBody] CreatePriceHistoryRequest request)
        {
            var property = await _context.Properties
                .FirstOrDefaultAsync(p => p.PropertyId == request.PropertyId);

            if (property == null)
            {
                return NotFound("Property not found.");
            }

            if (request.AuctionId.HasValue)
            {
                var auctionExists = await _context.Auctions
                    .AnyAsync(a => a.AuctionId == request.AuctionId.Value);

                if (!auctionExists)
                {
                    return NotFound("Auction not found.");
                }
            }

            var priceHistory = new PropertyPriceHistory
            {
                PropertyId = request.PropertyId,
                Price = request.Price,
                PriceDate = request.PriceDate,
                Source = request.Source,
                AuctionId = request.AuctionId,
                CreatedAt = DateTime.UtcNow
            };

            _context.PropertyPriceHistories.Add(priceHistory);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetPriceHistoryForProperty),
                new { propertyId = request.PropertyId }, priceHistory);
        }

        [HttpPut("{priceHistoryId}")]
        [Authorize]
        public async Task<IActionResult> UpdatePriceHistory(Guid priceHistoryId, [FromBody] UpdatePriceHistoryRequest request)
        {
            var priceHistory = await _context.PropertyPriceHistories
                .FirstOrDefaultAsync(ph => ph.PriceHistoryId == priceHistoryId);

            if (priceHistory == null)
            {
                return NotFound("Price history record not found.");
            }

            priceHistory.Price = request.Price;
            priceHistory.PriceDate = request.PriceDate;
            priceHistory.Source = request.Source;
            priceHistory.AuctionId = request.AuctionId;

            await _context.SaveChangesAsync();

            return NoContent();
        }

        [HttpDelete("{priceHistoryId}")]
        [Authorize]
        public async Task<IActionResult> DeletePriceHistory(Guid priceHistoryId)
        {
            var priceHistory = await _context.PropertyPriceHistories
                .FirstOrDefaultAsync(ph => ph.PriceHistoryId == priceHistoryId);

            if (priceHistory == null)
            {
                return NotFound("Price history record not found.");
            }

            _context.PropertyPriceHistories.Remove(priceHistory);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        [HttpGet("analytics/{propertyId}")]
        public async Task<ActionResult<PriceAnalyticsResponse>> GetPriceAnalytics(Guid propertyId)
        {
            var priceHistory = await _context.PropertyPriceHistories
                .Where(ph => ph.PropertyId == propertyId)
                .OrderBy(ph => ph.PriceDate)
                .ToListAsync();

            if (!priceHistory.Any())
            {
                return NotFound("No price history found for this property.");
            }

            var prices = priceHistory.Select(ph => ph.Price).ToList();
            var minPrice = prices.Min();
            var maxPrice = prices.Max();
            var avgPrice = prices.Average();
            var latestPrice = prices.Last();
            var firstPrice = prices.First();
            var priceChange = firstPrice > 0 ? (latestPrice - firstPrice) / firstPrice * 100 : 0;
            var priceChangeAmount = latestPrice - firstPrice;
            var variance = prices.Select(p => Math.Pow((double)(p - avgPrice), 2)).Average();
            var volatility = Math.Sqrt(variance);

            var sourceBreakdown = priceHistory
                .GroupBy(ph => ph.Source)
                .Select(g => new SourceBreakdown
                {
                    Source = g.Key,
                    Count = g.Count(),
                    AveragePrice = g.Average(ph => ph.Price),
                    Percentage = (double)g.Count() / priceHistory.Count * 100
                })
                .ToList();

            return Ok(new PriceAnalyticsResponse
            {
                PropertyId = propertyId,
                TotalDataPoints = priceHistory.Count,
                MinPrice = minPrice,
                MaxPrice = maxPrice,
                AveragePrice = avgPrice,
                LatestPrice = latestPrice,
                FirstPrice = firstPrice,
                PriceChangePercentage = priceChange,
                PriceChangeAmount = priceChangeAmount,
                Volatility = volatility,
                SourceBreakdown = sourceBreakdown,
                PriceHistory = priceHistory.Select(ph => new PriceHistoryDataPoint
                {
                    Date = ph.PriceDate,
                    Price = ph.Price,
                    Source = ph.Source,
                    AuctionId = ph.AuctionId,
                    PropertyId = ph.PropertyId
                }).ToList()
            });
        }

        private static object BuildPriceStatistics(List<PropertyPriceHistory> history)
        {
            if (!history.Any())
            {
                return new
                {
                    AveragePrice = 0m,
                    MinPrice = 0m,
                    MaxPrice = 0m,
                    PriceChange = 0m,
                    PriceChangePercent = 0m,
                    DataPoints = 0
                };
            }

            var prices = history.Select(h => h.Price).ToList();
            var average = Math.Round(prices.Average(), 2);
            var min = prices.Min();
            var max = prices.Max();
            var first = prices.First();
            var last = prices.Last();
            var changeAmount = last - first;
            var changePercent = first != 0 ? Math.Round((last - first) / first * 100, 2) : 0m;

            return new
            {
                AveragePrice = average,
                MinPrice = min,
                MaxPrice = max,
                PriceChange = changeAmount,
                PriceChangePercent = changePercent,
                DataPoints = prices.Count
            };
        }

        private static IEnumerable<object> BuildPriceDistribution(List<PropertyPriceHistory> history)
        {
            if (!history.Any())
            {
                return Array.Empty<object>();
            }

            var min = history.Min(h => h.Price);
            var max = history.Max(h => h.Price);

            if (min == max)
            {
                return new[] { new { Range = $"{min:0} EGP", Count = history.Count } };
            }

            var bucketCount = 3;
            var step = (max - min) / bucketCount;
            if (step == 0) step = 1;

            var buckets = new List<object>();
            for (int i = 0; i < bucketCount; i++)
            {
                var start = min + step * i;
                var end = i == bucketCount - 1 ? max : min + step * (i + 1);
                var count = history.Count(h => h.Price >= start && (i == bucketCount - 1 ? h.Price <= end : h.Price < end));
                buckets.Add(new
                {
                    Range = $"{Math.Round(start, 0):0} - {Math.Round(end, 0):0} EGP",
                    Count = count
                });
            }

            return buckets;
        }

        private static object BuildTimeRange(List<PropertyPriceHistory> history)
        {
            if (!history.Any())
            {
                var now = DateTime.UtcNow;
                return new
                {
                    StartDate = now.ToString("o"),
                    EndDate = now.ToString("o"),
                    DurationDays = 0
                };
            }

            var start = history.First().PriceDate;
            var end = history.Last().PriceDate;

            return new
            {
                StartDate = start.ToString("o"),
                EndDate = end.ToString("o"),
                DurationDays = (end - start).Days
            };
        }
    }

    public class CreatePriceHistoryRequest
    {
        public Guid PropertyId { get; set; }
        public decimal Price { get; set; }
        public DateTime PriceDate { get; set; }
        public string Source { get; set; } = string.Empty;
        public Guid? AuctionId { get; set; }
    }

    public class UpdatePriceHistoryRequest
    {
        public decimal Price { get; set; }
        public DateTime PriceDate { get; set; }
        public string Source { get; set; } = string.Empty;
        public Guid? AuctionId { get; set; }
    }

    public class PriceAnalyticsResponse
    {
        public Guid PropertyId { get; set; }
        public int TotalDataPoints { get; set; }
        public decimal MinPrice { get; set; }
        public decimal MaxPrice { get; set; }
        public decimal AveragePrice { get; set; }
        public decimal LatestPrice { get; set; }
        public decimal FirstPrice { get; set; }
        public decimal PriceChangePercentage { get; set; }
        public decimal PriceChangeAmount { get; set; }
        public double Volatility { get; set; }
        public List<SourceBreakdown> SourceBreakdown { get; set; } = new();
        public List<PriceHistoryDataPoint> PriceHistory { get; set; } = new();
    }

    public class SourceBreakdown
    {
        public string Source { get; set; } = string.Empty;
        public int Count { get; set; }
        public decimal AveragePrice { get; set; }
        public double Percentage { get; set; }
    }

    public class PriceHistoryDataPoint
    {
        public DateTime Date { get; set; }
        public decimal Price { get; set; }
        public string Source { get; set; } = string.Empty;
        public Guid? AuctionId { get; set; }
        public Guid PropertyId { get; set; }
    }
}
