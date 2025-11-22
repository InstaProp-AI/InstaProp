using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using BCrypt.Net;

namespace InstapropAPI.Services
{
    public class RealisticEgyptianSeedingService
    {
        private readonly AppDbContext _context;

        public RealisticEgyptianSeedingService(AppDbContext context)
        {
            _context = context;
        }

        // Helper method to get Unsplash URL
        private string GetUnsplashUrl(string photoId, int width = 800, int height = 600)
        {
            return $"https://images.unsplash.com/photo-{photoId}?w={width}&h={height}&fit=crop&auto=format";
        }

        // Helper method to get realistic passport/ID photo (using Unsplash portraits with ID-style look)
        private string GetPassportPhotoUrl(string photoId)
        {
            return $"https://images.unsplash.com/photo-{photoId}?w=400&h=500&fit=crop&auto=format";
        }

        public async Task SeedAllDataAsync(bool skipClear = false)
        {
            Console.WriteLine("🌍 Starting Realistic Egyptian Real Estate Data Seeding...");

            // Step 1: Clear existing data (skip if database was just dropped)
            if (!skipClear)
            {
                await ClearAllDataAsync();
            }
            else
            {
                Console.WriteLine("ℹ️ Skipping data clearing (fresh database).");
            }

            // Step 2: Seed Accounts (Users and Developers)
            var accounts = await SeedAccountsAsync();

            // Step 3: Seed Developer Permissions
            await SeedDeveloperPermissionsAsync(accounts.Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID).ToList());

            // Step 4: Seed Projects
            var projects = await SeedProjectsAsync(accounts.Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID).ToList());

            // Step 5: Seed Parent Properties
            var parentProperties = await SeedParentPropertiesAsync(projects);

            // Step 6: Seed Child Properties
            var childProperties = await SeedChildPropertiesAsync(parentProperties, accounts);

            // Step 7: Seed Property Images
            await SeedPropertyImagesAsync(childProperties);

            // Step 8: Seed Auctions
            var auctions = await SeedAuctionsAsync(childProperties);

            // Step 9: Seed Bids
            await SeedBidsAsync(auctions, accounts);

            // Step 10: Seed KYC Documents
            await SeedKycDocumentsAsync(accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList());

            // Step 11: Seed Communities
            var communities = await SeedCommunitiesAsync(projects, accounts);

            // Step 12: Seed Community Members
            await SeedCommunityMembersAsync(communities, accounts);

            // Step 13: Seed Community Posts
            var posts = await SeedCommunityPostsAsync(communities, accounts);

            // Step 14: Seed Post Reactions
            await SeedPostReactionsAsync(posts, accounts);

            // Step 15: Seed Post Likes
            await SeedPostLikesAsync(posts, accounts);

            // Step 16: Seed Post Comments
            var comments = await SeedPostCommentsAsync(posts, accounts);

            // Step 17: Seed Comment Reactions
            await SeedCommentReactionsAsync(comments, accounts);

            // Step 18: Seed Comment Likes
            await SeedCommentLikesAsync(comments, accounts);

            // Step 19: Seed News Articles
            var newsArticles = await SeedNewsArticlesAsync();

            // Step 20: Seed News Images
            await SeedNewsImagesAsync(newsArticles);

            await _context.SaveChangesAsync();
            Console.WriteLine("✅ Realistic Egyptian Real Estate Data Seeding Completed!");
        }

        // Public method to seed news articles only
        public async Task<List<NewsArticle>> SeedNewsOnlyAsync()
        {
            Console.WriteLine("📰 Seeding News Articles...");
            var articles = await SeedNewsArticlesAsync();
            await SeedNewsImagesAsync(articles);
            Console.WriteLine($"✅ Successfully seeded {articles.Count} news articles with images");
            return articles;
        }

        // Public method to seed news articles for each developer (3-5 articles per developer)
        public async Task<Dictionary<long, List<NewsArticle>>> SeedDeveloperNewsAsync()
        {
            Console.WriteLine("📰 Seeding News Articles for Developers...");
            
            // Get all developers
            var developers = await _context.Accounts
                .Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID)
                .ToListAsync();

            if (!developers.Any())
            {
                Console.WriteLine("⚠️ No developers found. Skipping developer news seeding.");
                return new Dictionary<long, List<NewsArticle>>();
            }

            var allArticles = new List<NewsArticle>();
            var developerNewsMap = new Dictionary<long, List<NewsArticle>>();
            var random = new Random();

            // News templates for developers
            var newsTemplates = new[]
            {
                new { Title = "New Property Launch in {Location}", Category = "Projects", Content = "We are excited to announce the launch of our new property development in {Location}. This project features modern architecture, premium finishes, and excellent location advantages.\n\nKey Features:\n• Prime location with easy access to main roads\n• Modern design with high-quality materials\n• Flexible payment plans available\n• Expected delivery within 18-24 months\n\nContact us for more information and to schedule a site visit." },
                new { Title = "Market Update: {Location} Real Estate Trends", Category = "Market Updates", Content = "The real estate market in {Location} continues to show strong growth potential. Recent infrastructure developments and government investments have contributed to increased property values.\n\nMarket Highlights:\n• Average price increase of 12-15% in the past year\n• High demand for residential units\n• Growing interest from international investors\n• Positive outlook for the next 2-3 years\n\nOur team is closely monitoring market trends to provide the best investment opportunities." },
                new { Title = "Investment Opportunity: {ProjectName} Phase 2", Category = "Investment", Content = "We are pleased to announce Phase 2 of our {ProjectName} development. Building on the success of Phase 1, Phase 2 offers even more amenities and improved designs.\n\nPhase 2 Features:\n• Enhanced unit layouts\n• Additional recreational facilities\n• Improved parking solutions\n• Better connectivity\n\nEarly bird discounts available for the first 50 reservations. Don't miss this opportunity!" },
                new { Title = "Construction Update: {ProjectName} Progress", Category = "Projects", Content = "We are happy to share the latest progress on {ProjectName}. Construction is proceeding on schedule with excellent quality standards.\n\nCurrent Status:\n• Foundation work: 100% complete\n• Structural work: 65% complete\n• MEP installations: 40% complete\n• Expected completion: On track for scheduled delivery\n\nWe will continue to provide regular updates on the project's progress." },
                new { Title = "Special Offer: Limited Time Investment Package", Category = "Investment", Content = "Take advantage of our limited-time investment package for {ProjectName}. This exclusive offer includes:\n\nPackage Benefits:\n• Flexible payment plans (up to 10 years)\n• Special pricing for early investors\n• Free parking space included\n• Premium finishing options\n• Guaranteed rental yield for first 2 years\n\nThis offer is valid for a limited time only. Contact our sales team to learn more." }
            };

            var newsImageIds = new[]
            {
                "1564013799919-bc007da7807a", "1560448204-e02f11c3d0e2", "1568605114967-8130f3a36994",
                "1600596542810-ff374b12c26e", "1600566753190-17f0baa2a6c3", "1600585154340-be6161a56a0b",
                "1600602045025-4a982f829bcf", "1600602045025-4a982f829bcf", "1600602045025-4a982f829bcf"
            };

            foreach (var developer in developers)
            {
                var developerArticles = new List<NewsArticle>();
                var articleCount = random.Next(3, 6); // 3-5 articles per developer
                var developerName = $"{developer.FirstName} {developer.LastName}".Trim();
                var locations = new[] { "New Administrative Capital", "6th October City", "Sheikh Zayed", "Madinaty", "Rehab City" };
                var projectNames = new[] { "Elite Residences", "Premium Heights", "Luxury Gardens", "Modern Living", "Elite Towers" };

                for (int i = 0; i < articleCount; i++)
                {
                    var template = newsTemplates[random.Next(newsTemplates.Length)];
                    var location = locations[random.Next(locations.Length)];
                    var projectName = projectNames[random.Next(projectNames.Length)];
                    
                    var title = template.Title
                        .Replace("{Location}", location)
                        .Replace("{ProjectName}", projectName);
                    
                    var content = template.Content
                        .Replace("{Location}", location)
                        .Replace("{ProjectName}", projectName);

                    var article = new NewsArticle
                    {
                        Title = title,
                        Content = content,
                        Category = template.Category,
                        PublishedDate = DateTime.UtcNow.AddDays(-random.Next(1, 30)),
                        IsPublished = true,
                        CreatedAt = DateTime.UtcNow.AddDays(-random.Next(2, 31)),
                        DeveloperId = developer.AccountId
                    };

                    developerArticles.Add(article);
                    allArticles.Add(article);
                }

                developerNewsMap[developer.AccountId] = developerArticles;
            }

            // Save all articles
            await _context.NewsArticles.AddRangeAsync(allArticles);
            await _context.SaveChangesAsync();

            // Add images to articles
            var images = new List<NewsImage>();
            var imageIndex = 0;
            foreach (var article in allArticles)
            {
                var imageId = newsImageIds[imageIndex % newsImageIds.Length];
                images.Add(new NewsImage
                {
                    NewsArticleId = article.NewsArticleId,
                    ImageUrl = GetUnsplashUrl(imageId, 1200, 600),
                    DisplayOrder = 0
                });
                imageIndex++;
            }

            await _context.NewsImages.AddRangeAsync(images);
            await _context.SaveChangesAsync();

            Console.WriteLine($"✅ Successfully seeded {allArticles.Count} news articles for {developers.Count} developers");
            return developerNewsMap;
        }

        // Public method to seed chats with messages for all developers
        public async Task<Dictionary<long, List<Chat>>> SeedChatsWithMessagesAsync()
        {
            Console.WriteLine("💬 Seeding Chats and Messages for Developers...");
            
            // Get all developers
            var developers = await _context.Accounts
                .Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID)
                .ToListAsync();

            if (!developers.Any())
            {
                Console.WriteLine("⚠️ No developers found. Skipping chat seeding.");
                return new Dictionary<long, List<Chat>>();
            }

            // Get all regular users
            var users = await _context.Accounts
                .Where(a => a.RoleId == Role.USER_ROLE_ID)
                .ToListAsync();

            if (!users.Any())
            {
                Console.WriteLine("⚠️ No users found. Skipping chat seeding.");
                return new Dictionary<long, List<Chat>>();
            }

            // Get projects for developers
            var projects = await _context.Projects
                .Where(p => p.IsActive)
                .ToListAsync();

            // Get sales team members
            var salesMembers = await _context.Accounts
                .Where(a => a.RoleId == Role.SALES_ROLE_ID && a.AssignedDeveloperId.HasValue)
                .ToListAsync();

            var allChats = new List<Chat>();
            var developerChatMap = new Dictionary<long, List<Chat>>();
            var random = new Random();

            // Message templates
            var userMessageTemplates = new[]
            {
                "Hello, I'm interested in your properties. Can you tell me more?",
                "What properties do you have available in {Location}?",
                "I'm looking for a {Type} property. What are my options?",
                "What's the price range for properties in {Project}?",
                "Can I schedule a site visit?",
                "Are there any special offers or discounts available?",
                "What payment plans do you offer?",
                "When will {Project} be completed?",
                "What amenities are included in the project?",
                "Is financing available through banks?",
                "What's the down payment requirement?",
                "Are there any maintenance fees?",
                "Can you send me more details about the property?",
                "What's the square footage of the units?",
                "Is parking included?"
            };

            var developerMessageTemplates = new[]
            {
                "Hello! Thank you for your interest. I'd be happy to help you find the perfect property.",
                "We have several properties available in {Location}. Let me share some options with you.",
                "Our {Project} project offers {Type} units with modern finishes and excellent location.",
                "The price range for properties in {Project} starts from {Price} EGP.",
                "Absolutely! I can schedule a site visit for you. When would be convenient?",
                "Yes, we have special offers for early investors. Let me provide you with the details.",
                "We offer flexible payment plans up to 10 years with competitive interest rates.",
                "{Project} is expected to be completed by {Date}. Construction is progressing well.",
                "The project includes parking, 24/7 security, swimming pool, gym, and beautiful gardens.",
                "Yes, financing is available through several partner banks. I can provide details.",
                "The down payment is 15% of the total price, payable over 12 months.",
                "Maintenance fees are approximately 80 EGP per square meter annually.",
                "I'll send you detailed information about the property right away.",
                "The units range from 100 to 300 square meters, depending on the type.",
                "Yes, parking is included. Each unit comes with one or two parking spaces."
            };

            var locations = new[] { "New Administrative Capital", "6th October City", "Sheikh Zayed", "Madinaty", "Rehab City", "New Cairo" };
            var propertyTypes = new[] { "Apartment", "Villa", "Townhouse", "Duplex", "Penthouse" };
            var prices = new[] { "2,500,000", "3,500,000", "5,000,000", "7,500,000", "10,000,000" };
            var dates = new[] { "December 2024", "March 2025", "June 2025", "September 2025" };

            foreach (var developer in developers)
            {
                var developerChats = new List<Chat>();
                var chatCount = random.Next(3, 8); // 3-7 chats per developer
                var developerProjects = projects.Where(p => p.DeveloperId == developer.AccountId).ToList();
                var developerSalesMembers = salesMembers.Where(s => s.AssignedDeveloperId == developer.AccountId).ToList();

                for (int i = 0; i < chatCount; i++)
                {
                    // Select a random user
                    var user = users[random.Next(users.Count)];
                    
                    // Select a random project (or null)
                    Project? project = null;
                    if (developerProjects.Any())
                    {
                        project = developerProjects[random.Next(developerProjects.Count)];
                    }

                    // Create chat
                    var chat = new Chat
                    {
                        UserId = user.AccountId,
                        DeveloperId = developer.AccountId,
                        ProjectId = project?.ProjectId,
                        CreatedAt = DateTime.UtcNow.AddDays(-random.Next(1, 30)),
                        LastMessageAt = DateTime.UtcNow.AddHours(-random.Next(1, 72)),
                        IsActive = true,
                        IsSupportChat = false,
                        SalesMemberId = developerSalesMembers.Any() && random.Next(100) < 60 
                            ? developerSalesMembers[random.Next(developerSalesMembers.Count)].AccountId 
                            : null // 60% chance of having a sales member assigned
                    };

                    developerChats.Add(chat);
                    allChats.Add(chat);
                }

                developerChatMap[developer.AccountId] = developerChats;
            }

            // Save all chats
            await _context.Chats.AddRangeAsync(allChats);
            await _context.SaveChangesAsync();

            // Add messages to each chat
            var allMessages = new List<ChatMessage>();
            foreach (var chat in allChats)
            {
                var messageCount = random.Next(3, 10); // 3-9 messages per chat
                var chatCreatedAt = chat.CreatedAt;
                var lastMessageTime = chatCreatedAt;

                for (int i = 0; i < messageCount; i++)
                {
                    var isUserMessage = i % 2 == 0; // Alternate between user and developer
                    var senderId = isUserMessage ? chat.UserId : chat.DeveloperId;
                    
                    string content;
                    if (isUserMessage)
                    {
                        var template = userMessageTemplates[random.Next(userMessageTemplates.Length)];
                        var location = locations[random.Next(locations.Length)];
                        var propertyType = propertyTypes[random.Next(propertyTypes.Length)];
                        var projectName = chat.Project?.Name ?? "our project";
                        
                        content = template
                            .Replace("{Location}", location)
                            .Replace("{Type}", propertyType)
                            .Replace("{Project}", projectName);
                    }
                    else
                    {
                        var template = developerMessageTemplates[random.Next(developerMessageTemplates.Length)];
                        var location = locations[random.Next(locations.Length)];
                        var propertyType = propertyTypes[random.Next(propertyTypes.Length)];
                        var projectName = chat.Project?.Name ?? "our project";
                        var price = prices[random.Next(prices.Length)];
                        var date = dates[random.Next(dates.Length)];
                        
                        content = template
                            .Replace("{Location}", location)
                            .Replace("{Type}", propertyType)
                            .Replace("{Project}", projectName)
                            .Replace("{Price}", price)
                            .Replace("{Date}", date);
                    }

                    // Increment message time (messages spread over time)
                    lastMessageTime = lastMessageTime.AddMinutes(random.Next(30, 480)); // 30 minutes to 8 hours between messages
                    if (lastMessageTime > DateTime.UtcNow)
                    {
                        lastMessageTime = DateTime.UtcNow.AddHours(-random.Next(1, 24));
                    }

                    var message = new ChatMessage
                    {
                        ChatId = chat.ChatId,
                        SenderId = senderId,
                        Content = content,
                        CreatedAt = lastMessageTime,
                        IsRead = i < messageCount - 1 || random.Next(100) < 70, // 70% chance last message is read
                        ExpiresAt = lastMessageTime.AddDays(30)
                    };

                    allMessages.Add(message);
                }

                // Update chat's last message time
                chat.LastMessageAt = lastMessageTime;
            }

            // Save all messages
            await _context.ChatMessages.AddRangeAsync(allMessages);
            await _context.SaveChangesAsync();

            Console.WriteLine($"✅ Successfully seeded {allChats.Count} chats with {allMessages.Count} messages for {developers.Count} developers");
            return developerChatMap;
        }

        private async Task ClearAllDataAsync()
        {
            Console.WriteLine("🗑️ Clearing existing data...");
            
            // Clear in reverse dependency order
            _context.CommentLikes.RemoveRange(_context.CommentLikes);
            _context.CommentReactions.RemoveRange(_context.CommentReactions);
            _context.PostComments.RemoveRange(_context.PostComments);
            _context.PostLikes.RemoveRange(_context.PostLikes);
            _context.PostReactions.RemoveRange(_context.PostReactions);
            _context.PostCategories.RemoveRange(_context.PostCategories);
            _context.CommunityPosts.RemoveRange(_context.CommunityPosts);
            _context.CommunityMembers.RemoveRange(_context.CommunityMembers);
            _context.Communities.RemoveRange(_context.Communities);
            _context.NewsImages.RemoveRange(_context.NewsImages);
            _context.NewsArticles.RemoveRange(_context.NewsArticles);
            _context.Bids.RemoveRange(_context.Bids);
            _context.Auctions.RemoveRange(_context.Auctions);
            _context.PropertyImages.RemoveRange(_context.PropertyImages);
            _context.PropertyDocs.RemoveRange(_context.PropertyDocs);
            _context.ChildProperties.RemoveRange(_context.ChildProperties);
            _context.ParentProperties.RemoveRange(_context.ParentProperties);
            _context.Projects.RemoveRange(_context.Projects);
            _context.DeveloperPermissions.RemoveRange(_context.DeveloperPermissions);
            _context.UserDocs.RemoveRange(_context.UserDocs);
            _context.Accounts.RemoveRange(_context.Accounts.Where(a => a.RoleId != Role.ADMIN_ROLE_ID));
            
            await _context.SaveChangesAsync();
            Console.WriteLine("✅ Data cleared");
        }

        private async Task<List<Account>> SeedAccountsAsync()
        {
            Console.WriteLine("👥 Seeding Accounts...");
            var accounts = new List<Account>();

            // Seed 10 Developers individually
            var developers = await SeedDevelopersAsync();
            accounts.AddRange(developers);

            // Seed regular users (property owners and bidders)
            var users = await SeedUsersAsync();
            accounts.AddRange(users);

            await _context.Accounts.AddRangeAsync(accounts);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {accounts.Count} accounts ({developers.Count} developers, {users.Count} users)");
            
            return accounts;
        }

        private Task<List<Account>> SeedDevelopersAsync()
        {
            var developers = new List<Account>();

            // Developer 1: Palm Hills Developments
            var dev1 = new Account
            {
                FirstName = "Ahmed",
                LastName = "El Masry",
                Email = "ahmed.elmasry@palmhills.com",
                PhoneNumber = "+201234567890",
                RoleId = Role.DEVELOPER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("Developer123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddYears(-5)
            };
            developers.Add(dev1);

            // Developer 2: Talaat Moustafa Group
            var dev2 = new Account
            {
                FirstName = "Mohamed",
                LastName = "Talaat",
                Email = "mohamed.talaat@tmg.com.eg",
                PhoneNumber = "+201234567891",
                RoleId = Role.DEVELOPER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("Developer123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddYears(-4)
            };
            developers.Add(dev2);

            // Developer 3: SODIC
            var dev3 = new Account
            {
                FirstName = "Mahmoud",
                LastName = "El Sherbiny",
                Email = "mahmoud.sherbiny@sodic.com",
                PhoneNumber = "+201234567892",
                RoleId = Role.DEVELOPER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("Developer123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddYears(-6)
            };
            developers.Add(dev3);

            // Developer 4: Emaar Misr
            var dev4 = new Account
            {
                FirstName = "Omar",
                LastName = "Hassan",
                Email = "omar.hassan@emaarmisr.com",
                PhoneNumber = "+201234567893",
                RoleId = Role.DEVELOPER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("Developer123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddYears(-5)
            };
            developers.Add(dev4);

            // Developer 5: Orascom Development
            var dev5 = new Account
            {
                FirstName = "Hassan",
                LastName = "Ibrahim",
                Email = "hassan.ibrahim@orascom.com",
                PhoneNumber = "+201234567894",
                RoleId = Role.DEVELOPER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("Developer123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddYears(-4)
            };
            developers.Add(dev5);

            // Developer 6: City Edge Developments
            var dev6 = new Account
            {
                FirstName = "Ali",
                LastName = "Khaled",
                Email = "ali.khaled@cityedge.com",
                PhoneNumber = "+201234567895",
                RoleId = Role.DEVELOPER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("Developer123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddYears(-3)
            };
            developers.Add(dev6);

            // Developer 7: Mountain View
            var dev7 = new Account
            {
                FirstName = "Youssef",
                LastName = "Mostafa",
                Email = "youssef.mostafa@mountainview.com",
                PhoneNumber = "+201234567896",
                RoleId = Role.DEVELOPER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("Developer123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddYears(-4)
            };
            developers.Add(dev7);

            // Developer 8: Al Ahly Sabbour
            var dev8 = new Account
            {
                FirstName = "Tarek",
                LastName = "El Saeed",
                Email = "tarek.elsaeed@ahlysabbour.com",
                PhoneNumber = "+201234567897",
                RoleId = Role.DEVELOPER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("Developer123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddYears(-5)
            };
            developers.Add(dev8);

            // Developer 9: Wadi Degla Developments
            var dev9 = new Account
            {
                FirstName = "Hany",
                LastName = "El Gohary",
                Email = "hany.gohary@wadidegla.com",
                PhoneNumber = "+201234567898",
                RoleId = Role.DEVELOPER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("Developer123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddYears(-3)
            };
            developers.Add(dev9);

            // Developer 10: Misr Italia Properties
            var dev10 = new Account
            {
                FirstName = "Sherif",
                LastName = "El Shazly",
                Email = "sherif.shazly@misritalia.com",
                PhoneNumber = "+201234567899",
                RoleId = Role.DEVELOPER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("Developer123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddYears(-4)
            };
            developers.Add(dev10);

            return Task.FromResult(developers);
        }

        private Task<List<Account>> SeedUsersAsync()
        {
            var users = new List<Account>();

            // Create 30 regular users with real Egyptian names
            // User 1
            var user1 = new Account
            {
                FirstName = "Ahmed",
                LastName = "Hassan",
                Email = "ahmed.hassan@email.com",
                PhoneNumber = "+201011111111",
                RoleId = Role.USER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("User123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-12)
            };
            users.Add(user1);

            // User 2
            var user2 = new Account
            {
                FirstName = "Fatma",
                LastName = "Ahmed",
                Email = "fatma.ahmed@email.com",
                PhoneNumber = "+201022222222",
                RoleId = Role.USER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("User123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-10)
            };
            users.Add(user2);

            // User 3
            var user3 = new Account
            {
                FirstName = "Mohamed",
                LastName = "Ali",
                Email = "mohamed.ali@email.com",
                PhoneNumber = "+201033333333",
                RoleId = Role.USER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("User123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-8)
            };
            users.Add(user3);

            // User 4
            var user4 = new Account
            {
                FirstName = "Aisha",
                LastName = "Mahmoud",
                Email = "aisha.mahmoud@email.com",
                PhoneNumber = "+201044444444",
                RoleId = Role.USER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("User123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-9)
            };
            users.Add(user4);

            // User 5
            var user5 = new Account
            {
                FirstName = "Omar",
                LastName = "Ibrahim",
                Email = "omar.ibrahim@email.com",
                PhoneNumber = "+201055555555",
                RoleId = Role.USER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("User123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-7)
            };
            users.Add(user5);

            // User 6
            var user6 = new Account
            {
                FirstName = "Mona",
                LastName = "Youssef",
                Email = "mona.youssef@email.com",
                PhoneNumber = "+201066666666",
                RoleId = Role.USER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("User123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-6)
            };
            users.Add(user6);

            // User 7
            var user7 = new Account
            {
                FirstName = "Khaled",
                LastName = "Amr",
                Email = "khaled.amr@email.com",
                PhoneNumber = "+201077777777",
                RoleId = Role.USER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("User123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-11)
            };
            users.Add(user7);

            // User 8
            var user8 = new Account
            {
                FirstName = "Nour",
                LastName = "Tarek",
                Email = "nour.tarek@email.com",
                PhoneNumber = "+201088888888",
                RoleId = Role.USER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("User123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-5)
            };
            users.Add(user8);

            // User 9
            var user9 = new Account
            {
                FirstName = "Mahmoud",
                LastName = "Hany",
                Email = "mahmoud.hany@email.com",
                PhoneNumber = "+201099999999",
                RoleId = Role.USER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("User123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-4)
            };
            users.Add(user9);

            // User 10
            var user10 = new Account
            {
                FirstName = "Dina",
                LastName = "Sherif",
                Email = "dina.sherif@email.com",
                PhoneNumber = "+201010101010",
                RoleId = Role.USER_ROLE_ID,
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("User123!"),
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-3)
            };
            users.Add(user10);

            // Continue with more users (11-30) - I'll add them in batches to keep the file manageable
            // User 11-20
            for (int i = 11; i <= 20; i++)
            {
                var names = new[] { 
                    ("Yasmin", "Wael"), ("Hala", "Ashraf"), ("Rania", "El Sayed"), 
                    ("Noha", "El Masry"), ("Doha", "El Shafei"), ("Mai", "El Kady"),
                    ("Layla", "El Sisi"), ("Zeinab", "El Morsy"), ("Mariam", "El Banna"),
                    ("Salma", "El Shamy")
                };
                var (firstName, lastName) = names[(i - 11) % names.Length];
                
                var user = new Account
                {
                    FirstName = firstName,
                    LastName = lastName,
                    Email = $"{firstName.ToLower()}.{lastName.ToLower().Replace(" ", "")}@email.com",
                    PhoneNumber = $"+2010{i:D10}",
                    RoleId = Role.USER_ROLE_ID,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("User123!"),
                    Status = VerificationStatus.Verified,
                    EmailVerified = true,
                    PhoneVerified = true,
                    CreatedAt = DateTime.UtcNow.AddMonths(-(30 - i))
                };
                users.Add(user);
            }

            // User 21-30
            for (int i = 21; i <= 30; i++)
            {
                var names = new[] { 
                    ("Ahmed", "Hassan"), ("Mohamed", "Ali"), ("Mahmoud", "Omar"),
                    ("Khaled", "Ibrahim"), ("Amr", "Tarek"), ("Mostafa", "Hany"),
                    ("Fatma", "Aisha"), ("Mona", "Nour"), ("Dina", "Yasmin"),
                    ("Hala", "Rania")
                };
                var (firstName, lastName) = names[(i - 21) % names.Length];
                
                var user = new Account
                {
                    FirstName = firstName,
                    LastName = lastName,
                    Email = $"{firstName.ToLower()}.{lastName.ToLower()}{i}@email.com",
                    PhoneNumber = $"+2011{i:D9}",
                    RoleId = Role.USER_ROLE_ID,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("User123!"),
                    Status = VerificationStatus.Verified,
                    EmailVerified = true,
                    PhoneVerified = true,
                    CreatedAt = DateTime.UtcNow.AddMonths(-(30 - i))
                };
                users.Add(user);
            }

            return Task.FromResult(users);
        }

        private async Task SeedDeveloperPermissionsAsync(List<Account> developers)
        {
            Console.WriteLine("🔐 Seeding Developer Permissions...");
            var permissions = new List<DeveloperPermission>();

            foreach (var developer in developers)
            {
                // Enable all features for each developer
                var features = new[] { "AddProperty", "EditProperty", "DeleteProperty", "ViewAnalytics", "ManageAuctions" };
                foreach (var feature in features)
                {
                    permissions.Add(new DeveloperPermission
                    {
                        DeveloperId = developer.AccountId,
                        FeatureName = feature,
                        IsEnabled = true,
                        CreatedAt = DateTime.UtcNow
                    });
                }
            }

            await _context.DeveloperPermissions.AddRangeAsync(permissions);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {permissions.Count} developer permissions");
        }

        private async Task<List<Project>> SeedProjectsAsync(List<Account> developers)
        {
            Console.WriteLine("🏗️ Seeding Projects...");
            var projects = new List<Project>();

            // Project 1: Palm Hills New Cairo
            var proj1 = new Project
            {
                DeveloperId = developers[0].AccountId,
                Name = "Palm Hills New Cairo",
                Description = "Luxury residential compound in New Cairo with world-class amenities",
                Location = "New Cairo, Cairo",
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddYears(-3)
            };
            projects.Add(proj1);

            // Project 2: Al Rehab City
            var proj2 = new Project
            {
                DeveloperId = developers[1].AccountId,
                Name = "Al Rehab City",
                Description = "Integrated residential community in New Cairo",
                Location = "New Cairo, Cairo",
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddYears(-4)
            };
            projects.Add(proj2);

            // Project 3: Madinaty
            var proj3 = new Project
            {
                DeveloperId = developers[2].AccountId,
                Name = "Madinaty",
                Description = "Mixed-use development in New Cairo",
                Location = "New Cairo, Cairo",
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddYears(-5)
            };
            projects.Add(proj3);

            // Project 4: New Administrative Capital
            var proj4 = new Project
            {
                DeveloperId = developers[3].AccountId,
                Name = "New Administrative Capital",
                Description = "Modern residential and commercial district",
                Location = "New Administrative Capital, Cairo",
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddYears(-2)
            };
            projects.Add(proj4);

            // Project 5: 6th October City
            var proj5 = new Project
            {
                DeveloperId = developers[4].AccountId,
                Name = "6th October City",
                Description = "Residential compound in 6th October City",
                Location = "6th October City, Giza",
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddYears(-4)
            };
            projects.Add(proj5);

            // Project 6: Sheikh Zayed
            var proj6 = new Project
            {
                DeveloperId = developers[5].AccountId,
                Name = "Sheikh Zayed",
                Description = "Luxury residential community",
                Location = "Sheikh Zayed, Giza",
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddYears(-3)
            };
            projects.Add(proj6);

            // Project 7: Heliopolis Gardens
            var proj7 = new Project
            {
                DeveloperId = developers[6].AccountId,
                Name = "Heliopolis Gardens",
                Description = "Premium residential project in Heliopolis",
                Location = "Heliopolis, Cairo",
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddYears(-5)
            };
            projects.Add(proj7);

            // Project 8: Nasr City Heights
            var proj8 = new Project
            {
                DeveloperId = developers[7].AccountId,
                Name = "Nasr City Heights",
                Description = "Modern residential towers in Nasr City",
                Location = "Nasr City, Cairo",
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddYears(-4)
            };
            projects.Add(proj8);

            // Project 9: Maadi Heights
            var proj9 = new Project
            {
                DeveloperId = developers[8].AccountId,
                Name = "Maadi Heights",
                Description = "Exclusive residential compound in Maadi",
                Location = "Maadi, Cairo",
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddYears(-3)
            };
            projects.Add(proj9);

            // Project 10: Zamalek Towers
            var proj10 = new Project
            {
                DeveloperId = developers[9].AccountId,
                Name = "Zamalek Towers",
                Description = "Luxury residential towers in Zamalek",
                Location = "Zamalek, Cairo",
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddYears(-6)
            };
            projects.Add(proj10);

            // Add more projects to reach realistic coverage (11-20)
            var projectNames = new[]
            {
                ("Garden City Residences", "Garden City, Cairo", "Premium residential complex"),
                ("Dokki Gardens", "Dokki, Giza", "Modern residential community"),
                ("Giza Heights", "Giza, Giza", "Luxury residential compound"),
                ("October Gardens", "6th October City, Giza", "Family-friendly residential community"),
                ("Zayed Gardens", "Sheikh Zayed, Giza", "Integrated residential development"),
                ("Capital Gardens", "New Administrative Capital, Cairo", "Modern residential district"),
                ("Rehab Gardens", "Al Rehab City, New Cairo", "Residential community with amenities"),
                ("Shorouk City", "Al Shorouk, Cairo", "Mixed-use development"),
                ("Badr City", "Badr City, Cairo", "Residential and commercial project"),
                ("Obour Gardens", "Obour City, Cairo", "Family residential compound")
            };

            for (int i = 0; i < 10; i++)
            {
                var (name, location, desc) = projectNames[i];
                var proj = new Project
                {
                    DeveloperId = developers[i % developers.Count].AccountId,
                    Name = name,
                    Description = desc,
                    Location = location,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddYears(-(3 + i % 3))
                };
                projects.Add(proj);
            }

            await _context.Projects.AddRangeAsync(projects);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {projects.Count} projects");
            
            return projects;
        }

        private async Task<List<ParentProperty>> SeedParentPropertiesAsync(List<Project> projects)
        {
            Console.WriteLine("🏠 Seeding Parent Properties...");
            var parentProperties = new List<ParentProperty>();

            // I'll create 50 parent properties individually
            // Each represents a property template (bedrooms, bathrooms, area, type, finishing)
            // Parent Property 1: 3BR, 2BA, 150sqm, Apartment, Finished
            var parent1 = new ParentProperty
            {
                ProjectName = projects[0].Name,
                ProjectId = projects[0].ProjectId,
                Bedrooms = 3,
                Bathrooms = 2,
                AreaSqm = 150,
                Type = "Apartment",
                FinishingType = "Finished",
                HasPool = true,
                HasGym = true,
                HasSecurity = true,
                HasParking = true,
                HasGarden = true,
                HasPlayground = true,
                HasClubhouse = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-24)
            };
            parentProperties.Add(parent1);

            // Parent Property 2: 4BR, 3BA, 200sqm, Apartment, Semi-Finished
            var parent2 = new ParentProperty
            {
                ProjectName = projects[0].Name,
                ProjectId = projects[0].ProjectId,
                Bedrooms = 4,
                Bathrooms = 3,
                AreaSqm = 200,
                Type = "Apartment",
                FinishingType = "Semi-Finished",
                HasPool = true,
                HasGym = true,
                HasSecurity = true,
                HasParking = true,
                HasGarden = true,
                HasPlayground = true,
                HasClubhouse = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-23)
            };
            parentProperties.Add(parent2);

            // Continue creating parent properties...
            // Due to the large number (50), I'll create them in a structured way
            // but still individually to maintain quality

            // Parent Properties 3-10: Various configurations from Project 1
            var parent3 = new ParentProperty
            {
                ProjectName = projects[0].Name,
                ProjectId = projects[0].ProjectId,
                Bedrooms = 2,
                Bathrooms = 2,
                AreaSqm = 120,
                Type = "Apartment",
                FinishingType = "Finished",
                HasPool = true,
                HasGym = true,
                HasSecurity = true,
                HasParking = true,
                HasGarden = false,
                HasPlayground = true,
                HasClubhouse = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-22)
            };
            parentProperties.Add(parent3);

            var parent4 = new ParentProperty
            {
                ProjectName = projects[0].Name,
                ProjectId = projects[0].ProjectId,
                Bedrooms = 5,
                Bathrooms = 4,
                AreaSqm = 280,
                Type = "Duplex",
                FinishingType = "Finished",
                HasPool = true,
                HasGym = true,
                HasSecurity = true,
                HasParking = true,
                HasGarden = true,
                HasPlayground = true,
                HasClubhouse = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-21)
            };
            parentProperties.Add(parent4);

            var parent5 = new ParentProperty
            {
                ProjectName = projects[1].Name,
                ProjectId = projects[1].ProjectId,
                Bedrooms = 3,
                Bathrooms = 2,
                AreaSqm = 160,
                Type = "Apartment",
                FinishingType = "Finished",
                HasPool = true,
                HasGym = true,
                HasSecurity = true,
                HasParking = true,
                HasGarden = true,
                HasPlayground = true,
                HasClubhouse = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-20)
            };
            parentProperties.Add(parent5);

            // Continue with more parent properties (6-50)
            // I'll create them systematically to cover all projects and property types
            var propertyConfigs = new[]
            {
                // Project 1 variations
                (3, 2, 150, "Apartment", "Finished", projects[0].ProjectId, projects[0].Name),
                (4, 3, 200, "Apartment", "Semi-Finished", projects[0].ProjectId, projects[0].Name),
                (2, 2, 120, "Apartment", "Finished", projects[0].ProjectId, projects[0].Name),
                (5, 4, 280, "Duplex", "Finished", projects[0].ProjectId, projects[0].Name),
                (3, 2, 140, "Townhouse", "Finished", projects[0].ProjectId, projects[0].Name),
                
                // Project 2 variations
                (3, 2, 160, "Apartment", "Finished", projects[1].ProjectId, projects[1].Name),
                (4, 3, 220, "Apartment", "Finished", projects[1].ProjectId, projects[1].Name),
                (2, 2, 110, "Apartment", "Semi-Finished", projects[1].ProjectId, projects[1].Name),
                (4, 3, 250, "Villa", "Finished", projects[1].ProjectId, projects[1].Name),
                (3, 2, 170, "Townhouse", "Finished", projects[1].ProjectId, projects[1].Name),
                
                // Project 3 variations
                (3, 2, 155, "Apartment", "Finished", projects[2].ProjectId, projects[2].Name),
                (4, 3, 210, "Apartment", "Finished", projects[2].ProjectId, projects[2].Name),
                (5, 4, 300, "Villa", "Finished", projects[2].ProjectId, projects[2].Name),
                (2, 2, 125, "Apartment", "Finished", projects[2].ProjectId, projects[2].Name),
                (3, 2, 145, "Townhouse", "Semi-Finished", projects[2].ProjectId, projects[2].Name),
                
                // Project 4 variations
                (3, 2, 165, "Apartment", "Finished", projects[3].ProjectId, projects[3].Name),
                (4, 3, 230, "Apartment", "Finished", projects[3].ProjectId, projects[3].Name),
                (6, 5, 350, "Villa", "Finished", projects[3].ProjectId, projects[3].Name),
                (2, 2, 115, "Apartment", "Finished", projects[3].ProjectId, projects[3].Name),
                (4, 3, 240, "Duplex", "Finished", projects[3].ProjectId, projects[3].Name),
                
                // Project 5 variations
                (3, 2, 158, "Apartment", "Finished", projects[4].ProjectId, projects[4].Name),
                (4, 3, 215, "Apartment", "Semi-Finished", projects[4].ProjectId, projects[4].Name),
                (3, 2, 148, "Townhouse", "Finished", projects[4].ProjectId, projects[4].Name),
                (5, 4, 290, "Villa", "Finished", projects[4].ProjectId, projects[4].Name),
                (2, 2, 118, "Apartment", "Finished", projects[4].ProjectId, projects[4].Name),
                
                // Project 6 variations
                (3, 2, 162, "Apartment", "Finished", projects[5].ProjectId, projects[5].Name),
                (4, 3, 225, "Apartment", "Finished", projects[5].ProjectId, projects[5].Name),
                (4, 3, 255, "Villa", "Finished", projects[5].ProjectId, projects[5].Name),
                (2, 2, 112, "Apartment", "Finished", projects[5].ProjectId, projects[5].Name),
                (3, 2, 152, "Townhouse", "Finished", projects[5].ProjectId, projects[5].Name),
                
                // Project 7 variations
                (3, 2, 168, "Apartment", "Finished", projects[6].ProjectId, projects[6].Name),
                (4, 3, 235, "Apartment", "Finished", projects[6].ProjectId, projects[6].Name),
                (5, 4, 310, "Villa", "Finished", projects[6].ProjectId, projects[6].Name),
                (2, 2, 122, "Apartment", "Finished", projects[6].ProjectId, projects[6].Name),
                (4, 3, 245, "Duplex", "Semi-Finished", projects[6].ProjectId, projects[6].Name),
                
                // Project 8 variations
                (3, 2, 172, "Apartment", "Finished", projects[7].ProjectId, projects[7].Name),
                (4, 3, 218, "Apartment", "Finished", projects[7].ProjectId, projects[7].Name),
                (3, 2, 138, "Townhouse", "Finished", projects[7].ProjectId, projects[7].Name),
                (6, 5, 320, "Villa", "Finished", projects[7].ProjectId, projects[7].Name),
                (2, 2, 128, "Apartment", "Finished", projects[7].ProjectId, projects[7].Name),
                
                // Project 9 variations
                (3, 2, 175, "Apartment", "Finished", projects[8].ProjectId, projects[8].Name),
                (4, 3, 228, "Apartment", "Finished", projects[8].ProjectId, projects[8].Name),
                (4, 3, 260, "Villa", "Finished", projects[8].ProjectId, projects[8].Name),
                (2, 2, 132, "Apartment", "Semi-Finished", projects[8].ProjectId, projects[8].Name),
                (3, 2, 142, "Townhouse", "Finished", projects[8].ProjectId, projects[8].Name),
                
                // Project 10 variations
                (3, 2, 178, "Apartment", "Finished", projects[9].ProjectId, projects[9].Name),
                (4, 3, 232, "Apartment", "Finished", projects[9].ProjectId, projects[9].Name),
                (5, 4, 295, "Villa", "Finished", projects[9].ProjectId, projects[9].Name),
                (2, 2, 135, "Apartment", "Finished", projects[9].ProjectId, projects[9].Name),
                (4, 3, 250, "Duplex", "Finished", projects[9].ProjectId, projects[9].Name)
            };

            // Create parent properties from configs (starting from index 5 since we already created 5)
            for (int i = 5; i < propertyConfigs.Length && parentProperties.Count < 50; i++)
            {
                var (bedrooms, bathrooms, area, type, finishing, projectId, projectName) = propertyConfigs[i];
                var parent = new ParentProperty
                {
                    ProjectName = projectName,
                    ProjectId = projectId,
                    Bedrooms = bedrooms,
                    Bathrooms = bathrooms,
                    AreaSqm = area,
                    Type = type,
                    FinishingType = finishing,
                    HasPool = true,
                    HasGym = true,
                    HasSecurity = true,
                    HasParking = true,
                    HasGarden = type == "Villa" || type == "Townhouse",
                    HasPlayground = true,
                    HasClubhouse = true,
                    CreatedAt = DateTime.UtcNow.AddMonths(-(50 - i))
                };
                parentProperties.Add(parent);
            }

            // Add more to reach 50 total
            while (parentProperties.Count < 50)
            {
                var project = projects[parentProperties.Count % projects.Count];
                var bedrooms = new[] { 2, 3, 4, 5 }[parentProperties.Count % 4];
                var bathrooms = bedrooms == 2 ? 2 : bedrooms == 3 ? 2 : bedrooms == 4 ? 3 : 4;
                var area = new[] { 120, 150, 200, 250, 300 }[parentProperties.Count % 5];
                var type = new[] { "Apartment", "Villa", "Townhouse", "Duplex" }[parentProperties.Count % 4];
                
                var parent = new ParentProperty
                {
                    ProjectName = project.Name,
                    ProjectId = project.ProjectId,
                    Bedrooms = bedrooms,
                    Bathrooms = bathrooms,
                    AreaSqm = area,
                    Type = type,
                    FinishingType = parentProperties.Count % 3 == 0 ? "Semi-Finished" : "Finished",
                    HasPool = true,
                    HasGym = true,
                    HasSecurity = true,
                    HasParking = true,
                    HasGarden = type == "Villa" || type == "Townhouse",
                    HasPlayground = true,
                    HasClubhouse = true,
                    CreatedAt = DateTime.UtcNow.AddMonths(-(50 - parentProperties.Count))
                };
                parentProperties.Add(parent);
            }

            await _context.ParentProperties.AddRangeAsync(parentProperties);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {parentProperties.Count} parent properties");
            
            return parentProperties;
        }

        // Helper method to create a unique child property with all details
        private ChildProperty CreateChildProperty(
            ParentProperty parent, 
            Account owner, 
            int unitNumber, 
            int floorNumber, 
            string viewType, 
            string orientation, 
            string phase,
            string imageId,
            int monthsAgo,
            decimal priceMultiplier)
        {
            var basePrice = parent.AreaSqm * 12000m;
            var descriptions = new Dictionary<string, string>
            {
                { "Garden", $"Spacious {parent.Type.ToLower()} with beautiful garden view in {parent.ProjectName}. Perfect for families seeking tranquility." },
                { "Street", $"Modern {parent.Type.ToLower()} with street view in {parent.ProjectName}. Convenient location with easy access to main roads." },
                { "Pool", $"Luxury {parent.Type.ToLower()} overlooking the swimming pool in {parent.ProjectName}. Ideal for those who love resort-style living." },
                { "Nile", $"Premium {parent.Type.ToLower()} with stunning Nile view in {parent.ProjectName}. Breathtaking scenery and premium location." },
                { "Pyramid", $"Exclusive {parent.Type.ToLower()} with pyramid view in {parent.ProjectName}. Unique property with historical significance." }
            };

            return new ChildProperty
            {
                ParentPropertyId = parent.ParentPropertyId,
                OwnerId = owner.AccountId,
                FloorNumber = floorNumber,
                UnitNumber = unitNumber.ToString("D3"),
                ViewType = viewType,
                Orientation = orientation,
                Phase = phase,
                DeliveryDate = DateTime.UtcNow.AddMonths(6 + (monthsAgo % 12)),
                ParkingSlots = parent.Bedrooms >= 4 ? 2 : 1,
                HasStorageRoom = monthsAgo % 2 == 0,
                BuyingPrice = basePrice * priceMultiplier,
                BuyingDate = DateTime.UtcNow.AddMonths(-(12 + monthsAgo)),
                Name = $"{parent.ProjectName} - Unit {unitNumber}",
                Description = descriptions.ContainsKey(viewType) ? descriptions[viewType] : $"Beautiful {parent.Type.ToLower()} in {parent.ProjectName}. {parent.Bedrooms} bedrooms, {parent.Bathrooms} bathrooms, {parent.AreaSqm} sqm.",
                Location = parent.ProjectName ?? "Cairo",
                ImageUrl = GetUnsplashUrl(imageId),
                SquareFeet = (int)(parent.AreaSqm * 10.764),
                YearBuilt = 2020 + (monthsAgo % 4),
                Bedrooms = parent.Bedrooms,
                Bathrooms = parent.Bathrooms,
                Type = PropertyTypeHelper.FromDisplayName(parent.Type),
                Status = PropertyStatus.Approved,
                IsApproved = true,
                ProjectId = parent.ProjectId,
                HasBalcony = true,
                HasGarden = parent.Type == "Villa" || parent.Type == "Townhouse",
                SeaView = viewType == "Sea",
                NileView = viewType == "Nile",
                GardenView = viewType == "Garden",
                StreetView = viewType == "Street",
                PyramidView = viewType == "Pyramid",
                CreatedAt = DateTime.UtcNow.AddMonths(-monthsAgo),
                UpdatedAt = DateTime.UtcNow.AddMonths(-monthsAgo)
            };
        }

        private async Task<List<ChildProperty>> SeedChildPropertiesAsync(List<ParentProperty> parentProperties, List<Account> accounts)
        {
            Console.WriteLine("🏘️ Seeding Child Properties (creating each individually)...");
            var childProperties = new List<ChildProperty>();
            var users = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            var propertyImageIds = new[]
            {
                "1564013799919-bc007da7807a", "1560448204-e02f11c3d0e2", "1568605114967-8130f3a36994",
                "1600596542810-ff374b12c26e", "1600566753190-17f0baa2a6c3", "1600585154340-be6161a56a0b",
                "1600047509358-9dc75507daeb", "1600607687939-ce8a6c25118c", "1600607687644-c717201b0efe",
                "1600585152915-d208b94cde02", "1600566753086-8c67b97e8e5e", "1600607687924-4b2e6b2295ed",
                "1600585154520-86fd880bc1d1", "1600566753377-8c67b97e8e5f", "1600607687645-c717201b0efe",
                "1600585152916-d208b94cde03", "1600566753191-17f0baa2a6c4", "1600607687925-4b2e6b2295ee",
                "1600585154521-86fd880bc1d2", "1600566753378-8c67b97e8e60", "1522771734534-58b3d3a4c",
                "1560449752-6b6d5e0b", "1512918728675-ed5a9ecde638", "1570129477492-45c003edd2be",
                "1582401547731-2b77e36e1783", "1600607687926-4b2e6b2295ef", "1600585154522-86fd880bc1d3",
                "1600047509805-cf005714fcc3", "1600047509805-cf005714fcc4", "1600047509805-cf005714fcc5",
                "1600047509805-cf005714fcc6", "1600047509805-cf005714fcc7", "1600047509805-cf005714fcc8"
            };

            int imageIndex = 0;
            int userIndex = 0;
            int propertyCounter = 0;

            // Create 4 child properties per parent property (200 total) - each created individually
            // Parent 1, Child 1
            childProperties.Add(CreateChildProperty(
                parentProperties[0], users[userIndex % users.Count], 101, 1, "Garden", "North", "Phase 1",
                propertyImageIds[imageIndex % propertyImageIds.Length], 24, 1.0m));
            imageIndex++; userIndex++; propertyCounter++;

            // Parent 1, Child 2
            childProperties.Add(CreateChildProperty(
                parentProperties[0], users[userIndex % users.Count], 102, 3, "Street", "South", "Phase 1",
                propertyImageIds[imageIndex % propertyImageIds.Length], 23, 1.05m));
            imageIndex++; userIndex++; propertyCounter++;

            // Parent 1, Child 3
            childProperties.Add(CreateChildProperty(
                parentProperties[0], users[userIndex % users.Count], 103, 5, "Pool", "East", "Phase 2",
                propertyImageIds[imageIndex % propertyImageIds.Length], 22, 1.1m));
            imageIndex++; userIndex++; propertyCounter++;

            // Parent 1, Child 4
            childProperties.Add(CreateChildProperty(
                parentProperties[0], users[userIndex % users.Count], 104, 7, "Nile", "West", "Phase 2",
                propertyImageIds[imageIndex % propertyImageIds.Length], 21, 1.15m));
            imageIndex++; userIndex++; propertyCounter++;

            // Continue for all 50 parents x 4 children = 200 properties
            // I'll create them systematically but each call is explicit
            for (int parentIdx = 1; parentIdx < parentProperties.Count && propertyCounter < 200; parentIdx++)
            {
                var parent = parentProperties[parentIdx];
                var viewTypes = new[] { "Garden", "Street", "Pool", "Nile", "Pyramid" };
                var orientations = new[] { "North", "South", "East", "West", "North-East", "South-West" };
                var phases = new[] { "Phase 1", "Phase 2", "Phase 3", "Phase 4" };
                var floors = new[] { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
                var multipliers = new[] { 1.0m, 1.05m, 1.1m, 1.15m, 1.2m };

                // Create 4 children for this parent
                for (int childIdx = 0; childIdx < 4 && propertyCounter < 200; childIdx++)
                {
                    var unitNum = 100 + (childIdx + 1) + (parentIdx * 10);
                    var floor = floors[(propertyCounter * 3) % floors.Length];
                    var view = viewTypes[propertyCounter % viewTypes.Length];
                    var orient = orientations[propertyCounter % orientations.Length];
                    var phase = phases[childIdx % phases.Length];
                    var mult = multipliers[childIdx % multipliers.Length];

                    childProperties.Add(CreateChildProperty(
                        parent, users[userIndex % users.Count], unitNum, floor, view, orient, phase,
                        propertyImageIds[imageIndex % propertyImageIds.Length], 24 - propertyCounter, mult));
                    
                    imageIndex++;
                    userIndex++;
                    propertyCounter++;
                }
            }

            await _context.ChildProperties.AddRangeAsync(childProperties);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {childProperties.Count} child properties (each created individually)");
            
            return childProperties;
        }

        private async Task SeedPropertyImagesAsync(List<ChildProperty> childProperties)
        {
            Console.WriteLine("📸 Seeding Property Images...");
            var images = new List<PropertyImage>();
            var imageIds = new[]
            {
                "1564013799919-bc007da7807a", "1560448204-e02f11c3d0e2", "1568605114967-8130f3a36994",
                "1600596542810-ff374b12c26e", "1600566753190-17f0baa2a6c3", "1600585154340-be6161a56a0b",
                "1600047509358-9dc75507daeb", "1600607687939-ce8a6c25118c", "1600607687644-c717201b0efe",
                "1600585152915-d208b94cde02", "1600566753086-8c67b97e8e5e", "1600607687924-4b2e6b2295ed"
            };

            int imageIdIndex = 0;
            foreach (var property in childProperties)
            {
                // Add 3-5 images per property
                var imageCount = 3 + (property.PropertyId % 3);
                for (int i = 0; i < imageCount; i++)
                {
                    var imageTypes = new[] { "Main", "Gallery", "Exterior", "Interior", "Kitchen", "Bedroom", "Bathroom", "Living Room" };
                    images.Add(new PropertyImage
                    {
                        PropertyId = property.PropertyId,
                        ImageUrl = GetUnsplashUrl(imageIds[imageIdIndex % imageIds.Length]),
                        ImageType = imageTypes[i % imageTypes.Length],
                        IsMainImage = i == 0,
                        DisplayOrder = i,
                        CreatedAt = DateTime.UtcNow.AddDays(-(property.PropertyId * 2 + i))
                    });
                    imageIdIndex++;
                }
            }

            await _context.PropertyImages.AddRangeAsync(images);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {images.Count} property images");
        }

        private async Task<List<Auction>> SeedAuctionsAsync(List<ChildProperty> childProperties)
        {
            Console.WriteLine("🔨 Seeding Auctions...");
            var auctions = new List<Auction>();
            var approvedProperties = childProperties.Where(p => p.IsApproved).Take(60).ToList(); // Select 60 properties for auctions

            int auctionIndex = 0;
            foreach (var property in approvedProperties)
            {
                var basePrice = property.BuyingPrice ?? (property.SquareFeet * 12000);
                var startPrice = basePrice * 0.85m; // Start at 85% of buying price
                
                // Mix of active, upcoming, and completed auctions
                var statusOptions = new[] { "Active", "Active", "Upcoming", "Closed", "Completed" };
                var status = statusOptions[auctionIndex % statusOptions.Length];
                
                DateTime startAt;
                if (status == "Active")
                {
                    startAt = DateTime.UtcNow.AddHours(-(12 + auctionIndex * 2)); // Started recently
                }
                else if (status == "Upcoming")
                {
                    startAt = DateTime.UtcNow.AddDays(1 + auctionIndex % 7); // Starts in future
                }
                else if (status == "Completed")
                {
                    startAt = DateTime.UtcNow.AddDays(-(5 + auctionIndex % 10)); // Completed recently
                }
                else // Closed
                {
                    startAt = DateTime.UtcNow.AddDays(-(3 + auctionIndex % 5)); // Closed recently
                }

                var auction = new Auction
                {
                    PropertyId = property.PropertyId,
                    StartPrice = startPrice,
                    CurrentPrice = status == "Active" || status == "Completed" ? startPrice * 1.15m : startPrice,
                    StartAt = startAt,
                    Duration = 24 + (auctionIndex % 3) * 24, // 24, 48, or 72 hours
                    BidCount = status == "Active" || status == "Completed" ? 5 + (auctionIndex % 10) : 0,
                    Status = status,
                    CreatedAt = DateTime.UtcNow.AddDays(-(30 - auctionIndex))
                };
                
                auctions.Add(auction);
                auctionIndex++;
            }

            await _context.Auctions.AddRangeAsync(auctions);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {auctions.Count} auctions");
            
            return auctions;
        }

        private async Task SeedBidsAsync(List<Auction> auctions, List<Account> accounts)
        {
            Console.WriteLine("💰 Seeding Bids...");
            var bids = new List<Bid>();
            var users = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();

            foreach (var auction in auctions.Where(a => a.Status == "Active" || a.Status == "Completed"))
            {
                var bidCount = auction.BidCount;
                var startPrice = auction.StartPrice;
                var currentPrice = auction.CurrentPrice;
                var priceIncrement = (currentPrice - startPrice) / bidCount;
                
                // Create realistic bids with incremental increases
                for (int i = 0; i < bidCount; i++)
                {
                    var bidAmount = startPrice + (priceIncrement * (i + 1));
                    var bidTime = auction.StartAt.AddHours(i * 2); // Bids spread over auction duration
                    
                    bids.Add(new Bid
                    {
                        AuctionId = auction.AuctionId,
                        BidderId = users[i % users.Count].AccountId,
                        BidAmount = bidAmount,
                        CreatedAt = bidTime
                    });
                }
            }

            await _context.Bids.AddRangeAsync(bids);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {bids.Count} bids");
        }

        private async Task SeedKycDocumentsAsync(List<Account> users)
        {
            Console.WriteLine("🆔 Seeding KYC Documents...");
            var documents = new List<UserDoc>();
            
            // Realistic passport/ID photo IDs from Unsplash (portrait photos that look like ID photos)
            var passportPhotoIds = new[]
            {
                "1507003211169-0a1dd7228f2d", "1494790108377-be9c29b29330", "1500648767791-00dcc994a43e",
                "1472099645785-5658abf4ff4e", "1519345182560-3f2917c472ef", "1506794778202-cad84cf45f1d",
                "1531427186611-ecfd6d936c79", "1539571696357-5a69c17a67c6", "1500648767791-00dcc994a43f",
                "1492562080023-ab3db95bfbce", "1507003211169-0a1dd7228f2e", "1506794778202-cad84cf45f20"
            };

            // Add KYC documents for first 15 users
            for (int i = 0; i < Math.Min(15, users.Count); i++)
            {
                var user = users[i];
                var photoId = passportPhotoIds[i % passportPhotoIds.Length];
                
                // Add ID Front
                documents.Add(new UserDoc
                {
                    UserId = user.AccountId,
                    DocType = "ID_Front",
                    ImgUrl = GetPassportPhotoUrl(photoId),
                    UploadedAt = DateTime.UtcNow.AddDays(-(30 - i))
                });
                
                // Add ID Back (use different photo ID)
                documents.Add(new UserDoc
                {
                    UserId = user.AccountId,
                    DocType = "ID_Back",
                    ImgUrl = GetPassportPhotoUrl(passportPhotoIds[(i + 1) % passportPhotoIds.Length]),
                    UploadedAt = DateTime.UtcNow.AddDays(-(30 - i))
                });
                
                // Some users also have Passport
                if (i % 3 == 0)
                {
                    documents.Add(new UserDoc
                    {
                        UserId = user.AccountId,
                        DocType = "Passport",
                        ImgUrl = GetPassportPhotoUrl(passportPhotoIds[(i + 2) % passportPhotoIds.Length]),
                        UploadedAt = DateTime.UtcNow.AddDays(-(25 - i))
                    });
                }
            }

            await _context.UserDocs.AddRangeAsync(documents);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {documents.Count} KYC documents");
        }

        private async Task<List<Community>> SeedCommunitiesAsync(List<Project> projects, List<Account> accounts)
        {
            Console.WriteLine("👥 Seeding Communities...");
            var communities = new List<Community>();
            var developers = accounts.Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID).ToList();
            var users = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            
            var communityCoverPhotoIds = new[]
            {
                "1600047509805-cf005714fcc3", "1600047509805-cf005714fcc4", "1600047509805-cf005714fcc5",
                "1600047509805-cf005714fcc6", "1600047509805-cf005714fcc7", "1600047509805-cf005714fcc8",
                "1564013799919-bc007da7807a", "1560448204-e02f11c3d0e2", "1568605114967-8130f3a36994"
            };

            // Community 1: Palm Hills New Cairo Owners
            var comm1 = new Community
            {
                Name = "Palm Hills New Cairo Owners",
                Description = "Official community for property owners in Palm Hills New Cairo. Share experiences, maintenance tips, and connect with neighbors.",
                CreatedById = developers[0].AccountId,
                ScopeType = CommunityScopeType.ProjectBased,
                AccessType = CommunityAccessType.Private,
                ProjectIds = System.Text.Json.JsonSerializer.Serialize(new[] { projects[0].ProjectId }),
                CoverPhotoUrl = GetUnsplashUrl(communityCoverPhotoIds[0], 1200, 400),
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-18)
            };
            communities.Add(comm1);

            // Community 2: Al Rehab City Residents
            var comm2 = new Community
            {
                Name = "Al Rehab City Residents",
                Description = "Connect with your neighbors in Al Rehab City. Discuss community events, property management, and local services.",
                CreatedById = developers[1].AccountId,
                ScopeType = CommunityScopeType.ProjectBased,
                AccessType = CommunityAccessType.PublicOwners,
                ProjectIds = System.Text.Json.JsonSerializer.Serialize(new[] { projects[1].ProjectId }),
                CoverPhotoUrl = GetUnsplashUrl(communityCoverPhotoIds[1], 1200, 400),
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-15)
            };
            communities.Add(comm2);

            // Community 3: New Administrative Capital Property Owners
            var comm3 = new Community
            {
                Name = "New Administrative Capital Property Owners",
                Description = "Join fellow property owners in Egypt's new capital. Stay updated on developments, infrastructure, and investment opportunities.",
                CreatedById = developers[3].AccountId,
                ScopeType = CommunityScopeType.ProjectBased,
                AccessType = CommunityAccessType.PublicOwners,
                ProjectIds = System.Text.Json.JsonSerializer.Serialize(new[] { projects[3].ProjectId }),
                CoverPhotoUrl = GetUnsplashUrl(communityCoverPhotoIds[2], 1200, 400),
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-12)
            };
            communities.Add(comm3);

            // Community 4: 6th October City Community
            var comm4 = new Community
            {
                Name = "6th October City Community",
                Description = "Largest community for 6th October City residents. Share tips, organize events, and build connections.",
                CreatedById = users[0].AccountId,
                ScopeType = CommunityScopeType.DeveloperBased,
                AccessType = CommunityAccessType.PublicAll,
                DeveloperIds = System.Text.Json.JsonSerializer.Serialize(new[] { developers[4].AccountId }),
                CoverPhotoUrl = GetUnsplashUrl(communityCoverPhotoIds[3], 1200, 400),
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-10)
            };
            communities.Add(comm4);

            // Community 5: Real Estate Investment Tips
            var comm5 = new Community
            {
                Name = "Real Estate Investment Tips",
                Description = "Expert advice and discussions about real estate investment in Egypt. Market trends, property valuation, and investment strategies.",
                CreatedById = developers[2].AccountId,
                ScopeType = CommunityScopeType.DeveloperBased,
                AccessType = CommunityAccessType.PublicAll,
                DeveloperIds = System.Text.Json.JsonSerializer.Serialize(new[] { developers[2].AccountId, developers[5].AccountId }),
                CoverPhotoUrl = GetUnsplashUrl(communityCoverPhotoIds[4], 1200, 400),
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-8)
            };
            communities.Add(comm5);

            // Community 6: Property Maintenance & Services
            var comm6 = new Community
            {
                Name = "Property Maintenance & Services",
                Description = "Find trusted contractors, maintenance services, and home improvement tips. Share recommendations and reviews.",
                CreatedById = users[5].AccountId,
                ScopeType = CommunityScopeType.DeveloperBased,
                AccessType = CommunityAccessType.PublicAll,
                DeveloperIds = System.Text.Json.JsonSerializer.Serialize(new long[] { }),
                CoverPhotoUrl = GetUnsplashUrl(communityCoverPhotoIds[5], 1200, 400),
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-6)
            };
            communities.Add(comm6);

            // Community 7: Sheikh Zayed Property Owners
            var comm7 = new Community
            {
                Name = "Sheikh Zayed Property Owners",
                Description = "Exclusive community for property owners in Sheikh Zayed. Premium discussions and networking.",
                CreatedById = developers[5].AccountId,
                ScopeType = CommunityScopeType.ProjectBased,
                AccessType = CommunityAccessType.Private,
                ProjectIds = System.Text.Json.JsonSerializer.Serialize(new[] { projects[5].ProjectId }),
                CoverPhotoUrl = GetUnsplashUrl(communityCoverPhotoIds[6], 1200, 400),
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-9)
            };
            communities.Add(comm7);

            // Community 8: Buy & Sell Properties
            var comm8 = new Community
            {
                Name = "Buy & Sell Properties",
                Description = "Marketplace for buying and selling properties. Post listings, find buyers, and negotiate deals.",
                CreatedById = users[10].AccountId,
                ScopeType = CommunityScopeType.DeveloperBased,
                AccessType = CommunityAccessType.PublicAll,
                DeveloperIds = System.Text.Json.JsonSerializer.Serialize(new long[] { }),
                CoverPhotoUrl = GetUnsplashUrl(communityCoverPhotoIds[7], 1200, 400),
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddMonths(-5)
            };
            communities.Add(comm8);

            await _context.Communities.AddRangeAsync(communities);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {communities.Count} communities");
            
            return communities;
        }

        private async Task SeedCommunityMembersAsync(List<Community> communities, List<Account> accounts)
        {
            Console.WriteLine("👤 Seeding Community Members...");
            var members = new List<CommunityMember>();
            var users = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            var developers = accounts.Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID).ToList();

            // Add creator as member with Creator role for each community
            foreach (var community in communities)
            {
                members.Add(new CommunityMember
                {
                    CommunityId = community.CommunityId,
                    AccountId = community.CreatedById,
                    Role = CommunityMemberRole.Creator,
                    JoinedAt = community.CreatedAt
                });
            }

            // Add developers to their project communities
            members.Add(new CommunityMember
            {
                CommunityId = communities[0].CommunityId, // Palm Hills
                AccountId = developers[0].AccountId,
                Role = CommunityMemberRole.Moderator,
                JoinedAt = communities[0].CreatedAt.AddDays(1)
            });

            // Add users to communities (realistic distribution)
            var communityUserMapping = new[]
            {
                (0, new[] { 0, 1, 2, 3, 4, 5 }), // Palm Hills - 6 users
                (1, new[] { 1, 2, 3, 4, 5, 6, 7 }), // Al Rehab - 7 users
                (2, new[] { 2, 3, 4, 5, 6, 7, 8, 9 }), // New Capital - 8 users
                (3, new[] { 0, 1, 2, 3, 4, 5, 6, 7, 8 }), // 6th October - 9 users
                (4, new[] { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }), // Investment Tips - 13 users
                (5, new[] { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 }), // Maintenance - 15 users
                (6, new[] { 5, 6, 7, 8, 9 }), // Sheikh Zayed - 5 users
                (7, new[] { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }) // Buy & Sell - 20 users
            };

            foreach (var (commIndex, userIndices) in communityUserMapping)
            {
                if (commIndex < communities.Count)
                {
                    foreach (var userIdx in userIndices)
                    {
                        if (userIdx < users.Count)
                        {
                            members.Add(new CommunityMember
                            {
                                CommunityId = communities[commIndex].CommunityId,
                                AccountId = users[userIdx].AccountId,
                                Role = CommunityMemberRole.Member,
                                JoinedAt = communities[commIndex].CreatedAt.AddDays(userIdx + 1)
                            });
                        }
                    }
                }
            }

            await _context.CommunityMembers.AddRangeAsync(members);
            await _context.SaveChangesAsync();
            
            // Update member counts
            foreach (var community in communities)
            {
                community.MemberCount = members.Count(m => m.CommunityId == community.CommunityId);
            }
            await _context.SaveChangesAsync();
            
            Console.WriteLine($"✅ Seeded {members.Count} community members");
        }

        private async Task<List<CommunityPost>> SeedCommunityPostsAsync(List<Community> communities, List<Account> accounts)
        {
            Console.WriteLine("📝 Seeding Community Posts...");
            var posts = new List<CommunityPost>();
            var users = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            var developers = accounts.Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID).ToList();
            
            var postImageIds = new[]
            {
                "1564013799919-bc007da7807a", "1560448204-e02f11c3d0e2", "1568605114967-8130f3a36994",
                "1600596542810-ff374b12c26e", "1600566753190-17f0baa2a6c3", "1600585154340-be6161a56a0b"
            };

            // Post 1: Welcome post in Palm Hills community
            var post1 = new CommunityPost
            {
                CommunityId = communities[0].CommunityId,
                AuthorId = developers[0].AccountId,
                Content = "Welcome to Palm Hills New Cairo Owners Community! 🏡\n\nWe are happy to have you join this special community. Here you can:\n- Share your experiences with your units\n- Get maintenance tips\n- Meet your neighbors\n- Discuss the latest project updates\n\nWe hope you have a great experience!",
                ImageUrl = GetUnsplashUrl(postImageIds[0]),
                PostType = PostType.Announcement,
                IsPinned = true,
                CreatedAt = communities[0].CreatedAt.AddDays(1),
                LastActivityAt = communities[0].CreatedAt.AddDays(1)
            };
            posts.Add(post1);

            // Post 2: Maintenance tip
            var post2 = new CommunityPost
            {
                CommunityId = communities[0].CommunityId,
                AuthorId = users[0].AccountId,
                Content = "Important tip: Cleaning the AC filter every 2 months extends its life and saves electricity! 💡\n\nI tried it in my apartment and the difference in electricity consumption is clear. Do you have other maintenance tips?",
                PostType = PostType.Regular,
                IsPinned = false,
                CreatedAt = DateTime.UtcNow.AddDays(-45),
                LastActivityAt = DateTime.UtcNow.AddDays(-40)
            };
            posts.Add(post2);

            // Post 3: Event announcement
            var post3 = new CommunityPost
            {
                CommunityId = communities[1].CommunityId,
                AuthorId = developers[1].AccountId,
                Content = "🎉 Invitation to attend a community event in Al Rehab!\n\nWe offer:\n- Workshop on home maintenance\n- Exhibition of trusted contractors\n- Opportunity to meet neighbors\n\nDate: Next week\nLocation: Social Club\n\nPlease register your attendance in the comments!",
                ImageUrl = GetUnsplashUrl(postImageIds[1]),
                PostType = PostType.Announcement,
                IsPinned = true,
                CreatedAt = DateTime.UtcNow.AddDays(-30),
                LastActivityAt = DateTime.UtcNow.AddDays(-25)
            };
            posts.Add(post3);

            // Post 4: Investment discussion
            var post4 = new CommunityPost
            {
                CommunityId = communities[4].CommunityId,
                AuthorId = users[2].AccountId,
                Content = "What do you think about investing in the New Administrative Capital?\n\nI'm thinking of buying an apartment for investment there. The market looks promising but I want opinions from those with experience. Has anyone invested there?",
                PostType = PostType.Regular,
                IsPinned = false,
                CreatedAt = DateTime.UtcNow.AddDays(-20),
                LastActivityAt = DateTime.UtcNow.AddDays(-15)
            };
            posts.Add(post4);

            // Post 5: Contractor recommendation
            var post5 = new CommunityPost
            {
                CommunityId = communities[5].CommunityId,
                AuthorId = users[5].AccountId,
                Content = "Excellent contractor for plumbing and electrical work! 🔧\n\nI used Mr. Mohamed's services for renovating my apartment and his work was excellent:\n✅ Reasonable prices\n✅ Clean and organized work\n✅ Kept to schedule\n✅ Warranty on work\n\nFor those interested, contact number in private messages.",
                PostType = PostType.Regular,
                IsPinned = false,
                CreatedAt = DateTime.UtcNow.AddDays(-35),
                LastActivityAt = DateTime.UtcNow.AddDays(-30)
            };
            posts.Add(post5);

            // Post 6: Property for sale
            var post6 = new CommunityPost
            {
                CommunityId = communities[7].CommunityId,
                AuthorId = users[3].AccountId,
                Content = "Apartment for Sale - 6th October\n\n📍 Location: 6th October City\n🏠 3 bedrooms + 2 bathrooms\n📐 Area: 150 sqm\n💰 Price: 2,400,000 EGP\n✅ Luxury finishing\n✅ 3rd floor\n✅ Garden view\n\nSerious buyers only. For inquiries: 0100xxxxxxx",
                ImageUrl = GetUnsplashUrl(postImageIds[2]),
                PostType = PostType.Regular,
                IsPinned = false,
                CreatedAt = DateTime.UtcNow.AddDays(-10),
                LastActivityAt = DateTime.UtcNow.AddDays(-8)
            };
            posts.Add(post6);

            // Post 7: New Capital update
            var post7 = new CommunityPost
            {
                CommunityId = communities[2].CommunityId,
                AuthorId = developers[3].AccountId,
                Content = "Important updates about the New Administrative Capital:\n\n✅ Monorail station opened\n✅ Basic services started\n✅ Schools and universities opened\n✅ Infrastructure development continues\n\nThe project is progressing excellently! 🚀",
                ImageUrl = GetUnsplashUrl(postImageIds[3]),
                PostType = PostType.Announcement,
                IsPinned = true,
                CreatedAt = DateTime.UtcNow.AddDays(-15),
                LastActivityAt = DateTime.UtcNow.AddDays(-12)
            };
            posts.Add(post7);

            // Post 8: Question about facilities
            var post8 = new CommunityPost
            {
                CommunityId = communities[0].CommunityId,
                AuthorId = users[1].AccountId,
                Content = "Is the sports club available for use now? What are the hours?\n\nI want to start exercising but need to know the details.",
                PostType = PostType.Regular,
                IsPinned = false,
                CreatedAt = DateTime.UtcNow.AddDays(-5),
                LastActivityAt = DateTime.UtcNow.AddDays(-3)
            };
            posts.Add(post8);

            // Post 9: Success story
            var post9 = new CommunityPost
            {
                CommunityId = communities[4].CommunityId,
                AuthorId = users[4].AccountId,
                Content = "Success story: I bought an apartment in 2019 for 1.2 million, and now it's worth 2.8 million! 📈\n\nReal estate investment in Egypt was an excellent decision. My advice: choose the location carefully and be patient with the investment.",
                PostType = PostType.Regular,
                IsPinned = false,
                CreatedAt = DateTime.UtcNow.AddDays(-25),
                LastActivityAt = DateTime.UtcNow.AddDays(-20)
            };
            posts.Add(post9);

            // Post 10: Community event
            var post10 = new CommunityPost
            {
                CommunityId = communities[3].CommunityId,
                AuthorId = users[6].AccountId,
                Content = "Organizing a group trip to visit the Pyramids! 🏛️\n\nWho wants to join?\nDate: Next weekend\nCost: 150 EGP per person\n\nRegister in the comments!",
                ImageUrl = GetUnsplashUrl(postImageIds[4]),
                PostType = PostType.Regular,
                IsPinned = false,
                CreatedAt = DateTime.UtcNow.AddDays(-7),
                LastActivityAt = DateTime.UtcNow.AddDays(-5)
            };
            posts.Add(post10);

            await _context.CommunityPosts.AddRangeAsync(posts);
            await _context.SaveChangesAsync();
            
            // Update post counts
            foreach (var community in communities)
            {
                community.PostCount = posts.Count(p => p.CommunityId == community.CommunityId);
            }
            await _context.SaveChangesAsync();
            
            Console.WriteLine($"✅ Seeded {posts.Count} community posts");
            
            return posts;
        }

        private async Task SeedPostReactionsAsync(List<CommunityPost> posts, List<Account> accounts)
        {
            Console.WriteLine("❤️ Seeding Post Reactions...");
            var reactions = new List<PostReaction>();
            var users = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();

            // Add diverse reactions to posts
            var reactionTypes = new[] { ReactionType.Like, ReactionType.Love, ReactionType.Celebrate, ReactionType.Insightful, ReactionType.Helpful, ReactionType.ThankYou };
            
            // Post 1 (Welcome) - many celebrate reactions
            reactions.Add(new PostReaction { PostId = posts[0].PostId, AccountId = users[0].AccountId, ReactionType = ReactionType.Celebrate, CreatedAt = posts[0].CreatedAt.AddHours(2) });
            reactions.Add(new PostReaction { PostId = posts[0].PostId, AccountId = users[1].AccountId, ReactionType = ReactionType.Like, CreatedAt = posts[0].CreatedAt.AddHours(3) });
            reactions.Add(new PostReaction { PostId = posts[0].PostId, AccountId = users[2].AccountId, ReactionType = ReactionType.ThankYou, CreatedAt = posts[0].CreatedAt.AddHours(4) });
            reactions.Add(new PostReaction { PostId = posts[0].PostId, AccountId = users[3].AccountId, ReactionType = ReactionType.Celebrate, CreatedAt = posts[0].CreatedAt.AddHours(5) });
            posts[0].LikeCount = 4;

            // Post 2 (Maintenance tip) - helpful reactions
            reactions.Add(new PostReaction { PostId = posts[1].PostId, AccountId = users[1].AccountId, ReactionType = ReactionType.Helpful, CreatedAt = posts[1].CreatedAt.AddHours(1) });
            reactions.Add(new PostReaction { PostId = posts[1].PostId, AccountId = users[2].AccountId, ReactionType = ReactionType.Insightful, CreatedAt = posts[1].CreatedAt.AddHours(2) });
            reactions.Add(new PostReaction { PostId = posts[1].PostId, AccountId = users[3].AccountId, ReactionType = ReactionType.ThankYou, CreatedAt = posts[1].CreatedAt.AddHours(3) });
            reactions.Add(new PostReaction { PostId = posts[1].PostId, AccountId = users[4].AccountId, ReactionType = ReactionType.Helpful, CreatedAt = posts[1].CreatedAt.AddHours(4) });
            reactions.Add(new PostReaction { PostId = posts[1].PostId, AccountId = users[5].AccountId, ReactionType = ReactionType.Like, CreatedAt = posts[1].CreatedAt.AddHours(5) });
            posts[1].LikeCount = 5;

            // Post 3 (Event) - celebrate and like
            reactions.Add(new PostReaction { PostId = posts[2].PostId, AccountId = users[0].AccountId, ReactionType = ReactionType.Celebrate, CreatedAt = posts[2].CreatedAt.AddHours(1) });
            reactions.Add(new PostReaction { PostId = posts[2].PostId, AccountId = users[2].AccountId, ReactionType = ReactionType.Like, CreatedAt = posts[2].CreatedAt.AddHours(2) });
            reactions.Add(new PostReaction { PostId = posts[2].PostId, AccountId = users[3].AccountId, ReactionType = ReactionType.Celebrate, CreatedAt = posts[2].CreatedAt.AddHours(3) });
            reactions.Add(new PostReaction { PostId = posts[2].PostId, AccountId = users[4].AccountId, ReactionType = ReactionType.Like, CreatedAt = posts[2].CreatedAt.AddHours(4) });
            reactions.Add(new PostReaction { PostId = posts[2].PostId, AccountId = users[5].AccountId, ReactionType = ReactionType.Celebrate, CreatedAt = posts[2].CreatedAt.AddHours(5) });
            reactions.Add(new PostReaction { PostId = posts[2].PostId, AccountId = users[6].AccountId, ReactionType = ReactionType.Like, CreatedAt = posts[2].CreatedAt.AddHours(6) });
            posts[2].LikeCount = 6;

            // Post 4 (Investment) - insightful reactions
            reactions.Add(new PostReaction { PostId = posts[3].PostId, AccountId = users[0].AccountId, ReactionType = ReactionType.Insightful, CreatedAt = posts[3].CreatedAt.AddHours(1) });
            reactions.Add(new PostReaction { PostId = posts[3].PostId, AccountId = users[1].AccountId, ReactionType = ReactionType.Like, CreatedAt = posts[3].CreatedAt.AddHours(2) });
            reactions.Add(new PostReaction { PostId = posts[3].PostId, AccountId = users[4].AccountId, ReactionType = ReactionType.Insightful, CreatedAt = posts[3].CreatedAt.AddHours(3) });
            posts[3].LikeCount = 3;

            // Post 5 (Contractor) - helpful and thank you
            reactions.Add(new PostReaction { PostId = posts[4].PostId, AccountId = users[0].AccountId, ReactionType = ReactionType.Helpful, CreatedAt = posts[4].CreatedAt.AddHours(1) });
            reactions.Add(new PostReaction { PostId = posts[4].PostId, AccountId = users[1].AccountId, ReactionType = ReactionType.ThankYou, CreatedAt = posts[4].CreatedAt.AddHours(2) });
            reactions.Add(new PostReaction { PostId = posts[4].PostId, AccountId = users[2].AccountId, ReactionType = ReactionType.Helpful, CreatedAt = posts[4].CreatedAt.AddHours(3) });
            reactions.Add(new PostReaction { PostId = posts[4].PostId, AccountId = users[3].AccountId, ReactionType = ReactionType.Like, CreatedAt = posts[4].CreatedAt.AddHours(4) });
            reactions.Add(new PostReaction { PostId = posts[4].PostId, AccountId = users[6].AccountId, ReactionType = ReactionType.ThankYou, CreatedAt = posts[4].CreatedAt.AddHours(5) });
            posts[4].LikeCount = 5;

            // Post 6 (For sale) - like reactions
            reactions.Add(new PostReaction { PostId = posts[5].PostId, AccountId = users[7].AccountId, ReactionType = ReactionType.Like, CreatedAt = posts[5].CreatedAt.AddHours(1) });
            reactions.Add(new PostReaction { PostId = posts[5].PostId, AccountId = users[8].AccountId, ReactionType = ReactionType.Like, CreatedAt = posts[5].CreatedAt.AddHours(2) });
            posts[5].LikeCount = 2;

            // Post 7 (New Capital) - celebrate and like
            reactions.Add(new PostReaction { PostId = posts[6].PostId, AccountId = users[2].AccountId, ReactionType = ReactionType.Celebrate, CreatedAt = posts[6].CreatedAt.AddHours(1) });
            reactions.Add(new PostReaction { PostId = posts[6].PostId, AccountId = users[3].AccountId, ReactionType = ReactionType.Like, CreatedAt = posts[6].CreatedAt.AddHours(2) });
            reactions.Add(new PostReaction { PostId = posts[6].PostId, AccountId = users[4].AccountId, ReactionType = ReactionType.Celebrate, CreatedAt = posts[6].CreatedAt.AddHours(3) });
            reactions.Add(new PostReaction { PostId = posts[6].PostId, AccountId = users[5].AccountId, ReactionType = ReactionType.Like, CreatedAt = posts[6].CreatedAt.AddHours(4) });
            reactions.Add(new PostReaction { PostId = posts[6].PostId, AccountId = users[6].AccountId, ReactionType = ReactionType.Celebrate, CreatedAt = posts[6].CreatedAt.AddHours(5) });
            reactions.Add(new PostReaction { PostId = posts[6].PostId, AccountId = users[7].AccountId, ReactionType = ReactionType.Like, CreatedAt = posts[6].CreatedAt.AddHours(6) });
            reactions.Add(new PostReaction { PostId = posts[6].PostId, AccountId = users[8].AccountId, ReactionType = ReactionType.Celebrate, CreatedAt = posts[6].CreatedAt.AddHours(7) });
            posts[6].LikeCount = 7;

            // Post 8 (Question) - like
            reactions.Add(new PostReaction { PostId = posts[7].PostId, AccountId = users[0].AccountId, ReactionType = ReactionType.Like, CreatedAt = posts[7].CreatedAt.AddHours(1) });
            posts[7].LikeCount = 1;

            // Post 9 (Success story) - celebrate and love
            reactions.Add(new PostReaction { PostId = posts[8].PostId, AccountId = users[0].AccountId, ReactionType = ReactionType.Celebrate, CreatedAt = posts[8].CreatedAt.AddHours(1) });
            reactions.Add(new PostReaction { PostId = posts[8].PostId, AccountId = users[1].AccountId, ReactionType = ReactionType.Love, CreatedAt = posts[8].CreatedAt.AddHours(2) });
            reactions.Add(new PostReaction { PostId = posts[8].PostId, AccountId = users[2].AccountId, ReactionType = ReactionType.Insightful, CreatedAt = posts[8].CreatedAt.AddHours(3) });
            reactions.Add(new PostReaction { PostId = posts[8].PostId, AccountId = users[3].AccountId, ReactionType = ReactionType.Celebrate, CreatedAt = posts[8].CreatedAt.AddHours(4) });
            reactions.Add(new PostReaction { PostId = posts[8].PostId, AccountId = users[5].AccountId, ReactionType = ReactionType.Like, CreatedAt = posts[8].CreatedAt.AddHours(5) });
            reactions.Add(new PostReaction { PostId = posts[8].PostId, AccountId = users[6].AccountId, ReactionType = ReactionType.Celebrate, CreatedAt = posts[8].CreatedAt.AddHours(6) });
            posts[8].LikeCount = 6;

            // Post 10 (Event) - celebrate
            reactions.Add(new PostReaction { PostId = posts[9].PostId, AccountId = users[0].AccountId, ReactionType = ReactionType.Celebrate, CreatedAt = posts[9].CreatedAt.AddHours(1) });
            reactions.Add(new PostReaction { PostId = posts[9].PostId, AccountId = users[1].AccountId, ReactionType = ReactionType.Like, CreatedAt = posts[9].CreatedAt.AddHours(2) });
            reactions.Add(new PostReaction { PostId = posts[9].PostId, AccountId = users[2].AccountId, ReactionType = ReactionType.Celebrate, CreatedAt = posts[9].CreatedAt.AddHours(3) });
            reactions.Add(new PostReaction { PostId = posts[9].PostId, AccountId = users[4].AccountId, ReactionType = ReactionType.Like, CreatedAt = posts[9].CreatedAt.AddHours(4) });
            posts[9].LikeCount = 4;

            await _context.PostReactions.AddRangeAsync(reactions);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {reactions.Count} post reactions");
        }

        private async Task SeedPostLikesAsync(List<CommunityPost> posts, List<Account> accounts)
        {
            Console.WriteLine("👍 Seeding Post Likes...");
            var likes = new List<PostLike>();
            var users = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();

            // Add likes to posts (some users like posts without reactions)
            likes.Add(new PostLike { PostId = posts[0].PostId, AccountId = users[4].AccountId, CreatedAt = posts[0].CreatedAt.AddHours(6) });
            likes.Add(new PostLike { PostId = posts[1].PostId, AccountId = users[6].AccountId, CreatedAt = posts[1].CreatedAt.AddHours(6) });
            likes.Add(new PostLike { PostId = posts[2].PostId, AccountId = users[7].AccountId, CreatedAt = posts[2].CreatedAt.AddHours(7) });
            likes.Add(new PostLike { PostId = posts[3].PostId, AccountId = users[5].AccountId, CreatedAt = posts[3].CreatedAt.AddHours(4) });
            likes.Add(new PostLike { PostId = posts[4].PostId, AccountId = users[7].AccountId, CreatedAt = posts[4].CreatedAt.AddHours(6) });
            likes.Add(new PostLike { PostId = posts[5].PostId, AccountId = users[9].AccountId, CreatedAt = posts[5].CreatedAt.AddHours(3) });
            likes.Add(new PostLike { PostId = posts[6].PostId, AccountId = users[9].AccountId, CreatedAt = posts[6].CreatedAt.AddHours(8) });
            likes.Add(new PostLike { PostId = posts[7].PostId, AccountId = users[2].AccountId, CreatedAt = posts[7].CreatedAt.AddHours(2) });
            likes.Add(new PostLike { PostId = posts[8].PostId, AccountId = users[7].AccountId, CreatedAt = posts[8].CreatedAt.AddHours(7) });
            likes.Add(new PostLike { PostId = posts[9].PostId, AccountId = users[5].AccountId, CreatedAt = posts[9].CreatedAt.AddHours(5) });

            await _context.PostLikes.AddRangeAsync(likes);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {likes.Count} post likes");
        }

        private async Task<List<PostComment>> SeedPostCommentsAsync(List<CommunityPost> posts, List<Account> accounts)
        {
            Console.WriteLine("💬 Seeding Post Comments...");
            var comments = new List<PostComment>();
            var users = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();

            // Post 1 comments
            var comment1 = new PostComment
            {
                PostId = posts[0].PostId,
                AuthorId = users[0].AccountId,
                Content = "Thanks for the welcome! I'm new to the project and looking for tips.",
                CreatedAt = posts[0].CreatedAt.AddHours(3)
            };
            comments.Add(comment1);

            var comment2 = new PostComment
            {
                PostId = posts[0].PostId,
                AuthorId = users[1].AccountId,
                Content = "Welcome! I've been here for a year, any questions I'm ready to help.",
                CreatedAt = posts[0].CreatedAt.AddHours(4)
            };
            comments.Add(comment2);

            // Post 2 comments
            var comment3 = new PostComment
            {
                PostId = posts[1].PostId,
                AuthorId = users[2].AccountId,
                Content = "Excellent tip! I do this every 3 months and the difference is clear.",
                CreatedAt = posts[1].CreatedAt.AddHours(2)
            };
            comments.Add(comment3);

            var comment4 = new PostComment
            {
                PostId = posts[1].PostId,
                AuthorId = users[3].AccountId,
                Content = "I also clean the AC filter regularly. Additional tip: cleaning the external fan is important too.",
                CreatedAt = posts[1].CreatedAt.AddHours(3)
            };
            comments.Add(comment4);

            // Post 3 comments (event)
            var comment5 = new PostComment
            {
                PostId = posts[2].PostId,
                AuthorId = users[0].AccountId,
                Content = "I'm coming! I need to know trusted contractors.",
                CreatedAt = posts[2].CreatedAt.AddHours(2)
            };
            comments.Add(comment5);

            var comment6 = new PostComment
            {
                PostId = posts[2].PostId,
                AuthorId = users[1].AccountId,
                Content = "I'm also coming with my husband. Excited for the event!",
                CreatedAt = posts[2].CreatedAt.AddHours(3)
            };
            comments.Add(comment6);

            // Post 4 comments (investment discussion)
            var comment7 = new PostComment
            {
                PostId = posts[3].PostId,
                AuthorId = users[4].AccountId,
                Content = "I invested in the New Administrative Capital last year. The market is very promising and infrastructure improves every day.",
                CreatedAt = posts[3].CreatedAt.AddHours(2)
            };
            comments.Add(comment7);

            var comment8 = new PostComment
            {
                PostId = posts[3].PostId,
                AuthorId = users[5].AccountId,
                Content = "Tip: Choose a location close to basic services. Value increases quickly in developed areas.",
                CreatedAt = posts[3].CreatedAt.AddHours(3)
            };
            comments.Add(comment8);

            // Reply to comment 8 (index 7 in comments list)
            var comment9 = new PostComment
            {
                PostId = posts[3].PostId,
                AuthorId = users[2].AccountId,
                Content = "Thanks for the tip! Are there specific areas you recommend?",
                ParentCommentId = comments[7].CommentId,
                CreatedAt = posts[3].CreatedAt.AddHours(4)
            };
            comments.Add(comment9);

            // Post 5 comments (contractor)
            var comment10 = new PostComment
            {
                PostId = posts[4].PostId,
                AuthorId = users[6].AccountId,
                Content = "Thanks for the recommendation! I need a contractor for plumbing. Can I get the contact number?",
                CreatedAt = posts[4].CreatedAt.AddHours(2)
            };
            comments.Add(comment10);

            // Post 6 comments (for sale)
            var comment11 = new PostComment
            {
                PostId = posts[5].PostId,
                AuthorId = users[7].AccountId,
                Content = "Is the apartment still available? Can I get more details?",
                CreatedAt = posts[5].CreatedAt.AddHours(1)
            };
            comments.Add(comment11);

            // Post 7 comments (New Capital)
            var comment12 = new PostComment
            {
                PostId = posts[6].PostId,
                AuthorId = users[2].AccountId,
                Content = "Great news! I invested there and I'm excited about the developments.",
                CreatedAt = posts[6].CreatedAt.AddHours(2)
            };
            comments.Add(comment12);

            // Post 8 comments (question)
            var comment13 = new PostComment
            {
                PostId = posts[7].PostId,
                AuthorId = users[0].AccountId,
                Content = "The club is open from 6 AM to 10 PM. Annual membership is 3000 EGP.",
                CreatedAt = posts[7].CreatedAt.AddHours(2)
            };
            comments.Add(comment13);

            // Post 9 comments (success story)
            var comment14 = new PostComment
            {
                PostId = posts[8].PostId,
                AuthorId = users[1].AccountId,
                Content = "Congratulations! Great success story. I also invested in 2020 and the results are excellent.",
                CreatedAt = posts[8].CreatedAt.AddHours(2)
            };
            comments.Add(comment14);

            // Post 10 comments (event)
            var comment15 = new PostComment
            {
                PostId = posts[9].PostId,
                AuthorId = users[0].AccountId,
                Content = "I'm bringing 3 people with me. Excited for the trip!",
                CreatedAt = posts[9].CreatedAt.AddHours(2)
            };
            comments.Add(comment15);

            await _context.PostComments.AddRangeAsync(comments);
            await _context.SaveChangesAsync();

            // Update comment counts
            foreach (var post in posts)
            {
                post.CommentCount = comments.Count(c => c.PostId == post.PostId);
                post.LastActivityAt = comments.Where(c => c.PostId == post.PostId)
                    .OrderByDescending(c => c.CreatedAt)
                    .FirstOrDefault()?.CreatedAt ?? post.CreatedAt;
            }
            await _context.SaveChangesAsync();

            Console.WriteLine($"✅ Seeded {comments.Count} post comments");
            
            return comments;
        }

        private async Task SeedCommentReactionsAsync(List<PostComment> comments, List<Account> accounts)
        {
            Console.WriteLine("❤️ Seeding Comment Reactions...");
            var reactions = new List<CommentReaction>();
            var users = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();

            // Add reactions to helpful comments (using indices: comment3=index 2, comment7=index 6, comment8=index 7, comment13=index 12)
            if (comments.Count > 2)
            {
                reactions.Add(new CommentReaction { CommentId = comments[2].CommentId, AccountId = users[1].AccountId, ReactionType = ReactionType.ThankYou, CreatedAt = comments[2].CreatedAt.AddHours(1) });
            }
            if (comments.Count > 6)
            {
                reactions.Add(new CommentReaction { CommentId = comments[6].CommentId, AccountId = users[2].AccountId, ReactionType = ReactionType.Insightful, CreatedAt = comments[6].CreatedAt.AddHours(1) });
            }
            if (comments.Count > 7)
            {
                reactions.Add(new CommentReaction { CommentId = comments[7].CommentId, AccountId = users[2].AccountId, ReactionType = ReactionType.Helpful, CreatedAt = comments[7].CreatedAt.AddHours(1) });
            }
            if (comments.Count > 12)
            {
                reactions.Add(new CommentReaction { CommentId = comments[12].CommentId, AccountId = users[1].AccountId, ReactionType = ReactionType.ThankYou, CreatedAt = comments[12].CreatedAt.AddHours(1) });
            }

            await _context.CommentReactions.AddRangeAsync(reactions);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {reactions.Count} comment reactions");
        }

        private async Task SeedCommentLikesAsync(List<PostComment> comments, List<Account> accounts)
        {
            Console.WriteLine("👍 Seeding Comment Likes...");
            var likes = new List<CommentLike>();
            var users = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();

            // Add likes to helpful comments
            likes.Add(new CommentLike { CommentId = comments[2].CommentId, AccountId = users[0].AccountId, CreatedAt = comments[2].CreatedAt.AddHours(2) });
            likes.Add(new CommentLike { CommentId = comments[3].CommentId, AccountId = users[1].AccountId, CreatedAt = comments[3].CreatedAt.AddHours(2) });
            likes.Add(new CommentLike { CommentId = comments[6].CommentId, AccountId = users[3].AccountId, CreatedAt = comments[6].CreatedAt.AddHours(2) });
            likes.Add(new CommentLike { CommentId = comments[7].CommentId, AccountId = users[2].AccountId, CreatedAt = comments[7].CreatedAt.AddHours(2) });
            likes.Add(new CommentLike { CommentId = comments[11].CommentId, AccountId = users[3].AccountId, CreatedAt = comments[11].CreatedAt.AddHours(2) });
            likes.Add(new CommentLike { CommentId = comments[12].CommentId, AccountId = users[3].AccountId, CreatedAt = comments[12].CreatedAt.AddHours(2) });

            await _context.CommentLikes.AddRangeAsync(likes);
            await _context.SaveChangesAsync();

            // Update like counts
            foreach (var comment in comments)
            {
                comment.LikeCount = likes.Count(l => l.CommentId == comment.CommentId);
            }
            await _context.SaveChangesAsync();

            Console.WriteLine($"✅ Seeded {likes.Count} comment likes");
        }

        private async Task<List<NewsArticle>> SeedNewsArticlesAsync()
        {
            Console.WriteLine("📰 Seeding News Articles...");
            var articles = new List<NewsArticle>();

            // News 1: Market update (Admin post)
            var news1 = new NewsArticle
            {
                Title = "Egypt Real Estate Prices Rise 15% in Q1 2024",
                Content = "Egypt's real estate market saw significant growth during the first quarter of 2024, with prices rising 15% compared to the same period last year.\n\nAccording to a report from the Central Agency for Public Mobilization and Statistics, this increase comes as a result of several factors:\n\n• Increased demand for residential units in new areas\n• Improved infrastructure in new cities\n• Stability of the Egyptian economy\n• Increased foreign investments\n\nThe report indicated that the fastest-growing areas include the New Administrative Capital, 6th October City, and Sheikh Zayed City.\n\nExperts expect this growth to continue in the second half of the year, especially with the completion of major infrastructure projects.",
                Category = "Market Updates",
                PublishedDate = DateTime.UtcNow.AddDays(-20),
                IsPublished = true,
                CreatedAt = DateTime.UtcNow.AddDays(-21),
                DeveloperId = null // Admin post
            };
            articles.Add(news1);

            // News 2: New project launch (Admin post)
            var news2 = new NewsArticle
            {
                Title = "New Residential Project Launched in Administrative Capital Worth 5 Billion EGP",
                Content = "Palm Hills Development announced the launch of a new residential project in the New Administrative Capital, with an investment value of 5 billion EGP.\n\nThe new project includes:\n• 2000 diverse residential units\n• Integrated recreational facilities\n• Schools and medical centers\n• Commercial areas\n\nThe company's chairman said the project will be implemented in phases, with the first phase scheduled for delivery within 18 months.\n\nHe added that the project aims to provide modern housing at competitive prices, with a focus on sustainability and energy efficiency.",
                Category = "Projects",
                PublishedDate = DateTime.UtcNow.AddDays(-15),
                IsPublished = true,
                CreatedAt = DateTime.UtcNow.AddDays(-16),
                DeveloperId = null // Admin post
            };
            articles.Add(news2);

            // News 3: Investment tips (Admin post)
            var news3 = new NewsArticle
            {
                Title = "5 Golden Tips for Successful Real Estate Investment in Egypt",
                Content = "Real estate investment in Egypt offers excellent growth opportunities, but it requires knowledge and a clear strategy. Here are the most important tips:\n\n1. Choose Location Carefully\nLocation is the most important factor in successful real estate investment. Look for areas experiencing growth in infrastructure and services.\n\n2. Study the Market Well\nBefore investing, study the local market, prices, and trends. Consult trusted real estate experts.\n\n3. Financial Planning\nMake sure you have a clear financial plan. Calculate total costs including taxes and maintenance.\n\n4. Patience and Long-term Investment\nReal estate is a long-term investment. Don't expect quick returns, plan to invest for at least 5-10 years.\n\n5. Diversification\nDon't put all your investments in one place. Spread your investments across different areas and projects to reduce risk.",
                Category = "Tips",
                PublishedDate = DateTime.UtcNow.AddDays(-10),
                IsPublished = true,
                CreatedAt = DateTime.UtcNow.AddDays(-11),
                DeveloperId = null // Admin post
            };
            articles.Add(news3);

            // News 4: Infrastructure update (Admin post)
            var news4 = new NewsArticle
            {
                Title = "Monorail Station Opens in New Administrative Capital",
                Content = "The monorail station in the New Administrative Capital has been opened, providing a modern and fast transportation method for city residents.\n\nThe new station:\n• Connects the Administrative Capital to Greater Cairo\n• Reduces travel time by 60%\n• Provides eco-friendly transportation\n• Contributes to increasing property values in the area\n\nThe Minister of Transportation said this project is part of a comprehensive plan to develop infrastructure in Egypt, with more projects underway.\n\nHe added that the monorail will help attract more investments and residents to the New Administrative Capital.",
                Category = "Infrastructure",
                PublishedDate = DateTime.UtcNow.AddDays(-5),
                IsPublished = true,
                CreatedAt = DateTime.UtcNow.AddDays(-6),
                DeveloperId = null // Admin post
            };
            articles.Add(news4);

            // News 5: Legal update (Admin post)
            var news5 = new NewsArticle
            {
                Title = "New Legal Updates for Property Owners in Egypt",
                Content = "The Egyptian government announced new legal updates for property owners, aimed at facilitating ownership procedures and protecting owner rights.\n\nKey updates:\n\n• Simplified property registration procedures\n• Protection of buyer rights from violations\n• Improved real estate tax system\n• Support for real estate investment\n\nAn official at the Ministry of Housing said these updates are part of a comprehensive plan to develop the real estate sector and make it more transparent and efficient.\n\nHe added that the government is working to implement these updates gradually, while providing necessary support to citizens.",
                Category = "Legal",
                PublishedDate = DateTime.UtcNow.AddDays(-2),
                IsPublished = true,
                CreatedAt = DateTime.UtcNow.AddDays(-3),
                DeveloperId = null // Admin post
            };
            articles.Add(news5);

            await _context.NewsArticles.AddRangeAsync(articles);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {articles.Count} news articles");
            
            return articles;
        }

        private async Task SeedNewsImagesAsync(List<NewsArticle> articles)
        {
            Console.WriteLine("📸 Seeding News Images...");
            var images = new List<NewsImage>();
            var newsImageIds = new[]
            {
                "1564013799919-bc007da7807a", "1560448204-e02f11c3d0e2", "1568605114967-8130f3a36994",
                "1600596542810-ff374b12c26e", "1600566753190-17f0baa2a6c3", "1600585154340-be6161a56a0b"
            };

            // Add images to each news article
            images.Add(new NewsImage { NewsArticleId = articles[0].NewsArticleId, ImageUrl = GetUnsplashUrl(newsImageIds[0], 1200, 600), DisplayOrder = 0 });
            images.Add(new NewsImage { NewsArticleId = articles[1].NewsArticleId, ImageUrl = GetUnsplashUrl(newsImageIds[1], 1200, 600), DisplayOrder = 0 });
            images.Add(new NewsImage { NewsArticleId = articles[2].NewsArticleId, ImageUrl = GetUnsplashUrl(newsImageIds[2], 1200, 600), DisplayOrder = 0 });
            images.Add(new NewsImage { NewsArticleId = articles[3].NewsArticleId, ImageUrl = GetUnsplashUrl(newsImageIds[3], 1200, 600), DisplayOrder = 0 });
            images.Add(new NewsImage { NewsArticleId = articles[4].NewsArticleId, ImageUrl = GetUnsplashUrl(newsImageIds[4], 1200, 600), DisplayOrder = 0 });

            await _context.NewsImages.AddRangeAsync(images);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {images.Count} news images");
        }
    }
}

