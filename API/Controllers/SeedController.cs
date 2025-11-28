using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using InstapropAPI.Services;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [AllowAnonymous] // Allow anonymous for local development
    public class SeedController : ControllerBase
    {
        private readonly GlobalSeedingService _seedingService;

        public SeedController(GlobalSeedingService seedingService)
        {
            _seedingService = seedingService;
        }

        // POST: api/Seed/data
        [HttpPost("data")]
        public async Task<ActionResult<object>> SeedData([FromQuery] bool skipClear = false)
        {
            try
            {
                Console.WriteLine("🌱 Starting data seeding...");
                await _seedingService.PreSeedTestDataAsync(skipClear: skipClear);
                
                return Ok(new
                {
                    success = true,
                    message = "Data seeding completed successfully"
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Seeding error: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                return StatusCode(500, new
                {
                    success = false,
                    error = ex.Message,
                    stackTrace = ex.StackTrace
                });
            }
        }
    }
}

