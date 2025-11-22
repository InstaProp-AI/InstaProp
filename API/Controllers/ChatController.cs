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

        private long? GetCurrentAccountId()
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim != null && long.TryParse(accountIdClaim.Value, out long accountId))
            {
                return accountId;
            }
            return null;
        }

        // GET: api/chat - Get user's chat list
        [HttpGet]
        public async Task<ActionResult<IEnumerable<ChatDto>>> GetChats()
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
                if (!account.AssignedDeveloperId.HasValue)
                    return Ok(new List<ChatDto>()); // Sales without developer assignment see nothing

                chatQuery = _context.Chats
                    .Where(c => 
                        c.SalesMemberId == accountId || // Chats I've taken
                        (c.DeveloperId == account.AssignedDeveloperId.Value && c.SalesMemberId == null) // Available chats for my developer
                    );
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
                UserName = FormatAccountName(c.User),
                DeveloperId = c.DeveloperId,
                DeveloperName = FormatAccountName(c.Developer),
                ProjectId = c.ProjectId,
                ProjectName = c.Project?.Name,
                CreatedAt = c.CreatedAt,
                LastMessageAt = c.LastMessageAt,
                IsActive = c.IsActive,
                LastMessage = c.Messages.FirstOrDefault()?.Content,
                UnreadCount = c.Messages.Count(m => !m.IsRead && m.SenderId != accountId),
                IsSupportChat = c.IsSupportChat,
                SalesMemberId = c.SalesMemberId,
                SalesMemberName = c.SalesMember != null ? FormatAccountName(c.SalesMember) : null,
                IsAvailable = account.RoleId == Role.SALES_ROLE_ID && c.SalesMemberId == null // Available for sales to take
            }).ToList();

            return Ok(chatDtos);
        }

        // GET: api/chat/{chatId} - Get specific chat with messages
        [HttpGet("{chatId}")]
        public async Task<ActionResult<ChatDetailsDto>> GetChat(long chatId)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var chat = await _context.Chats
                .Include(c => c.User)
                .Include(c => c.Developer)
                .Include(c => c.Project)
                .Include(c => c.Messages.OrderBy(m => m.CreatedAt))
                    .ThenInclude(m => m.Sender)
                .Include(c => c.Messages)
                    .ThenInclude(m => m.Property)
                .FirstOrDefaultAsync(c => c.ChatId == chatId);

            if (chat == null)
                return NotFound("Chat not found");

            // Verify user has access to this chat (user, developer, or assigned sales)
            if (chat.UserId != accountId && chat.DeveloperId != accountId && chat.SalesMemberId != accountId)
                return Forbid();

            var chatDetails = new ChatDetailsDto
            {
                ChatId = chat.ChatId,
                UserId = chat.UserId,
                UserName = FormatAccountName(chat.User),
                DeveloperId = chat.DeveloperId,
                DeveloperName = FormatAccountName(chat.Developer),
                ProjectId = chat.ProjectId,
                ProjectName = chat.Project?.Name,
                CreatedAt = chat.CreatedAt,
                LastMessageAt = chat.LastMessageAt,
                IsActive = chat.IsActive,
                IsSupportChat = chat.IsSupportChat,
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
                    DeveloperName = FormatAccountName(existingChat.Developer),
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
                DeveloperName = FormatAccountName(developer),
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
        public async Task<ActionResult<MessageDto>> SendMessage(long chatId, [FromBody] SendMessageDto dto)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var chat = await _context.Chats
                .Include(c => c.User)
                .Include(c => c.Developer)
                .FirstOrDefaultAsync(c => c.ChatId == chatId);

            if (chat == null)
                return NotFound("Chat not found");

            // Verify user has access to this chat (user, developer, or assigned sales member)
            if (chat.UserId != accountId && chat.DeveloperId != accountId && chat.SalesMemberId != accountId)
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
                PropertyId = (int?)dto.PropertyId,
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
                var salesTeam = await _context.Accounts
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
        public async Task<IActionResult> TakeChat(long chatId)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var account = await _context.Accounts.FindAsync(accountId.Value);
            if (account == null || account.RoleId != Role.SALES_ROLE_ID)
                return Forbid("Only sales team members can take chats.");

            if (!account.AssignedDeveloperId.HasValue)
                return BadRequest("Sales account must be assigned to a developer.");

            var chat = await _context.Chats
                .Include(c => c.Developer)
                .FirstOrDefaultAsync(c => c.ChatId == chatId);

            if (chat == null)
                return NotFound("Chat not found");

            // Verify chat is for the sales member's assigned developer
            if (chat.DeveloperId != account.AssignedDeveloperId.Value)
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
        public async Task<IActionResult> MarkAsRead(long chatId)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
                return Unauthorized();

            var chat = await _context.Chats
                .Include(c => c.Messages)
                .FirstOrDefaultAsync(c => c.ChatId == chatId);

            if (chat == null)
                return NotFound("Chat not found");

            // Verify user has access to this chat (user, developer, or assigned sales)
            if (chat.UserId != accountId && chat.DeveloperId != accountId && chat.SalesMemberId != accountId)
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

        private string FormatAccountName(Account account)
        {
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
        public long ChatId { get; set; }
        public long UserId { get; set; }
        public string? UserName { get; set; }
        public long DeveloperId { get; set; }
        public string? DeveloperName { get; set; }
        public long? ProjectId { get; set; }
        public string? ProjectName { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastMessageAt { get; set; }
        public bool IsActive { get; set; }
        public string? LastMessage { get; set; }
        public int UnreadCount { get; set; }
        public bool IsSupportChat { get; set; }
        public long? SalesMemberId { get; set; }
        public string? SalesMemberName { get; set; }
        public bool IsAvailable { get; set; } // For sales: indicates if chat is available to take
    }

    public class ChatDetailsDto
    {
        public long ChatId { get; set; }
        public long UserId { get; set; }
        public string? UserName { get; set; }
        public long DeveloperId { get; set; }
        public string? DeveloperName { get; set; }
        public long? ProjectId { get; set; }
        public string? ProjectName { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastMessageAt { get; set; }
        public bool IsActive { get; set; }
        public bool IsSupportChat { get; set; }
        public List<MessageDto> Messages { get; set; } = new();
    }

    public class MessageDto
    {
        public long MessageId { get; set; }
        public long SenderId { get; set; }
        public string? SenderName { get; set; }
        public string Content { get; set; } = string.Empty;
        public long? PropertyId { get; set; }
        public string? PropertyName { get; set; }
        public string? PropertyLocation { get; set; }
        public string? PropertyImageUrl { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsRead { get; set; }
    }

    public class CreateChatDto
    {
        public long DeveloperId { get; set; }
        public long? ProjectId { get; set; }
    }

    public class SendMessageDto
    {
        public string Content { get; set; } = string.Empty;
        public long? PropertyId { get; set; }
    }
}

