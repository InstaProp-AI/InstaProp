using Microsoft.AspNetCore.Mvc;
using PropertyFlipperAPI.Data;
using Microsoft.EntityFrameworkCore;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TestController : ControllerBase
    {
        private readonly AppDbContext _context;

        public TestController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("database")]
        public async Task<IActionResult> TestDatabase()
        {
            try
            {
                // Test database connection
                var userCount = await _context.Users.CountAsync();
                var propertyCount = await _context.Properties.CountAsync();
                var auctionCount = await _context.Auctions.CountAsync();

                return Ok(new
                {
                    message = "Database connection successful",
                    userCount,
                    propertyCount,
                    auctionCount,
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new
                {
                    message = "Database connection failed",
                    error = ex.Message,
                    timestamp = DateTime.UtcNow
                });
            }
        }

        [HttpGet("seed")]
        public async Task<IActionResult> SeedData()
        {
            try
            {
                // Clear existing data first
                _context.Users.RemoveRange(_context.Users);
                _context.Properties.RemoveRange(_context.Properties);
                _context.Auctions.RemoveRange(_context.Auctions);
                _context.Bids.RemoveRange(_context.Bids);
                await _context.SaveChangesAsync();

                var seedService = new Services.SeedDataService(_context);
                await seedService.SeedDataAsync();

                return Ok(new
                {
                    message = "Data seeded successfully",
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new
                {
                    message = "Seeding failed",
                    error = ex.Message,
                    stackTrace = ex.StackTrace,
                    timestamp = DateTime.UtcNow
                });
            }
        }
    }
}