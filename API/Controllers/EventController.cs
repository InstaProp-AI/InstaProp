using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Attributes;
using InstapropAPI.Services;

namespace InstapropAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EventController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly NotificationService _notificationService;
        private readonly OpenAIService _openAIService;
        private readonly RewardService _rewardService;
        private readonly ImgBBService _imgBBService;
        private readonly InstallmentSummaryService _installmentSummaryService;

        public EventController(
            AppDbContext context,
            NotificationService notificationService,
            OpenAIService openAIService,
            ImgBBService imgBBService,
            RewardService rewardService,
            InstallmentSummaryService installmentSummaryService)
        {
            _context = context;
            _notificationService = notificationService;
            _openAIService = openAIService;
            _imgBBService = imgBBService;
            _rewardService = rewardService;
            _installmentSummaryService = installmentSummaryService;
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

            // Validate payment event requirements
            if (eventDto.Type == EventType.Installment)
            {
                if (!eventDto.PropertyId.HasValue)
                {
                    return BadRequest("PropertyId is required for installment events");
                }
                if (!eventDto.Amount.HasValue || eventDto.Amount.Value <= 0)
                {
                    return BadRequest("Amount is required and must be > 0 for installment events");
                }
            }

            // Create the parent/first event
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
                IsRecurring = eventDto.IsRecurring,
                RecurrencePattern = eventDto.RecurrencePattern,
                RecurrenceInterval = eventDto.RecurrenceInterval,
                RecurrenceEndDate = eventDto.RecurrenceEndDate,
                RecurrenceCount = eventDto.RecurrenceCount,
                ParentEventId = null, // This is the parent
                Amount = eventDto.Amount,
                PropertyId = eventDto.PropertyId,
                AuctionId = eventDto.AuctionId,
                BidId = eventDto.BidId,
                CreatedAt = DateTime.UtcNow
            };

            _context.Events.Add(eventEntity);
            await _context.SaveChangesAsync();

            // Award rewards for creating an event
            await _rewardService.AwardPointsAsync(userId.Value, "EventCreate", RewardPoints.EventCreated, $"Created event '{eventDto.Title}'", eventDto.PropertyId);

            // If this is a recurring event, generate the recurring instances
            if (eventDto.IsRecurring && eventDto.RecurrencePattern.HasValue && eventDto.RecurrenceInterval.HasValue)
            {
                var recurringEvents = GenerateRecurringEvents(eventEntity, eventDto, userId.Value);
                if (recurringEvents.Any())
                {
                    _context.Events.AddRange(recurringEvents);
                    await _context.SaveChangesAsync();
                }
            }

            if (eventDto.Type == EventType.Installment && eventDto.PropertyId.HasValue)
            {
                await SyncInstallmentSummaryAsync(eventDto.PropertyId.Value);
            }

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

            var wasInstallment = eventEntity.Type == EventType.Installment;

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

            if (eventEntity.PropertyId.HasValue &&
                (wasInstallment || eventDto.Type == EventType.Installment))
            {
                await SyncInstallmentSummaryAsync(eventEntity.PropertyId.Value);
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

            if (eventEntity.PropertyId.HasValue && eventEntity.Type == EventType.Installment)
            {
                await SyncInstallmentSummaryAsync(eventEntity.PropertyId.Value);
            }

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

            var propertyId = eventEntity.PropertyId;
            var wasInstallment = eventEntity.Type == EventType.Installment;

            _context.Events.Remove(eventEntity);
            await _context.SaveChangesAsync();

            if (propertyId.HasValue && wasInstallment)
            {
                await SyncInstallmentSummaryAsync(propertyId.Value);
            }

            return NoContent();
        }

        // GET: api/Event/by-property/{propertyId}
        [HttpGet("by-property/{propertyId}")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<EventDto>>> GetEventsByProperty(long propertyId)
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            // Ensure the property belongs to the user (or allow if events are public)
            var ownsProperty = await _context.ChildProperties.AnyAsync(p => p.PropertyId == propertyId && p.OwnerId == userId);
            if (!ownsProperty)
                return StatusCode(403, new { message = "You can only view events for your own properties" });

            var events = await _context.Events
                .Where(e => e.UserId == userId && e.PropertyId == propertyId)
                .OrderBy(e => e.EventDate)
                .ToListAsync();

            return events.Select(EventDto.FromEvent).ToList();
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

            // Notify all users about the new public event
            if (createdEvents.Any())
            {
                await _notificationService.NotifyNewPublicEvent(createdEvents.First().EventId);
            }

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

        // POST: api/Event/scan-payment-schedule
        [HttpPost("scan-payment-schedule")]
        [Authorize]
        public async Task<ActionResult<PaymentScheduleScanResult>> ScanPaymentSchedule([FromForm] IFormFile image, [FromForm] long propertyId, [FromForm] int? reminderMinutes, [FromForm] decimal? buyingPrice)
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            // Verify user account exists
            var userAccount = await _context.Accounts.FirstOrDefaultAsync(a => a.AccountId == userId.Value);
            if (userAccount == null)
                return StatusCode(500, new { message = "User account not found" });

            if (image == null || image.Length == 0)
                return BadRequest("No image file provided");

            // Validate property ownership
            var property = await _context.ChildProperties.FirstOrDefaultAsync(p => p.PropertyId == propertyId);
            if (property == null)
                return NotFound("Property not found");
            if (property.OwnerId != userId)
                return StatusCode(403, new { message = "You can only upload schedules for your own properties" });

            // Validate image file type - accept all image formats
            var contentType = image.ContentType?.ToLower() ?? "";
            
            // Log the content type for debugging
            Console.WriteLine($"Received file with ContentType: {image.ContentType}, FileName: {image.FileName}");
            
            // Accept any file that is an image or has image extension
            var isImageType = string.IsNullOrEmpty(contentType) || 
                             contentType.StartsWith("image/") || 
                             contentType.Contains("image");
            
            var fileName = image.FileName?.ToLower() ?? "";
            var hasImageExtension = fileName.EndsWith(".jpg") || 
                                   fileName.EndsWith(".jpeg") || 
                                   fileName.EndsWith(".png") || 
                                   fileName.EndsWith(".gif") || 
                                   fileName.EndsWith(".bmp") ||
                                   fileName.EndsWith(".webp");
            
            if (!isImageType && !hasImageExtension)
            {
                return BadRequest($"Invalid file type. Received ContentType: '{image.ContentType}', FileName: '{image.FileName}'. Please upload an image file (JPEG, PNG, etc.).");
            }

            // Validate file size (max 10MB)
            if (image.Length > 10 * 1024 * 1024)
                return BadRequest("Image file too large. Maximum size is 10MB.");

            try
            {
                // Read image data
                byte[] imageData;
                using (var memoryStream = new MemoryStream())
                {
                    await image.CopyToAsync(memoryStream);
                    imageData = memoryStream.ToArray();
                }

                // Upload the original schedule image
                string? uploadedImageUrl = null;
                try
                {
                    byte[] fileBytesForUpload = imageData;
                    var uploadResult = await _imgBBService.UploadImageAsync(
                        fileBytesForUpload,
                        $"payment_schedule_property_{propertyId}_{DateTime.UtcNow.Ticks}",
                        0
                    );
                    uploadedImageUrl = uploadResult.DisplayUrl;
                }
                catch (Exception ex)
                {
                    // If upload fails, continue without image URL
                    Console.WriteLine($"Warning: Failed to upload schedule image: {ex.Message}");
                }

                // Analyze image with OpenAI
                var paymentItems = await _openAIService.AnalyzePaymentScheduleAsync(imageData);

                if (paymentItems == null || paymentItems.Count == 0)
                    return BadRequest("No payment schedule data could be extracted from the image. Please ensure the image contains a clear payment schedule.");

                var createdEvents = new List<Event>();
                var scheduleGroupId = Guid.NewGuid().ToString();

                // Create events for each payment item
                foreach (var item in paymentItems)
                {
                    DateTime paymentDate;
                    if (!DateTime.TryParse(item.Date, out paymentDate))
                    {
                        // Skip invalid dates
                        continue;
                    }

                    var eventEntity = new Event
                    {
                        UserId = userId.Value,
                        Title = $"Payment: {item.Description}",
                        Description = $"Amount: ${item.Amount:F2}\n{item.Description}",
                        EventDate = paymentDate,
                        Type = EventType.Installment,
                        Location = null,
                        IsAllDay = true,
                        StartTime = null,
                        EndTime = null,
                        IsCompleted = false,
                        IsReminderSet = reminderMinutes.HasValue && reminderMinutes.Value > 0,
                        ReminderMinutes = reminderMinutes,
                        PropertyId = propertyId,
                        AuctionId = null,
                        BidId = null,
                        Amount = item.Amount,
                        ScheduleImageUrl = uploadedImageUrl,
                        ScheduleGroupId = scheduleGroupId,
                        ScheduleBuyingPrice = buyingPrice,
                        CreatedAt = DateTime.UtcNow
                    };

                    _context.Events.Add(eventEntity);
                    createdEvents.Add(eventEntity);
                }

                if (createdEvents.Count == 0)
                    return BadRequest("No valid payment dates could be extracted from the image.");

                await _context.SaveChangesAsync();

                // Award rewards for importing payment schedule
                await _rewardService.AwardPointsAsync(userId.Value, "ScheduleImport", RewardPoints.ScheduleImport, $"Imported {createdEvents.Count} payment events", propertyId);

                await SyncInstallmentSummaryAsync(propertyId);

                return Ok(new PaymentScheduleScanResult
                {
                    Success = true,
                    Message = $"Successfully created {createdEvents.Count} payment event(s)",
                    EventsCreated = createdEvents.Count,
                    Events = createdEvents.Select(EventDto.FromEvent).ToList()
                });
            }
            catch (Exception ex)
            {
                // Log full exception details for debugging
                var errorMessage = ex.Message;
                if (ex.InnerException != null)
                {
                    errorMessage += $" | Inner: {ex.InnerException.Message}";
                    if (ex.InnerException.InnerException != null)
                    {
                        errorMessage += $" | Inner2: {ex.InnerException.InnerException.Message}";
                    }
                }
                
                Console.WriteLine($"❌ Payment schedule scan error: {errorMessage}");
                Console.WriteLine($"❌ Stack trace: {ex.StackTrace}");
                
                return StatusCode(500, new PaymentScheduleScanResult
                {
                    Success = false,
                    Message = $"Error processing payment schedule: {errorMessage}",
                    EventsCreated = 0
                });
            }
        }

        private bool EventExists(long id)
        {
            return _context.Events.Any(e => e.EventId == id);
        }

        private async Task SyncInstallmentSummaryAsync(long propertyIdLong)
        {
            if (propertyIdLong <= 0) return;

            var property = await _context.ChildProperties
                .Include(p => p.InstallmentSummary)
                .FirstOrDefaultAsync(p => p.PropertyId == propertyIdLong);

            if (property == null)
                return;

            var installmentEvents = await _context.Events
                .Where(e => e.PropertyId == propertyIdLong && e.Type == EventType.Installment)
                .ToListAsync();

            if (property.InstallmentSummary == null && installmentEvents.Count == 0)
                return;

            var totalPaid = installmentEvents
                .Where(e => e.IsCompleted && e.Amount.HasValue)
                .Sum(e => e.Amount!.Value);

            var schedulePrice = installmentEvents
                .Where(e => e.ScheduleBuyingPrice.HasValue && e.ScheduleBuyingPrice.Value > 0)
                .Select(e => e.ScheduleBuyingPrice!.Value)
                .DefaultIfEmpty(0m)
                .Max();

            var existingSummary = property.InstallmentSummary;
            var contractedPrice = existingSummary?.ContractedPrice ?? 0m;

            if (contractedPrice <= 0 && schedulePrice > 0)
            {
                contractedPrice = schedulePrice;
            }

            if (contractedPrice <= 0 && existingSummary == null)
            {
                var totalScheduled = installmentEvents
                    .Where(e => e.Amount.HasValue && e.Amount.Value > 0)
                    .Sum(e => e.Amount!.Value);

                if (totalScheduled > 0)
                {
                    contractedPrice = totalScheduled;
                }
            }

            if (contractedPrice <= 0 && existingSummary == null)
            {
                return;
            }

            var downPaymentPercent = existingSummary?.DownPaymentPercent ?? 0m;
            var termYears = existingSummary?.TermYears;

            var installmentEndDate = existingSummary?.InstallmentEndDate;
            if (installmentEndDate == null && installmentEvents.Count > 0)
            {
                installmentEndDate = installmentEvents
                    .Select(e => (DateTime?)e.EventDate)
                    .Where(d => d.HasValue)
                    .Max();
            }

            await _installmentSummaryService.UpsertSummaryAsync(
                (int)propertyIdLong,
                contractedPrice,
                totalPaid,
                downPaymentPercent,
                termYears,
                installmentEndDate,
                existingSummary?.IsFullyPaid);
        }

        private List<Event> GenerateRecurringEvents(Event parentEvent, EventCreateDto dto, long userId)
        {
            var events = new List<Event>();
            
            if (!dto.IsRecurring || dto.RecurrencePattern == null || dto.RecurrenceInterval == null)
            {
                return events;
            }

            var currentDate = dto.EventDate;
            var maxOccurrences = dto.RecurrenceCount ?? 100; // Default max 100 if no end date or count specified
            var hasEndDate = dto.RecurrenceEndDate.HasValue;
            var endDate = dto.RecurrenceEndDate ?? currentDate.AddYears(2); // Default 2 years

            var occurrenceCount = 0;

            // Generate events (skip first one as parent already created)
            while (occurrenceCount < maxOccurrences && currentDate <= endDate)
            {
                // Calculate next occurrence date
                switch (dto.RecurrencePattern.Value)
                {
                    case RecurrencePattern.Daily:
                        currentDate = currentDate.AddDays(dto.RecurrenceInterval.Value);
                        break;
                    case RecurrencePattern.Weekly:
                        currentDate = currentDate.AddDays(7 * dto.RecurrenceInterval.Value);
                        break;
                    case RecurrencePattern.Monthly:
                        currentDate = currentDate.AddMonths(dto.RecurrenceInterval.Value);
                        break;
                    case RecurrencePattern.Yearly:
                        currentDate = currentDate.AddYears(dto.RecurrenceInterval.Value);
                        break;
                }

                // Check if we've passed the end date
                if (hasEndDate && currentDate > endDate)
                {
                    break;
                }

                occurrenceCount++;

                // Check if we've reached the count limit
                if (dto.RecurrenceCount.HasValue && occurrenceCount >= dto.RecurrenceCount.Value)
                {
                    if (currentDate > endDate)
                        break;
                }

                // Create the recurring event instance
                var recurringEvent = new Event
                {
                    UserId = userId,
                    Title = dto.Title,
                    Description = dto.Description,
                    EventDate = currentDate,
                    Type = dto.Type,
                    Location = dto.Location,
                    IsAllDay = dto.IsAllDay,
                    StartTime = dto.StartTime.HasValue 
                        ? new DateTime(currentDate.Year, currentDate.Month, currentDate.Day, 
                                      dto.StartTime.Value.Hour, dto.StartTime.Value.Minute, dto.StartTime.Value.Second)
                        : null,
                    EndTime = dto.EndTime.HasValue 
                        ? new DateTime(currentDate.Year, currentDate.Month, currentDate.Day, 
                                      dto.EndTime.Value.Hour, dto.EndTime.Value.Minute, dto.EndTime.Value.Second)
                        : null,
                    IsCompleted = false,
                    IsReminderSet = dto.IsReminderSet,
                    ReminderMinutes = dto.ReminderMinutes,
                    PropertyId = dto.PropertyId,
                    AuctionId = dto.AuctionId,
                    BidId = dto.BidId,
                    IsRecurring = false, // Individual instances are not recurring themselves
                    ParentEventId = parentEvent.EventId,
                    Amount = dto.Amount,
                    CreatedAt = DateTime.UtcNow
                };

                events.Add(recurringEvent);
            }

            return events;
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
        public bool IsRecurring { get; set; }
        public RecurrencePattern? RecurrencePattern { get; set; }
        public int? RecurrenceInterval { get; set; }
        public DateTime? RecurrenceEndDate { get; set; }
        public int? RecurrenceCount { get; set; }
        public long? ParentEventId { get; set; }
        public decimal? Amount { get; set; }
        public long? PropertyId { get; set; }
        public long? AuctionId { get; set; }
        public long? BidId { get; set; }
        public DateTime CreatedAt { get; set; }
        public string? ScheduleImageUrl { get; set; }
        public string? ScheduleGroupId { get; set; }
        public decimal? ScheduleBuyingPrice { get; set; }

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
                IsRecurring = eventEntity.IsRecurring,
                RecurrencePattern = eventEntity.RecurrencePattern,
                RecurrenceInterval = eventEntity.RecurrenceInterval,
                RecurrenceEndDate = eventEntity.RecurrenceEndDate,
                RecurrenceCount = eventEntity.RecurrenceCount,
                ParentEventId = eventEntity.ParentEventId,
                Amount = eventEntity.Amount,
                PropertyId = eventEntity.PropertyId,
                AuctionId = eventEntity.AuctionId,
                BidId = eventEntity.BidId,
                CreatedAt = eventEntity.CreatedAt,
                ScheduleImageUrl = eventEntity.ScheduleImageUrl,
                ScheduleGroupId = eventEntity.ScheduleGroupId,
                ScheduleBuyingPrice = eventEntity.ScheduleBuyingPrice
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
        public bool IsRecurring { get; set; } = false;
        public RecurrencePattern? RecurrencePattern { get; set; }
        public int? RecurrenceInterval { get; set; }
        public DateTime? RecurrenceEndDate { get; set; }
        public int? RecurrenceCount { get; set; }
        public decimal? Amount { get; set; }
        public long? PropertyId { get; set; }
        public long? AuctionId { get; set; }
        public long? BidId { get; set; }
        public string? ScheduleImageUrl { get; set; }
        public string? ScheduleGroupId { get; set; }
        public decimal? ScheduleBuyingPrice { get; set; }
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

    public class PaymentScheduleScanResult
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public int EventsCreated { get; set; }
        public List<EventDto>? Events { get; set; }
    }
}
