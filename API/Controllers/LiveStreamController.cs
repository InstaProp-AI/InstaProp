using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using System.Security.Claims;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LiveStreamController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly ILogger<LiveStreamController> _logger;

        public LiveStreamController(AppDbContext context, ILogger<LiveStreamController> logger)
        {
            _context = context;
            _logger = logger;
        }

        private Guid? GetCurrentAccountId()
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim != null && Guid.TryParse(accountIdClaim.Value, out var guid))
                return guid;
            return null;
        }

        // POST: api/livestream/start
        [HttpPost("start")]
        [Authorize]
        public async Task<ActionResult<LiveStreamDto>> StartStream([FromBody] StartStreamRequest request)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null || account.RoleId != Role.DEVELOPER_ROLE_ID) // SECURITY: Check non-guessable RoleId
                return Forbid();

            var stream = new LiveStream
            {
                DeveloperId = accountId.Value,
                Title = request.Title,
                Description = request.Description,
                StreamUrl = request.StreamUrl,
                ThumbnailUrl = request.ThumbnailUrl,
                Status = "Live",
                StartTime = DateTime.UtcNow,
                ViewerCount = 0,
                CreatedAt = DateTime.UtcNow
            };

            _context.LiveStreams.Add(stream);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Developer {DeveloperId} started stream {StreamId}", accountId.Value, stream.StreamId);

            return Ok(MapToDto(stream, accountId));
        }

        // POST: api/livestream/end/{id}
        [HttpPost("end/{id}")]
        [Authorize]
        public async Task<ActionResult> EndStream(Guid id)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var stream = await _context.LiveStreams
                .FirstOrDefaultAsync(s => s.StreamId == id);

            if (stream == null)
                return NotFound("Stream not found");

            if (stream.DeveloperId != accountId.Value)
                return Forbid("You can only end your own streams");

            stream.Status = "Ended";
            stream.EndTime = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            _logger.LogInformation("Stream {StreamId} ended by developer {DeveloperId}", id, accountId.Value);

            return Ok(new { message = "Stream ended successfully" });
        }

        // POST: api/livestream/{id}/chat
        [HttpPost("{id}/chat")]
        [Authorize]
        public async Task<ActionResult<StreamChatMessageDto>> SendChatMessage(Guid id, [FromBody] SendChatMessageRequest request)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var stream = await _context.LiveStreams
                .FirstOrDefaultAsync(s => s.StreamId == id);

            if (stream == null)
                return NotFound("Stream not found");

            if (stream.Status != "Live")
                return BadRequest("Stream is not live");

            // Verify user is viewing the stream
            var isViewing = await _context.StreamViewers
                .AnyAsync(v => v.StreamId == id && v.UserId == accountId.Value && v.LeftAt == null);

            if (!isViewing)
                return BadRequest("You must be viewing the stream to send messages");

            var message = new StreamChatMessage
            {
                StreamId = id,
                UserId = accountId.Value,
                Message = request.Message,
                CreatedAt = DateTime.UtcNow
            };

            _context.StreamChatMessages.Add(message);
            await _context.SaveChangesAsync();

            // Load user for response
            await _context.Entry(message)
                .Reference(m => m.User)
                .LoadAsync();

            return Ok(new StreamChatMessageDto
            {
                MessageId = message.MessageId,
                StreamId = message.StreamId,
                UserId = message.UserId,
                UserName = $"{message.User.FirstName} {message.User.LastName}",
                UserProfileImageUrl = null, // Account model doesn't have ProfileImageUrl
                Message = message.Message,
                CreatedAt = message.CreatedAt
            });
        }

        // GET: api/livestream/{id}/chat
        [HttpGet("{id}/chat")]
        public async Task<ActionResult<IEnumerable<StreamChatMessageDto>>> GetChatMessages(
            Guid id,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 50)
        {
            var stream = await _context.LiveStreams
                .FirstOrDefaultAsync(s => s.StreamId == id);

            if (stream == null)
                return NotFound("Stream not found");

            var messages = await _context.StreamChatMessages
                .Include(m => m.User)
                .Where(m => m.StreamId == id)
                .OrderByDescending(m => m.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var dtos = messages.Select(m => new StreamChatMessageDto
            {
                MessageId = m.MessageId,
                StreamId = m.StreamId,
                UserId = m.UserId,
                UserName = $"{m.User.FirstName} {m.User.LastName}",
                UserProfileImageUrl = null, // Account model doesn't have ProfileImageUrl
                Message = m.Message,
                CreatedAt = m.CreatedAt
            }).ToList();

            return Ok(dtos);
        }

        // POST: api/livestream/seed-test-data
        // Creates test live streams for development/demo purposes
        [HttpPost("seed-test-data")]
        [AllowAnonymous]
        public async Task<ActionResult<string>> SeedTestLiveStreams()
        {
            try
            {
                // Get first developer account
                var developer = await _context.Accounts
                    .Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID)
                    .FirstOrDefaultAsync();

                if (developer == null)
                {
                    return BadRequest("No developer accounts found. Please create a developer account first.");
                }

                // Check if test streams already exist
                var existingCount = await _context.LiveStreams
                    .Where(s => s.Status == "Live")
                    .CountAsync();

                if (existingCount > 0)
                {
                    return Ok($"Test live streams already exist ({existingCount} streams with Status='Live'). No new streams created.");
                }

                var now = DateTime.UtcNow;
                var random = new Random();
                var liveStreams = new List<LiveStream>();

                var streamTitles = new[]
                {
                    "Exclusive Property Tour - New Cairo Development",
                    "Live Q&A: Investment Opportunities in Dubai",
                    "Virtual Property Showcase - Luxury Apartments"
                };

                var streamDescriptions = new[]
                {
                    "Join us for an exclusive tour of our latest development project in New Cairo. See the properties, amenities, and ask questions in real-time!",
                    "Get expert insights on the best investment opportunities in Dubai's real estate market. Ask our team anything!",
                    "Experience luxury living with our virtual property showcase. See stunning apartments with premium finishes and world-class amenities."
                };

                var streamUrls = new[]
                {
                    "https://example.com/stream/new-cairo-tour",
                    "https://example.com/stream/dubai-investment-qa",
                    "https://example.com/stream/luxury-apartments"
                };

                var thumbnailUrls = new[]
                {
                    "https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800",
                    "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800",
                    "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800"
                };

                for (int i = 0; i < 3; i++)
                {
                    var startTime = now.AddHours(-random.Next(0, 2)); // Started 0-2 hours ago
                    var viewerCount = random.Next(50, 500);

                    var stream = new LiveStream
                    {
                        StreamId = Guid.NewGuid(),
                        DeveloperId = developer.AccountId,
                        Title = streamTitles[i],
                        Description = streamDescriptions[i],
                        StreamUrl = streamUrls[i],
                        ThumbnailUrl = thumbnailUrls[i],
                        Status = "Live",
                        ViewerCount = viewerCount,
                        StartTime = startTime,
                        EndTime = null,
                        CreatedAt = startTime
                    };

                    liveStreams.Add(stream);
                }

                await _context.LiveStreams.AddRangeAsync(liveStreams);
                await _context.SaveChangesAsync();

                _logger.LogInformation("Created {Count} test live streams", liveStreams.Count);
                return Ok($"Successfully created {liveStreams.Count} test live streams.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error seeding test live streams");
                return StatusCode(500, $"Error creating test live streams: {ex.Message}");
            }
        }

        // GET: api/livestream/active
        [AllowAnonymous]
        [HttpGet("active")]
        public async Task<ActionResult<IEnumerable<LiveStreamDto>>> GetActiveStreams()
        {
            var accountId = GetCurrentAccountId();

            var streams = await _context.LiveStreams
                .Include(s => s.Developer)
                .Where(s => s.Status == "Live")
                .OrderByDescending(s => s.StartTime)
                .ToListAsync();

            var result = streams.Select(s => MapToDto(s, accountId));
            return Ok(result);
        }

        // GET: api/livestream/count
        [AllowAnonymous]
        [HttpGet("count")]
        public async Task<ActionResult<int>> GetLiveStreamCount()
        {
            var count = await _context.LiveStreams
                .Where(s => s.Status == "Live")
                .CountAsync();

            return Ok(count);
        }

        // GET: api/livestream/all
        [AllowAnonymous]
        [HttpGet("all")]
        public async Task<ActionResult<IEnumerable<LiveStreamDto>>> GetAllStreams()
        {
            var accountId = GetCurrentAccountId();

            var streams = await _context.LiveStreams
                .Include(s => s.Developer)
                .OrderByDescending(s => s.StartTime)
                .ToListAsync();

            var result = streams.Select(s => MapToDto(s, accountId));
            return Ok(result);
        }

        // GET: api/livestream/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<LiveStreamDto>> GetStream(Guid id)
        {
            var accountId = GetCurrentAccountId();

            var stream = await _context.LiveStreams
                .Include(s => s.Developer)
                .FirstOrDefaultAsync(s => s.StreamId == id);

            if (stream == null)
                return NotFound("Stream not found");

            return Ok(MapToDto(stream, accountId));
        }

        // POST: api/livestream/{id}/join
        [HttpPost("{id}/join")]
        [Authorize]
        public async Task<ActionResult> JoinStream(Guid id)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var stream = await _context.LiveStreams.FindAsync(id);
            if (stream == null)
                return NotFound("Stream not found");

            if (stream.Status != "Live")
                return BadRequest("Stream is not live");

            // Check if user already joined
            var existingViewer = await _context.StreamViewers
                .FirstOrDefaultAsync(v => v.StreamId == id && v.UserId == accountId.Value && v.LeftAt == null);

            if (existingViewer == null)
            {
                // Add viewer
                var viewer = new StreamViewer
                {
                    StreamId = id,
                    UserId = accountId.Value,
                    JoinedAt = DateTime.UtcNow
                };
                _context.StreamViewers.Add(viewer);

                // Increment viewer count
                stream.ViewerCount++;
                await _context.SaveChangesAsync();
            }

            return Ok(new { message = "Joined stream successfully", viewerCount = stream.ViewerCount });
        }

        // POST: api/livestream/{id}/leave
        [HttpPost("{id}/leave")]
        [Authorize]
        public async Task<ActionResult> LeaveStream(Guid id)
        {
            var accountId = GetCurrentAccountId();
            if (!accountId.HasValue)
                return Unauthorized();

            var viewer = await _context.StreamViewers
                .FirstOrDefaultAsync(v => v.StreamId == id && v.UserId == accountId.Value && v.LeftAt == null);

            if (viewer != null)
            {
                viewer.LeftAt = DateTime.UtcNow;

                var stream = await _context.LiveStreams.FindAsync(id);
                if (stream != null && stream.ViewerCount > 0)
                {
                    stream.ViewerCount--;
                }

                await _context.SaveChangesAsync();
            }

            return Ok(new { message = "Left stream successfully" });
        }

        private LiveStreamDto MapToDto(LiveStream stream, Guid? accountId)
        {
            return new LiveStreamDto
            {
                StreamId = stream.StreamId,
                DeveloperId = stream.DeveloperId,
                DeveloperName = $"{stream.Developer?.FirstName} {stream.Developer?.LastName}",
                DeveloperProfileImageUrl = null, // Add if available in Account model
                Title = stream.Title,
                Description = stream.Description,
                StreamUrl = stream.StreamUrl,
                ThumbnailUrl = stream.ThumbnailUrl,
                Status = stream.Status,
                ViewerCount = stream.ViewerCount,
                StartTime = stream.StartTime,
                EndTime = stream.EndTime,
                CreatedAt = stream.CreatedAt
            };
        }
    }

    public class StartStreamRequest
    {
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string StreamUrl { get; set; } = string.Empty;
        public string? ThumbnailUrl { get; set; }
    }

    public class LiveStreamDto
    {
        public Guid StreamId { get; set; }
        public Guid DeveloperId { get; set; }
        public string DeveloperName { get; set; } = string.Empty;
        public string? DeveloperProfileImageUrl { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string StreamUrl { get; set; } = string.Empty;
        public string? ThumbnailUrl { get; set; }
        public string Status { get; set; } = string.Empty;
        public int ViewerCount { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime? EndTime { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class SendChatMessageRequest
    {
        public string Message { get; set; } = string.Empty;
    }

    public class StreamChatMessageDto
    {
        public Guid MessageId { get; set; }
        public Guid StreamId { get; set; }
        public Guid UserId { get; set; }
        public string UserName { get; set; } = string.Empty;
        public string? UserProfileImageUrl { get; set; }
        public string Message { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }
}

