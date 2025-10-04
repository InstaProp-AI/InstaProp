using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CalendarController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CalendarController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Calendar/events
        [HttpGet("events")]
        public async Task<ActionResult<IEnumerable<object>>> GetEvents([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            var start = startDate ?? DateTime.UtcNow.Date;
            var end = endDate ?? DateTime.UtcNow.Date.AddDays(30);

            var events = new List<object>();

            // Get auctions
            var auctions = await _context.Auctions
                .Where(a => a.CreatedAt >= start && a.CreatedAt <= end)
                .Include(a => a.Property)
                .Select(a => new
                {
                    Id = a.AuctionId,
                    Title = a.Property.Name,
                    Start = a.StartAt,
                    End = a.EndAt,
                    Type = "auction",
                    Location = a.Property.Location,
                    Price = a.CurrentPrice,
                    Status = a.Status,
                    Color = GetAuctionColor(a.Status)
                })
                .ToListAsync();

            events.AddRange(auctions);

            // Get inspection events
            var inspections = await _context.Properties
                .Where(p => p.IsApproved && p.CreatedAt >= start && p.CreatedAt <= end)
                .Select(p => new
                {
                    Id = p.PropertyId,
                    Title = $"Inspection: {p.Name}",
                    Start = p.CreatedAt.AddDays(1),
                    End = p.CreatedAt.AddDays(1).AddHours(2),
                    Type = "inspection",
                    Location = p.Location,
                    Price = 0,
                    Status = "Scheduled",
                    Color = "#FF9800"
                })
                .ToListAsync();

            events.AddRange(inspections);

            // Add demo events
            var demoEvents = GetDemoEvents(start, end);
            events.AddRange(demoEvents);

            return Ok(events);
        }

        // GET: api/Calendar/auctions
        [HttpGet("auctions")]
        public async Task<ActionResult<IEnumerable<object>>> GetAuctionEvents([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            var start = startDate ?? DateTime.UtcNow.Date;
            var end = endDate ?? DateTime.UtcNow.Date.AddDays(30);

            var auctions = await _context.Auctions
                .Where(a => a.CreatedAt >= start && a.CreatedAt <= end)
                .Include(a => a.Property)
                .Select(a => new
                {
                    a.AuctionId,
                    a.Property.Name,
                    a.Property.Location,
                    a.StartAt,
                    a.EndAt,
                    a.CurrentPrice,
                    a.Status,
                    a.BidCount,
                    Property = new
                    {
                        a.Property.PropertyId,
                        a.Property.Name,
                        a.Property.Location,
                        a.Property.Bedrooms,
                        a.Property.Bathrooms,
                        a.Property.SquareFeet
                    }
                })
                .ToListAsync();

            return Ok(auctions);
        }

        // GET: api/Calendar/workshops
        [HttpGet("workshops")]
        public async Task<ActionResult<IEnumerable<object>>> GetWorkshops()
        {
            var workshops = new List<object>
            {
                new
                {
                    Id = 1,
                    Title = "Property Valuation Workshop",
                    Description = "Learn how to accurately value properties using market data",
                    Date = DateTime.UtcNow.AddDays(2),
                    Time = "10:00 AM - 12:00 PM",
                    Location = "Online",
                    Type = "workshop",
                    MaxAttendees = 50,
                    CurrentAttendees = 23
                },
                new
                {
                    Id = 2,
                    Title = "Auction Strategy Seminar",
                    Description = "Master the art of bidding and auction strategies",
                    Date = DateTime.UtcNow.AddDays(5),
                    Time = "2:00 PM - 4:00 PM",
                    Location = "Auction House",
                    Type = "seminar",
                    MaxAttendees = 30,
                    CurrentAttendees = 18
                },
                new
                {
                    Id = 3,
                    Title = "Real Estate Investment Basics",
                    Description = "Introduction to real estate investment strategies",
                    Date = DateTime.UtcNow.AddDays(7),
                    Time = "6:00 PM - 8:00 PM",
                    Location = "Community Center",
                    Type = "workshop",
                    MaxAttendees = 40,
                    CurrentAttendees = 35
                }
            };

            return Ok(workshops);
        }

        // GET: api/Calendar/inspections
        [HttpGet("inspections")]
        public async Task<ActionResult<IEnumerable<object>>> GetInspections([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            var start = startDate ?? DateTime.UtcNow.Date;
            var end = endDate ?? DateTime.UtcNow.Date.AddDays(30);

            var inspections = await _context.Properties
                .Where(p => p.IsApproved && p.CreatedAt >= start && p.CreatedAt <= end)
                .Select(p => new
                {
                    p.PropertyId,
                    p.Name,
                    p.Location,
                    InspectionDate = p.CreatedAt.AddDays(1),
                    Duration = "2 hours",
                    Inspector = "John Smith",
                    Status = "Scheduled",
                    Notes = "General property inspection"
                })
                .ToListAsync();

            return Ok(inspections);
        }

        // POST: api/Calendar/register
        [HttpPost("register")]
        public async Task<ActionResult<object>> RegisterForEvent([FromBody] EventRegistrationRequest request)
        {
            // In a real application, you would save this to a database
            var registration = new
            {
                Id = Guid.NewGuid(),
                EventId = request.EventId,
                UserId = request.UserId,
                EventType = request.EventType,
                RegistrationDate = DateTime.UtcNow,
                Status = "Confirmed"
            };

            return Ok(registration);
        }

        private List<object> GetDemoEvents(DateTime start, DateTime end)
        {
            var events = new List<object>();

            // Add some demo events
            for (int i = 0; i < 10; i++)
            {
                var eventDate = start.AddDays(i * 3);
                if (eventDate <= end)
                {
                    events.Add(new
                    {
                        Id = 1000 + i,
                        Title = $"Demo Event {i + 1}",
                        Start = eventDate,
                        End = eventDate.AddHours(2),
                        Type = i % 2 == 0 ? "workshop" : "preview",
                        Location = i % 2 == 0 ? "Online" : "Auction House",
                        Price = 0,
                        Status = "Scheduled",
                        Color = i % 2 == 0 ? "#2196F3" : "#FF9800"
                    });
                }
            }

            return events;
        }

        private string GetAuctionColor(string status)
        {
            return status switch
            {
                "Active" => "#4CAF50",
                "Upcoming" => "#2196F3",
                "Ended" => "#9E9E9E",
                _ => "#FF9800"
            };
        }
    }

    public class EventRegistrationRequest
    {
        public int EventId { get; set; }
        public int UserId { get; set; }
        public string EventType { get; set; } = string.Empty;
    }
}
