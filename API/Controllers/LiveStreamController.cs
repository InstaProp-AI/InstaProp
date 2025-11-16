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

        private long? GetCurrentAccountId()
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim != null && long.TryParse(accountIdClaim.Value, out long accountId))
                return accountId;
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
            if (account == null || account.Type != AccountType.Developer)
                return Forbid("Only developers can start live streams");

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
        public async Task<ActionResult> EndStream(long id)
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
        public async Task<ActionResult<StreamChatMessageDto>> SendChatMessage(long id, [FromBody] SendChatMessageRequest request)
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
            long id,
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

        // GET: api/livestream/active
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

        // GET: api/livestream/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<LiveStreamDto>> GetStream(long id)
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
        public async Task<ActionResult> JoinStream(long id)
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
        public async Task<ActionResult> LeaveStream(long id)
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

        private LiveStreamDto MapToDto(LiveStream stream, long? accountId)
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
        public long StreamId { get; set; }
        public long DeveloperId { get; set; }
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
        public long MessageId { get; set; }
        public long StreamId { get; set; }
        public long UserId { get; set; }
        public string UserName { get; set; } = string.Empty;
        public string? UserProfileImageUrl { get; set; }
        public string Message { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }
}

