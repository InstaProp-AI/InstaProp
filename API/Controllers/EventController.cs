using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using PropertyFlipperAPI.Attributes;

namespace PropertyFlipperAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EventController : ControllerBase
    {
        private readonly AppDbContext _context;

        public EventController(AppDbContext context)
        {
            _context = context;
        }

        // Helper method to get current user ID
        private long? GetCurrentAccountId()
        {
            var userIdClaim = User.FindFirst("uid");
            if (userIdClaim != null && long.TryParse(userIdClaim.Value, out long userId))
            {
                return userId;
            }
            return null;
        }

        // GET: api/Event
        [HttpGet]
        [Authorize]
        public async Task<ActionResult<IEnumerable<EventDto>>> GetEvents()
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            var events = await _context.Events
                .Where(e => e.UserId == userId || e.IsPublic)
                .OrderBy(e => e.EventDate)
                .ToListAsync();

            var eventDtos = events.Select(EventDto.FromEvent).ToList();
            return eventDtos;
        }

        // GET: api/Event/5
        [HttpGet("{id}")]
        [Authorize]
        public async Task<ActionResult<EventDto>> GetEvent(long id)
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            var eventEntity = await _context.Events
                .FirstOrDefaultAsync(e => e.EventId == id && e.UserId == userId);

            if (eventEntity == null)
                return NotFound();

            return EventDto.FromEvent(eventEntity);
        }

        // GET: api/Event/month/{year}/{month}
        [HttpGet("month/{year}/{month}")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<EventDto>>> GetEventsByMonth(int year, int month)
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            var startDate = new DateTime(year, month, 1, 0, 0, 0, DateTimeKind.Utc);
            var endDate = startDate.AddMonths(1).AddDays(-1).Date;

            var events = await _context.Events
                .Where(e => (e.UserId == userId || e.IsPublic) && 
                           e.EventDate.Date >= startDate.Date && 
                           e.EventDate.Date <= endDate.Date)
                .OrderBy(e => e.EventDate)
                .ToListAsync();

            var eventDtos = events.Select(EventDto.FromEvent).ToList();
            return eventDtos;
        }

        // GET: api/Event/today
        [HttpGet("today")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<EventDto>>> GetTodaysEvents()
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            var today = DateTime.UtcNow.Date;

            var events = await _context.Events
                .Where(e => (e.UserId == userId || e.IsPublic) && e.EventDate.Date == today)
                .OrderBy(e => e.StartTime ?? e.EventDate)
                .ToListAsync();

            var eventDtos = events.Select(EventDto.FromEvent).ToList();
            return eventDtos;
        }

        // GET: api/Event/upcoming
        [HttpGet("upcoming")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<EventDto>>> GetUpcomingEvents()
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            var now = DateTime.UtcNow;

            var events = await _context.Events
                .Where(e => (e.UserId == userId || e.IsPublic) && 
                           e.EventDate >= now &&
                           !e.IsCompleted)
                .OrderBy(e => e.EventDate)
                .Take(10)
                .ToListAsync();

            var eventDtos = events.Select(EventDto.FromEvent).ToList();
            return eventDtos;
        }

        // POST: api/Event
        [HttpPost]
        [Authorize]
        public async Task<ActionResult<EventDto>> PostEvent(EventCreateDto eventDto)
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            var eventEntity = new Event
            {
                UserId = userId.Value,
                Title = eventDto.Title,
                Description = eventDto.Description,
                EventDate = eventDto.EventDate,
                Type = eventDto.Type,
                Location = eventDto.Location,
                IsAllDay = eventDto.IsAllDay,
                StartTime = eventDto.StartTime,
                EndTime = eventDto.EndTime,
                IsCompleted = false,
                IsReminderSet = eventDto.IsReminderSet,
                ReminderMinutes = eventDto.ReminderMinutes,
                PropertyId = eventDto.PropertyId,
                AuctionId = eventDto.AuctionId,
                BidId = eventDto.BidId,
                CreatedAt = DateTime.UtcNow
            };

            _context.Events.Add(eventEntity);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetEvent", new { id = eventEntity.EventId }, EventDto.FromEvent(eventEntity));
        }

        // PUT: api/Event/5
        [HttpPut("{id}")]
        [Authorize]
        public async Task<IActionResult> PutEvent(long id, EventUpdateDto eventDto)
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            var eventEntity = await _context.Events
                .FirstOrDefaultAsync(e => e.EventId == id && e.UserId == userId);

            if (eventEntity == null)
                return NotFound();

            eventEntity.Title = eventDto.Title;
            eventEntity.Description = eventDto.Description;
            eventEntity.EventDate = eventDto.EventDate;
            eventEntity.Type = eventDto.Type;
            eventEntity.Location = eventDto.Location;
            eventEntity.IsAllDay = eventDto.IsAllDay;
            eventEntity.StartTime = eventDto.StartTime;
            eventEntity.EndTime = eventDto.EndTime;
            eventEntity.IsCompleted = eventDto.IsCompleted;
            eventEntity.IsReminderSet = eventDto.IsReminderSet;
            eventEntity.ReminderMinutes = eventDto.ReminderMinutes;
            eventEntity.UpdatedAt = DateTime.UtcNow;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!EventExists(id))
                    return NotFound();
                throw;
            }

            return NoContent();
        }

        // PUT: api/Event/5/complete
        [HttpPut("{id}/complete")]
        [Authorize]
        public async Task<IActionResult> CompleteEvent(long id)
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            var eventEntity = await _context.Events
                .FirstOrDefaultAsync(e => e.EventId == id && e.UserId == userId);

            if (eventEntity == null)
                return NotFound();

            eventEntity.IsCompleted = true;
            eventEntity.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return NoContent();
        }

        // DELETE: api/Event/5
        [HttpDelete("{id}")]
        [Authorize]
        public async Task<IActionResult> DeleteEvent(long id)
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            var eventEntity = await _context.Events
                .FirstOrDefaultAsync(e => e.EventId == id && e.UserId == userId);

            if (eventEntity == null)
                return NotFound();

            _context.Events.Remove(eventEntity);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // POST: api/Event/public (Admin only - Create public event for all users)
        [HttpPost("public")]
        [Authorize]
        [AdminAuthorize]
        public async Task<ActionResult<EventDto>> CreatePublicEvent(PublicEventCreateDto publicEventDto)
        {
            // Get all users to assign the public event to
            var allUsers = await _context.Accounts.Where(a => a.Type == AccountType.User).ToListAsync();
            
            if (!allUsers.Any())
            {
                return BadRequest("No users found to assign public event to.");
            }

            var createdEvents = new List<Event>();

            // Create the event for each user
            foreach (var user in allUsers)
            {
                var eventEntity = new Event
                {
                    UserId = user.AccountId,
                    Title = publicEventDto.Title,
                    Description = publicEventDto.Description,
                    EventDate = publicEventDto.EventDate,
                    Type = publicEventDto.Type,
                    Location = publicEventDto.Location,
                    IsAllDay = publicEventDto.IsAllDay,
                    StartTime = publicEventDto.StartTime,
                    EndTime = publicEventDto.EndTime,
                    IsCompleted = false,
                    IsReminderSet = publicEventDto.IsReminderSet,
                    ReminderMinutes = publicEventDto.ReminderMinutes,
                    IsPublic = true, // Mark as public event
                    PropertyId = null,
                    AuctionId = null,
                    BidId = null,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Events.Add(eventEntity);
                createdEvents.Add(eventEntity);
            }

            await _context.SaveChangesAsync();

            // Return the first created event as representative
            return CreatedAtAction("GetEvent", new { id = createdEvents.First().EventId }, 
                EventDto.FromEvent(createdEvents.First()));
        }

        // GET: api/Event/public (Admin only - Get all public events)
        [HttpGet("public")]
        [Authorize]
        [AdminAuthorize]
        public async Task<ActionResult<IEnumerable<EventDto>>> GetPublicEvents()
        {
            var publicEvents = await _context.Events
                .Where(e => e.IsPublic)
                .OrderBy(e => e.EventDate)
                .Take(50) // Limit to recent 50 public events
                .ToListAsync();

            var eventDtos = publicEvents.Select(EventDto.FromEvent).ToList();
            return eventDtos;
        }

        // GET: api/Event/public/calendar (Public - No auth required)
        [HttpGet("public/calendar")]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<EventDto>>> GetPublicCalendarEvents()
        {
            var now = DateTime.UtcNow;
            var events = await _context.Events
                .Where(e => e.IsPublic && e.EventDate >= now)
                .OrderBy(e => e.EventDate)
                .Take(50) // Limit to upcoming 50 public events
                .ToListAsync();

            var eventDtos = events.Select(EventDto.FromEvent).ToList();
            return eventDtos;
        }

        // GET: api/Event/public/calendar/month/{year}/{month} (Public - No auth required)
        [HttpGet("public/calendar/month/{year}/{month}")]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<EventDto>>> GetPublicEventsByMonth(int year, int month)
        {
            var startDate = new DateTime(year, month, 1, 0, 0, 0, DateTimeKind.Utc);
            var endDate = startDate.AddMonths(1).AddDays(-1).Date;

            var events = await _context.Events
                .Where(e => e.IsPublic && 
                           e.EventDate.Date >= startDate.Date && 
                           e.EventDate.Date <= endDate.Date)
                .OrderBy(e => e.EventDate)
                .ToListAsync();

            var eventDtos = events.Select(EventDto.FromEvent).ToList();
            return eventDtos;
        }

        // GET: api/Event/public/calendar/today (Public - No auth required)
        [HttpGet("public/calendar/today")]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<EventDto>>> GetPublicTodaysEvents()
        {
            var today = DateTime.UtcNow.Date;

            var events = await _context.Events
                .Where(e => e.IsPublic && e.EventDate.Date == today)
                .OrderBy(e => e.StartTime ?? e.EventDate)
                .ToListAsync();

            var eventDtos = events.Select(EventDto.FromEvent).ToList();
            return eventDtos;
        }

        // GET: api/Event/public/calendar/upcoming (Public - No auth required)
        [HttpGet("public/calendar/upcoming")]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<EventDto>>> GetPublicUpcomingEvents()
        {
            var now = DateTime.UtcNow;

            var events = await _context.Events
                .Where(e => e.IsPublic && 
                           e.EventDate >= now &&
                           !e.IsCompleted)
                .OrderBy(e => e.EventDate)
                .Take(10)
                .ToListAsync();

            var eventDtos = events.Select(EventDto.FromEvent).ToList();
            return eventDtos;
        }

        private bool EventExists(long id)
        {
            return _context.Events.Any(e => e.EventId == id);
        }
    }

    // DTOs
    public class EventDto
    {
        public long EventId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime EventDate { get; set; }
        public EventType Type { get; set; }
        public string? Location { get; set; }
        public bool IsAllDay { get; set; }
        public DateTime? StartTime { get; set; }
        public DateTime? EndTime { get; set; }
        public bool IsCompleted { get; set; }
        public bool IsReminderSet { get; set; }
        public int? ReminderMinutes { get; set; }
        public bool IsPublic { get; set; }
        public long? PropertyId { get; set; }
        public long? AuctionId { get; set; }
        public long? BidId { get; set; }
        public DateTime CreatedAt { get; set; }

        public static EventDto FromEvent(Event eventEntity)
        {
            return new EventDto
            {
                EventId = eventEntity.EventId,
                Title = eventEntity.Title,
                Description = eventEntity.Description,
                EventDate = eventEntity.EventDate,
                Type = eventEntity.Type,
                Location = eventEntity.Location,
                IsAllDay = eventEntity.IsAllDay,
                StartTime = eventEntity.StartTime,
                EndTime = eventEntity.EndTime,
                IsCompleted = eventEntity.IsCompleted,
                IsReminderSet = eventEntity.IsReminderSet,
                ReminderMinutes = eventEntity.ReminderMinutes,
                IsPublic = eventEntity.IsPublic,
                PropertyId = eventEntity.PropertyId,
                AuctionId = eventEntity.AuctionId,
                BidId = eventEntity.BidId,
                CreatedAt = eventEntity.CreatedAt
            };
        }
    }

    public class EventCreateDto
    {
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime EventDate { get; set; }
        public EventType Type { get; set; }
        public string? Location { get; set; }
        public bool IsAllDay { get; set; } = false;
        public DateTime? StartTime { get; set; }
        public DateTime? EndTime { get; set; }
        public bool IsReminderSet { get; set; } = false;
        public int? ReminderMinutes { get; set; }
        public long? PropertyId { get; set; }
        public long? AuctionId { get; set; }
        public long? BidId { get; set; }
    }

    public class PublicEventCreateDto
    {
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime EventDate { get; set; }
        public EventType Type { get; set; }
        public string? Location { get; set; }
        public bool IsAllDay { get; set; } = false;
        public DateTime? StartTime { get; set; }
        public DateTime? EndTime { get; set; }
        public bool IsReminderSet { get; set; } = false;
        public int? ReminderMinutes { get; set; }
    }

    public class EventUpdateDto
    {
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime EventDate { get; set; }
        public EventType Type { get; set; }
        public string? Location { get; set; }
        public bool IsAllDay { get; set; }
        public DateTime? StartTime { get; set; }
        public DateTime? EndTime { get; set; }
        public bool IsCompleted { get; set; }
        public bool IsReminderSet { get; set; }
        public int? ReminderMinutes { get; set; }
    }
}
