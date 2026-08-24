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
        private readonly DemoPropertySeedingService _demoPropertySeedingService;

        public SeedController(
            GlobalSeedingService seedingService,
            DemoPropertySeedingService demoPropertySeedingService)
        {
            _seedingService = seedingService;
            _demoPropertySeedingService = demoPropertySeedingService;
        }

        // POST: api/Seed/properties — wipe non-Egyptian market data and seed Egypt-only demo
        [HttpPost("properties")]
        public async Task<ActionResult<object>> SeedDemoProperties()
        {
            try
            {
                Console.WriteLine("🇪🇬 Resetting and seeding Egypt-only market...");
                var result = await _demoPropertySeedingService.ResetAndSeedEgyptianMarketAsync();

                return Ok(new
                {
                    success = true,
                    message = "Egypt-only market seeded successfully",
                    developers = result.Developers,
                    projects = result.Projects,
                    properties = result.Properties,
                    images = result.Images,
                    auctions = result.Auctions
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Demo property seeding error: {ex.Message}");
                return StatusCode(500, new
                {
                    success = false,
                    error = ex.Message,
                    stackTrace = ex.StackTrace
                });
            }
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

