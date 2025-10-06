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

        // GET: api/Property
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Property>>> GetProperties()
        {
            return await _context.Properties
                .Include(p => p.Owner)
                .ToListAsync();
        }

        // GET: api/Property/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Property>> GetProperty(int id)
        {
            var property = await _context.Properties
                .Include(p => p.Owner)
                .FirstOrDefaultAsync(p => p.PropertyId == id);

            if (property == null)
            {
                return NotFound();
            }

            return property;
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
                StartingPrice = propertyDto.StartingPrice,
                Type = propertyType,
                Bedrooms = propertyDto.Bedrooms,
                Bathrooms = propertyDto.Bathrooms,
                SquareFeet = propertyDto.SquareFeet,
                YearBuilt = propertyDto.YearBuilt,
                Category = propertyDto.Category,
                ImageUrl = propertyDto.ImageUrl,
                IsVerified = false, // Will be verified by admin
                IsEditable = true, // Can be edited until verified
                CreatedAt = DateTime.UtcNow
            };

            _context.Properties.Add(property);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetProperty", new { id = property.PropertyId }, property);
        }

        // PUT: api/Property/5
        [HttpPut("{id}")]
        [Authorize]
        public async Task<IActionResult> PutProperty(int id, Property property)
        {
            if (id != property.PropertyId)
            {
                return BadRequest();
            }

            // Check if property is editable (only before verification)
            var existingProperty = await _context.Properties.FindAsync(id);
            if (existingProperty == null)
                return NotFound();

            if (!existingProperty.IsEditable)
            {
                return BadRequest(new { message = "Property cannot be edited after verification" });
            }

            // Check if user owns the property (unless admin)
            var accountId = GetCurrentAccountId();
            var accountType = GetCurrentAccountType();
            
            if (accountId == null)
                return Unauthorized();

            if (accountType != "Admin" && existingProperty.OwnerId != accountId)
            {
                return Forbid("You can only edit your own properties");
            }

            property.UpdatedAt = DateTime.UtcNow;
            _context.Entry(property).State = EntityState.Modified;

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

            return NoContent();
        }

        // DELETE: api/Property/5
        [HttpDelete("{id}")]
        [Authorize]
        [AdminAuthorize]
        public async Task<IActionResult> DeleteProperty(int id)
        {
            var property = await _context.Properties.FindAsync(id);
            if (property == null)
            {
                return NotFound();
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

            property.IsApproved = true;
            await _context.SaveChangesAsync();

            return NoContent();
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
                return Forbid("You can only upload documents for your own properties");

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

        // PUT: api/Property/{id}/verify
        [HttpPut("{id}/verify")]
        [Authorize]
        [AdminAuthorize]
        public async Task<ActionResult> VerifyProperty(long id)
        {
            var property = await _context.Properties.FindAsync(id);
            if (property == null)
                return NotFound();

            // Verify property and make it non-editable
            property.IsVerified = true;
            property.IsEditable = false;
            property.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Property verified successfully" });
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
    }

    public class PropertyDocUploadDto
    {
        public string DocType { get; set; } = string.Empty; // Ownership, Legal, FloorPlan, etc.
        public string ImageUrl { get; set; } = string.Empty;
    }
}
