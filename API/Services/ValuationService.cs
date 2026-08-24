using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Controllers;

namespace InstapropAPI.Services
{
    public class ValuationService
    {
        private readonly AppDbContext _context;
        private readonly OpenAIService _openAIService;

        public ValuationService(AppDbContext context, OpenAIService openAIService)
        {
            _context = context;
            _openAIService = openAIService;
        }

        /// <summary>
        /// Gets or calculates property valuation with 2-week caching
        /// </summary>
        public async Task<decimal?> GetOrCalculatePropertyValuation(Guid propertyId)
        {
            // Check for recent valuation (less than 14 days old)
            var recentValuation = await _context.PropertyValuations
                .Where(v => v.PropertyId == propertyId && 
                           v.CalculatedAt >= DateTime.UtcNow.AddDays(-14))
                .OrderByDescending(v => v.CalculatedAt)
                .FirstOrDefaultAsync();

            if (recentValuation != null)
            {
                return recentValuation.EstimatedValue;
            }

            // No recent valuation found, calculate new one
            var property = await _context.Properties
                .FirstOrDefaultAsync(p => p.PropertyId == propertyId);

            if (property == null)
            {
                return null;
            }

            try
            {
                // Create valuation request for AI
                var request = new ValuationRequest
                {
                    PropertyId = propertyId,
                    Location = property.Location,
                    Bedrooms = property.Bedrooms,
                    Bathrooms = property.Bathrooms,
                    SquareFeet = property.SquareFeet,
                    YearBuilt = property.YearBuilt,
                    PropertyType = PropertyTypeHelper.ToDisplayName(property.Type)
                };

                // Get AI valuation
                var aiResult = await _openAIService.ValuatePropertyAsync(
                    new PropertyValuationData
                    {
                        Location = property.Location,
                        Bedrooms = property.Bedrooms,
                        Bathrooms = property.Bathrooms,
                        SquareFeet = property.SquareFeet,
                        YearBuilt = property.YearBuilt,
                        PropertyType = PropertyTypeHelper.ToDisplayName(property.Type)
                    },
                    await GetSimilarProperties(request),
                    await GetRelevantAuctions(request)
                );

                // Store valuation in database
                var valuation = new PropertyValuation
                {
                    PropertyId = propertyId,
                    EstimatedValue = aiResult.EstimatedPrice,
                    Confidence = aiResult.Confidence,
                    CalculatedAt = DateTime.UtcNow,
                    ValuationSource = ValuationSource.AI,
                    AIReasoning = aiResult.Reasoning,
                    ComparablesCount = aiResult.TopComparables?.Count,
                    PriceRangeLow = aiResult.PriceRangeLow,
                    PriceRangeHigh = aiResult.PriceRangeHigh,
                    MarketTrends = aiResult.MarketTrends
                };

                _context.PropertyValuations.Add(valuation);
                await _context.SaveChangesAsync();

                return aiResult.EstimatedPrice;
            }
            catch (Exception ex)
            {
                // If AI valuation fails, return null to use fallback logic
                Console.WriteLine($"AI valuation failed for property {propertyId}: {ex.Message}");
                return null;
            }
        }

        private async Task<List<ComparablePropertyData>> GetSimilarProperties(ValuationRequest request)
        {
            var comparables = new List<ComparablePropertyData>();

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
                    // Similar bedrooms (±1)
                    p.Bedrooms >= request.Bedrooms - 1 && p.Bedrooms <= request.Bedrooms + 1
                )
                .Take(30)
                .ToListAsync();

            foreach (var prop in properties)
            {
                var latestAuction = prop.Auctions
                    .Where(a => a.Status == "Closed")
                    .OrderByDescending(a => a.StartAt)
                    .FirstOrDefault();

                if (latestAuction != null)
                {
                    comparables.Add(new ComparablePropertyData
                    {
                        Name = prop.Name,
                        Location = prop.Location,
                        Bedrooms = prop.Bedrooms,
                        Bathrooms = prop.Bathrooms,
                        SquareFeet = prop.SquareFeet,
                        Price = (decimal)latestAuction.CurrentPrice,
                        Status = "Sold"
                    });
                }
            }

            return comparables;
        }

        private async Task<List<AuctionDataForValuation>> GetRelevantAuctions(ValuationRequest request)
        {
            var auctions = new List<AuctionDataForValuation>();

            // Get recent auctions for similar properties
            var minSqft = (int)(request.SquareFeet * 0.8);
            var maxSqft = (int)(request.SquareFeet * 1.2);

            var recentAuctions = await _context.Auctions
                .Include(a => a.Property)
                .Where(a => 
                    a.Property.SquareFeet >= minSqft && a.Property.SquareFeet <= maxSqft &&
                    a.Property.Bedrooms >= request.Bedrooms - 1 && a.Property.Bedrooms <= request.Bedrooms + 1 &&
                    a.StartAt >= DateTime.UtcNow.AddMonths(-6) // Last 6 months
                )
                .OrderByDescending(a => a.StartAt)
                .Take(20)
                .ToListAsync();

            foreach (var auction in recentAuctions)
            {
                auctions.Add(new AuctionDataForValuation
                {
                    PropertyName = auction.Property.Name,
                    Location = auction.Property.Location,
                    Bedrooms = auction.Property.Bedrooms,
                    Bathrooms = auction.Property.Bathrooms,
                    SquareFeet = auction.Property.SquareFeet,
                    CurrentPrice = auction.CurrentPrice,
                    Status = auction.Status,
                    BidCount = auction.BidCount
                });
            }

            return auctions;
        }
    }
}
