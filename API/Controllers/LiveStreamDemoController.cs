using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Extensions;
using System.Security.Claims;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LiveStreamDemoController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly ILogger<LiveStreamDemoController> _logger;

        public LiveStreamDemoController(AppDbContext context, ILogger<LiveStreamDemoController> logger)
        {
            _context = context;
            _logger = logger;
        }

        // POST: api/livestreamdemo/create
        [HttpPost("create")]
        [Authorize(Roles = "Admin,Developer")]
        public async Task<ActionResult> CreateDemoStreams()
        {
            // Get first developer account for demo
            var developer = await _context.Accounts
                .FirstOrDefaultAsync(a => a.RoleId == Role.DEVELOPER_ROLE_ID); // SECURITY: Check non-guessable RoleId

            if (developer == null)
                return BadRequest("No developer account found. Please create a developer account first.");

            var demoStreams = new List<LiveStream>
            {
                new LiveStream
                {
                    DeveloperId = developer.AccountId,
                    Title = "Property Investment Tips & Strategies",
                    Description = "Join us for live tips on real estate investment strategies and market insights.",
                    StreamUrl = "https://demo-stream-url-1.com",
                    ThumbnailUrl = "https://via.placeholder.com/800x450.png?text=Property+Investment",
                    Status = "Live",
                    ViewerCount = 45,
                    StartTime = DateTime.UtcNow.AddHours(-1),
                    CreatedAt = DateTime.UtcNow.AddHours(-1),
                },
                new LiveStream
                {
                    DeveloperId = developer.AccountId,
                    Title = "New Development Project Preview",
                    Description = "Exclusive first look at our upcoming residential complex in New Cairo.",
                    StreamUrl = "https://demo-stream-url-2.com",
                    ThumbnailUrl = "https://via.placeholder.com/800x450.png?text=New+Development",
                    Status = "Scheduled",
                    ViewerCount = 0,
                    StartTime = DateTime.UtcNow.AddHours(2),
                    CreatedAt = DateTime.UtcNow.AddDays(-1),
                },
                new LiveStream
                {
                    DeveloperId = developer.AccountId,
                    Title = "Market Analysis Q&A Session",
                    Description = "Ask us anything about the current real estate market trends.",
                    StreamUrl = "https://demo-stream-url-3.com",
                    ThumbnailUrl = "https://via.placeholder.com/800x450.png?text=Market+Analysis",
                    Status = "Ended",
                    ViewerCount = 128,
                    StartTime = DateTime.UtcNow.AddDays(-2),
                    EndTime = DateTime.UtcNow.AddDays(-2).AddHours(2),
                    CreatedAt = DateTime.UtcNow.AddDays(-2),
                },
            };

            _context.LiveStreams.AddRange(demoStreams);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Created {Count} demo live streams", demoStreams.Count);

            return Ok(new
            {
                message = $"Created {demoStreams.Count} demo live streams successfully",
                streams = demoStreams.Select(s => new
                {
                    streamId = s.StreamId,
                    title = s.Title,
                    status = s.Status,
                }).ToList()
            });
        }
    }
}

