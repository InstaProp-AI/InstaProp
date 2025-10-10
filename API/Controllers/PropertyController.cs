using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using Microsoft.AspNetCore.Authorization;
using PropertyFlipperAPI.Attributes;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PropertyController : ControllerBase
    {
        private readonly AppDbContext _context;

        public PropertyController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Property (Public - only properties with auctions)
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Property>>> GetProperties()
        {
            return await _context.Properties
                .Where(p => p.Auctions.Any()) // Only properties that have auctions
                .Include(p => p.Owner)
                .Include(p => p.Auctions.Where(a => a.Status == "Active")) // Only active auctions
                .ToListAsync();
        }

        // GET: api/Property/all (Admin only - all properties)
        [HttpGet("all")]
        [Authorize]
        [AdminAuthorize]
        public async Task<ActionResult<IEnumerable<Property>>> GetAllProperties()
        {
            return await _context.Properties
                .Include(p => p.Owner)
                .Include(p => p.PropertyDocs)
                .Include(p => p.Auctions)
                .ToListAsync();
        }

        // GET: api/Property/my-properties (User's own properties)
        [HttpGet("my-properties")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<Property>>> GetMyProperties()
        {
            var userIdClaim = User.FindFirst("uid");
            if (userIdClaim == null || !long.TryParse(userIdClaim.Value, out long userId))
            {
                return BadRequest("Invalid user ID");
            }

            return await _context.Properties
                .Where(p => p.OwnerId == userId)
                .Include(p => p.PropertyDocs)
                .Include(p => p.Auctions)
                .ToListAsync();
        }

        // GET: api/Property/5
        [HttpGet("{id}")]
        public async Task<ActionResult<object>> GetProperty(int id)
        {
            var property = await _context.Properties
                .Include(p => p.Owner)
                .Include(p => p.Auctions)
                .Include(p => p.Project)
                .Include(p => p.PropertyDocs)
                .FirstOrDefaultAsync(p => p.PropertyId == id);

            if (property == null)
            {
                return NotFound();
            }

            // Return a DTO to avoid JsonIgnore issues and circular references
            return Ok(new
            {
                property.PropertyId,
                property.OwnerId,
                property.ProjectId,
                property.Name,
                property.Description,
                property.Location,
                Type = property.Type.ToString(),
                Status = property.Status.ToString(),
                property.Bedrooms,
                property.Bathrooms,
                property.SquareFeet,
                property.YearBuilt,
                property.Category,
                property.ImageUrl,
                property.CreatedAt,
                property.UpdatedAt,
                Owner = property.Owner != null ? new
                {
                    property.Owner.AccountId,
                    property.Owner.FirstName,
                    property.Owner.LastName,
                    property.Owner.Email,
                    property.Owner.PhoneNumber,
                    Type = property.Owner.Type.ToString(),
                    Status = property.Owner.Status.ToString(),
                    property.Owner.EmailVerified,
                    property.Owner.PhoneVerified
                } : null,
                Auctions = property.Auctions.Select(a => new
                {
                    a.AuctionId,
                    a.PropertyId,
                    a.StartPrice,
                    a.CurrentPrice,
                    a.StartAt,
                    a.Duration,
                    a.BuyNowPrice,
                    a.Status,
                    a.BidCount,
                    a.CreatedAt
                }).ToList(),
                Project = property.Project != null ? new
                {
                    property.Project.ProjectId,
                    property.Project.Name,
                    property.Project.Description,
                    property.Project.Location
                } : null,
                PropertyDocs = property.PropertyDocs.Select(d => new
                {
                    d.DocId,
                    d.PropertyId,
                    d.DocType,
                    d.ImgUrl,
                    d.UploadedAt
                }).ToList()
            });
        }

        // POST: api/Property 
        [HttpPost]
        [Authorize]
        public async Task<ActionResult<Property>> PostProperty(PropertyDto propertyDto)
        {
            // Get the current user ID from the JWT token
            var userIdClaim = User.FindFirst("uid");
            if (userIdClaim == null || !long.TryParse(userIdClaim.Value, out long userId))
            {
                return BadRequest("Invalid user ID");
            }

            // Get account to determine property type
            var account = await _context.Accounts.FindAsync(userId);
            if (account == null)
            {
                return BadRequest("Account not found");
            }

            // Determine property type based on account type
            var propertyType = account.Type == AccountType.Developer ? PropertyType.Primary : PropertyType.Resale;

            // Create Property entity from DTO
            var property = new Property
            {
                OwnerId = userId,
                ProjectId = propertyDto.ProjectId, // Optional for developers
                Name = propertyDto.Name,
                Description = propertyDto.Description,
                Location = propertyDto.Location,
                Type = propertyType,
                Bedrooms = propertyDto.Bedrooms,
                Bathrooms = propertyDto.Bathrooms,
                SquareFeet = propertyDto.SquareFeet,
                YearBuilt = propertyDto.YearBuilt,
                Category = propertyDto.Category,
                ImageUrl = propertyDto.ImageUrl ?? "",
                Status = PropertyStatus.NotApproved, // Default status
                CreatedAt = DateTime.UtcNow
            };

            _context.Properties.Add(property);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetProperty", new { id = property.PropertyId }, property);
        }

        // POST: api/Property/skip-documents
        [HttpPost("skip-documents")]
        [Authorize]
        public async Task<ActionResult<Property>> PostPropertySkipDocuments(PropertyDto propertyDto)
        {
            // Get the current user ID from the JWT token
            var userIdClaim = User.FindFirst("uid");
            if (userIdClaim == null || !long.TryParse(userIdClaim.Value, out long userId))
            {
                return BadRequest("Invalid user ID");
            }

            // Get account to determine property type
            var account = await _context.Accounts.FindAsync(userId);
            if (account == null)
            {
                return BadRequest("Account not found");
            }

            // Determine property type based on account type
            var propertyType = account.Type == AccountType.Developer ? PropertyType.Primary : PropertyType.Resale;

            // Create Property entity from DTO
            var property = new Property
            {
                OwnerId = userId,
                ProjectId = propertyDto.ProjectId, // Optional for developers
                Name = propertyDto.Name,
                Description = propertyDto.Description,
                Location = propertyDto.Location,
                Type = propertyType,
                Bedrooms = propertyDto.Bedrooms,
                Bathrooms = propertyDto.Bathrooms,
                SquareFeet = propertyDto.SquareFeet,
                YearBuilt = propertyDto.YearBuilt,
                Category = propertyDto.Category,
                ImageUrl = propertyDto.ImageUrl ?? "",
                Status = PropertyStatus.NotApproved, // Default status
                CreatedAt = DateTime.UtcNow
            };

            _context.Properties.Add(property);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetProperty", new { id = property.PropertyId }, property);
        }

        // PUT: api/Property/5
        [HttpPut("{id}")]
        [Authorize]
        public async Task<IActionResult> PutProperty(int id, [FromBody] PropertyUpdateDto updateDto)
        {
            // Check if property is editable (only before approval)
            var existingProperty = await _context.Properties.FindAsync(id);
            if (existingProperty == null)
                return NotFound();

            if (existingProperty.Status == PropertyStatus.Approved)
            {
                return BadRequest(new { message = "Property cannot be edited after approval" });
            }

            // Check if user owns the property (unless admin)
            var accountId = GetCurrentAccountId();
            var accountType = GetCurrentAccountType();
            
            if (accountId == null)
                return Unauthorized();

            if (accountType != "Admin" && existingProperty.OwnerId != accountId)
            {
                return StatusCode(403, new { message = "You can only edit your own properties" });
            }

            // Update only the allowed fields
            existingProperty.Name = updateDto.Name;
            existingProperty.Description = updateDto.Description;
            existingProperty.Location = updateDto.Location;
            existingProperty.UpdatedAt = DateTime.UtcNow;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!PropertyExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return Ok(existingProperty);
        }

        // DELETE: api/Property/5
        [HttpDelete("{id}")]
        [Authorize]
        public async Task<IActionResult> DeleteProperty(int id)
        {
            var property = await _context.Properties
                .Include(p => p.Auctions)
                .FirstOrDefaultAsync(p => p.PropertyId == id);
                
            if (property == null)
            {
                return NotFound();
            }

            // Check if user owns the property (unless admin)
            var accountId = GetCurrentAccountId();
            var accountType = GetCurrentAccountType();
            
            if (accountId == null)
                return Unauthorized();

            if (accountType != "Admin" && property.OwnerId != accountId)
            {
                return StatusCode(403, new { message = "You can only delete your own properties" });
            }

            // Check if property has any active or pending auctions
            var hasActiveAuction = property.Auctions.Any(a => 
                a.Status == "Active" || 
                a.Status == "Requested" || 
                a.Status == "Approved");
            
            if (hasActiveAuction)
            {
                return BadRequest(new { message = "Cannot delete property. It is currently in auction or has a pending auction request." });
            }

            _context.Properties.Remove(property);
            await _context.SaveChangesAsync();

            return NoContent();
        }


        // PUT: api/Property/5/approve
        [HttpPut("{id}/approve")]
        [Authorize]
        [AdminAuthorize]
        public async Task<IActionResult> ApproveProperty(int id)
        {
            var property = await _context.Properties.FindAsync(id);
            if (property == null)
            {
                return NotFound();
            }

            // Check if property has documents before approval
            var hasDocuments = await _context.PropertyDocs
                .AnyAsync(d => d.PropertyId == id);
            
            if (!hasDocuments)
            {
                return BadRequest(new { message = "Property must have documents before approval" });
            }

            // Approve property
            property.Status = PropertyStatus.Approved;
            property.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Property approved successfully" });
        }

        // POST: api/Property/{id}/documents
        [HttpPost("{id}/documents")]
        [Authorize]
        public async Task<ActionResult> UploadPropertyDocument(long id, [FromBody] PropertyDocUploadDto docDto)
        {
            var property = await _context.Properties.FindAsync(id);
            if (property == null)
                return NotFound();

            // Check if user owns the property
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            if (property.OwnerId != accountId)
                return StatusCode(403, new { message = "You can only upload documents for your own properties" });

            // Change status to Pending when first document is uploaded
            if (property.Status == PropertyStatus.NotApproved)
            {
                property.Status = PropertyStatus.Pending;
                property.UpdatedAt = DateTime.UtcNow;
            }

            // Check if document type already exists for this property
            var existingDoc = await _context.PropertyDocs
                .FirstOrDefaultAsync(d => d.PropertyId == id && d.DocType == docDto.DocType);

            if (existingDoc != null)
            {
                // Update existing document
                existingDoc.ImgUrl = docDto.ImageUrl;
                existingDoc.UploadedAt = DateTime.UtcNow;
            }
            else
            {
                // Create new document
                var propertyDoc = new PropertyDoc
                {
                    PropertyId = id,
                    DocType = docDto.DocType,
                    ImgUrl = docDto.ImageUrl,
                    UploadedAt = DateTime.UtcNow
                };
                _context.PropertyDocs.Add(propertyDoc);
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Property document uploaded successfully" });
        }

        // GET: api/Property/{id}/documents
        [HttpGet("{id}/documents")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<PropertyDoc>>> GetPropertyDocuments(long id)
        {
            var property = await _context.Properties.FindAsync(id);
            if (property == null)
                return NotFound();

            var documents = await _context.PropertyDocs
                .Where(d => d.PropertyId == id)
                .ToListAsync();

            return Ok(documents);
        }

        // PUT: api/Property/{id}/verify (DEPRECATED - use /approve instead)
        // This endpoint is kept for backward compatibility but redirects to approve
        [HttpPut("{id}/verify")]
        [Authorize]
        [AdminAuthorize]
        public async Task<IActionResult> VerifyProperty(long id)
        {
            // Redirect to ApproveProperty method
            return await ApproveProperty((int)id);
        }

        private bool PropertyExists(int id)
        {
            return _context.Properties.Any(e => e.PropertyId == id);
        }

        private long? GetCurrentAccountId()
        {
            var uidClaim = User.FindFirst("uid");
            return uidClaim != null ? long.Parse(uidClaim.Value) : null;
        }

        private string? GetCurrentAccountType()
        {
            var typeClaim = User.FindFirst("type");
            return typeClaim?.Value;
        }

        // POST: api/Property/estimate (Public - simple property valuation)
        [HttpPost("estimate")]
        public ActionResult<object> EstimateProperty([FromBody] PropertyEstimateDto estimateDto)
        {
            // Simple estimation algorithm based on basic factors
            double basePrice = 0;
            
            // Base price by location (simplified)
            var location = estimateDto.Location.ToLower();
            if (location.Contains("manhattan") || location.Contains("beverly hills") || location.Contains("miami beach"))
                basePrice = 800000; // High-end areas
            else if (location.Contains("downtown") || location.Contains("city center"))
                basePrice = 500000; // Urban areas
            else if (location.Contains("suburb") || location.Contains("residential"))
                basePrice = 350000; // Suburban areas
            else
                basePrice = 250000; // Default

            // Adjust by bedrooms
            basePrice += (estimateDto.Bedrooms - 1) * 50000;

            // Adjust by bathrooms
            basePrice += (estimateDto.Bathrooms - 1) * 30000;

            // Adjust by square feet
            basePrice += (estimateDto.SquareFeet - 1000) * 100;

            // Adjust by year built (newer = more expensive)
            var currentYear = DateTime.Now.Year;
            var age = currentYear - estimateDto.YearBuilt;
            if (age < 5) basePrice *= 1.2;
            else if (age < 10) basePrice *= 1.1;
            else if (age > 30) basePrice *= 0.9;

            var estimatedValue = Math.Max(basePrice, 100000); // Minimum $100k

            return Ok(new {
                estimatedValue = Math.Round(estimatedValue, 2),
                confidence = "Low - Basic estimation only",
                message = "For detailed valuation with market analysis, please log in",
                factors = new {
                    location = estimateDto.Location,
                    bedrooms = estimateDto.Bedrooms,
                    bathrooms = estimateDto.Bathrooms,
                    squareFeet = estimateDto.SquareFeet,
                    yearBuilt = estimateDto.YearBuilt
                }
            });
        }
    }

    public class PropertyDocUploadDto
    {
        public string DocType { get; set; } = string.Empty; // Ownership, Legal, FloorPlan, etc.
        public string ImageUrl { get; set; } = string.Empty;
    }

    public class PropertyEstimateDto
    {
        public string Location { get; set; } = string.Empty;
        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public int SquareFeet { get; set; }
        public int YearBuilt { get; set; }
    }
}
