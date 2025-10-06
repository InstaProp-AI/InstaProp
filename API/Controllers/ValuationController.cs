using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using Microsoft.AspNetCore.Authorization;

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
                    CalculatedValue = p.StartingPrice, // This would be replaced with actual valuation
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
                basePrice = property.StartingPrice;
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

        private long? GetCurrentAccountId()
        {
            var uidClaim = User.FindFirst("uid");
            return uidClaim != null ? long.Parse(uidClaim.Value) : null;
        }
    }

    public class ValuationRequest
    {
        public long? PropertyId { get; set; }
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
        public long PropertyId { get; set; }
        public string PropertyName { get; set; } = string.Empty;
        public string? Location { get; set; }
        public decimal CalculatedValue { get; set; }
        public DateTime CalculatedAt { get; set; }
    }
}
