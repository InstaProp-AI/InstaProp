using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Extensions;
using InstapropAPI.Services;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class HelpChatController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly FirestoreService _firestoreService;
        private readonly FcmPushNotificationService _fcmService;

        private const string SupportEmail = "support@propertyflipper.app";
        private const string SupportPhone = "+201000000000";
        private const string SupportFirstName = "Customer";
        private const string SupportLastName = "Support";

        public HelpChatController(
            AppDbContext context,
            FirestoreService firestoreService,
            FcmPushNotificationService fcmService)
        {
            _context = context;
            _firestoreService = firestoreService;
            _fcmService = fcmService;
        }

        [HttpGet]
        public async Task<ActionResult<HelpChatDetailsDto>> GetSupportChat([FromQuery] int top = 20)
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null)
            {
                return Unauthorized();
            }

            var supportAccount = await EnsureSupportAccountAsync();

            var chat = await _context.Chats
                .Where(c => c.UserId == accountId && c.DeveloperId == supportAccount.AccountId && c.IsSupportChat)
                .Include(c => c.Messages.OrderByDescending(m => m.CreatedAt).Take(top))
                    .ThenInclude(m => m.Sender)
                .FirstOrDefaultAsync();

            if (chat == null)
            {
                return Ok(new HelpChatDetailsDto
                {
                    ChatId = null,
                    SupportTitle = GetSupportTitle(supportAccount),
                    Messages = new List<HelpChatMessageDto>()
                });
            }

            var messages = chat.Messages
                .OrderBy(m => m.CreatedAt)
                .Select(m => new HelpChatMessageDto
                {
                    MessageId = m.MessageId,
                    SenderId = m.SenderId,
                    SenderName = FormatAccountName(m.Sender),
                    Content = m.Content,
                    CreatedAt = m.CreatedAt,
                    IsMine = m.SenderId == accountId
                })
                .ToList();

            return Ok(new HelpChatDetailsDto
            {
                ChatId = chat.ChatId,
                SupportTitle = GetSupportTitle(supportAccount),
                Messages = messages
            });
        }

        [HttpPost("messages")]
        public async Task<ActionResult<HelpChatSendResponse>> SendSupportMessage([FromBody] HelpChatMessageRequest request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.Content))
            {
                return BadRequest("Message content is required");
            }

            var accountId = GetCurrentAccountId();
            if (accountId == null)
            {
                return Unauthorized();
            }

            var supportAccount = await EnsureSupportAccountAsync();

            var chat = await _context.Chats
                .Include(c => c.User)
                .Include(c => c.Developer)
                .FirstOrDefaultAsync(c => c.UserId == accountId && c.DeveloperId == supportAccount.AccountId && c.IsSupportChat);

            var isNewChat = false;

            if (chat == null)
            {
                chat = new Chat
                {
                    UserId = accountId.Value,
                    DeveloperId = supportAccount.AccountId,
                    CreatedAt = DateTime.UtcNow,
                    LastMessageAt = DateTime.UtcNow,
                    IsActive = true,
                    IsSupportChat = true
                };

                _context.Chats.Add(chat);
                await _context.SaveChangesAsync();

                await _firestoreService.CreateChatAsync(chat.ChatId, chat.UserId, chat.DeveloperId, chat.ProjectId);

                // Reload with navigation properties for consistent downstream logic
                chat = await _context.Chats
                    .Include(c => c.User)
                    .Include(c => c.Developer)
                    .FirstAsync(c => c.ChatId == chat.ChatId);

                isNewChat = true;
            }

            var message = new ChatMessage
            {
                ChatId = chat.ChatId,
                SenderId = accountId.Value,
                Content = request.Content.Trim(),
                CreatedAt = DateTime.UtcNow,
                IsRead = false,
                ExpiresAt = DateTime.UtcNow.AddDays(30)
            };

            _context.ChatMessages.Add(message);
            chat.LastMessageAt = message.CreatedAt;
            chat.IsSupportChat = true;
            chat.IsActive = true;

            await _context.SaveChangesAsync();

            await _firestoreService.SendChatMessageAsync(
                chat.ChatId,
                message.MessageId,
                message.SenderId,
                message.Content,
                null,
                message.CreatedAt,
                message.ExpiresAt);

            await _fcmService.SendChatNotificationAsync(
                chat.DeveloperId,
                $"New customer support request",
                message.Content.Length > 100 ? message.Content[..100] + "..." : message.Content);

            var senderAccount = await _context.Accounts.FindAsync(accountId.Value);

            return Ok(new HelpChatSendResponse
            {
                ChatId = chat.ChatId,
                CreatedNewChat = isNewChat,
                SupportTitle = GetSupportTitle(supportAccount),
                Message = new HelpChatMessageDto
                {
                    MessageId = message.MessageId,
                    SenderId = message.SenderId,
                    SenderName = senderAccount != null
                        ? FormatAccountName(senderAccount)
                        : "You",
                    Content = message.Content,
                    CreatedAt = message.CreatedAt,
                    IsMine = true
                }
            });
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

        private async Task<Account> EnsureSupportAccountAsync()
        {
            var supportAccount = await _context.Accounts
                .FirstOrDefaultAsync(a => a.Email == SupportEmail);

            if (supportAccount != null)
            {
                return supportAccount;
            }

            supportAccount = new Account
            {
                FirstName = SupportFirstName,
                LastName = SupportLastName,
                Email = SupportEmail,
                PhoneNumber = SupportPhone,
                RoleId = Role.DEVELOPER_ROLE_ID, // SECURITY: Use non-guessable RoleId
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow,
                ShowInDirectory = false
            };

            _context.Accounts.Add(supportAccount);
            await _context.SaveChangesAsync();

            return supportAccount;
        }

        private static string GetSupportTitle(Account supportAccount)
        {
            return FormatAccountNameStatic(supportAccount);
        }

        private static string FormatAccountName(Account account)
        {
            return FormatAccountNameStatic(account);
        }

        private static string FormatAccountNameStatic(Account account)
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

    public class HelpChatDetailsDto
    {
        public long? ChatId { get; set; }
        public string SupportTitle { get; set; } = "Customer Support";
        public List<HelpChatMessageDto> Messages { get; set; } = new();
    }

    public class HelpChatMessageDto
    {
        public long MessageId { get; set; }
        public long SenderId { get; set; }
        public string SenderName { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public bool IsMine { get; set; }
    }

    public class HelpChatMessageRequest
    {
        public string Content { get; set; } = string.Empty;
    }

    public class HelpChatSendResponse
    {
        public long ChatId { get; set; }
        public bool CreatedNewChat { get; set; }
        public string SupportTitle { get; set; } = "Customer Support";
        public HelpChatMessageDto Message { get; set; } = new();
    }
}
