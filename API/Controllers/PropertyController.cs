using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;

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
        public async Task<ActionResult<Property>> PostProperty(PropertyDto propertyDto)
        {
            // Get the current user ID from the JWT token
            var userIdClaim = User.FindFirst("uid");
            if (userIdClaim == null)
            {
                return Unauthorized("User not authenticated");
            }

            if (!long.TryParse(userIdClaim.Value, out long userId))
            {
                return BadRequest("Invalid user ID");
            }

            // Create Property entity from DTO
            var property = new Property
            {
                OwnerId = userId,
                Name = propertyDto.Name,
                Description = propertyDto.Description,
                Location = propertyDto.Location,
                StartingPrice = propertyDto.StartingPrice,
                Bedrooms = propertyDto.Bedrooms,
                Bathrooms = propertyDto.Bathrooms,
                SquareFeet = propertyDto.SquareFeet,
                YearBuilt = propertyDto.YearBuilt,
                Category = propertyDto.Category,
                ImageUrl = propertyDto.ImageUrl,
                CreatedAt = DateTime.UtcNow
            };

            _context.Properties.Add(property);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetProperty", new { id = property.PropertyId }, property);
        }

        // PUT: api/Property/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutProperty(int id, Property property)
        {
            if (id != property.PropertyId)
            {
                return BadRequest();
            }

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

        // GET: api/Property/user/5
        [HttpGet("user/{userId}")]
        public async Task<ActionResult<IEnumerable<Property>>> GetUserProperties(int userId)
        {
            return await _context.Properties
                .Where(p => p.OwnerId == userId)
                .Include(p => p.Owner)
                .ToListAsync();
        }

        // GET: api/Property/approved
        [HttpGet("approved")]
        public async Task<ActionResult<IEnumerable<Property>>> GetApprovedProperties()
        {
            return await _context.Properties
                .Where(p => p.IsApproved)
                .Include(p => p.Owner)
                .ToListAsync();
        }

        // PUT: api/Property/5/approve
        [HttpPut("{id}/approve")]
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

        private bool PropertyExists(int id)
        {
            return _context.Properties.Any(e => e.PropertyId == id);
        }
    }
}
