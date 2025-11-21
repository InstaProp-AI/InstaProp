using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using BCrypt.Net;
using System.Text.Json;

namespace InstapropAPI.Services
{
    public class CompleteEgyptianSeedingService
    {
        private readonly AppDbContext _context;
        private readonly Random _random = new Random();

        // Real Unsplash Photo IDs for properties (working URLs)
        private readonly string[] _propertyPhotoIds = {
            "1564013799919-bc007da7807a", "1560448204-e02f11c3d0e2", "1568605114967-8130f3a36994",
            "1600596542810-ff374b12c26e", "1600566753190-17f0baa2a6c3", "1600585154340-be6161a56a0b",
            "1600047509358-9dc75507daeb", "1600607687939-ce8a6c25118c", "1600607687644-c717201b0efe",
            "1600585152915-d208b94cde02", "1600566753086-8c67b97e8e5e", "1600607687924-4b2e6b2295ed",
            "1600585154520-86fd880bc1d1", "1600566753377-8c67b97e8e5f", "1600607687645-c717201b0efe",
            "1600585152916-d208b94cde03", "1600566753191-17f0baa2a6c4", "1600607687925-4b2e6b2295ee",
            "1600585154521-86fd880bc1d2", "1600566753378-8c67b97e8e60", "1522771734534-58b3d3a4c",
            "1560449752-6b6d5e0b", "1512918728675-ed5a9ecde638", "1570129477492-45c003edd2be",
            "1582401547731-2b77e36e1783", "1600607687926-4b2e6b2295ef", "1600585154522-86fd880bc1d3"
        };

        private readonly string[] _developerProfilePhotoIds = {
            "1507003211169-0a1dd7228f2d", "1494790108377-be9c29b29330", "1500648767791-00dcc994a43e",
            "1472099645785-5658abf4ff4e", "1519345182560-3f2917c472ef", "1506794778202-cad84cf45f1d",
            "1500648767791-00dcc994a43f", "1492562080023-ab3db95bfbce", "1507003211169-0a1dd7228f2e",
            "1531427186611-ecfd6d936c79", "1506794778202-cad84cf45f20", "1539571696357-5a69c17a67c6",
            "1506794778202-cad84cf45f21", "1500648767791-00dcc994a440", "1492562080023-ab3db95bfbcf"
        };

        private readonly string[] _projectCoverPhotoIds = {
            "1600047509805-cf005714fcc3", "1600047509805-cf005714fcc4", "1600047509805-cf005714fcc5",
            "1600047509805-cf005714fcc6", "1600047509805-cf005714fcc7", "1600047509805-cf005714fcc8",
            "1600047509805-cf005714fcc9", "1600047509805-cf005714fcca", "1600047509805-cf005714fccb",
            "1600047509805-cf005714fccc", "1600047509805-cf005714fccd", "1600047509805-cf005714fcce",
            "1600047509805-cf005714fccf", "1600047509805-cf005714fcd0", "1600047509805-cf005714fcd1",
            "1600047509805-cf005714fcd2", "1600047509805-cf005714fcd3", "1600047509805-cf005714fcd4",
            "1600047509805-cf005714fcd5", "1600047509805-cf005714fcd6", "1522771734534-58b3d3a4c5",
            "1560449752-6b6d5e0b6d", "1512918728675-ed5a9ecde639", "1570129477492-45c003edd2bf"
        };

        private readonly string[] _newsPhotoIds = {
            "1594909122845-11baa059b2bf", "1600585154520-86fd880bc1d1", "1564013799919-bc007da7807a",
            "1600607687939-ce8a6c25118c", "1600566753190-17f0baa2a6c3", "1600047509805-cf005714fcc3",
            "1600585152915-d208b94cde02", "1600566753086-8c67b97e8e5e", "1600607687924-4b2e6b2295ed",
            "1600585154521-86fd880bc1d2", "1594909122845-11baa059b2c0", "1600585154523-86fd880bc1d4"
        };

        // Helper method to get real Unsplash URL
        private string GetUnsplashUrl(string photoId, int width = 800, int height = 600)
        {
            return $"https://images.unsplash.com/photo-{photoId}?w={width}&h={height}&fit=crop&auto=format";
        }

        // Egyptian Real Estate Data
        private readonly string[] _egyptianGovernorates = {
            "Cairo", "Giza", "Alexandria", "Sharm El Sheikh", "Hurghada", "Luxor", "Aswan",
            "Port Said", "Suez", "Ismailia", "Dakahlia", "Gharbia", "Monufia", "Qalyubia",
            "Sharqia", "Beheira", "Kafr El Sheikh", "Damietta", "Red Sea", "New Valley",
            "Matrouh", "North Sinai", "South Sinai", "Fayyum", "Beni Suef", "Minya",
            "Asyut", "Sohag", "Qena", "Aswan"
        };

        private readonly string[] _cairoDistricts = {
            "New Cairo", "Heliopolis", "Nasr City", "Maadi", "Zamalek", "Garden City",
            "Dokki", "Giza", "6th October City", "Sheikh Zayed", "New Administrative Capital",
            "Madinaty", "Rehab City", "Al Shorouk", "Badr City", "Obour City"
        };

        private readonly string[] _egyptianDevelopers = {
            "Palm Hills Developments", "Talaat Moustafa Group", "SODIC", "Emaar Misr",
            "Orascom Development", "City Edge Developments", "Mountain View", "Al Ahly Capital",
            "Misr Italia Properties", "Arkan Palm", "Al Ahly Sabbour", "Hassan Allam Properties",
            "Wadi Degla Developments", "Al Futtaim Group", "Qalaa Holdings", "El Nasr Housing",
            "New Urban Communities Authority", "Cairo Investment and Real Estate Development",
            "Al Ahli Capital", "Egyptian Real Estate Investment"
        };

        private readonly string[] _egyptianProjects = {
            "Palm Hills New Cairo", "Al Rehab City", "Madinaty", "New Administrative Capital",
            "6th October City", "Sheikh Zayed", "New Cairo", "Heliopolis Gardens",
            "Nasr City Heights", "Maadi Heights", "Zamalek Towers", "Garden City Residences",
            "Dokki Gardens", "Giza Heights", "October Gardens", "Zayed Gardens",
            "Capital Gardens", "Madinaty Heights", "Rehab Gardens", "Shorouk City",
            "Badr City", "Obour Gardens", "Al Shorouk City", "New Heliopolis",
            "Cairo Festival City", "Mountain View", "Arkan Palm", "Al Ahly Sabbour",
            "Wadi Degla", "Al Futtaim City", "Qalaa Gardens", "El Nasr Gardens"
        };

        private readonly string[] _egyptianNames = {
            "Ahmed", "Mohamed", "Mahmoud", "Omar", "Hassan", "Ali", "Youssef", "Ibrahim",
            "Khaled", "Amr", "Tarek", "Mostafa", "Hany", "Sherif", "Wael", "Ashraf",
            "Fatma", "Aisha", "Mona", "Nour", "Dina", "Yasmin", "Hala", "Rania",
            "Noha", "Doha", "Mai", "Layla", "Zeinab", "Mariam", "Salma", "Reem"
        };

        private readonly string[] _egyptianLastNames = {
            "Hassan", "Ahmed", "Mohamed", "Ali", "Ibrahim", "Mahmoud", "Omar", "Khaled",
            "Mostafa", "Youssef", "Amr", "Tarek", "Hany", "Sherif", "Wael", "Ashraf",
            "El Sayed", "El Masry", "El Shafei", "El Sherbiny", "El Kady", "El Sisi",
            "El Saeed", "El Morsy", "El Gohary", "El Shazly", "El Banna", "El Shamy"
        };

        public CompleteEgyptianSeedingService(AppDbContext context)
        {
            _context = context;
        }

        public async Task SeedAllDataAsync()
        {
            Console.WriteLine("🌍 Starting Complete Egyptian Real Estate Data Seeding...");

            // Step 1: Clear existing data
            await ClearAllDataAsync();

            // Step 2: Seed Gold Prices (5 years monthly)
            await SeedGoldPricesAsync();

            // Step 3: Seed Accounts (Users, Developers, Admins)
            var accounts = await SeedAccountsAsync();

            // Step 4: Seed Developer Permissions (for all developers)
            await SeedDeveloperPermissionsAsync(accounts);

            // Step 5: Seed Developer Profiles
            await SeedDeveloperProfilesAsync(accounts);

            // Step 6: Seed Projects
            var projects = await SeedProjectsAsync(accounts);

            // Step 7: Seed Parent Properties
            var parentProperties = await SeedParentPropertiesAsync(projects);

            // Step 8: Seed Child Properties
            var childProperties = await SeedChildPropertiesAsync(parentProperties, accounts);

            // Step 9: Seed Property Images (with real URLs)
            await SeedPropertyImagesAsync(childProperties);

            // Step 10: Seed Property Documents
            await SeedPropertyDocumentsAsync(childProperties);

            // Step 11: Seed Auctions
            var auctions = await SeedAuctionsAsync(childProperties);

            // Step 12: Seed Bids
            await SeedBidsAsync(auctions, accounts);

            // Step 13: Seed Events
            await SeedEventsAsync(projects);

            // Step 14: Seed Notifications
            await SeedNotificationsAsync(accounts);

            // Step 15: Seed Chats
            var chats = await SeedChatsAsync(accounts, childProperties);

            // Step 16: Seed Chat Messages
            await SeedChatMessagesAsync(chats);

            // Step 17: Seed AI Chats
            var aiChats = await SeedAIChatsAsync(accounts);

            // Step 18: Seed AI Chat Messages
            await SeedAIChatMessagesAsync(aiChats);

            // Step 19: Seed Project Milestones
            await SeedProjectMilestonesAsync(projects);

            // Step 20: Seed Project Updates
            await SeedProjectUpdatesAsync(projects);

            // Step 21: Seed User Rewards
            await SeedUserRewardsAsync(accounts);

            // Step 22: Seed User Badges
            await SeedUserBadgesAsync(accounts);

            // Step 23: Seed Referrals
            await SeedReferralsAsync(accounts);

            // Step 24: Seed Property Views
            await SeedPropertyViewsAsync(childProperties, accounts);

            // Step 25: Seed Developer Ratings
            await SeedDeveloperRatingsAsync(accounts);

            // Step 26: Seed Property Price History
            await SeedPropertyPriceHistoryAsync(parentProperties, auctions);

            // Step 27: Seed User Documents
            await SeedUserDocumentsAsync(accounts);

            // Step 28: Seed News Articles (with real photo URLs)
            await SeedNewsArticlesAsync();

            // Step 29: Seed Communities (includes members, posts, comments, reactions, polls)
            var communities = await SeedCommunitiesAsync(accounts, projects);
            await SeedCommunityPostsAsync(communities, accounts);

            // Step 30: Seed Property Valuations
            await SeedPropertyValuationsAsync(childProperties);

            // Step 31: Seed User Achievements
            await SeedUserAchievementsAsync(accounts);

            await _context.SaveChangesAsync();
            Console.WriteLine("✅ Complete Egyptian Real Estate Data Seeding Finished!");
        }

        // Seed only chats and messages (without clearing everything)
        public async Task SeedChatsAndMessagesAsync()
        {
            Console.WriteLine("💬 Seeding Chats and Messages...");
            
            // Get existing accounts and properties
            var accounts = await _context.Accounts.ToListAsync();
            var childProperties = await _context.ChildProperties.ToListAsync();
            
            if (!accounts.Any() || !childProperties.Any())
            {
                Console.WriteLine("⚠️ Cannot seed chats: No accounts or properties found. Please seed full data first.");
                return;
            }
            
            // Clear existing chats and messages
            _context.ChatMessages.RemoveRange(_context.ChatMessages);
            _context.Chats.RemoveRange(_context.Chats);
            await _context.SaveChangesAsync();
            Console.WriteLine("🗑️ Cleared existing chats and messages");
            
            // Seed chats
            var chats = await SeedChatsAsync(accounts, childProperties);
            
            // Seed messages
            await SeedChatMessagesAsync(chats);
            
            await _context.SaveChangesAsync();
            Console.WriteLine("✅ Chats and Messages Seeding Finished!");
        }

        private async Task ClearAllDataAsync()
        {
            Console.WriteLine("🗑️ Clearing existing data...");
            
            // Clear in reverse order to avoid foreign key constraints
            // Developer Permissions
            _context.DeveloperPermissions.RemoveRange(_context.DeveloperPermissions);
            
            // Community-related entities
            _context.PollVotes.RemoveRange(_context.PollVotes);
            _context.Polls.RemoveRange(_context.Polls);
            _context.CommentReactions.RemoveRange(_context.CommentReactions);
            _context.PostReactions.RemoveRange(_context.PostReactions);
            _context.CommentLikes.RemoveRange(_context.CommentLikes);
            _context.PostLikes.RemoveRange(_context.PostLikes);
            _context.PostBookmarks.RemoveRange(_context.PostBookmarks);
            _context.PostComments.RemoveRange(_context.PostComments);
            _context.PostCategories.RemoveRange(_context.PostCategories);
            _context.CommunityPosts.RemoveRange(_context.CommunityPosts);
            _context.CommunityMembers.RemoveRange(_context.CommunityMembers);
            _context.Communities.RemoveRange(_context.Communities);
            _context.UserAchievements.RemoveRange(_context.UserAchievements);
            
            // News entities
            _context.NewsImages.RemoveRange(_context.NewsImages);
            _context.NewsArticles.RemoveRange(_context.NewsArticles);
            
            // Property valuations
            _context.PropertyValuations.RemoveRange(_context.PropertyValuations);
            
            // AI Chat entities
            _context.AIChatMessages.RemoveRange(_context.AIChatMessages);
            _context.AIChats.RemoveRange(_context.AIChats);
            
            // Chat entities
            _context.ChatMessages.RemoveRange(_context.ChatMessages);
            _context.Chats.RemoveRange(_context.Chats);
            
            // Auction and bidding entities
            _context.Bids.RemoveRange(_context.Bids);
            _context.Auctions.RemoveRange(_context.Auctions);
            
            // Property-related entities
            _context.PropertyViews.RemoveRange(_context.PropertyViews);
            _context.PropertyPriceHistories.RemoveRange(_context.PropertyPriceHistories);
            _context.PropertyDocs.RemoveRange(_context.PropertyDocs);
            _context.PropertyImages.RemoveRange(_context.PropertyImages);
            _context.ChildProperties.RemoveRange(_context.ChildProperties);
            _context.ParentProperties.RemoveRange(_context.ParentProperties);
            
            // Project entities
            _context.ProjectUpdates.RemoveRange(_context.ProjectUpdates);
            _context.ProjectMilestones.RemoveRange(_context.ProjectMilestones);
            _context.Events.RemoveRange(_context.Events);
            _context.Projects.RemoveRange(_context.Projects);
            
            // User-related entities
            _context.Referrals.RemoveRange(_context.Referrals);
            _context.UserBadges.RemoveRange(_context.UserBadges);
            _context.UserRewards.RemoveRange(_context.UserRewards);
            _context.DeveloperRatings.RemoveRange(_context.DeveloperRatings);
            _context.UserDocs.RemoveRange(_context.UserDocs);
            _context.Notifications.RemoveRange(_context.Notifications);
            
            // Developer and account entities
            _context.DeveloperProfiles.RemoveRange(_context.DeveloperProfiles);
            _context.Accounts.RemoveRange(_context.Accounts);
            
            // Market data
            _context.GoldPrices.RemoveRange(_context.GoldPrices);

            await _context.SaveChangesAsync();
        }

        private async Task SeedGoldPricesAsync()
        {
            Console.WriteLine("🥇 Seeding Gold Prices (5 years monthly)...");
            
            var startDate = DateTime.UtcNow.AddYears(-5);
            var currentDate = DateTime.UtcNow;
            
            var goldPrices = new List<GoldPrice>();
            var currentDateForLoop = startDate;
            
            while (currentDateForLoop <= currentDate)
            {
                // Egyptian gold prices in EGP per gram (realistic range: 800-2000 EGP)
                var basePrice = 1200 + _random.Next(-200, 400);
                var monthlyVariation = _random.Next(-50, 100);
                var price = Math.Max(800, basePrice + monthlyVariation);
                
                goldPrices.Add(new GoldPrice
                {
                    Date = currentDateForLoop,
                    PricePerGram = price,
                    Month = currentDateForLoop.Month,
                    Year = currentDateForLoop.Year,
                    Source = "Manual"
                });
                
                currentDateForLoop = currentDateForLoop.AddMonths(1);
            }
            
            _context.GoldPrices.AddRange(goldPrices);
            await _context.SaveChangesAsync();
        }

        private async Task<List<Account>> SeedAccountsAsync()
        {
            Console.WriteLine("👥 Seeding Accounts...");
            
            var accounts = new List<Account>();
            
            // SECURITY: Create accounts with non-guessable RoleId instead of Type enum
            // Create 1 Admin
            accounts.Add(new Account
            {
                FirstName = "Admin",
                LastName = "User",
                Email = "admin@propertyflipper.com",
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("Admin123!"),
                PhoneNumber = "+201234567890",
                RoleId = Role.ADMIN_ROLE_ID, // Non-guessable 64-bit ID
                Status = VerificationStatus.Verified,
                EmailVerified = true,
                PhoneVerified = true,
                CreatedAt = DateTime.UtcNow.AddYears(-2),
                UpdatedAt = DateTime.UtcNow
            });

            // Create 15 Developers
            for (int i = 0; i < 15; i++)
            {
                var firstName = _egyptianNames[_random.Next(_egyptianNames.Length)];
                var lastName = _egyptianLastNames[_random.Next(_egyptianLastNames.Length)];
                
                accounts.Add(new Account
                {
                    FirstName = firstName,
                    LastName = lastName,
                    Email = $"dev{i + 1}@{_egyptianDevelopers[i].ToLower().Replace(" ", "").Replace("developments", "").Replace("group", "").Replace("properties", "")}.com",
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("Dev123!"),
                    PhoneNumber = $"+201{_random.Next(100000000, 999999999)}",
                    RoleId = Role.DEVELOPER_ROLE_ID, // Non-guessable 64-bit ID
                    Status = VerificationStatus.Verified,
                    EmailVerified = true,
                    PhoneVerified = true,
                    CreatedAt = DateTime.UtcNow.AddYears(-_random.Next(1, 3)),
                    UpdatedAt = DateTime.UtcNow
                });
            }

            // Create 50 Regular Users
            for (int i = 0; i < 50; i++)
            {
                var firstName = _egyptianNames[_random.Next(_egyptianNames.Length)];
                var lastName = _egyptianLastNames[_random.Next(_egyptianLastNames.Length)];
                
                accounts.Add(new Account
                {
                    FirstName = firstName,
                    LastName = lastName,
                    Email = $"user{i + 1}@gmail.com",
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("User123!"),
                    PhoneNumber = $"+201{_random.Next(100000000, 999999999)}",
                    RoleId = Role.USER_ROLE_ID, // Non-guessable 64-bit ID
                    Status = _random.Next(3) == 0 ? VerificationStatus.Pending : VerificationStatus.Verified,
                    EmailVerified = _random.Next(3) != 0,
                    PhoneVerified = _random.Next(3) != 0,
                    CreatedAt = DateTime.UtcNow.AddMonths(-_random.Next(1, 24)),
                    UpdatedAt = DateTime.UtcNow
                });
            }

            _context.Accounts.AddRange(accounts);
            await _context.SaveChangesAsync();
            return accounts;
        }

        private async Task SeedDeveloperPermissionsAsync(List<Account> accounts)
        {
            Console.WriteLine("🔐 Seeding Developer Permissions...");
            
            var developerAccounts = accounts.Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID).ToList();
            var permissions = new List<DeveloperPermission>();
            
            foreach (var developer in developerAccounts)
            {
                // Default features are always enabled (no need to store, but we'll add for completeness)
                // Optional features - randomly enable some for each developer
                var optionalFeatures = FeaturePermission.OptionalFeatures;
                
                foreach (var feature in optionalFeatures)
                {
                    // Randomly enable 30-70% of optional features per developer
                    var isEnabled = _random.Next(10) < (_random.Next(3, 8));
                    
                    permissions.Add(new DeveloperPermission
                    {
                        DeveloperId = developer.AccountId,
                        FeatureName = feature,
                        IsEnabled = isEnabled,
                        CreatedAt = developer.CreatedAt,
                        UpdatedAt = DateTime.UtcNow
                    });
                }
            }

            _context.DeveloperPermissions.AddRange(permissions);
            await _context.SaveChangesAsync();
        }

        private async Task SeedDeveloperProfilesAsync(List<Account> accounts)
        {
            Console.WriteLine("🏢 Seeding Developer Profiles...");
            
            var developerAccounts = accounts.Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID).ToList();
            var profiles = new List<DeveloperProfile>();
            
            for (int i = 0; i < developerAccounts.Count; i++)
            {
                var account = developerAccounts[i];
                var companyName = _egyptianDevelopers[i];
                
                var photoId = _developerProfilePhotoIds[i % _developerProfilePhotoIds.Length];
                
                profiles.Add(new DeveloperProfile
                {
                    AccountId = account.AccountId,
                    CompanyName = companyName,
                    Bio = $"Leading real estate developer in Egypt with over {_random.Next(5, 20)} years of experience in creating premium residential and commercial projects.",
                    ProfileImageUrl = GetUnsplashUrl(photoId, 400, 400),
                    Rating = (decimal)Math.Round(3.5 + _random.NextDouble() * 1.5, 1),
                    TotalRatings = _random.Next(10, 100),
                    PortfolioDescription = $"Specialized in luxury residential developments, commercial projects, and mixed-use communities across Egypt's most prestigious locations.",
                    CreatedAt = account.CreatedAt,
                    UpdatedAt = DateTime.UtcNow
                });
            }

            _context.DeveloperProfiles.AddRange(profiles);
            await _context.SaveChangesAsync();
        }

        private async Task<List<Project>> SeedProjectsAsync(List<Account> accounts)
        {
            Console.WriteLine("🏗️ Seeding Projects...");
            
            var developerAccounts = accounts.Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID).ToList();
            var projects = new List<Project>();
            
            for (int i = 0; i < 25; i++)
            {
                var developer = developerAccounts[_random.Next(developerAccounts.Count)];
                var projectName = _egyptianProjects[_random.Next(_egyptianProjects.Length)];
                var governorate = _egyptianGovernorates[_random.Next(_egyptianGovernorates.Length)];
                var district = governorate == "Cairo" ? _cairoDistricts[_random.Next(_cairoDistricts.Length)] : $"{governorate} District";
                
                projects.Add(new Project
                {
                    Name = projectName,
                    Description = $"Premium residential development featuring modern architecture, world-class amenities, and prime location in {district}, {governorate}.",
                    Location = $"{district}, {governorate}",
                    DeveloperId = developer.AccountId,
                    IsActive = _random.Next(10) != 0, // 90% active
                    CreatedAt = DateTime.UtcNow.AddMonths(-_random.Next(6, 36)),
                    UpdatedAt = DateTime.UtcNow
                });
            }

            _context.Projects.AddRange(projects);
            await _context.SaveChangesAsync();
            return projects;
        }

        private async Task<List<ParentProperty>> SeedParentPropertiesAsync(List<Project> projects)
        {
            Console.WriteLine("🏠 Seeding Parent Properties...");
            
            var parentProperties = new List<ParentProperty>();
            var propertyTypes = new[] { "Apartment", "Villa", "Townhouse", "Penthouse", "Studio" };
            var finishingTypes = new[] { "Finished", "Semi-Finished", "Unfinished" };
            
            for (int i = 0; i < 100; i++)
            {
                var project = projects[_random.Next(projects.Count)];
                var propertyType = propertyTypes[_random.Next(propertyTypes.Length)];
                var finishingType = finishingTypes[_random.Next(finishingTypes.Length)];
                
                // Generate realistic property specifications
                int bedrooms, bathrooms, areaSqm;
                
                switch (propertyType)
                {
                    case "Studio":
                        bedrooms = 0;
                        bathrooms = 1;
                        areaSqm = _random.Next(25, 45);
                        break;
                    case "Apartment":
                        bedrooms = _random.Next(1, 4);
                        bathrooms = bedrooms + _random.Next(0, 2);
                        areaSqm = bedrooms * 40 + _random.Next(20, 60);
                        break;
                    case "Villa":
                        bedrooms = _random.Next(3, 6);
                        bathrooms = bedrooms + _random.Next(1, 3);
                        areaSqm = bedrooms * 50 + _random.Next(100, 200);
                        break;
                    case "Townhouse":
                        bedrooms = _random.Next(2, 4);
                        bathrooms = bedrooms + _random.Next(0, 2);
                        areaSqm = bedrooms * 45 + _random.Next(50, 100);
                        break;
                    case "Penthouse":
                        bedrooms = _random.Next(2, 5);
                        bathrooms = bedrooms + _random.Next(1, 2);
                        areaSqm = bedrooms * 60 + _random.Next(80, 150);
                        break;
                    default:
                        bedrooms = _random.Next(1, 3);
                        bathrooms = bedrooms + 1;
                        areaSqm = bedrooms * 40 + _random.Next(20, 40);
                        break;
                }
                
                var propertyTypeEnum = PropertyTypeHelper.FromDisplayName(propertyType);

                parentProperties.Add(new ParentProperty
                {
                    ProjectName = project.Name,
                    Bedrooms = bedrooms,
                    Bathrooms = bathrooms,
                    AreaSqm = areaSqm,
                    Type = PropertyTypeHelper.ToDisplayName(propertyTypeEnum),
                    FinishingType = finishingType,
                    HasPool = _random.Next(3) == 0,
                    HasGym = _random.Next(2) == 0,
                    HasSecurity = true,
                    HasParking = true,
                    HasGarden = propertyType == "Villa" || _random.Next(3) == 0,
                    HasPlayground = _random.Next(3) == 0,
                    HasClubhouse = _random.Next(4) == 0,
                    ProjectId = project.ProjectId,
                    CreatedAt = DateTime.UtcNow.AddMonths(-_random.Next(1, 24)),
                    UpdatedAt = DateTime.UtcNow
                });
            }

            _context.ParentProperties.AddRange(parentProperties);
            await _context.SaveChangesAsync();
            return parentProperties;
        }

        private async Task<List<ChildProperty>> SeedChildPropertiesAsync(List<ParentProperty> parentProperties, List<Account> accounts)
        {
            Console.WriteLine("🏘️ Seeding Child Properties...");
            
            var childProperties = new List<ChildProperty>();
            var phases = new[] { "Phase 1", "Phase 2", "Phase 3", "Phase 4" };
            var viewTypes = new[] { "Sea View", "Nile View", "Pyramid View", "Garden View", "Street View" };
            var orientations = new[] { "North", "South", "East", "West", "North-East", "South-West" };
            
            foreach (var parent in parentProperties)
            {
                var parentTypeEnum = PropertyTypeHelper.FromDisplayName(parent.Type);

                // Create 2-8 child properties per parent
                var childCount = _random.Next(2, 9);
                
                for (int i = 0; i < childCount; i++)
                {
                    var owner = _random.Next(3) == 0 ? accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).FirstOrDefault() : null;
                    var phase = phases[_random.Next(phases.Length)];
                    var viewType = viewTypes[_random.Next(viewTypes.Length)];
                    var orientation = orientations[_random.Next(orientations.Length)];
                    
                    var childProperty = new ChildProperty
                    {
                        ParentPropertyId = parent.ParentPropertyId,
                        OwnerId = owner?.AccountId,
                        Phase = phase,
                        FloorNumber = parentTypeEnum == PropertyType.Villa ? 0 : _random.Next(1, 20),
                        UnitNumber = $"{_random.Next(1, 50)}{(char)('A' + _random.Next(4))}",
                        ViewType = viewType,
                        Orientation = orientation,
                        DeliveryDate = DateTime.UtcNow.AddMonths(_random.Next(6, 36)),
                        ParkingSlots = _random.Next(1, 3),
                        HasStorageRoom = _random.Next(2) == 0,
                        BuyingPrice = owner != null ? _random.Next(500000, 5000000) : null,
                        BuyingDate = owner != null ? DateTime.UtcNow.AddMonths(-_random.Next(1, 12)) : null,
                        Quantity = 1,
                        
                        // Amenities
                        HasNannyRoom = _random.Next(4) == 0,
                        HasDriverRoom = _random.Next(4) == 0,
                        HasMaidRoom = _random.Next(3) == 0,
                        HasPrivatePool = _random.Next(5) == 0,
                        HasRoofAccess = _random.Next(3) == 0,
                        HasBalcony = _random.Next(2) == 0,
                        HasGarden = parent.HasGarden && _random.Next(2) == 0,
                        HasClubhouse = parent.HasClubhouse && _random.Next(3) == 0,
                        HasInfrastructure = _random.Next(2) == 0,
                        HasUndergroundParking = _random.Next(2) == 0,
                        HasMedicalCenter = _random.Next(3) == 0,
                        HasCommercialStrip = _random.Next(3) == 0,
                        HasBusinessHub = _random.Next(3) == 0,
                        HasOutdoorPools = _random.Next(3) == 0,
                        HasBicycleLanes = _random.Next(2) == 0,
                        HasJoggingTrail = _random.Next(2) == 0,
                        SmartHome = _random.Next(3) == 0,
                        CentralAC = _random.Next(2) == 0,
                        NaturalGas = _random.Next(2) == 0,
                        HasGenerator = _random.Next(3) == 0,
                        
                        // Views
                        SeaView = viewType == "Sea View",
                        NileView = viewType == "Nile View",
                        PyramidView = viewType == "Pyramid View",
                        GardenView = viewType == "Garden View",
                        StreetView = viewType == "Street View",
                        
                        // Legacy fields
                        Name = $"{parent.ProjectName} - {parent.Type} {parent.Bedrooms}BR",
                        Description = $"Beautiful {parent.Type.ToLowerInvariant()} in {parent.ProjectName} with {parent.Bedrooms} bedrooms and {parent.Bathrooms} bathrooms.",
                        Location = $"{parent.ProjectName}, Egypt",
                        ImageUrl = GetUnsplashUrl(_propertyPhotoIds[childProperties.Count % _propertyPhotoIds.Length]),
                        SquareFeet = (int)(parent.AreaSqm * 10.764), // Convert to sq ft
                        YearBuilt = DateTime.UtcNow.Year - _random.Next(0, 5),
                        IsApproved = _random.Next(4) != 0,
                        CreatedAt = parent.CreatedAt,
                        UpdatedAt = DateTime.UtcNow,
                        
                        // Inherited properties
                        Bedrooms = parent.Bedrooms,
                        Bathrooms = parent.Bathrooms,
                        Type = parentTypeEnum,
                        Status = (PropertyStatus)_random.Next(0, 4),
                        ProjectId = parent.ProjectId
                    };
                    
                    childProperties.Add(childProperty);
                }
            }

            _context.ChildProperties.AddRange(childProperties);
            await _context.SaveChangesAsync();
            return childProperties;
        }

        private async Task SeedPropertyImagesAsync(List<ChildProperty> childProperties)
        {
            Console.WriteLine("📸 Seeding Property Images...");
            
            var propertyImages = new List<PropertyImage>();
            
            foreach (var property in childProperties)
            {
                // Add 3-8 images per property
                var imageCount = _random.Next(3, 9);
                
                for (int i = 0; i < imageCount; i++)
                {
                    var photoIndex = (propertyImages.Count + i) % _propertyPhotoIds.Length;
                    var photoId = _propertyPhotoIds[photoIndex];
                    
                    propertyImages.Add(new PropertyImage
                    {
                        PropertyId = property.PropertyId,
                        ImageUrl = GetUnsplashUrl(photoId, 1200, 800),
                        ImageType = i == 0 ? "Main" : (i == 1 ? "Living Room" : (i == 2 ? "Bedroom" : (i == 3 ? "Kitchen" : (i == 4 ? "Bathroom" : "Exterior")))),
                        IsMainImage = i == 0,
                        DisplayOrder = i,
                        CreatedAt = property.CreatedAt.AddDays(_random.Next(0, 30))
                    });
                }
            }

            _context.PropertyImages.AddRange(propertyImages);
            await _context.SaveChangesAsync();
        }

        private async Task SeedPropertyDocumentsAsync(List<ChildProperty> childProperties)
        {
            Console.WriteLine("📄 Seeding Property Documents...");
            
            var propertyDocs = new List<PropertyDoc>();
            var docTypes = new[] { "Master Plan", "Floor Plan", "Legal Document", "Ownership Certificate", "Building Permit", "Insurance" };
            
            foreach (var property in childProperties.Where(p => p.OwnerId != null))
            {
                // Add 2-5 documents per owned property
                var docCount = _random.Next(2, 6);
                
                for (int i = 0; i < docCount; i++)
                {
                    var photoIndex = (propertyDocs.Count + i) % _propertyPhotoIds.Length;
                    var photoId = _propertyPhotoIds[photoIndex];
                    
                    propertyDocs.Add(new PropertyDoc
                    {
                        PropertyId = property.PropertyId,
                        DocType = docTypes[_random.Next(docTypes.Length)],
                        ImgUrl = GetUnsplashUrl(photoId, 800, 1000),
                        DeleteUrl = $"https://api.imgbb.com/1/delete/{_random.Next(100000, 999999)}",
                        UploadedAt = property.CreatedAt.AddDays(_random.Next(0, 30))
                    });
                }
            }

            _context.PropertyDocs.AddRange(propertyDocs);
            await _context.SaveChangesAsync();
        }

        private async Task<List<Auction>> SeedAuctionsAsync(List<ChildProperty> childProperties)
        {
            Console.WriteLine("🔨 Seeding Auctions...");
            
            var auctions = new List<Auction>();
            var statuses = new[] { "Active", "Closed", "Cancelled", "Requested" };
            
            // Create auctions for 30% of properties
            var propertiesWithAuctions = childProperties.Where(p => _random.Next(10) < 3).ToList();
            
            foreach (var property in propertiesWithAuctions)
            {
                var status = statuses[_random.Next(statuses.Length)];
                var startPrice = property.BuyingPrice.HasValue ? 
                    (decimal)(property.BuyingPrice.Value * (decimal)(0.8 + _random.NextDouble() * 0.4)) : 
                    (decimal)(_random.Next(500000, 5000000));
                
                var auction = new Auction
                {
                    PropertyId = property.PropertyId,
                    StartPrice = startPrice,
                    CurrentPrice = startPrice + (decimal)(_random.NextDouble() * (double)startPrice * 0.3),
                    StartAt = DateTime.UtcNow.AddDays(-_random.Next(0, 30)),
                    Duration = _random.Next(24, 168), // 1-7 days
                    BidCount = _random.Next(0, 15),
                    Status = status,
                    CreatedAt = DateTime.UtcNow.AddDays(-_random.Next(1, 60))
                };
                
                auctions.Add(auction);
            }

            _context.Auctions.AddRange(auctions);
            await _context.SaveChangesAsync();
            return auctions;
        }

        private async Task SeedBidsAsync(List<Auction> auctions, List<Account> accounts)
        {
            Console.WriteLine("💰 Seeding Bids...");
            
            var bids = new List<Bid>();
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            
            foreach (var auction in auctions.Where(a => a.Status == "Active" || a.Status == "Closed"))
            {
                // Create 2-10 bids per auction
                var bidCount = _random.Next(2, 11);
                var currentPrice = auction.StartPrice;
                
                for (int i = 0; i < bidCount; i++)
                {
                    var bidder = userAccounts[_random.Next(userAccounts.Count)];
                    currentPrice += (decimal)(_random.NextDouble() * 50000); // Increase by up to 50k EGP
                    
                    bids.Add(new Bid
                    {
                        AuctionId = auction.AuctionId,
                        BidderId = bidder.AccountId,
                        BidAmount = currentPrice,
                        CreatedAt = auction.StartAt.AddHours(_random.Next(0, auction.Duration))
                    });
                }
            }

            _context.Bids.AddRange(bids);
            await _context.SaveChangesAsync();
        }

        private async Task SeedEventsAsync(List<Project> projects)
        {
            Console.WriteLine("📅 Seeding Events...");
            
            var events = new List<Event>();
            var eventTypes = new[] { "Project Launch", "Construction Update", "Handover Ceremony", "Sales Event", "Open House" };
            
            foreach (var project in projects)
            {
                // Create 3-8 events per project
                var eventCount = _random.Next(3, 9);
                
                for (int i = 0; i < eventCount; i++)
                {
                    var eventDate = DateTime.UtcNow.AddDays(-_random.Next(0, 365));
                    
                    events.Add(new Event
                    {
                        UserId = project.DeveloperId,
                        Title = $"{eventTypes[_random.Next(eventTypes.Length)]} - {project.Name}",
                        Description = $"Join us for an exciting {eventTypes[_random.Next(eventTypes.Length)].ToLower()} at {project.Name}. Don't miss this opportunity!",
                        EventDate = eventDate,
                        Location = project.Location,
                        Type = (EventType)_random.Next(0, 11),
                        IsRecurring = _random.Next(5) == 0,
                        RecurrencePattern = _random.Next(5) == 0 ? (RecurrencePattern?)_random.Next(0, 4) : null,
                        CreatedAt = eventDate.AddDays(-_random.Next(1, 30)),
                        UpdatedAt = DateTime.UtcNow
                    });
                }
            }

            _context.Events.AddRange(events);
            await _context.SaveChangesAsync();
        }

        private async Task SeedNotificationsAsync(List<Account> accounts)
        {
            Console.WriteLine("🔔 Seeding Notifications...");
            
            var notifications = new List<Notification>();
            var notificationTypes = new[] { "Auction Started", "Bid Placed", "Auction Won", "Property Added", "System Update" };
            
            foreach (var account in accounts)
            {
                // Create 5-15 notifications per user
                var notificationCount = _random.Next(5, 16);
                
                for (int i = 0; i < notificationCount; i++)
                {
                    notifications.Add(new Notification
                    {
                        UserId = account.AccountId,
                        Title = notificationTypes[_random.Next(notificationTypes.Length)],
                        Message = $"You have a new {notificationTypes[_random.Next(notificationTypes.Length)].ToLower()} notification.",
                        Type = (NotificationType)_random.Next(0, 5),
                        IsRead = _random.Next(3) != 0,
                        CreatedAt = DateTime.UtcNow.AddDays(-_random.Next(0, 30))
                    });
                }
            }

            _context.Notifications.AddRange(notifications);
            await _context.SaveChangesAsync();
        }

        private async Task<List<Chat>> SeedChatsAsync(List<Account> accounts, List<ChildProperty> childProperties)
        {
            Console.WriteLine("💬 Seeding Chats...");
            
            var chats = new List<Chat>();
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            var developerAccounts = accounts.Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID).ToList();
            
            // Create 30-50 chats for better testing
            var chatCount = _random.Next(30, 51);
            
            for (int i = 0; i < chatCount; i++)
            {
                var user = userAccounts[_random.Next(userAccounts.Count)];
                var developer = developerAccounts[_random.Next(developerAccounts.Count)];
                var property = childProperties[_random.Next(childProperties.Count)];
                
                // Assign 30-50% of chats to sales members (use developers as sales members)
                long? salesMemberId = null;
                if (_random.Next(10) < 4) // 40% chance
                {
                    // Pick a random developer to act as sales member (can be different from the developer)
                    var salesMember = developerAccounts[_random.Next(developerAccounts.Count)];
                    salesMemberId = salesMember.AccountId;
                }
                
                chats.Add(new Chat
                {
                    UserId = user.AccountId,
                    DeveloperId = developer.AccountId,
                    ProjectId = property.ProjectId,
                    SalesMemberId = salesMemberId,
                    IsActive = _random.Next(4) != 0,
                    IsSupportChat = _random.Next(5) == 0, // 20% are support chats
                    CreatedAt = DateTime.UtcNow.AddDays(-_random.Next(0, 90)),
                    LastMessageAt = DateTime.UtcNow.AddDays(-_random.Next(0, 30))
                });
            }

            _context.Chats.AddRange(chats);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {chats.Count} chats ({chats.Count(c => c.SalesMemberId != null)} assigned to sales members)");
            return chats;
        }

        private async Task SeedChatMessagesAsync(List<Chat> chats)
        {
            Console.WriteLine("💭 Seeding Chat Messages...");
            
            var messages = new List<ChatMessage>();
            var userMessages = new[]
            {
                "Hello, I'm interested in this property. Can you tell me more about it?",
                "What is the current price for this unit?",
                "When will the project be completed?",
                "Are there any payment plans available?",
                "What amenities are included?",
                "Is parking included?",
                "What about the view from this unit?",
                "Can I schedule a site visit?",
                "What are the maintenance fees?",
                "Is financing available?",
                "How many bedrooms does this unit have?",
                "What's the square footage?",
                "Is the property ready to move in?",
                "What's the down payment requirement?",
                "Are pets allowed?",
                "What about schools nearby?",
                "Is there public transportation access?",
                "What's the nearest shopping center?",
                "Can I see floor plans?",
                "What's included in the price?"
            };
            
            var developerMessages = new[]
            {
                "Hello! Thank you for your interest. I'd be happy to help you with this property.",
                "The current price is {price} EGP. We also offer flexible payment plans.",
                "The project is expected to be completed by {date}. Construction is progressing well.",
                "Yes, we have several payment plan options. Let me send you the details.",
                "The property includes parking, 24/7 security, swimming pool, gym, and gardens.",
                "Yes, parking is included. Each unit comes with one or two parking spaces.",
                "The view is excellent! The unit overlooks the main garden and pool area.",
                "Absolutely! I can schedule a site visit for you. When would be convenient?",
                "Maintenance fees are approximately {amount} EGP per square meter annually.",
                "Yes, financing is available through several partner banks. I can provide details.",
                "This unit has {bedrooms} bedrooms and {bathrooms} bathrooms.",
                "The unit is {sqft} square feet. Would you like to see the floor plan?",
                "The property is {status}. We have both ready and off-plan units available.",
                "The down payment is {percentage}% of the total price, payable over 12 months.",
                "Yes, pets are allowed. The building is pet-friendly with designated areas.",
                "There are several excellent schools within a 5-minute drive.",
                "Yes, the metro station is just 500 meters away, very convenient.",
                "There's a large shopping mall within walking distance, about 10 minutes.",
                "Of course! I'll send you the floor plans via email.",
                "The price includes finishing, kitchen appliances, and air conditioning units."
            };
            
            foreach (var chat in chats)
            {
                // Create 5-15 messages per chat for better testing
                var messageCount = _random.Next(5, 16);
                var baseTime = chat.CreatedAt;
                
                for (int i = 0; i < messageCount; i++)
                {
                    // Alternate between user and developer messages, but start with user
                    var isFromUser = (i % 2) == 0;
                    var senderId = isFromUser ? chat.UserId : chat.DeveloperId;
                    
                    // Select appropriate message template
                    var messageTemplate = isFromUser 
                        ? userMessages[_random.Next(userMessages.Length)]
                        : developerMessages[_random.Next(developerMessages.Length)];
                    
                    // Simple template replacement for variety
                    var message = messageTemplate
                        .Replace("{price}", (_random.Next(2, 8) * 1000000).ToString())
                        .Replace("{date}", DateTime.UtcNow.AddMonths(_random.Next(6, 24)).ToString("MMMM yyyy"))
                        .Replace("{amount}", (_random.Next(50, 150)).ToString())
                        .Replace("{bedrooms}", chat.ProjectId != null ? "3" : _random.Next(2, 5).ToString())
                        .Replace("{bathrooms}", chat.ProjectId != null ? "2" : _random.Next(2, 4).ToString())
                        .Replace("{sqft}", (_random.Next(1200, 3500)).ToString())
                        .Replace("{status}", _random.Next(2) == 0 ? "ready to move in" : "under construction")
                        .Replace("{percentage}", (_random.Next(10, 20)).ToString());
                    
                    // Calculate message time (spread over days since chat creation)
                    var daysSinceChat = (DateTime.UtcNow - chat.CreatedAt).TotalDays;
                    var messageOffset = TimeSpan.FromDays(daysSinceChat * (i / (double)messageCount));
                    var messageTime = baseTime + messageOffset;
                    
                    // Ensure message time doesn't exceed last message time
                    if (messageTime > chat.LastMessageAt)
                    {
                        messageTime = chat.LastMessageAt.AddMinutes(-_random.Next(0, 60));
                    }
                    
                    messages.Add(new ChatMessage
                    {
                        ChatId = chat.ChatId,
                        SenderId = senderId,
                        Content = message,
                        PropertyId = (int?)chat.ProjectId,
                        IsRead = _random.Next(4) != 0, // 75% are read
                        CreatedAt = messageTime,
                        ExpiresAt = messageTime.AddDays(30)
                    });
                }
                
                // Update chat's last message time
                var lastMessage = messages.Where(m => m.ChatId == chat.ChatId).OrderByDescending(m => m.CreatedAt).FirstOrDefault();
                if (lastMessage != null)
                {
                    chat.LastMessageAt = lastMessage.CreatedAt;
                }
            }

            _context.ChatMessages.AddRange(messages);
            await _context.SaveChangesAsync();
            Console.WriteLine($"✅ Seeded {messages.Count} chat messages");
        }

        private async Task<List<AIChat>> SeedAIChatsAsync(List<Account> accounts)
        {
            Console.WriteLine("🤖 Seeding AI Chats...");
            
            var aiChats = new List<AIChat>();
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            
            // Create 15-25 AI chats
            var chatCount = _random.Next(15, 26);
            
            for (int i = 0; i < chatCount; i++)
            {
                var user = userAccounts[_random.Next(userAccounts.Count)];
                
                aiChats.Add(new AIChat
                {
                    UserId = user.AccountId,
                    Status = _random.Next(3) != 0 ? "Active" : "Completed",
                    StartedAt = DateTime.UtcNow.AddDays(-_random.Next(0, 30)),
                    UpdatedAt = DateTime.UtcNow
                });
            }

            _context.AIChats.AddRange(aiChats);
            await _context.SaveChangesAsync();
            return aiChats;
        }

        private async Task SeedAIChatMessagesAsync(List<AIChat> aiChats)
        {
            Console.WriteLine("🤖💭 Seeding AI Chat Messages...");
            
            var messages = new List<AIChatMessage>();
            var userQuestions = new[]
            {
                "What is the best area to invest in Cairo?",
                "How do I calculate property ROI?",
                "What are the current market trends?",
                "Should I buy now or wait?",
                "What documents do I need for property purchase?",
                "How do I get a mortgage in Egypt?",
                "What are the tax implications?",
                "How do I evaluate a property's value?",
                "What are the risks of real estate investment?",
                "How do I find good deals?"
            };
            
            var aiResponses = new[]
            {
                "Based on current market analysis, I recommend considering New Cairo or Sheikh Zayed for investment opportunities.",
                "ROI can be calculated by dividing annual rental income by property purchase price, then multiplying by 100.",
                "The Egyptian real estate market is showing steady growth with increasing demand for residential properties.",
                "Market conditions suggest it's a good time to invest, but consider your financial situation first.",
                "You'll need ID, proof of income, property documents, and legal papers for the transaction.",
                "Several banks offer competitive mortgage rates. I can help you compare options.",
                "Property taxes in Egypt are generally low, but consult a tax advisor for specific cases.",
                "Consider location, amenities, developer reputation, and future development plans in the area.",
                "Main risks include market fluctuations, liquidity, and maintenance costs. Diversification helps.",
                "Look for properties in emerging areas, consider pre-construction deals, and negotiate with developers."
            };
            
            foreach (var chat in aiChats)
            {
                // Create 2-8 messages per AI chat
                var messageCount = _random.Next(2, 9);
                
                for (int i = 0; i < messageCount; i++)
                {
                    var isUserMessage = i % 2 == 0;
                    var content = isUserMessage ? 
                        userQuestions[_random.Next(userQuestions.Length)] : 
                        aiResponses[_random.Next(aiResponses.Length)];
                    
                    messages.Add(new AIChatMessage
                    {
                        AIChatId = chat.AIChatId,
                        Content = content,
                        Role = isUserMessage ? "User" : "Assistant",
                        MessageType = "Text",
                        CreatedAt = chat.StartedAt.AddMinutes(_random.Next(0, 60))
                    });
                }
            }

            _context.AIChatMessages.AddRange(messages);
            await _context.SaveChangesAsync();
        }

        private async Task SeedProjectMilestonesAsync(List<Project> projects)
        {
            Console.WriteLine("🎯 Seeding Project Milestones...");
            
            var milestones = new List<ProjectMilestone>();
            var milestoneNames = new[] { "Foundation", "Structure", "Finishing", "Handover", "Landscaping" };
            
            foreach (var project in projects)
            {
                // Create 3-6 milestones per project
                var milestoneCount = _random.Next(3, 7);
                
                for (int i = 0; i < milestoneCount; i++)
                {
                    var milestone = new ProjectMilestone
                    {
                        ProjectId = project.ProjectId,
                        Title = milestoneNames[_random.Next(milestoneNames.Length)],
                        Description = $"Milestone {i + 1} for {project.Name}",
                        TargetDate = DateTime.UtcNow.AddDays(_random.Next(30, 365)),
                        Status = (MilestoneStatus)_random.Next(0, 4),
                        CreatedAt = project.CreatedAt.AddDays(_random.Next(0, 30)),
                        UpdatedAt = DateTime.UtcNow
                    };
                    
                    milestones.Add(milestone);
                }
            }

            _context.ProjectMilestones.AddRange(milestones);
            await _context.SaveChangesAsync();
        }

        private async Task SeedProjectUpdatesAsync(List<Project> projects)
        {
            Console.WriteLine("📢 Seeding Project Updates...");
            
            var updates = new List<ProjectUpdate>();
            
            foreach (var project in projects)
            {
                // Create 2-5 updates per project
                var updateCount = _random.Next(2, 6);
                
                for (int i = 0; i < updateCount; i++)
                {
                    var photoIndex = updates.Count % _projectCoverPhotoIds.Length;
                    var photoId = _projectCoverPhotoIds[photoIndex];
                    
                    updates.Add(new ProjectUpdate
                    {
                        ProjectId = project.ProjectId,
                        Title = $"Update {i + 1} - {project.Name}",
                        Content = $"Progress update for {project.Name}. Construction is proceeding according to schedule.",
                        ImageUrl = GetUnsplashUrl(photoId, 800, 600),
                        CreatedAt = project.CreatedAt.AddDays(_random.Next(0, 90))
                    });
                }
            }

            _context.ProjectUpdates.AddRange(updates);
            await _context.SaveChangesAsync();
        }

        private async Task SeedUserRewardsAsync(List<Account> accounts)
        {
            Console.WriteLine("🏆 Seeding User Rewards...");
            
            var rewards = new List<UserReward>();
            var rewardTypes = new[] { "Login", "Property View", "Bid Placed", "Auction Won", "Referral" };
            
            foreach (var account in accounts.Where(a => a.RoleId == Role.USER_ROLE_ID))
            {
                // Create 5-20 rewards per user
                var rewardCount = _random.Next(5, 21);
                
                for (int i = 0; i < rewardCount; i++)
                {
                    rewards.Add(new UserReward
                    {
                        AccountId = account.AccountId,
                        RewardType = rewardTypes[_random.Next(rewardTypes.Length)],
                        Points = _random.Next(10, 100),
                        Description = $"Earned {_random.Next(10, 100)} points for {rewardTypes[_random.Next(rewardTypes.Length)].ToLower()}",
                        EarnedAt = DateTime.UtcNow.AddDays(-_random.Next(0, 90))
                    });
                }
            }

            _context.UserRewards.AddRange(rewards);
            await _context.SaveChangesAsync();
        }

        private async Task SeedUserBadgesAsync(List<Account> accounts)
        {
            Console.WriteLine("🥇 Seeding User Badges...");
            
            var badges = new List<UserBadge>();
            var badgeNames = new[] { "First Bid", "Property Hunter", "Auction Master", "Loyal User", "Referral King" };
            
            foreach (var account in accounts.Where(a => a.RoleId == Role.USER_ROLE_ID))
            {
                // Create 1-5 badges per user
                var badgeCount = _random.Next(1, 6);
                
                for (int i = 0; i < badgeCount; i++)
                {
                    badges.Add(new UserBadge
                    {
                        AccountId = account.AccountId,
                        BadgeName = badgeNames[_random.Next(badgeNames.Length)],
                        BadgeIcon = "🏆",
                        Description = $"Achievement badge: {badgeNames[_random.Next(badgeNames.Length)]}",
                        AwardedAt = DateTime.UtcNow.AddDays(-_random.Next(0, 90))
                    });
                }
            }

            _context.UserBadges.AddRange(badges);
            await _context.SaveChangesAsync();
        }

        private async Task SeedReferralsAsync(List<Account> accounts)
        {
            Console.WriteLine("👥 Seeding Referrals...");
            
            var referrals = new List<Referral>();
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            
            // Create 10-20 referrals
            var referralCount = _random.Next(10, 21);
            
            for (int i = 0; i < referralCount; i++)
            {
                var referrer = userAccounts[_random.Next(userAccounts.Count)];
                var referred = userAccounts[_random.Next(userAccounts.Count)];
                
                if (referrer.AccountId != referred.AccountId)
                {
                    referrals.Add(new Referral
                    {
                        ReferrerId = referrer.AccountId,
                        ReferredUserId = referred.AccountId,
                        ReferralCode = $"REF{_random.Next(100000, 999999)}",
                        IsConverted = _random.Next(3) != 0,
                        CreatedAt = DateTime.UtcNow.AddDays(-_random.Next(0, 60))
                    });
                }
            }

            _context.Referrals.AddRange(referrals);
            await _context.SaveChangesAsync();
        }

        private async Task SeedPropertyViewsAsync(List<ChildProperty> childProperties, List<Account> accounts)
        {
            Console.WriteLine("👁️ Seeding Property Views...");
            
            var views = new List<PropertyView>();
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            
            foreach (var property in childProperties)
            {
                // Create 5-20 views per property
                var viewCount = _random.Next(5, 21);
                
                for (int i = 0; i < viewCount; i++)
                {
                    var viewer = userAccounts[_random.Next(userAccounts.Count)];
                    
                    views.Add(new PropertyView
                    {
                        PropertyId = property.PropertyId,
                        UserId = viewer.AccountId,
                        ViewedAt = DateTime.UtcNow.AddDays(-_random.Next(0, 30))
                    });
                }
            }

            _context.PropertyViews.AddRange(views);
            await _context.SaveChangesAsync();
        }

        private async Task SeedDeveloperRatingsAsync(List<Account> accounts)
        {
            Console.WriteLine("⭐ Seeding Developer Ratings...");
            
            var ratings = new List<DeveloperRating>();
            var developerAccounts = accounts.Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID).ToList();
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            
            foreach (var developer in developerAccounts)
            {
                // Create 5-15 ratings per developer
                var ratingCount = _random.Next(5, 16);
                
                for (int i = 0; i < ratingCount; i++)
                {
                    var user = userAccounts[_random.Next(userAccounts.Count)];
                    
                    ratings.Add(new DeveloperRating
                    {
                        DeveloperId = developer.AccountId,
                        UserId = user.AccountId,
                        Rating = _random.Next(3, 6), // 3-5 stars
                        Comment = $"Great developer with excellent projects and customer service.",
                        CreatedAt = DateTime.UtcNow.AddDays(-_random.Next(0, 180))
                    });
                }
            }

            _context.DeveloperRatings.AddRange(ratings);
            await _context.SaveChangesAsync();
        }

        private async Task SeedPropertyPriceHistoryAsync(List<ParentProperty> parentProperties, List<Auction> auctions)
        {
            Console.WriteLine("📈 Seeding Property Price History...");
            
            var priceHistories = new List<PropertyPriceHistory>();
            
            foreach (var parent in parentProperties)
            {
                // Create 3-12 price history entries per parent property
                var historyCount = _random.Next(3, 13);
                var basePrice = _random.Next(500000, 5000000);
                
                for (int i = 0; i < historyCount; i++)
                {
                    var priceDate = DateTime.UtcNow.AddMonths(-_random.Next(0, 24));
                    var price = basePrice + _random.Next(-200000, 500000);
                    
                    priceHistories.Add(new PropertyPriceHistory
                    {
                        ParentPropertyId = parent.ParentPropertyId,
                        Price = price,
                        PriceDate = priceDate,
                        Source = "Auction",
                        Notes = $"Price from auction on {priceDate:yyyy-MM-dd}"
                    });
                }
            }

            _context.PropertyPriceHistories.AddRange(priceHistories);
            await _context.SaveChangesAsync();
        }

        private async Task SeedUserDocumentsAsync(List<Account> accounts)
        {
            Console.WriteLine("📋 Seeding User Documents...");
            
            var userDocs = new List<UserDoc>();
            var docTypes = new[] { "ID_Front", "ID_Back", "Passport_Front", "Passport_Back", "ProofOfAddress" };
            
            foreach (var account in accounts.Where(a => a.RoleId == Role.USER_ROLE_ID))
            {
                // Create 2-4 documents per user
                var docCount = _random.Next(2, 5);
                
                for (int i = 0; i < docCount; i++)
                {
                    var photoIndex = (userDocs.Count + i) % _propertyPhotoIds.Length;
                    var photoId = _propertyPhotoIds[photoIndex];
                    
                    userDocs.Add(new UserDoc
                    {
                        UserId = account.AccountId,
                        DocType = docTypes[_random.Next(docTypes.Length)],
                        ImgUrl = GetUnsplashUrl(photoId, 800, 1000),
                        DeleteUrl = $"https://api.imgbb.com/1/delete/{_random.Next(100000, 999999)}",
                        UploadedAt = account.CreatedAt.AddDays(_random.Next(0, 30))
                    });
                }
            }

            _context.UserDocs.AddRange(userDocs);
            await _context.SaveChangesAsync();
        }

        private async Task SeedNewsArticlesAsync()
        {
            Console.WriteLine("📰 Seeding News Articles...");
            
            var newsArticles = new List<NewsArticle>();
            var categories = new[] { "Market News", "Project Updates", "Investment Tips", "Developer News", "Government Policies" };
            
            var newsTitles = new[]
            {
                "Egypt's Real Estate Market Shows Strong Growth in 2024",
                "New Administrative Capital Announces New Residential Phase",
                "Investment Opportunities in New Cairo Districts",
                "Mortgage Rates Drop to Historic Lows",
                "New Regulations Impact Property Buyers",
                "Luxury Projects See High Demand",
                "Affordable Housing Initiative Launches",
                "Market Analysis: Best Areas to Invest",
                "Developer Announces Mega Project",
                "Property Prices Stabilize After Recent Fluctuations",
                "Experts Predict Market Growth",
                "New Payment Plans Available for Buyers",
                "Government Unveils New Urban Development Plan",
                "Residential Projects Near Completion",
                "Investment Guide: First-Time Buyers",
                "Market Trends: What to Expect",
                "Developer Ratings and Reviews",
                "Property Auction Results Show High Activity",
                "New Amenities Enhance Living Standards",
                "Sustainable Building Practices on the Rise"
            };
            
            var newsContents = new[]
            {
                "The Egyptian real estate market continues to show resilience and growth despite global economic challenges. Key indicators point to sustained demand, particularly in New Cairo and the New Administrative Capital.",
                "Developers are reporting strong sales figures, with many projects reaching full occupancy ahead of schedule. The market is particularly active in luxury residential developments.",
                "Investors are taking notice of emerging opportunities in well-planned communities with comprehensive amenities and infrastructure.",
                "Financial institutions are introducing more flexible mortgage products to meet growing demand from first-time buyers and investors alike.",
                "Recent policy changes aim to streamline property registration processes and provide better protection for buyers and investors."
            };
            
            for (int i = 0; i < 25; i++)
            {
                var publishedDate = DateTime.UtcNow.AddDays(-_random.Next(0, 180));
                var isPublished = _random.Next(10) != 0; // 90% published
                var photoIndex = i % _newsPhotoIds.Length;
                var photoId = _newsPhotoIds[photoIndex];
                
                newsArticles.Add(new NewsArticle
                {
                    Title = newsTitles[_random.Next(newsTitles.Length)],
                    Content = newsContents[_random.Next(newsContents.Length)] + " " + 
                             "The market analysis suggests continued growth in key areas. Experts recommend thorough research before making investment decisions.",
                    Category = categories[_random.Next(categories.Length)],
                    PublishedDate = publishedDate,
                    CreatedAt = publishedDate.AddDays(-_random.Next(0, 7)),
                    UpdatedAt = _random.Next(3) == 0 ? publishedDate.AddDays(_random.Next(1, 30)) : null,
                    IsPublished = isPublished
                });
            }
            
            _context.NewsArticles.AddRange(newsArticles);
            await _context.SaveChangesAsync();
            
            // Seed images for news articles
            await SeedNewsImagesAsync(newsArticles);
        }

        private async Task SeedNewsImagesAsync(List<NewsArticle> newsArticles)
        {
            Console.WriteLine("🖼️ Seeding News Images...");
            
            var newsImages = new List<NewsImage>();
            
            foreach (var article in newsArticles.Where(a => a.IsPublished))
            {
                // Add 1-3 images per article
                var imageCount = _random.Next(1, 4);
                
                for (int i = 0; i < imageCount; i++)
                {
                    var photoIndex = (newsImages.Count + i) % _newsPhotoIds.Length;
                    var photoId = _newsPhotoIds[photoIndex];
                    
                    newsImages.Add(new NewsImage
                    {
                        NewsArticleId = article.NewsArticleId,
                        ImageUrl = GetUnsplashUrl(photoId, 1200, 800),
                        DisplayOrder = i
                    });
                }
            }
            
            _context.NewsImages.AddRange(newsImages);
            await _context.SaveChangesAsync();
        }

        private async Task SeedPropertyValuationsAsync(List<ChildProperty> childProperties)
        {
            Console.WriteLine("💰 Seeding Property Valuations...");
            
            var valuations = new List<PropertyValuation>();
            var valuationSources = new[] { "AI", "Manual" };
            
            // Create valuations for 30-40% of properties
            var propertiesToValuate = childProperties.Where(p => _random.Next(10) < 4).ToList();
            
            foreach (var property in propertiesToValuate)
            {
                var source = valuationSources[_random.Next(valuationSources.Length)];
                var basePrice = property.BuyingPrice ?? _random.Next(500000, 5000000);
                
                // Valuation can vary by ±15% from buying price
                var priceVariation = (decimal)(_random.NextDouble() * 0.3 - 0.15); // -15% to +15%
                var estimatedValue = basePrice * (1 + priceVariation);
                var confidence = source == "AI" ? (decimal?)(85 + _random.NextDouble() * 15) : (decimal?)(70 + _random.NextDouble() * 25);
                
                valuations.Add(new PropertyValuation
                {
                    PropertyId = property.PropertyId,
                    EstimatedValue = estimatedValue,
                    Confidence = confidence,
                    CalculatedAt = DateTime.UtcNow.AddDays(-_random.Next(0, 90)),
                    ValuationSource = source,
                    AIReasoning = source == "AI" ? 
                        $"Based on comparable properties in the area, market trends, and property features, the estimated value is {estimatedValue:N0} EGP." : null,
                    ComparablesCount = _random.Next(3, 15),
                    PriceRangeLow = estimatedValue * 0.85m,
                    PriceRangeHigh = estimatedValue * 1.15m,
                    MarketTrends = source == "AI" ? 
                        "Market shows steady growth. Similar properties in the area have appreciated 5-10% over the past year." : null
                });
            }
            
            _context.PropertyValuations.AddRange(valuations);
            await _context.SaveChangesAsync();
        }

        private async Task<List<Community>> SeedCommunitiesAsync(List<Account> accounts, List<Project> projects)
        {
            Console.WriteLine("👥 Seeding Communities...");
            
            var communities = new List<Community>();
            var communityNames = new[]
            {
                "New Cairo Property Owners",
                "Madinaty Community",
                "New Administrative Capital Residents",
                "Investment Discussions",
                "Property Buyers Network",
                "Real Estate Investors Egypt",
                "Luxury Property Enthusiasts",
                "First-Time Buyers Support",
                "Property Flipping Community",
                "Cairo Real Estate Chat"
            };
            
            var descriptions = new[]
            {
                "Connect with other property owners in New Cairo",
                "Discussion forum for Madinaty residents and investors",
                "Community for those investing in the New Administrative Capital",
                "Share investment strategies and market insights",
                "Network with fellow property buyers and sellers"
            };
            
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID || a.RoleId == Role.DEVELOPER_ROLE_ID).ToList();
            
            for (int i = 0; i < 8; i++)
            {
                var creator = userAccounts[_random.Next(userAccounts.Count)];
                var scopeType = _random.Next(2) == 0 ? CommunityScopeType.ProjectBased : CommunityScopeType.DeveloperBased;
                var accessType = (CommunityAccessType)_random.Next(0, 3);
                
                // Create project/developer IDs JSON arrays
                string? projectIds = null;
                string? developerIds = null;
                
                if (scopeType == CommunityScopeType.ProjectBased && projects.Any())
                {
                    var selectedProjects = projects.OrderBy(x => _random.Next()).Take(_random.Next(1, 4)).Select(p => p.ProjectId).ToList();
                    projectIds = JsonSerializer.Serialize(selectedProjects);
                }
                else if (scopeType == CommunityScopeType.DeveloperBased)
                {
                    var developerAccounts = accounts.Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID).ToList();
                    if (developerAccounts.Any())
                    {
                        var selectedDevelopers = developerAccounts.OrderBy(x => _random.Next()).Take(_random.Next(1, 3)).Select(d => d.AccountId).ToList();
                        developerIds = JsonSerializer.Serialize(selectedDevelopers);
                    }
                }
                
                communities.Add(new Community
                {
                    Name = communityNames[i],
                    Description = descriptions[_random.Next(descriptions.Length)],
                    CreatedById = creator.AccountId,
                    ScopeType = scopeType,
                    AccessType = accessType,
                    ProjectIds = projectIds,
                    DeveloperIds = developerIds,
                    CoverPhotoUrl = GetUnsplashUrl(_projectCoverPhotoIds[i % _projectCoverPhotoIds.Length], 1200, 600),
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddMonths(-_random.Next(1, 12)),
                    UpdatedAt = DateTime.UtcNow
                });
            }
            
            _context.Communities.AddRange(communities);
            await _context.SaveChangesAsync();
            
            // Seed members for each community
            await SeedCommunityMembersAsync(communities, accounts);
            
            return communities;
        }

        private async Task SeedCommunityMembersAsync(List<Community> communities, List<Account> accounts)
        {
            Console.WriteLine("👤 Seeding Community Members...");
            
            var members = new List<CommunityMember>();
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID || a.RoleId == Role.DEVELOPER_ROLE_ID).ToList();
            
            foreach (var community in communities)
            {
                // Add creator as Creator role
                members.Add(new CommunityMember
                {
                    CommunityId = community.CommunityId,
                    AccountId = community.CreatedById,
                    Role = CommunityMemberRole.Creator,
                    JoinedAt = community.CreatedAt
                });
                
                // Add 10-25 additional members
                var memberCount = _random.Next(10, 26);
                var availableAccounts = userAccounts.Where(a => a.AccountId != community.CreatedById).OrderBy(x => _random.Next()).Take(memberCount).ToList();
                
                foreach (var account in availableAccounts)
                {
                    var role = _random.Next(10) == 0 ? CommunityMemberRole.Moderator : CommunityMemberRole.Member;
                    
                    members.Add(new CommunityMember
                    {
                        CommunityId = community.CommunityId,
                        AccountId = account.AccountId,
                        Role = role,
                        JoinedAt = community.CreatedAt.AddDays(_random.Next(0, 180))
                    });
                }
            }
            
            _context.CommunityMembers.AddRange(members);
            await _context.SaveChangesAsync();
        }

        private async Task SeedCommunityPostsAsync(List<Community> communities, List<Account> accounts)
        {
            Console.WriteLine("📝 Seeding Community Posts...");
            
            var posts = new List<CommunityPost>();
            var postContents = new[]
            {
                "Has anyone heard about the new project launching next month?",
                "What do you think about the current market prices?",
                "I'm looking for advice on my first property purchase.",
                "Great experience with this developer! Highly recommend.",
                "Market analysis shows interesting trends this quarter.",
                "Any tips for property flipping in New Cairo?",
                "Sharing some photos from my recent property visit.",
                "Discussion about payment plans and financing options.",
                "What amenities are most important to you?",
                "Investment opportunities in emerging areas."
            };
            
            var categories = new[] { "General", "Investment", "Q&A", "Market Analysis", "Tips & Advice" };
            
            foreach (var community in communities)
            {
                // Get community members
                var communityMemberIds = _context.CommunityMembers
                    .Where(cm => cm.CommunityId == community.CommunityId)
                    .Select(cm => cm.AccountId)
                    .ToList();
                
                // Create 5-15 posts per community
                var postCount = _random.Next(5, 16);
                
                for (int i = 0; i < postCount; i++)
                {
                    var author = accounts.FirstOrDefault(a => communityMemberIds.Contains(a.AccountId));
                    if (author == null) continue;
                    
                    var postType = _random.Next(10) < 2 ? PostType.Poll : (_random.Next(10) < 1 ? PostType.Announcement : PostType.Regular);
                    var createdAt = community.CreatedAt.AddDays(_random.Next(0, 180));
                    
                    var post = new CommunityPost
                    {
                        CommunityId = community.CommunityId,
                        AuthorId = author.AccountId,
                        Content = postContents[_random.Next(postContents.Length)],
                        ImageUrl = _random.Next(4) == 0 ? GetUnsplashUrl(_propertyPhotoIds[posts.Count % _propertyPhotoIds.Length], 800, 600) : null,
                        PostType = postType,
                        IsPinned = _random.Next(20) == 0,
                        CreatedAt = createdAt,
                        UpdatedAt = _random.Next(5) == 0 ? createdAt.AddDays(_random.Next(1, 30)) : null,
                        LastActivityAt = createdAt
                    };
                    
                    posts.Add(post);
                }
            }
            
            _context.CommunityPosts.AddRange(posts);
            await _context.SaveChangesAsync();
            
            // Seed post categories
            await SeedPostCategoriesAsync(posts, categories);
            
            // Seed post likes
            await SeedPostLikesAsync(posts, accounts);
            
            // Seed post reactions
            await SeedPostReactionsAsync(posts, accounts);
            
            // Seed post bookmarks
            await SeedPostBookmarksAsync(posts, accounts);
            
            // Seed comments and comment interactions
            await SeedPostCommentsAsync(posts, accounts);
            
            // Seed polls
            await SeedPollsAsync(posts, accounts);
            
            // Update post counts
            foreach (var post in posts)
            {
                post.CalculateTrendingScore();
            }
            await _context.SaveChangesAsync();
        }

        private async Task SeedPostCategoriesAsync(List<CommunityPost> posts, string[] categories)
        {
            var postCategories = new List<PostCategory>();
            
            foreach (var post in posts.Where(p => _random.Next(3) != 0)) // 67% have categories
            {
                var categoryCount = _random.Next(1, 3);
                var selectedCategories = categories.OrderBy(x => _random.Next()).Take(categoryCount).ToList();
                
                foreach (var category in selectedCategories)
                {
                    postCategories.Add(new PostCategory
                    {
                        PostId = post.PostId,
                        CategoryName = category
                    });
                }
            }
            
            _context.PostCategories.AddRange(postCategories);
            await _context.SaveChangesAsync();
        }

        private async Task SeedPostLikesAsync(List<CommunityPost> posts, List<Account> accounts)
        {
            var likes = new List<PostLike>();
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            
            foreach (var post in posts)
            {
                // Get community members who can like
                var communityMemberIds = _context.CommunityMembers
                    .Where(cm => cm.CommunityId == post.CommunityId)
                    .Select(cm => cm.AccountId)
                    .ToList();
                
                var likers = userAccounts.Where(a => communityMemberIds.Contains(a.AccountId) && a.AccountId != post.AuthorId)
                    .OrderBy(x => _random.Next())
                    .Take(_random.Next(0, 20))
                    .ToList();
                
                foreach (var liker in likers)
                {
                    likes.Add(new PostLike
                    {
                        PostId = post.PostId,
                        AccountId = liker.AccountId,
                        CreatedAt = post.CreatedAt.AddMinutes(_random.Next(0, 1440))
                    });
                }
                
                post.LikeCount = likes.Count(l => l.PostId == post.PostId);
            }
            
            _context.PostLikes.AddRange(likes);
            await _context.SaveChangesAsync();
        }

        private async Task SeedPostReactionsAsync(List<CommunityPost> posts, List<Account> accounts)
        {
            var reactions = new List<PostReaction>();
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            
            foreach (var post in posts.Where(p => _random.Next(3) != 0)) // 67% have reactions
            {
                var communityMemberIds = _context.CommunityMembers
                    .Where(cm => cm.CommunityId == post.CommunityId)
                    .Select(cm => cm.AccountId)
                    .ToList();
                
                var reactors = userAccounts.Where(a => communityMemberIds.Contains(a.AccountId) && a.AccountId != post.AuthorId)
                    .OrderBy(x => _random.Next())
                    .Take(_random.Next(1, 10))
                    .ToList();
                
                foreach (var reactor in reactors)
                {
                    reactions.Add(new PostReaction
                    {
                        PostId = post.PostId,
                        AccountId = reactor.AccountId,
                        ReactionType = (ReactionType)_random.Next(0, 6),
                        CreatedAt = post.CreatedAt.AddMinutes(_random.Next(0, 1440))
                    });
                }
            }
            
            _context.PostReactions.AddRange(reactions);
            await _context.SaveChangesAsync();
        }

        private async Task SeedPostBookmarksAsync(List<CommunityPost> posts, List<Account> accounts)
        {
            var bookmarks = new List<PostBookmark>();
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            
            foreach (var post in posts.Where(p => _random.Next(5) == 0)) // 20% are bookmarked
            {
                var communityMemberIds = _context.CommunityMembers
                    .Where(cm => cm.CommunityId == post.CommunityId)
                    .Select(cm => cm.AccountId)
                    .ToList();
                
                var bookmarkedBy = userAccounts.Where(a => communityMemberIds.Contains(a.AccountId) && a.AccountId != post.AuthorId)
                    .OrderBy(x => _random.Next())
                    .Take(_random.Next(1, 5))
                    .ToList();
                
                foreach (var user in bookmarkedBy)
                {
                    bookmarks.Add(new PostBookmark
                    {
                        PostId = post.PostId,
                        AccountId = user.AccountId,
                        CreatedAt = post.CreatedAt.AddDays(_random.Next(0, 30))
                    });
                }
            }
            
            _context.PostBookmarks.AddRange(bookmarks);
            await _context.SaveChangesAsync();
        }

        private async Task SeedPostCommentsAsync(List<CommunityPost> posts, List<Account> accounts)
        {
            Console.WriteLine("💬 Seeding Post Comments...");
            
            var parentComments = new List<PostComment>();
            var replyComments = new List<PostComment>();
            var commentTexts = new[]
            {
                "Great post! Thanks for sharing.",
                "I have a similar experience.",
                "Can you provide more details?",
                "I disagree with this perspective.",
                "Very helpful information!",
                "Has anyone else tried this?",
                "What do you think about...",
                "I'll look into this more.",
                "Agreed! This is important.",
                "Thanks for the advice."
            };
            
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            
            // First phase: Create parent comments (no ParentCommentId)
            foreach (var post in posts)
            {
                var communityMemberIds = _context.CommunityMembers
                    .Where(cm => cm.CommunityId == post.CommunityId)
                    .Select(cm => cm.AccountId)
                    .ToList();
                
                // Create 2-8 parent comments per post
                var commentCount = _random.Next(2, 9);
                var commenters = userAccounts.Where(a => communityMemberIds.Contains(a.AccountId) && a.AccountId != post.AuthorId)
                    .OrderBy(x => _random.Next())
                    .Take(commentCount)
                    .ToList();
                
                foreach (var commenter in commenters)
                {
                    var comment = new PostComment
                    {
                        PostId = post.PostId,
                        AuthorId = commenter.AccountId,
                        Content = commentTexts[_random.Next(commentTexts.Length)],
                        CreatedAt = post.CreatedAt.AddMinutes(_random.Next(0, 2880)) // Within 2 days
                    };
                    
                    parentComments.Add(comment);
                }
            }
            
            // Save parent comments first to get their CommentIds
            _context.PostComments.AddRange(parentComments);
            await _context.SaveChangesAsync();
            
            // Second phase: Create reply comments that reference saved parent comments
            foreach (var post in posts)
            {
                var communityMemberIds = _context.CommunityMembers
                    .Where(cm => cm.CommunityId == post.CommunityId)
                    .Select(cm => cm.AccountId)
                    .ToList();
                
                // Get saved parent comments for this post
                var savedParentComments = parentComments.Where(c => c.PostId == post.PostId).ToList();
                if (savedParentComments.Any())
                {
                    var replyCount = _random.Next(0, Math.Min(5, savedParentComments.Count));
                    var parentsToReply = savedParentComments.OrderBy(x => _random.Next()).Take(replyCount).ToList();
                    
                    foreach (var parent in parentsToReply)
                    {
                        var replier = userAccounts.Where(a => communityMemberIds.Contains(a.AccountId) && a.AccountId != parent.AuthorId)
                            .OrderBy(x => _random.Next())
                            .FirstOrDefault();
                        
                        if (replier != null)
                        {
                            replyComments.Add(new PostComment
                            {
                                PostId = post.PostId,
                                AuthorId = replier.AccountId,
                                Content = commentTexts[_random.Next(commentTexts.Length)],
                                ParentCommentId = parent.CommentId, // Now this ID exists in the database
                                CreatedAt = parent.CreatedAt.AddMinutes(_random.Next(1, 1440))
                            });
                        }
                    }
                }
            }
            
            // Save reply comments
            if (replyComments.Any())
            {
                _context.PostComments.AddRange(replyComments);
                await _context.SaveChangesAsync();
            }
            
            // Combine all comments for likes and reactions
            var allComments = parentComments.Concat(replyComments).ToList();
            
            // Seed comment likes
            await SeedCommentLikesAsync(allComments, accounts);
            
            // Seed comment reactions
            await SeedCommentReactionsAsync(allComments, accounts);
            
            // Update comment counts on posts
            foreach (var post in posts)
            {
                post.CommentCount = allComments.Count(c => c.PostId == post.PostId);
            }
            await _context.SaveChangesAsync();
        }

        private async Task SeedCommentLikesAsync(List<PostComment> comments, List<Account> accounts)
        {
            var commentLikes = new List<CommentLike>();
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            
            foreach (var comment in comments.Where(c => _random.Next(3) != 0)) // 67% get likes
            {
                var post = _context.CommunityPosts.FirstOrDefault(p => p.PostId == comment.PostId);
                if (post == null) continue;
                
                var communityMemberIds = _context.CommunityMembers
                    .Where(cm => cm.CommunityId == post.CommunityId)
                    .Select(cm => cm.AccountId)
                    .ToList();
                
                var likers = userAccounts.Where(a => communityMemberIds.Contains(a.AccountId) && a.AccountId != comment.AuthorId)
                    .OrderBy(x => _random.Next())
                    .Take(_random.Next(0, 8))
                    .ToList();
                
                foreach (var liker in likers)
                {
                    commentLikes.Add(new CommentLike
                    {
                        CommentId = comment.CommentId,
                        AccountId = liker.AccountId,
                        CreatedAt = comment.CreatedAt.AddMinutes(_random.Next(0, 1440))
                    });
                }
                
                comment.LikeCount = commentLikes.Count(cl => cl.CommentId == comment.CommentId);
            }
            
            _context.CommentLikes.AddRange(commentLikes);
            await _context.SaveChangesAsync();
        }

        private async Task SeedCommentReactionsAsync(List<PostComment> comments, List<Account> accounts)
        {
            var reactions = new List<CommentReaction>();
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            
            foreach (var comment in comments.Where(c => _random.Next(4) == 0)) // 25% get reactions
            {
                var post = _context.CommunityPosts.FirstOrDefault(p => p.PostId == comment.PostId);
                if (post == null) continue;
                
                var communityMemberIds = _context.CommunityMembers
                    .Where(cm => cm.CommunityId == post.CommunityId)
                    .Select(cm => cm.AccountId)
                    .ToList();
                
                var reactors = userAccounts.Where(a => communityMemberIds.Contains(a.AccountId) && a.AccountId != comment.AuthorId)
                    .OrderBy(x => _random.Next())
                    .Take(_random.Next(1, 5))
                    .ToList();
                
                foreach (var reactor in reactors)
                {
                    reactions.Add(new CommentReaction
                    {
                        CommentId = comment.CommentId,
                        AccountId = reactor.AccountId,
                        ReactionType = (ReactionType)_random.Next(0, 6),
                        CreatedAt = comment.CreatedAt.AddMinutes(_random.Next(0, 1440))
                    });
                }
            }
            
            _context.CommentReactions.AddRange(reactions);
            await _context.SaveChangesAsync();
        }

        private async Task SeedPollsAsync(List<CommunityPost> posts, List<Account> accounts)
        {
            var polls = new List<Poll>();
            var pollPosts = posts.Where(p => p.PostType == PostType.Poll).ToList();
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            
            foreach (var post in pollPosts)
            {
                var options = new[]
                {
                    new { optionText = "Option A", voteCount = 0 },
                    new { optionText = "Option B", voteCount = 0 },
                    new { optionText = "Option C", voteCount = 0 },
                    new { optionText = "Option D", voteCount = 0 }
                }.OrderBy(x => _random.Next()).Take(_random.Next(2, 5)).ToList();
                
                var poll = new Poll
                {
                    PostId = post.PostId,
                    Question = "What is your opinion on this topic?",
                    Options = JsonSerializer.Serialize(options),
                    EndsAt = post.CreatedAt.AddDays(_random.Next(7, 30)),
                    TotalVotes = 0
                };
                
                polls.Add(poll);
            }
            
            _context.Polls.AddRange(polls);
            await _context.SaveChangesAsync();
            
            // Seed poll votes
            await SeedPollVotesAsync(polls, accounts);
        }

        private async Task SeedPollVotesAsync(List<Poll> polls, List<Account> accounts)
        {
            var pollVotes = new List<PollVote>();
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            
            foreach (var poll in polls)
            {
                var post = _context.CommunityPosts.FirstOrDefault(p => p.PostId == poll.PostId);
                if (post == null) continue;
                
                var communityMemberIds = _context.CommunityMembers
                    .Where(cm => cm.CommunityId == post.CommunityId)
                    .Select(cm => cm.AccountId)
                    .ToList();
                
                var voters = userAccounts.Where(a => communityMemberIds.Contains(a.AccountId))
                    .OrderBy(x => _random.Next())
                    .Take(_random.Next(5, 25))
                    .ToList();
                
                // Use JsonDocument to properly handle JSON deserialization
                using var doc = JsonDocument.Parse(poll.Options);
                var optionsList = doc.RootElement.EnumerateArray().Select(e => new Dictionary<string, object>
                {
                    { "optionText", e.GetProperty("optionText").GetString() ?? "" },
                    { "voteCount", e.GetProperty("voteCount").GetInt32() }
                }).ToList();
                
                if (optionsList == null || !optionsList.Any()) continue;
                
                foreach (var voter in voters)
                {
                    var optionIndex = _random.Next(0, optionsList.Count);
                    
                    pollVotes.Add(new PollVote
                    {
                        PollId = poll.PollId,
                        AccountId = voter.AccountId,
                        OptionIndex = optionIndex,
                        CreatedAt = post.CreatedAt.AddMinutes(_random.Next(0, 4320))
                    });
                    
                    // Update vote count in options JSON
                    optionsList[optionIndex]["voteCount"] = ((int)optionsList[optionIndex]["voteCount"]) + 1;
                }
                
                poll.Options = JsonSerializer.Serialize(optionsList);
                poll.TotalVotes = pollVotes.Count(pv => pv.PollId == poll.PollId);
            }
            
            _context.PollVotes.AddRange(pollVotes);
            await _context.SaveChangesAsync();
        }

        private async Task SeedUserAchievementsAsync(List<Account> accounts)
        {
            Console.WriteLine("🏅 Seeding User Achievements...");
            
            var achievements = new List<UserAchievement>();
            var achievementTypes = Enum.GetValues(typeof(AchievementType)).Cast<AchievementType>().ToArray();
            var achievementTitles = new Dictionary<AchievementType, string>
            {
                { AchievementType.FirstPost, "First Post" },
                { AchievementType.TenPosts, "Active Contributor" },
                { AchievementType.HundredLikes, "Popular Author" },
                { AchievementType.HelpfulMember, "Helpful Member" },
                { AchievementType.PopularPost, "Viral Content" },
                { AchievementType.CommunityContributor, "Community Leader" },
                { AchievementType.TopRated, "Top Rated" },
                { AchievementType.PropertyExpert, "Property Expert" },
                { AchievementType.ActiveMember, "Active Member" },
                { AchievementType.ValuableInsight, "Valuable Insight" }
            };
            
            var userAccounts = accounts.Where(a => a.RoleId == Role.USER_ROLE_ID).ToList();
            
            foreach (var account in userAccounts)
            {
                // Award 1-4 random achievements per user
                var achievementCount = _random.Next(1, 5);
                var awardedTypes = achievementTypes.OrderBy(x => _random.Next()).Take(achievementCount).ToList();
                
                foreach (var achievementType in awardedTypes)
                {
                    achievements.Add(new UserAchievement
                    {
                        AccountId = account.AccountId,
                        AchievementType = achievementType,
                        Title = achievementTitles.GetValueOrDefault(achievementType, "Achievement"),
                        Description = $"Earned for {achievementTitles.GetValueOrDefault(achievementType, "achievement")}",
                        PointsAwarded = _random.Next(10, 100),
                        EarnedAt = DateTime.UtcNow.AddDays(-_random.Next(0, 180))
                    });
                }
            }
            
            _context.UserAchievements.AddRange(achievements);
            await _context.SaveChangesAsync();
        }
    }
}
