using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using Microsoft.AspNetCore.Authorization;

namespace PropertyFlipperAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PriceHistoryController : ControllerBase
    {
        private readonly AppDbContext _context;

        public PriceHistoryController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/pricehistory/{parentPropertyId}
        [HttpGet("{parentPropertyId}")]
        public async Task<ActionResult<IEnumerable<PropertyPriceHistory>>> GetPriceHistoryForParentProperty(int parentPropertyId)
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

        // GET: api/pricehistory/child/{childPropertyId}
        [HttpGet("child/{childPropertyId}")]
        public async Task<ActionResult<IEnumerable<PropertyPriceHistory>>> GetPriceHistoryForChildProperty(int childPropertyId)
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
        public async Task<IActionResult> UpdatePriceHistory(int priceHistoryId, [FromBody] UpdatePriceHistoryRequest request)
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
        public async Task<IActionResult> DeletePriceHistory(int priceHistoryId)
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
        public async Task<ActionResult<PriceAnalyticsResponse>> GetPriceAnalytics(int parentPropertyId)
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
    }

    // Request/Response Models
    public class CreatePriceHistoryRequest
    {
        public int ParentPropertyId { get; set; }
        public decimal Price { get; set; }
        public DateTime PriceDate { get; set; }
        public string Source { get; set; } = string.Empty;
        public long? AuctionId { get; set; }
        public int? ChildPropertyId { get; set; }
    }

    public class UpdatePriceHistoryRequest
    {
        public decimal Price { get; set; }
        public DateTime PriceDate { get; set; }
        public string Source { get; set; } = string.Empty;
        public long? AuctionId { get; set; }
        public int? ChildPropertyId { get; set; }
    }

    public class PriceAnalyticsResponse
    {
        public int ParentPropertyId { get; set; }
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
        public long? AuctionId { get; set; }
        public int? ChildPropertyId { get; set; }
    }
}