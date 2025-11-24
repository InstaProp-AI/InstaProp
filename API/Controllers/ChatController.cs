using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Services;
using InstapropAPI.Attributes;
using System.Security.Claims;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [FeaturePermissionAttribute("Chats")]
    public class ChatController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly FirestoreService _firestoreService;
        private readonly FcmPushNotificationService _fcmService;

        public ChatController(
            AppDbContext context, 
            FirestoreService firestoreService,
            FcmPushNotificationService fcmService)
        {
            _context = context;
            _firestoreService = firestoreService;
            _fcmService = fcmService;
        }

        private Guid? GetCurrentAccountId()
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim != null && Guid.TryParse(accountIdClaim.Value, out var accountId))
            {
                return accountId;
            }
            return null;
        }

        // GET: api/chat - Get user's chat list
        [HttpGet]
        public async Task<ActionResult<IEnumerable<ChatDto>>> GetChats([FromQuery] Guid? developerId = null)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null)
                return Unauthorized();

            IQueryable<Chat> chatQuery;

            // Sales accounts see: chats they're assigned to OR available chats for their developer
            if (account.RoleId == Role.SALES_ROLE_ID)
            {
                var salesAccount = account as SalesAccount;
                if (salesAccount == null || !salesAccount.AssignedDeveloperId.HasValue)
                    return Ok(new List<ChatDto>()); // Sales without developer assignment see nothing

                chatQuery = _context.Chats
                    .Where(c => 
                        c.SalesMemberId == accountId || // Chats I've taken
                        (c.DeveloperId == salesAccount.AssignedDeveloperId.Value && c.SalesMemberId == null) // Available chats for my developer
                    );
            }
            else if (account.RoleId == Role.ADMIN_ROLE_ID)
            {
                // Admins can see all chats or filter by developerId
                if (developerId.HasValue)
                {
                    chatQuery = _context.Chats.Where(c => c.DeveloperId == developerId.Value);
                }
                else
                {
                    chatQuery = _context.Chats; // All chats for admin
                }
            }
            else
            {
                // Regular users and developers see their own chats
                chatQuery = _context.Chats
                    .Where(c => c.UserId == accountId || c.DeveloperId == accountId);
            }

            var chats = await chatQuery
                .Include(c => c.User)
                .Include(c => c.Developer)
                .Include(c => c.SalesMember)
                .Include(c => c.Project)
                .Include(c => c.Messages.OrderByDescending(m => m.CreatedAt).Take(1))
                .OrderByDescending(c => c.IsSupportChat)
                .ThenByDescending(c => c.LastMessageAt)
                .ToListAsync();

            var chatDtos = chats.Select(c => new ChatDto
            {
                ChatId = c.ChatId,
                UserId = c.UserId,
                UserName = FormatAccountName(c.User as AccountBase),
                DeveloperId = c.DeveloperId,
                DeveloperName = FormatAccountName(c.Developer as AccountBase),
                ProjectId = c.ProjectId,
                ProjectName = c.Project?.Name,
                CreatedAt = c.CreatedAt,
                LastMessageAt = c.LastMessageAt,
                IsActive = c.IsActive,
                LastMessage = c.Messages.FirstOrDefault()?.Content,
                UnreadCount = c.Messages.Count(m => !m.IsRead && m.SenderId != accountId),
                IsSupportChat = c.IsSupportChat,
                SalesMemberId = c.SalesMemberId,
                SalesMemberName = c.SalesMember != null ? FormatAccountName(c.SalesMember as AccountBase) : null,
                IsAvailable = account.RoleId == Role.SALES_ROLE_ID && c.SalesMemberId == null // Available for sales to take
            }).ToList();

            return Ok(chatDtos);
        }

        // GET: api/chat/{chatId} - Get specific chat with messages
        [HttpGet("{chatId}")]
        public async Task<ActionResult<ChatDetailsDto>> GetChat(Guid chatId)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null)
                return Unauthorized();

            var chat = await _context.Chats
                .Include(c => c.User)
                .Include(c => c.Developer)
                .Include(c => c.SalesMember)
                .Include(c => c.Project)
                .Include(c => c.Messages.OrderBy(m => m.CreatedAt))
                    .ThenInclude(m => m.Sender)
                .Include(c => c.Messages)
                    .ThenInclude(m => m.Property)
                .FirstOrDefaultAsync(c => c.ChatId == chatId);

            if (chat == null)
                return NotFound("Chat not found");

            // Verify user has access to this chat (user, developer, assigned sales, or admin)
            if (account.RoleId != Role.ADMIN_ROLE_ID && 
                chat.UserId != accountId && 
                chat.DeveloperId != accountId && 
                chat.SalesMemberId != accountId)
                return Forbid();

            var chatDetails = new ChatDetailsDto
            {
                ChatId = chat.ChatId,
                UserId = chat.UserId,
                UserName = FormatAccountName(chat.User as AccountBase),
                DeveloperId = chat.DeveloperId,
                DeveloperName = FormatAccountName(chat.Developer as AccountBase),
                ProjectId = chat.ProjectId,
                ProjectName = chat.Project?.Name,
                CreatedAt = chat.CreatedAt,
                LastMessageAt = chat.LastMessageAt,
                IsActive = chat.IsActive,
                IsSupportChat = chat.IsSupportChat,
                SalesMemberId = chat.SalesMemberId,
                SalesMemberName = chat.SalesMember != null ? FormatAccountName(chat.SalesMember as AccountBase) : null,
                Messages = chat.Messages.Select(m => new MessageDto
                {
                    MessageId = m.MessageId,
                    SenderId = m.SenderId,
                    SenderName = $"{m.Sender.FirstName} {m.Sender.LastName}",
                    Content = m.Content,
                    PropertyId = m.PropertyId,
                    PropertyName = m.Property?.Name,
                    PropertyLocation = m.Property?.Location,
                    PropertyImageUrl = m.Property?.ImageUrl,
                    CreatedAt = m.CreatedAt,
                    IsRead = m.IsRead
                }).ToList()
            };

            return Ok(chatDetails);
        }

        // POST: api/chat - Create new chat with developer
        [HttpPost]
        public async Task<ActionResult<ChatDto>> CreateChat([FromBody] CreateChatDto dto)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            // Verify developer exists and is actually a developer
            var developer = await _context.Accounts.FindAsync(dto.DeveloperId);
            if (developer == null)
                return NotFound("Developer not found");

            if (developer.RoleId != Role.DEVELOPER_ROLE_ID) // SECURITY: Check non-guessable RoleId
                return BadRequest("Specified account is not a developer");

            // Check if chat already exists
            var existingChat = await _context.Chats
                .Include(c => c.Developer)
                .Include(c => c.Project)
                .FirstOrDefaultAsync(c => 
                    c.UserId == accountId && 
                    c.DeveloperId == dto.DeveloperId && 
                    (dto.ProjectId == null || c.ProjectId == dto.ProjectId));

            if (existingChat != null)
            {
                return Ok(new ChatDto
                {
                    ChatId = existingChat.ChatId,
                    UserId = existingChat.UserId,
                    DeveloperId = existingChat.DeveloperId,
                    DeveloperName = FormatAccountName(existingChat.Developer as AccountBase),
                    ProjectId = existingChat.ProjectId,
                    ProjectName = existingChat.Project?.Name,
                    CreatedAt = existingChat.CreatedAt,
                    LastMessageAt = existingChat.LastMessageAt,
                    IsActive = existingChat.IsActive,
                    IsSupportChat = existingChat.IsSupportChat
                });
            }

            // Create new chat
            var chat = new Chat
            {
                UserId = accountId.Value,
                DeveloperId = dto.DeveloperId,
                ProjectId = dto.ProjectId,
                CreatedAt = DateTime.UtcNow,
                LastMessageAt = DateTime.UtcNow,
                IsActive = true
            };

            _context.Chats.Add(chat);
            await _context.SaveChangesAsync();

            // Create chat in Firestore for real-time
            await _firestoreService.CreateChatAsync(chat.ChatId, chat.UserId, chat.DeveloperId, chat.ProjectId);

            return CreatedAtAction(nameof(GetChat), new { chatId = chat.ChatId }, new ChatDto
            {
                ChatId = chat.ChatId,
                UserId = chat.UserId,
                DeveloperId = chat.DeveloperId,
                DeveloperName = FormatAccountName(developer as AccountBase),
                ProjectId = chat.ProjectId,
                ProjectName = chat.Project?.Name,
                CreatedAt = chat.CreatedAt,
                LastMessageAt = chat.LastMessageAt,
                IsActive = chat.IsActive,
                IsSupportChat = chat.IsSupportChat
            });
        }

        // POST: api/chat/{chatId}/message - Send message
        [HttpPost("{chatId}/message")]
        public async Task<ActionResult<MessageDto>> SendMessage(Guid chatId, [FromBody] SendMessageDto dto)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null)
                return Unauthorized();

            var chat = await _context.Chats
                .Include(c => c.User)
                .Include(c => c.Developer)
                .FirstOrDefaultAsync(c => c.ChatId == chatId);

            if (chat == null)
                return NotFound("Chat not found");

            // Verify user has access to this chat (user, developer, assigned sales member, or admin)
            if (account.RoleId != Role.ADMIN_ROLE_ID && 
                chat.UserId != accountId && 
                chat.DeveloperId != accountId && 
                chat.SalesMemberId != accountId)
                return Forbid();

            // Check if this is the first message in the chat
            var existingMessageCount = await _context.ChatMessages.CountAsync(m => m.ChatId == chatId);
            var isFirstMessage = existingMessageCount == 0;

            // Verify property exists if provided
            ChildProperty? property = null;
            if (dto.PropertyId.HasValue)
            {
                property = await _context.ChildProperties.FindAsync(dto.PropertyId.Value);
                if (property == null)
                    return NotFound("Property not found");
            }

            // Create message
            var message = new ChatMessage
            {
                ChatId = chatId,
                SenderId = accountId.Value,
                Content = dto.Content,
                PropertyId = dto.PropertyId,
                CreatedAt = DateTime.UtcNow,
                IsRead = false,
                ExpiresAt = DateTime.UtcNow.AddDays(30)
            };

            _context.ChatMessages.Add(message);

            // Update chat's last message time
            chat.LastMessageAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            // Send to Firestore for real-time delivery
            await _firestoreService.SendChatMessageAsync(
                chatId, 
                message.MessageId, 
                message.SenderId, 
                message.Content,
                message.PropertyId,
                message.CreatedAt,
                message.ExpiresAt);

            // Send push notification to recipient
            var recipientId = chat.UserId == accountId ? chat.DeveloperId : chat.UserId;
            var recipient = chat.UserId == accountId ? chat.Developer : chat.User;
            var sender = await _context.Accounts.FindAsync(accountId.Value);
            
            await _fcmService.SendChatNotificationAsync(
                recipientId,
                $"New message from {sender?.FirstName} {sender?.LastName}",
                dto.Content.Length > 100 ? dto.Content.Substring(0, 100) + "..." : dto.Content);

            // If this is the first message from a user to a developer, notify all sales team members
            if (isFirstMessage && chat.UserId == accountId && chat.SalesMemberId == null)
            {
                // Get all sales accounts assigned to this developer
                var salesTeam = await _context.SalesAccounts
                    .Where(a => a.RoleId == Role.SALES_ROLE_ID && a.AssignedDeveloperId == chat.DeveloperId)
                    .ToListAsync();

                var senderAccount = await _context.Accounts.FindAsync(accountId.Value);
                var senderName = senderAccount != null ? $"{senderAccount.FirstName} {senderAccount.LastName}" : "A user";

                // Create notifications and send push notifications to all sales team members
                foreach (var salesMember in salesTeam)
                {
                    // Create in-app notification
                    var notification = new Notification
                    {
                        UserId = salesMember.AccountId,
                        Title = "New Chat Available",
                        Message = $"{senderName} sent a message to {chat.Developer.FirstName} {chat.Developer.LastName}. Click to take this chat.",
                        Type = NotificationType.General,
                        CreatedAt = DateTime.UtcNow
                    };
                    _context.Notifications.Add(notification);

                    // Send push notification
                    await _fcmService.SendChatNotificationAsync(
                        salesMember.AccountId,
                        "New Chat Available",
                        $"{senderName} needs assistance. Take this chat now!");
                }

                // Save all notifications
                await _context.SaveChangesAsync();

                // Sync notifications to Firestore
                foreach (var salesMember in salesTeam)
                {
                    var notification = await _context.Notifications
                        .Where(n => n.UserId == salesMember.AccountId)
                        .OrderByDescending(n => n.CreatedAt)
                        .FirstOrDefaultAsync();
                    
                    if (notification != null)
                    {
                        try
                        {
                            await _firestoreService.UpdateUserNotificationAsync(salesMember.AccountId, notification);
                        }
                        catch
                        {
                            // Log but don't fail if Firestore sync fails
                        }
                    }
                }
            }

            // Load the sender for response
            var messageWithSender = await _context.ChatMessages
                .Include(m => m.Sender)
                .Include(m => m.Property)
                .FirstOrDefaultAsync(m => m.MessageId == message.MessageId);

            return Ok(new MessageDto
            {
                MessageId = messageWithSender!.MessageId,
                SenderId = messageWithSender.SenderId,
                SenderName = $"{messageWithSender.Sender.FirstName} {messageWithSender.Sender.LastName}",
                Content = messageWithSender.Content,
                PropertyId = messageWithSender.PropertyId,
                PropertyName = messageWithSender.Property?.Name,
                PropertyLocation = messageWithSender.Property?.Location,
                PropertyImageUrl = messageWithSender.Property?.ImageUrl,
                CreatedAt = messageWithSender.CreatedAt,
                IsRead = messageWithSender.IsRead
            });
        }

        // POST: api/chat/{chatId}/take - Sales takes an available chat
        [HttpPost("{chatId}/take")]
        public async Task<IActionResult> TakeChat(Guid chatId)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null || account.RoleId != Role.SALES_ROLE_ID)
                return Forbid();

            var salesAccount = account as SalesAccount;
            if (salesAccount == null || !salesAccount.AssignedDeveloperId.HasValue)
                return BadRequest("Sales account must be assigned to a developer.");

            var chat = await _context.Chats
                .Include(c => c.Developer)
                .FirstOrDefaultAsync(c => c.ChatId == chatId);

            if (chat == null)
                return NotFound("Chat not found");

            // Verify chat is for the sales member's assigned developer
            if (chat.DeveloperId != salesAccount.AssignedDeveloperId.Value)
                return Forbid("You can only take chats for your assigned developer.");

            // Check if chat is already taken
            if (chat.SalesMemberId.HasValue)
            {
                if (chat.SalesMemberId == accountId)
                    return Ok(new { message = "You already have this chat.", chatId = chat.ChatId });
                return BadRequest("This chat has already been taken by another sales member.");
            }

            // Assign chat to this sales member
            chat.SalesMemberId = accountId.Value;
            await _context.SaveChangesAsync();

            // Note: Firestore will be updated when messages are sent/received
            // No need to update Firestore here as chat structure doesn't change significantly

            return Ok(new { 
                message = "Chat taken successfully.", 
                chatId = chat.ChatId,
                salesMemberId = accountId.Value
            });
        }

        // PUT: api/chat/{chatId}/read - Mark messages as read
        [HttpPut("{chatId}/read")]
        public async Task<IActionResult> MarkAsRead(Guid chatId)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null)
                return Unauthorized();

            var chat = await _context.Chats
                .Include(c => c.Messages)
                .FirstOrDefaultAsync(c => c.ChatId == chatId);

            if (chat == null)
                return NotFound("Chat not found");

            // Verify user has access to this chat (user, developer, assigned sales, or admin)
            if (account.RoleId != Role.ADMIN_ROLE_ID && 
                chat.UserId != accountId && 
                chat.DeveloperId != accountId && 
                chat.SalesMemberId != accountId)
                return Forbid();

            // Mark all unread messages from the other person as read
            var unreadMessages = chat.Messages
                .Where(m => !m.IsRead && m.SenderId != accountId)
                .ToList();

            foreach (var message in unreadMessages)
            {
                message.IsRead = true;
            }

            await _context.SaveChangesAsync();

            // Update Firestore
            await _firestoreService.MarkChatMessagesAsReadAsync(chatId, accountId.Value);

            return NoContent();
        }

        // PUT: api/chat/{chatId}/assign - Assign or unassign sales member to chat (Admin or Developer)
        [HttpPut("{chatId}/assign")]
        public async Task<IActionResult> AssignSalesMember(Guid chatId, [FromBody] AssignSalesMemberDto dto)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null)
                return Unauthorized();

            var chat = await _context.Chats
                .Include(c => c.Developer)
                .Include(c => c.SalesMember)
                .FirstOrDefaultAsync(c => c.ChatId == chatId);

            if (chat == null)
                return NotFound("Chat not found");

            // Only admin or the developer who owns the chat can assign sales members
            if (account.RoleId != Role.ADMIN_ROLE_ID && chat.DeveloperId != accountId)
                return Forbid();

            // If salesMemberId is provided, verify it's a valid sales member assigned to this developer
            if (dto.SalesMemberId.HasValue)
            {
                var salesMember = await _context.Accounts.FindAsync(dto.SalesMemberId.Value);
                if (salesMember == null || salesMember.RoleId != Role.SALES_ROLE_ID)
                    return BadRequest("Invalid sales member");

                var salesMemberAccount = salesMember as SalesAccount;
                // Verify sales member is assigned to this developer (unless admin)
                if (account.RoleId != Role.ADMIN_ROLE_ID && (salesMemberAccount == null || salesMemberAccount.AssignedDeveloperId != chat.DeveloperId))
                    return BadRequest("Sales member must be assigned to this developer");
            }

            chat.SalesMemberId = dto.SalesMemberId;
            await _context.SaveChangesAsync();

            // Reload to get updated sales member name
            await _context.Entry(chat).Reference(c => c.SalesMember).LoadAsync();

            return Ok(new
            {
                chatId = chat.ChatId,
                salesMemberId = chat.SalesMemberId,
                salesMemberName = chat.SalesMember != null ? FormatAccountName(chat.SalesMember as AccountBase) : null
            });
        }

        // GET: api/chat/developers - Get developers with chat counts (for admin folder view)
        [HttpGet("developers")]
        public async Task<ActionResult<List<DeveloperChatCountDto>>> GetDevelopersWithChats()
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null)
                return Unauthorized();

            // Only admins can see all developers
            if (account.RoleId != Role.ADMIN_ROLE_ID)
                return Forbid();

            // Get developers and order by FirstName, then LastName (EF can translate this)
            var developers = await _context.Accounts
                .Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID)
                .OrderBy(a => a.FirstName)
                .ThenBy(a => a.LastName)
                .Select(a => new DeveloperChatCountDto
                {
                    DeveloperId = a.AccountId,
                    DeveloperName = $"{a.FirstName} {a.LastName}",
                    Email = a.Email,
                    ChatCount = _context.Chats.Count(c => c.DeveloperId == a.AccountId && c.IsActive)
                })
                .ToListAsync();

            return Ok(developers);
        }

        // GET: api/chat/{developerId}/sales-members - Get sales members for a developer
        [HttpGet("{developerId}/sales-members")]
        public async Task<ActionResult<List<SalesMemberDto>>> GetSalesMembersForDeveloper(Guid developerId)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null)
                return Unauthorized();

            // Verify developer exists
            var developer = await _context.Accounts.FindAsync(developerId);
            if (developer == null || developer.RoleId != Role.DEVELOPER_ROLE_ID)
                return NotFound("Developer not found");

            // Only admin or the developer can see their sales members
            if (account.RoleId != Role.ADMIN_ROLE_ID && accountId != developerId)
                return Forbid();

            var salesMembers = await _context.SalesAccounts
                .Where(a => a.RoleId == Role.SALES_ROLE_ID && a.AssignedDeveloperId == developerId)
                .Select(a => new SalesMemberDto
                {
                    AccountId = a.AccountId,
                    FirstName = a.FirstName,
                    LastName = a.LastName,
                    Email = a.Email
                })
                .OrderBy(s => s.FirstName)
                .ToListAsync();

            return Ok(salesMembers);
        }

        // GET: api/chat/stats - Get chat statistics
        [HttpGet("stats")]
        public async Task<ActionResult<ChatStatsDto>> GetChatStats([FromQuery] Guid? developerId = null)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null)
                return Unauthorized();

            IQueryable<Chat> chatQuery = _context.Chats.Where(c => c.IsActive);

            // Filter by developer if provided or if current user is a developer
            if (developerId.HasValue)
            {
                chatQuery = chatQuery.Where(c => c.DeveloperId == developerId.Value);
            }
            else if (account.RoleId == Role.DEVELOPER_ROLE_ID)
            {
                chatQuery = chatQuery.Where(c => c.DeveloperId == accountId.Value);
            }
            else if (account.RoleId != Role.ADMIN_ROLE_ID)
            {
                // Regular users only see their own chats
                chatQuery = chatQuery.Where(c => c.UserId == accountId.Value);
            }

            var chats = await chatQuery.ToListAsync();
            var chatIds = chats.Select(c => c.ChatId).ToList();

            var stats = new ChatStatsDto
            {
                TotalChats = chats.Count,
                TotalMessages = await _context.ChatMessages.CountAsync(m => chatIds.Contains(m.ChatId)),
                TotalUsers = chats.Select(c => c.UserId).Distinct().Count(),
                AssignedChats = chats.Count(c => c.SalesMemberId.HasValue),
                UnassignedChats = chats.Count(c => !c.SalesMemberId.HasValue),
                TotalSalesMembers = chats.Where(c => c.SalesMemberId.HasValue)
                    .Select(c => c.SalesMemberId!.Value)
                    .Distinct()
                    .Count()
            };

            return Ok(stats);
        }

        // DELETE: api/chat/cleanup - Auto-delete messages older than 30 days
        [HttpDelete("cleanup")]
        [AllowAnonymous] // Called by background service
        public async Task<IActionResult> CleanupExpiredMessages()
        {
            var now = DateTime.UtcNow;
            var expiredMessages = await _context.ChatMessages
                .Where(m => m.ExpiresAt <= now)
                .ToListAsync();

            _context.ChatMessages.RemoveRange(expiredMessages);
            await _context.SaveChangesAsync();

            return Ok(new { DeletedCount = expiredMessages.Count });
        }

        private string FormatAccountName(AccountBase? account)
        {
            if (account == null) return "Unknown";
            var first = account.FirstName?.Trim();
            var last = account.LastName?.Trim();

            if (!string.IsNullOrWhiteSpace(first) && !string.IsNullOrWhiteSpace(last))
            {
                return $"{first} {last}".Trim();
            }

            if (!string.IsNullOrWhiteSpace(first))
            {
                return first;
            }

            if (!string.IsNullOrWhiteSpace(last))
            {
                return last;
            }

            return account.Email;
        }
    }

    // DTOs
    public class ChatDto
    {
        public Guid ChatId { get; set; }
        public Guid UserId { get; set; }
        public string? UserName { get; set; }
        public Guid DeveloperId { get; set; }
        public string? DeveloperName { get; set; }
        public Guid? ProjectId { get; set; }
        public string? ProjectName { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastMessageAt { get; set; }
        public bool IsActive { get; set; }
        public string? LastMessage { get; set; }
        public int UnreadCount { get; set; }
        public bool IsSupportChat { get; set; }
        public Guid? SalesMemberId { get; set; }
        public string? SalesMemberName { get; set; }
        public bool IsAvailable { get; set; } // For sales: indicates if chat is available to take
    }

    public class ChatDetailsDto
    {
        public Guid ChatId { get; set; }
        public Guid UserId { get; set; }
        public string? UserName { get; set; }
        public Guid DeveloperId { get; set; }
        public string? DeveloperName { get; set; }
        public Guid? ProjectId { get; set; }
        public string? ProjectName { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastMessageAt { get; set; }
        public bool IsActive { get; set; }
        public bool IsSupportChat { get; set; }
        public Guid? SalesMemberId { get; set; }
        public string? SalesMemberName { get; set; }
        public List<MessageDto> Messages { get; set; } = new();
    }

    public class MessageDto
    {
        public Guid MessageId { get; set; }
        public Guid SenderId { get; set; }
        public string? SenderName { get; set; }
        public string Content { get; set; } = string.Empty;
        public Guid? PropertyId { get; set; }
        public string? PropertyName { get; set; }
        public string? PropertyLocation { get; set; }
        public string? PropertyImageUrl { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsRead { get; set; }
    }

    public class CreateChatDto
    {
        public Guid DeveloperId { get; set; }
        public Guid? ProjectId { get; set; }
    }

    public class SendMessageDto
    {
        public string Content { get; set; } = string.Empty;
        public Guid? PropertyId { get; set; }
    }

    public class AssignSalesMemberDto
    {
        public Guid? SalesMemberId { get; set; } // null to unassign
    }

    public class DeveloperChatCountDto
    {
        public Guid DeveloperId { get; set; }
        public string DeveloperName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public int ChatCount { get; set; }
    }

    public class ChatStatsDto
    {
        public int TotalChats { get; set; }
        public int TotalMessages { get; set; }
        public int TotalUsers { get; set; }
        public int AssignedChats { get; set; }
        public int UnassignedChats { get; set; }
        public int TotalSalesMembers { get; set; }
    }

    public class SalesMemberDto
    {
        public Guid AccountId { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
    }
}

