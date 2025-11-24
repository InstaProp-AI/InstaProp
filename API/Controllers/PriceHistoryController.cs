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

        // GET: api/pricehistory/{parentPropertyId}
        [HttpGet("{parentPropertyId}")]
        public async Task<ActionResult<IEnumerable<PropertyPriceHistory>>> GetPriceHistoryForParentProperty(Guid parentPropertyId)
        {
            try
            {
                var priceHistory = await _context.PropertyPriceHistories
                    .Where(ph => ph.ParentPropertyId == parentPropertyId)
                    .Include(ph => ph.ParentProperty)
                    .Include(ph => ph.Auction)
                    .Include(ph => ph.ChildProperty)
                    .OrderBy(ph => ph.PriceDate)
                    .ToListAsync();

                if (!priceHistory.Any())
                {
                    return NotFound($"No price history found for parent property ID {parentPropertyId}.");
                }

                return Ok(priceHistory);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpGet("parent/{parentPropertyId}")]
        public async Task<IActionResult> GetParentPriceHistoryBundle(Guid parentPropertyId)
        {
            var history = await _context.PropertyPriceHistories
                .Where(ph => ph.ParentPropertyId == parentPropertyId)
                .OrderBy(ph => ph.PriceDate)
                .ToListAsync();

            var statistics = BuildPriceStatistics(history);

            var payload = new
            {
                ParentPropertyId = parentPropertyId,
                PriceHistory = history.Select(ph => new
                {
                    ph.PriceHistoryId,
                    ph.ParentPropertyId,
                    ph.Price,
                    PriceDate = ph.PriceDate.ToString("o"),
                    ph.Source,
                    ph.AuctionId,
                    ph.ChildPropertyId,
                    CreatedAt = ph.CreatedAt.ToString("o")
                }),
                Statistics = statistics
            };

            return Ok(payload);
        }

        [HttpGet("parent/{parentPropertyId}/stats")]
        public async Task<IActionResult> GetParentPriceStatistics(Guid parentPropertyId)
        {
            var history = await _context.PropertyPriceHistories
                .Where(ph => ph.ParentPropertyId == parentPropertyId)
                .OrderBy(ph => ph.PriceDate)
                .ToListAsync();

            var statistics = BuildPriceStatistics(history);
            var distribution = BuildPriceDistribution(history);
            var timeRange = BuildTimeRange(history);

            var payload = new
            {
                ParentPropertyId = parentPropertyId,
                Message = history.Any() ? null : "No price history available",
                Statistics = statistics,
                PriceDistribution = distribution,
                TimeRange = timeRange
            };

            return Ok(payload);
        }

        // GET: api/pricehistory/child/{childPropertyId}
        [HttpGet("child/{childPropertyId}")]
        public async Task<ActionResult<IEnumerable<PropertyPriceHistory>>> GetPriceHistoryForChildProperty(Guid childPropertyId)
        {
            try
            {
                var priceHistory = await _context.PropertyPriceHistories
                    .Where(ph => ph.ChildPropertyId == childPropertyId)
                    .Include(ph => ph.ParentProperty)
                    .Include(ph => ph.Auction)
                    .Include(ph => ph.ChildProperty)
                    .OrderBy(ph => ph.PriceDate)
                    .ToListAsync();

                if (!priceHistory.Any())
                {
                    return NotFound($"No price history found for child property ID {childPropertyId}.");
                }

                return Ok(priceHistory);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // POST: api/pricehistory
        [HttpPost]
        [Authorize]
        public async Task<ActionResult<PropertyPriceHistory>> RecordPriceHistory([FromBody] CreatePriceHistoryRequest request)
        {
            try
            {
                // Validate parent property exists
                var parentProperty = await _context.ParentProperties
                    .FirstOrDefaultAsync(pp => pp.ParentPropertyId == request.ParentPropertyId);

                if (parentProperty == null)
                {
                    return NotFound("Parent property not found.");
                }

                // Validate child property exists if provided
                if (request.ChildPropertyId.HasValue)
                {
                    var childProperty = await _context.ChildProperties
                        .FirstOrDefaultAsync(cp => cp.PropertyId == request.ChildPropertyId.Value);

                    if (childProperty == null)
                    {
                        return NotFound("Child property not found.");
                    }
                }

                // Validate auction exists if provided
                if (request.AuctionId.HasValue)
                {
                    var auction = await _context.Auctions
                        .FirstOrDefaultAsync(a => a.AuctionId == request.AuctionId.Value);

                    if (auction == null)
                    {
                        return NotFound("Auction not found.");
                    }
                }

                var priceHistory = new PropertyPriceHistory
                {
                    ParentPropertyId = request.ParentPropertyId,
                    Price = request.Price,
                    PriceDate = request.PriceDate,
                    Source = request.Source,
                    AuctionId = request.AuctionId,
                    ChildPropertyId = request.ChildPropertyId,
                    CreatedAt = DateTime.UtcNow
                };

                _context.PropertyPriceHistories.Add(priceHistory);
                await _context.SaveChangesAsync();

                return CreatedAtAction(nameof(GetPriceHistoryForParentProperty), 
                    new { parentPropertyId = request.ParentPropertyId }, priceHistory);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // PUT: api/pricehistory/{priceHistoryId}
        [HttpPut("{priceHistoryId}")]
        [Authorize]
        public async Task<IActionResult> UpdatePriceHistory(Guid priceHistoryId, [FromBody] UpdatePriceHistoryRequest request)
        {
            try
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
                priceHistory.ChildPropertyId = request.ChildPropertyId;

                await _context.SaveChangesAsync();

                return NoContent();
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // DELETE: api/pricehistory/{priceHistoryId}
        [HttpDelete("{priceHistoryId}")]
        [Authorize]
        public async Task<IActionResult> DeletePriceHistory(Guid priceHistoryId)
        {
            try
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
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // GET: api/pricehistory/analytics/{parentPropertyId}
        [HttpGet("analytics/{parentPropertyId}")]
        public async Task<ActionResult<PriceAnalyticsResponse>> GetPriceAnalytics(Guid parentPropertyId)
        {
            try
            {
                var priceHistory = await _context.PropertyPriceHistories
                    .Where(ph => ph.ParentPropertyId == parentPropertyId)
                    .OrderBy(ph => ph.PriceDate)
                    .ToListAsync();

                if (!priceHistory.Any())
                {
                    return NotFound("No price history found for this parent property.");
                }

                var prices = priceHistory.Select(ph => ph.Price).ToList();
                var minPrice = prices.Min();
                var maxPrice = prices.Max();
                var avgPrice = prices.Average();
                var latestPrice = prices.Last();
                var firstPrice = prices.First();

                var priceChange = firstPrice > 0 ? (latestPrice - firstPrice) / firstPrice * 100 : 0;
                var priceChangeAmount = latestPrice - firstPrice;

                // Calculate price volatility (standard deviation)
                var variance = prices.Select(p => Math.Pow((double)(p - avgPrice), 2)).Average();
                var volatility = Math.Sqrt(variance);

                // Group by source
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
                    ParentPropertyId = parentPropertyId,
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
                        ChildPropertyId = ph.ChildPropertyId
                    }).ToList()
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
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
                return new[]
                {
                    new { Range = $"{min:0} EGP", Count = history.Count }
                };
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

    // Request/Response Models
    public class CreatePriceHistoryRequest
    {
        public Guid ParentPropertyId { get; set; }
        public decimal Price { get; set; }
        public DateTime PriceDate { get; set; }
        public string Source { get; set; } = string.Empty;
        public Guid? AuctionId { get; set; }
        public Guid? ChildPropertyId { get; set; }
    }

    public class UpdatePriceHistoryRequest
    {
        public decimal Price { get; set; }
        public DateTime PriceDate { get; set; }
        public string Source { get; set; } = string.Empty;
        public Guid? AuctionId { get; set; }
        public Guid? ChildPropertyId { get; set; }
    }

    public class PriceAnalyticsResponse
    {
        public Guid ParentPropertyId { get; set; }
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
        public Guid? ChildPropertyId { get; set; }
    }
}