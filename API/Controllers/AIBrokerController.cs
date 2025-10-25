using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using PropertyFlipperAPI.Services;
using System.Text.Json;

namespace PropertyFlipperAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class AIBrokerController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly OpenAIService _openAIService;
        private readonly ILogger<AIBrokerController> _logger;

        public AIBrokerController(AppDbContext context, OpenAIService openAIService, ILogger<AIBrokerController> logger)
        {
            _context = context;
            _openAIService = openAIService;
            _logger = logger;
        }

        private long? GetCurrentAccountId()
        {
            var userIdClaim = User.FindFirst("uid");
            if (userIdClaim != null && long.TryParse(userIdClaim.Value, out long userId))
            {
                return userId;
            }
            return null;
        }

        // POST: api/AIBroker/start-conversation
        [HttpPost("start-conversation")]
        public async Task<ActionResult<AIBrokerConversationDto>> StartConversation()
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            try
            {
                _logger.LogInformation($"Starting AI Broker conversation for user {userId}");

                // Create new AI chat session
                var aiChat = new AIChat
                {
                    UserId = userId.Value,
                    StartedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    Status = "Active"
                };

                _context.AIChats.Add(aiChat);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"Created AI Chat with ID: {aiChat.AIChatId}");

                // Generate budget options from database
                var budgetOptions = await GenerateBudgetOptions();
                _logger.LogInformation($"Generated {budgetOptions.Count} budget options");

                // Create initial greeting message
                var greetingMessage = new AIChatMessage
                {
                    AIChatId = aiChat.AIChatId,
                    Role = "Assistant",
                    Content = "Hi! I'm your personal broker assistant 👋 I'll help you find the perfect property! What's your budget range?",
                    MessageType = "OptionsPrompt",
                    QuestionType = "budget",
                    Options = JsonSerializer.Serialize(budgetOptions),
                    CreatedAt = DateTime.UtcNow
                };

                _context.AIChatMessages.Add(greetingMessage);
                await _context.SaveChangesAsync();

                return Ok(new AIBrokerConversationDto
                {
                    AIChatId = aiChat.AIChatId,
                    Messages = new List<AIBrokerMessageDto>
                    {
                        new AIBrokerMessageDto
                        {
                            MessageId = greetingMessage.MessageId,
                            Role = "Assistant",
                            Content = greetingMessage.Content,
                            MessageType = "OptionsPrompt",
                            Options = budgetOptions,
                            QuestionType = "budget",
                            CreatedAt = greetingMessage.CreatedAt
                        }
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error starting AI broker conversation");
                return StatusCode(500, new { message = $"Error starting conversation: {ex.Message}", details = ex.ToString() });
            }
        }

        // POST: api/AIBroker/send-message
        [HttpPost("send-message")]
        public async Task<ActionResult<AIBrokerResponseDto>> SendMessage([FromBody] AIBrokerMessageRequest request)
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            try
            {
                // Verify chat belongs to user
                var aiChat = await _context.AIChats
                    .Include(c => c.Messages)
                    .FirstOrDefaultAsync(c => c.AIChatId == request.AIChatId && c.UserId == userId);

                if (aiChat == null)
                    return NotFound("Chat not found");

                // Save user's message
                var userMessage = new AIChatMessage
                {
                    AIChatId = aiChat.AIChatId,
                    Role = "User",
                    Content = request.Message,
                    MessageType = "Text",
                    CreatedAt = DateTime.UtcNow
                };

                _context.AIChatMessages.Add(userMessage);
                await _context.SaveChangesAsync();

                // Update preferences
                var preferences = string.IsNullOrEmpty(aiChat.UserPreferences)
                    ? new UserPreferences()
                    : JsonSerializer.Deserialize<UserPreferences>(aiChat.UserPreferences) ?? new UserPreferences();

                // Update preferences based on user response
                UpdatePreferences(preferences, request.QuestionType, request.Message);

                aiChat.UserPreferences = JsonSerializer.Serialize(preferences);
                aiChat.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                // Use OpenAI to determine next response
                var conversationHistory = aiChat.Messages
                    .OrderBy(m => m.CreatedAt)
                    .Select(m => new PropertyFlipperAPI.Services.BrokerConversationMessage
                    {
                        Role = m.Role,
                        Content = m.Content
                    })
                    .ToList();

                var locations = await GenerateLocationOptions();
                var prefsString = $"Budget: {preferences.Budget ?? "Not set"}, Location: {preferences.Location ?? "Not set"}, Bedrooms: {preferences.Bedrooms}, Bathrooms: {preferences.Bathrooms}, Type: {preferences.PropertyType ?? "Not set"}";

                var aiResponse = await _openAIService.GetBrokerResponseAsync(
                    conversationHistory,
                    string.Join(", ", locations),
                    prefsString
                );

                // Process AI response
                var response = await ProcessAIResponse(aiChat, aiResponse, preferences);

                _logger.LogInformation($"Generated {response.Messages.Count} response messages");

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending message to AI broker");
                return StatusCode(500, new { message = $"Error processing message: {ex.Message}" });
            }
        }

        // GET: api/AIBroker/conversation/{id}
        [HttpGet("conversation/{id}")]
        public async Task<ActionResult<AIBrokerConversationDto>> GetConversation(long id)
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            var aiChat = await _context.AIChats
                .Include(c => c.Messages)
                .FirstOrDefaultAsync(c => c.AIChatId == id && c.UserId == userId);

            if (aiChat == null)
                return NotFound();

            var messages = aiChat.Messages.Select(m => new AIBrokerMessageDto
            {
                MessageId = m.MessageId,
                Role = m.Role,
                Content = m.Content,
                MessageType = m.MessageType,
                Options = string.IsNullOrEmpty(m.Options)
                    ? null
                    : JsonSerializer.Deserialize<List<string>>(m.Options),
                QuestionType = m.QuestionType,
                PropertyId = m.PropertyId,
                ProjectId = m.ProjectId,
                DeveloperId = m.DeveloperId,
                CreatedAt = m.CreatedAt
            }).ToList();

            return Ok(new AIBrokerConversationDto
            {
                AIChatId = aiChat.AIChatId,
                Messages = messages
            });
        }

        // GET: api/AIBroker/my-chats
        [HttpGet("my-chats")]
        public async Task<ActionResult<List<AIBrokerChatSummaryDto>>> GetMyAIChats()
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            var aiChats = await _context.AIChats
                .Include(c => c.Messages)
                .Where(c => c.UserId == userId)
                .OrderByDescending(c => c.UpdatedAt)
                .ToListAsync();

            var summaries = aiChats.Select(c => new AIBrokerChatSummaryDto
            {
                AIChatId = c.AIChatId,
                Status = c.Status,
                LastMessage = c.Messages.OrderByDescending(m => m.CreatedAt).FirstOrDefault()?.Content ?? "No messages",
                LastMessageAt = c.UpdatedAt,
                MessageCount = c.Messages.Count
            }).ToList();

            return Ok(summaries);
        }

        // GET: api/AIBroker/active-chat
        [HttpGet("active-chat")]
        public async Task<ActionResult<AIBrokerChatSummaryDto>> GetActiveChat()
        {
            var userId = GetCurrentAccountId();
            if (userId == null)
                return Unauthorized();

            // Get most recent active chat
            var activeChat = await _context.AIChats
                .Include(c => c.Messages)
                .Where(c => c.UserId == userId && c.Status == "Active")
                .OrderByDescending(c => c.UpdatedAt)
                .FirstOrDefaultAsync();

            if (activeChat == null)
                return NotFound();

            return Ok(new AIBrokerChatSummaryDto
            {
                AIChatId = activeChat.AIChatId,
                Status = activeChat.Status,
                LastMessage = activeChat.Messages.OrderByDescending(m => m.CreatedAt).FirstOrDefault()?.Content ?? "No messages",
                LastMessageAt = activeChat.UpdatedAt,
                MessageCount = activeChat.Messages.Count
            });
        }

        private async Task<List<string>> GenerateBudgetOptions()
        {
            try
            {
                // Query min/max prices from auctions
                var hasAuctions = await _context.Auctions.AnyAsync();
                
                // Return default ranges (can be enhanced later based on actual data)
                return new List<string>
                {
                    "Under $200k",
                    "$200k - $400k",
                    "$400k - $600k",
                    "$600k - $800k",
                    "Above $800k"
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating budget options");
                // Return default options on error
                return new List<string>
                {
                    "Under $200k",
                    "$200k - $400k",
                    "$400k - $600k",
                    "$600k - $800k",
                    "Above $800k"
                };
            }
        }

        private async Task<List<string>> GenerateLocationOptions()
        {
            try
            {
                // Get top 10 locations by property count
                var locations = await _context.ChildProperties
                    .Where(p => !string.IsNullOrEmpty(p.Location))
                    .GroupBy(p => p.Location)
                    .OrderByDescending(g => g.Count())
                    .Take(10)
                    .Select(g => g.Key!)
                    .ToListAsync();

                // Return default if no locations found
                if (locations.Count == 0)
                {
                    return new List<string> { "Downtown", "Suburbs", "Waterfront", "City Center" };
                }

                return locations;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating location options");
                return new List<string> { "Downtown", "Suburbs", "Waterfront", "City Center" };
            }
        }

        private async Task<AIBrokerResponseDto> ProcessAIResponse(AIChat chat, PropertyFlipperAPI.Services.BrokerAIResponse aiResponse, UserPreferences prefs)
        {
            var response = new AIBrokerResponseDto { Messages = new List<AIBrokerMessageDto>() };

            if (aiResponse.NextAction == "show_properties")
            {
                // AI determined we have enough info to show properties
                await GenerateRecommendations(chat, prefs, response);
            }
            else if (aiResponse.NextAction == "ask_question" && aiResponse.Options != null)
            {
                // AI is asking a question with options
                var message = new AIChatMessage
                {
                    AIChatId = chat.AIChatId,
                    Role = "Assistant",
                    Content = aiResponse.Message,
                    MessageType = "OptionsPrompt",
                    QuestionType = aiResponse.QuestionType,
                    Options = JsonSerializer.Serialize(aiResponse.Options),
                    CreatedAt = DateTime.UtcNow
                };
                _context.AIChatMessages.Add(message);
                await _context.SaveChangesAsync();

                response.Messages.Add(new AIBrokerMessageDto
                {
                    MessageId = message.MessageId,
                    Role = "Assistant",
                    Content = message.Content,
                    MessageType = "OptionsPrompt",
                    Options = aiResponse.Options,
                    QuestionType = aiResponse.QuestionType,
                    CreatedAt = message.CreatedAt
                });
            }
            else
            {
                // AI is just continuing conversation (text message)
                var message = new AIChatMessage
                {
                    AIChatId = chat.AIChatId,
                    Role = "Assistant",
                    Content = aiResponse.Message,
                    MessageType = "Text",
                    CreatedAt = DateTime.UtcNow
                };
                _context.AIChatMessages.Add(message);
                await _context.SaveChangesAsync();

                response.Messages.Add(new AIBrokerMessageDto
                {
                    MessageId = message.MessageId,
                    Role = "Assistant",
                    Content = message.Content,
                    MessageType = "Text",
                    CreatedAt = message.CreatedAt
                });
            }

            return response;
        }

        private void UpdatePreferences(UserPreferences prefs, string? questionType, string userMessage)
        {
            if (string.IsNullOrEmpty(questionType)) return;

            switch (questionType.ToLower())
            {
                case "budget":
                    prefs.Budget = userMessage;
                    break;
                case "location":
                    prefs.Location = userMessage;
                    break;
                case "bedrooms":
                    prefs.Bedrooms = ExtractNumber(userMessage);
                    break;
                case "bathrooms":
                    prefs.Bathrooms = ExtractNumber(userMessage);
                    break;
                case "propertytype":
                    prefs.PropertyType = userMessage;
                    break;
            }
        }

        private int ExtractNumber(string text)
        {
            var numbers = text.Where(char.IsDigit).ToArray();
            if (numbers.Length > 0)
            {
                return int.Parse(new string(numbers));
            }
            return 0;
        }

        // OLD METHOD - Removed and replaced with AI-driven ProcessAIResponse
        // The conversation is now managed entirely by OpenAI for natural, continuous dialogue

        private async Task GenerateRecommendations(AIChat chat, UserPreferences prefs, AIBrokerResponseDto response)
        {
            _logger.LogInformation("Starting GenerateRecommendations");

            // Searching message
            var searchingMessage = new AIChatMessage
            {
                AIChatId = chat.AIChatId,
                Role = "Assistant",
                Content = "Perfect! Let me search our database for the best matches... 🔍",
                MessageType = "Text",
                CreatedAt = DateTime.UtcNow
            };
            _context.AIChatMessages.Add(searchingMessage);
            await _context.SaveChangesAsync();

            response.Messages.Add(new AIBrokerMessageDto
            {
                MessageId = searchingMessage.MessageId,
                Role = "Assistant",
                Content = searchingMessage.Content,
                MessageType = "Text",
                CreatedAt = searchingMessage.CreatedAt
            });

            // Query matching properties and developers
            _logger.LogInformation("Querying matching properties...");
            var properties = await GetMatchingProperties(prefs);
            _logger.LogInformation($"Found {properties.Count} matching properties");

            _logger.LogInformation("Querying relevant developers...");
            var developers = await GetRelevantDevelopers(properties);
            _logger.LogInformation($"Found {developers.Count} developers");

            // If no properties found, send apologetic message
            if (properties.Count == 0)
            {
                var noResultsMessage = new AIChatMessage
                {
                    AIChatId = chat.AIChatId,
                    Role = "Assistant",
                    Content = "I apologize, but I couldn't find any properties matching your exact criteria in our current listings. Would you like to adjust your preferences and search again?",
                    MessageType = "Text",
                    CreatedAt = DateTime.UtcNow
                };
                _context.AIChatMessages.Add(noResultsMessage);
                await _context.SaveChangesAsync();

                response.Messages.Add(new AIBrokerMessageDto
                {
                    MessageId = noResultsMessage.MessageId,
                    Role = "Assistant",
                    Content = noResultsMessage.Content,
                    MessageType = "Text",
                    CreatedAt = noResultsMessage.CreatedAt
                });

                chat.Status = "Completed";
                await _context.SaveChangesAsync();
                return;
            }

            // Developer comparison message
            if (developers.Count >= 2)
            {
                var devMessage = new AIChatMessage
                {
                    AIChatId = chat.AIChatId,
                    Role = "Assistant",
                    Content = "Fantastic news! I found some great options for you! There are 2 excellent developers in the market that perfectly match your criteria. Here's a comparison between them. Take a look! 😊",
                    MessageType = "DeveloperComparison",
                    CreatedAt = DateTime.UtcNow
                };
                _context.AIChatMessages.Add(devMessage);
                await _context.SaveChangesAsync();

                response.Messages.Add(new AIBrokerMessageDto
                {
                    MessageId = devMessage.MessageId,
                    Role = "Assistant",
                    Content = devMessage.Content,
                    MessageType = "DeveloperComparison",
                    Developers = developers.Take(2).ToList(),
                    CreatedAt = devMessage.CreatedAt
                });

                _logger.LogInformation("Added developer comparison message");
            }
            else if (developers.Count == 1)
            {
                var devMessage = new AIChatMessage
                {
                    AIChatId = chat.AIChatId,
                    Role = "Assistant",
                    Content = "Great news! I found an excellent developer that matches your criteria perfectly!",
                    MessageType = "DeveloperComparison",
                    CreatedAt = DateTime.UtcNow
                };
                _context.AIChatMessages.Add(devMessage);
                await _context.SaveChangesAsync();

                response.Messages.Add(new AIBrokerMessageDto
                {
                    MessageId = devMessage.MessageId,
                    Role = "Assistant",
                    Content = devMessage.Content,
                    MessageType = "DeveloperComparison",
                    Developers = developers.Take(1).ToList(),
                    CreatedAt = devMessage.CreatedAt
                });

                _logger.LogInformation("Added single developer message");
            }

            // Property suggestions message - ALWAYS show if we have properties
            var propMessage = new AIChatMessage
            {
                AIChatId = chat.AIChatId,
                Role = "Assistant",
                Content = developers.Count > 0 
                    ? "These developers have some amazing projects in your budget and preferred location. Check out these properties:"
                    : "Here are some great properties that match your criteria:",
                MessageType = "PropertySuggestions",
                CreatedAt = DateTime.UtcNow
            };
            _context.AIChatMessages.Add(propMessage);
            await _context.SaveChangesAsync();

            response.Messages.Add(new AIBrokerMessageDto
            {
                MessageId = propMessage.MessageId,
                Role = "Assistant",
                Content = propMessage.Content,
                MessageType = "PropertySuggestions",
                Properties = properties.Take(3).ToList(),
                CreatedAt = propMessage.CreatedAt
            });

            _logger.LogInformation("Added property suggestions message");

            // DON'T mark chat as completed - keep it active for continuous conversation
            // The AI will continue helping the user after showing properties
            chat.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            _logger.LogInformation($"Recommendations complete. Total messages in response: {response.Messages.Count}");
            
            // After showing properties, AI will ask if they want to see more or refine search
            // This keeps the conversation continuous
        }

        private async Task<List<PropertySuggestionDto>> GetMatchingProperties(UserPreferences prefs)
        {
            try
            {
                _logger.LogInformation($"Searching properties with: Location={prefs.Location}, Bedrooms={prefs.Bedrooms}, Bathrooms={prefs.Bathrooms}, Type={prefs.PropertyType}");

                var query = _context.ChildProperties
                    .Include(p => p.Auctions)
                    .AsQueryable();

                // Filter by location (if specified)
                if (!string.IsNullOrEmpty(prefs.Location))
                {
                    query = query.Where(p => p.Location != null && p.Location.Contains(prefs.Location));
                }

                // Filter by bedrooms (if specified)
                if (prefs.Bedrooms > 0)
                {
                    query = query.Where(p => p.Bedrooms == prefs.Bedrooms);
                }

                // Filter by bathrooms (skip if "Any" or 0)
                if (prefs.Bathrooms > 0 && !prefs.PropertyType?.Contains("Any") == true)
                {
                    query = query.Where(p => p.Bathrooms >= prefs.Bathrooms);
                }

                // Filter by property type (skip if "Show Me Both")
                if (!string.IsNullOrEmpty(prefs.PropertyType) && !prefs.PropertyType.Contains("Both"))
                {
                    if (prefs.PropertyType.Contains("Primary") || prefs.PropertyType.Contains("New"))
                    {
                        query = query.Where(p => p.Type == PropertyType.Villa);
                    }
                    else if (prefs.PropertyType.Contains("Resale"))
                    {
                        query = query.Where(p => p.Type == PropertyType.Apartment);
                    }
                }

                // Get all matching properties (with or without auctions)
                var allProperties = await query.Take(20).ToListAsync();
                _logger.LogInformation($"Found {allProperties.Count} total properties before auction filter");

                // Prefer properties with auctions, but include others if needed
                var propertiesWithAuctions = allProperties
                    .Where(p => p.Auctions.Any(a => a.Status == "Active" || a.Status == "Approved"))
                    .ToList();

                var propertiesToUse = propertiesWithAuctions.Count > 0 ? propertiesWithAuctions : allProperties;
                _logger.LogInformation($"Using {propertiesToUse.Count} properties (with auctions: {propertiesWithAuctions.Count})");

                return propertiesToUse.Take(10).Select(p =>
                {
                    var auction = p.Auctions.FirstOrDefault(a => a.Status == "Active" || a.Status == "Approved");
                    return new PropertySuggestionDto
                    {
                        PropertyId = p.PropertyId,
                        Name = p.Name,
                        Location = p.Location ?? "",
                        Bedrooms = p.Bedrooms,
                        Bathrooms = p.Bathrooms,
                        SquareFeet = p.SquareFeet,
                        ImageUrl = p.ImageUrl,
                        Type = p.Type.ToString(),
                        Status = p.Status.ToString(),
                        AuctionId = auction?.AuctionId,
                        CurrentPrice = auction?.CurrentPrice ?? 0,
                        AuctionStartTime = auction?.StartAt,
                        AuctionStatus = auction?.Status
                    };
                }).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting matching properties");
                return new List<PropertySuggestionDto>();
            }
        }

        private async Task<List<DeveloperSuggestionDto>> GetRelevantDevelopers(List<PropertySuggestionDto> properties)
        {
            var developerIds = await _context.ChildProperties
                .Where(p => properties.Select(pr => pr.PropertyId).Contains(p.PropertyId))
                .Select(p => p.OwnerId)
                .Distinct()
                .ToListAsync();

            var developers = await _context.DeveloperProfiles
                .Include(d => d.Account)
                .Where(d => developerIds.Contains(d.AccountId))
                .ToListAsync();

            return developers.Select(d => new DeveloperSuggestionDto
            {
                DeveloperId = d.AccountId,
                Name = d.CompanyName ?? "Unknown Developer",
                CompanyName = d.CompanyName ?? "Independent Developer",
                AverageRating = (double)d.Rating,
                TotalProjects = _context.Projects.Count(p => p.DeveloperId == d.AccountId),
                TotalRatings = d.TotalRatings,
                Specialization = d.PortfolioDescription ?? "Real Estate Development"
            }).ToList();
        }
    }

    // DTOs
    public class AIBrokerMessageRequest
    {
        public long AIChatId { get; set; }
        public string Message { get; set; } = string.Empty;
        public string? QuestionType { get; set; }
    }

    public class AIBrokerConversationDto
    {
        public long AIChatId { get; set; }
        public List<AIBrokerMessageDto> Messages { get; set; } = new List<AIBrokerMessageDto>();
    }

    public class AIBrokerResponseDto
    {
        public List<AIBrokerMessageDto> Messages { get; set; } = new List<AIBrokerMessageDto>();
    }

    public class AIBrokerMessageDto
    {
        public long MessageId { get; set; }
        public string Role { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string MessageType { get; set; } = string.Empty;
        public List<string>? Options { get; set; }
        public string? QuestionType { get; set; }
        public long? PropertyId { get; set; }
        public long? ProjectId { get; set; }
        public long? DeveloperId { get; set; }
        public List<PropertySuggestionDto>? Properties { get; set; }
        public List<DeveloperSuggestionDto>? Developers { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class PropertySuggestionDto
    {
        public long PropertyId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public int SquareFeet { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public long? AuctionId { get; set; }
        public decimal CurrentPrice { get; set; }
        public DateTime? AuctionStartTime { get; set; }
        public string? AuctionStatus { get; set; }
    }

    public class DeveloperSuggestionDto
    {
        public long DeveloperId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string CompanyName { get; set; } = string.Empty;
        public double AverageRating { get; set; }
        public int TotalProjects { get; set; }
        public int TotalRatings { get; set; }
        public string Specialization { get; set; } = string.Empty;
    }

    public class UserPreferences
    {
        public string? Budget { get; set; }
        public string? Location { get; set; }
        public int Bedrooms { get; set; }
        public int Bathrooms { get; set; }
        public string? PropertyType { get; set; }
    }

    public class AIBrokerChatSummaryDto
    {
        public long AIChatId { get; set; }
        public string Status { get; set; } = string.Empty;
        public string LastMessage { get; set; } = string.Empty;
        public DateTime LastMessageAt { get; set; }
        public int MessageCount { get; set; }
    }
}

