using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using Microsoft.AspNetCore.Authorization;
using InstapropAPI.Services;
using InstapropAPI.Attributes;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [FeaturePermissionAttribute("Valuation")]
    public class ValuationController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly InstapropAPI.Services.OpenAIService _openAIService;
        private readonly RewardService _rewardService;

        public ValuationController(AppDbContext context, InstapropAPI.Services.OpenAIService openAIService, RewardService rewardService)
        {
            _context = context;
            _openAIService = openAIService;
            _rewardService = rewardService;
        }

        // POST: api/Valuation/calculate
        [HttpPost("calculate")]
        [Authorize]
        public async Task<ActionResult<ValuationResult>> CalculateValuation([FromBody] ValuationRequest request)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            // Get property details if PropertyId is provided
            Property? property = null;
            if (request.PropertyId.HasValue)
            {
                property = await _context.Properties
                    .FirstOrDefaultAsync(p => p.PropertyId == request.PropertyId);
                
                if (property == null)
                    return NotFound("Property not found");
            }

            // Calculate valuation based on property details
            var valuation = CalculatePropertyValuation(property, request);

            // Award rewards to user for running valuation
            if (accountId.HasValue)
            {
                await _rewardService.AwardPointsAsync(accountId.Value, "Valuation", RewardPoints.Valuation, request.PropertyId.HasValue ? $"Valuated property #{request.PropertyId}" : "Valuation");
            }

            return Ok(valuation);
        }

        // GET: api/Valuation/history
        [HttpGet("history")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<ValuationHistory>>> GetValuationHistory()
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            // Get user's properties and their valuations
            var properties = await _context.Properties
                .Where(p => p.OwnerId == accountId)
                .Select(p => new ValuationHistory
                {
                    PropertyId = p.PropertyId,
                    PropertyName = p.Name,
                    Location = p.Location,
                    CalculatedValue = (p.Bedrooms * 50000) + (p.Bathrooms * 30000) + (p.SquareFeet * 100), // Basic valuation
                    CalculatedAt = p.CreatedAt
                })
                .ToListAsync();

            return Ok(properties);
        }

        private ValuationResult CalculatePropertyValuation(Property? property, ValuationRequest request)
        {
            // Simple valuation algorithm (in real app, this would be more sophisticated)
            decimal basePrice = 0;
            
            if (property != null)
            {
                // Calculate based on property details
                basePrice = (property.Bedrooms * 50000) + (property.Bathrooms * 30000) + (property.SquareFeet * 100);
            }
            else if (request.Bedrooms > 0 && request.Bathrooms > 0 && request.SquareFeet > 0)
            {
                // Calculate based on provided details
                basePrice = (request.Bedrooms * 50000) + (request.Bathrooms * 30000) + (request.SquareFeet * 100);
            }

            // Apply location multiplier (simplified)
            decimal locationMultiplier = 1.0m;
            if (!string.IsNullOrEmpty(request.Location))
            {
                if (request.Location.ToLower().Contains("downtown") || request.Location.ToLower().Contains("city"))
                    locationMultiplier = 1.5m;
                else if (request.Location.ToLower().Contains("suburb"))
                    locationMultiplier = 1.2m;
            }

            // Apply year built factor
            decimal yearFactor = 1.0m;
            if (request.YearBuilt > 0)
            {
                int age = DateTime.Now.Year - request.YearBuilt;
                if (age < 5) yearFactor = 1.2m;
                else if (age < 15) yearFactor = 1.0m;
                else if (age < 30) yearFactor = 0.9m;
                else yearFactor = 0.8m;
            }

            decimal finalValue = basePrice * locationMultiplier * yearFactor;

            return new ValuationResult
            {
                EstimatedValue = finalValue,
                BasePrice = basePrice,
                LocationMultiplier = locationMultiplier,
                YearFactor = yearFactor,
                CalculatedAt = DateTime.UtcNow,
                Confidence = 0.85m // 85% confidence in the estimate
            };
        }

        // POST: api/Valuation/calculate-ai
        [HttpPost("calculate-ai")]
        [Authorize]
        public async Task<ActionResult<EnhancedValuationResult>> CalculateAIValuation([FromBody] ValuationRequest request)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            try
            {
                // Create property data for AI
                var propertyData = new InstapropAPI.Services.PropertyValuationData
                {
                    Location = request.Location ?? "",
                    Bedrooms = request.Bedrooms,
                    Bathrooms = request.Bathrooms,
                    SquareFeet = request.SquareFeet,
                    YearBuilt = request.YearBuilt,
                    PropertyType = request.PropertyType ?? "Residential"
                };

                // Query similar properties (20-30)
                var comparables = await GetSimilarProperties(request);

                // Query auction data (both completed and active)
                var auctions = await GetRelevantAuctions(request);

                Console.WriteLine($"Found {comparables.Count} comparable properties and {auctions.Count} auctions");

                // Call OpenAI for valuation
                var aiResult = await _openAIService.ValuatePropertyAsync(propertyData, comparables, auctions);

                // Map to enhanced result
                var result = new EnhancedValuationResult
                {
                    EstimatedValue = aiResult.EstimatedPrice,
                    PriceRangeLow = aiResult.PriceRangeLow,
                    PriceRangeHigh = aiResult.PriceRangeHigh,
                    Confidence = aiResult.Confidence,
                    AiReasoning = aiResult.Reasoning,
                    MarketTrends = aiResult.MarketTrends,
                    TopComparables = aiResult.TopComparables.Select(tc => new ComparablePropertyDto
                    {
                        Name = tc.Name,
                        Location = tc.Location,
                        Bedrooms = tc.Bedrooms,
                        Bathrooms = tc.Bathrooms,
                        SquareFeet = tc.SquareFeet,
                        Price = tc.Price,
                        Status = tc.Status
                    }).ToList(),
                    CalculatedAt = DateTime.UtcNow,
                    ComparablesCount = comparables.Count,
                    AuctionsCount = auctions.Count
                };

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = $"Error calculating AI valuation: {ex.Message}" });
            }
        }

        private async Task<List<InstapropAPI.Services.ComparablePropertyData>> GetSimilarProperties(ValuationRequest request)
        {
            var comparables = new List<InstapropAPI.Services.ComparablePropertyData>();

            // Calculate size range (±20%)
            var minSqft = (int)(request.SquareFeet * 0.8);
            var maxSqft = (int)(request.SquareFeet * 1.2);

            // Extract city from location
            var location = request.Location ?? "";
            
            // Query similar properties with their auction data
            var properties = await _context.Properties
                .Include(p => p.Auctions)
                .Where(p => 
                    // Same general location
                    (p.Location != null && (p.Location.Contains(location) || location.Contains(p.Location))) &&
                    // Similar size
                    p.SquareFeet >= minSqft && p.SquareFeet <= maxSqft &&
                    // Same bedrooms OR bathrooms
                    (p.Bedrooms == request.Bedrooms || p.Bathrooms == request.Bathrooms)
                )
                .OrderByDescending(p => p.CreatedAt)
                .Take(30)
                .ToListAsync();

            foreach (var prop in properties)
            {
                // Get price from most recent auction if available
                var latestAuction = prop.Auctions.OrderByDescending(a => a.CreatedAt).FirstOrDefault();
                decimal price = latestAuction?.CurrentPrice ?? latestAuction?.StartPrice ?? 0;

                comparables.Add(new InstapropAPI.Services.ComparablePropertyData
                {
                    Name = prop.Name,
                    Location = prop.Location ?? "",
                    Bedrooms = prop.Bedrooms,
                    Bathrooms = prop.Bathrooms,
                    SquareFeet = prop.SquareFeet,
                    YearBuilt = prop.YearBuilt,
                    Type = prop.Type.ToDisplayName(),
                    Price = price,
                    Status = prop.Status.ToString()
                });
            }

            return comparables;
        }

        private async Task<List<InstapropAPI.Services.AuctionDataForValuation>> GetRelevantAuctions(ValuationRequest request)
        {
            var auctionData = new List<InstapropAPI.Services.AuctionDataForValuation>();

            var minSqft = (int)(request.SquareFeet * 0.8);
            var maxSqft = (int)(request.SquareFeet * 1.2);
            var location = request.Location ?? "";

            // Get auctions with similar properties
            var auctions = await _context.Auctions
                .Include(a => a.Property)
                .Where(a => 
                    // Similar location
                    (a.Property.Location.Contains(location) || location.Contains(a.Property.Location)) &&
                    // Similar size
                    a.Property.SquareFeet >= minSqft && a.Property.SquareFeet <= maxSqft &&
                    // Same bedrooms OR bathrooms
                    (a.Property.Bedrooms == request.Bedrooms || a.Property.Bathrooms == request.Bathrooms)
                )
                .OrderByDescending(a => a.CreatedAt)
                .Take(30)
                .ToListAsync();

            foreach (var auction in auctions)
            {
                decimal currentPrice = auction.CurrentPrice > 0 ? auction.CurrentPrice : auction.StartPrice;
                
                auctionData.Add(new InstapropAPI.Services.AuctionDataForValuation
                {
                    PropertyName = auction.Property.Name,
                    Location = auction.Property.Location,
                    Bedrooms = auction.Property.Bedrooms,
                    Bathrooms = auction.Property.Bathrooms,
                    SquareFeet = auction.Property.SquareFeet,
                    CurrentPrice = currentPrice,
                    Status = auction.Status,
                    BidCount = auction.BidCount
                });
            }

            return auctionData;
        }

        private Guid? GetCurrentAccountId()
        {
            var uidClaim = User.FindFirst("uid");
            return uidClaim != null && Guid.TryParse(uidClaim.Value, out Guid accountId) ? accountId : null;
        }
    }

    public class ValuationRequest
    {
        public Guid? PropertyId { get; set; }
        public string? Location { get; set; }
        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public int SquareFeet { get; set; }
        public int YearBuilt { get; set; }
        public string? PropertyType { get; set; }
    }

    public class ValuationResult
    {
        public decimal EstimatedValue { get; set; }
        public decimal BasePrice { get; set; }
        public decimal LocationMultiplier { get; set; }
        public decimal YearFactor { get; set; }
        public decimal Confidence { get; set; }
        public DateTime CalculatedAt { get; set; }
    }

    public class ValuationHistory
    {
        public Guid PropertyId { get; set; }
        public string PropertyName { get; set; } = string.Empty;
        public string? Location { get; set; }
        public decimal CalculatedValue { get; set; }
        public DateTime CalculatedAt { get; set; }
    }

    public class EnhancedValuationResult
    {
        public decimal EstimatedValue { get; set; }
        public decimal PriceRangeLow { get; set; }
        public decimal PriceRangeHigh { get; set; }
        public decimal Confidence { get; set; }
        public string? AiReasoning { get; set; }
        public string? MarketTrends { get; set; }
        public List<ComparablePropertyDto> TopComparables { get; set; } = new List<ComparablePropertyDto>();
        public DateTime CalculatedAt { get; set; }
        public int ComparablesCount { get; set; }
        public int AuctionsCount { get; set; }
    }

    public class ComparablePropertyDto
    {
        public string Name { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public int SquareFeet { get; set; }
        public decimal Price { get; set; }
        public string Status { get; set; } = string.Empty;
    }
}
