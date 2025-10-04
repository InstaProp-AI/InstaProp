using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ValuationController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ValuationController(AppDbContext context)
        {
            _context = context;
        }

        // POST: api/Valuation/estimate
        [HttpPost("estimate")]
        public async Task<ActionResult<object>> EstimatePropertyValue([FromBody] ValuationRequest request)
        {
            // Simulate AI valuation process
            var baseValue = CalculateBaseValue(request);
            var marketAdjustment = CalculateMarketAdjustment(request);
            var conditionAdjustment = CalculateConditionAdjustment(request);
            
            var estimatedValue = baseValue + marketAdjustment + conditionAdjustment;
            var range = new
            {
                Min = estimatedValue * 0.9,
                Max = estimatedValue * 1.1
            };

            var comparableProperties = await GetComparableProperties(request);

            var result = new
            {
                EstimatedValue = estimatedValue,
                Range = range,
                ComparableProperties = comparableProperties,
                Confidence = CalculateConfidence(request),
                MarketTrends = GetMarketTrends(),
                Recommendations = GetRecommendations(request, estimatedValue)
            };

            return Ok(result);
        }

        // GET: api/Valuation/trends
        [HttpGet("trends")]
        public async Task<ActionResult<object>> GetMarketTrends()
        {
            var trends = new
            {
                AveragePrice = 450000,
                PriceChange = 5.2,
                DaysOnMarket = 45,
                InventoryLevel = "Low",
                MarketCondition = "Seller's Market",
                PricePerSqFt = 250
            };

            return Ok(trends);
        }

        // GET: api/Valuation/comparables
        [HttpGet("comparables")]
        public async Task<ActionResult<IEnumerable<object>>> GetComparableProperties([FromQuery] string location, [FromQuery] int bedrooms, [FromQuery] int bathrooms)
        {
            var comparables = await _context.Properties
                .Where(p => p.IsApproved && 
                           p.Location.Contains(location) &&
                           p.Bedrooms == bedrooms &&
                           p.Bathrooms == bathrooms)
                .Select(p => new
                {
                    p.PropertyId,
                    p.Name,
                    p.Location,
                    p.Bedrooms,
                    p.Bathrooms,
                    p.SquareFeet,
                    p.StartingPrice,
                    p.CreatedAt
                })
                .Take(10)
                .ToListAsync();

            return Ok(comparables);
        }

        private double CalculateBaseValue(ValuationRequest request)
        {
            // Base calculation using square footage and location
            var basePricePerSqFt = 200; // Base price per square foot
            
            // Adjust for location (simplified)
            if (request.Location.ToLower().Contains("downtown"))
                basePricePerSqFt = 300;
            else if (request.Location.ToLower().Contains("suburb"))
                basePricePerSqFt = 180;

            return request.SquareFeet * basePricePerSqFt;
        }

        private double CalculateMarketAdjustment(ValuationRequest request)
        {
            // Market adjustment based on current trends
            var adjustment = 0.0;
            
            // Adjust for market conditions
            adjustment += 5000; // Current market is up 5k
            
            // Adjust for property type
            if (request.Bedrooms >= 4)
                adjustment += 10000;
            
            return adjustment;
        }

        private double CalculateConditionAdjustment(ValuationRequest request)
        {
            // Condition adjustment based on year built
            var currentYear = DateTime.Now.Year;
            var age = currentYear - request.YearBuilt;
            
            if (age < 5)
                return 15000; // New construction premium
            else if (age < 15)
                return 5000; // Recent construction
            else if (age < 30)
                return 0; // Average condition
            else
                return -10000; // Older property discount
        }

        private async Task<IEnumerable<object>> GetComparableProperties(ValuationRequest request)
        {
            return await _context.Properties
                .Where(p => p.IsApproved && 
                           p.Bedrooms == request.Bedrooms &&
                           p.Bathrooms == request.Bathrooms &&
                           Math.Abs(p.SquareFeet - request.SquareFeet) <= 500)
                .Select(p => new
                {
                    p.Name,
                    p.Location,
                    p.Bedrooms,
                    p.Bathrooms,
                    p.SquareFeet,
                    p.StartingPrice,
                    p.CreatedAt
                })
                .Take(5)
                .ToListAsync();
        }

        private double CalculateConfidence(ValuationRequest request)
        {
            var confidence = 0.8; // Base confidence
            
            // Increase confidence with more data
            if (!string.IsNullOrEmpty(request.Location))
                confidence += 0.1;
            if (request.SquareFeet > 0)
                confidence += 0.05;
            if (request.YearBuilt > 0)
                confidence += 0.05;
                
            return Math.Min(confidence, 1.0);
        }

        private object GetMarketTrendsData()
        {
            return new
            {
                AveragePrice = 450000,
                PriceChange = 5.2,
                DaysOnMarket = 45,
                InventoryLevel = "Low",
                MarketCondition = "Seller's Market"
            };
        }

        private IEnumerable<string> GetRecommendations(ValuationRequest request, double estimatedValue)
        {
            var recommendations = new List<string>();
            
            if (estimatedValue > 500000)
                recommendations.Add("Consider staging the property for luxury market");
            
            if (request.YearBuilt < 2000)
                recommendations.Add("Highlight recent renovations or updates");
            
            if (request.Bedrooms >= 4)
                recommendations.Add("Emphasize family-friendly features");
                
            return recommendations;
        }
    }

    public class ValuationRequest
    {
        public string Address { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public int SquareFeet { get; set; }
        public int YearBuilt { get; set; }
        public string PropertyType { get; set; } = string.Empty;
        public string Condition { get; set; } = string.Empty;
    }
}
