using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using BCrypt.Net;

namespace PropertyFlipperAPI.Services
{
    public class CompleteEgyptianSeedingService
    {
        private readonly AppDbContext _context;
        private readonly Random _random = new Random();

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

            // Step 4: Seed Developer Profiles
            await SeedDeveloperProfilesAsync(accounts);

            // Step 5: Seed Projects
            var projects = await SeedProjectsAsync(accounts);

            // Step 6: Seed Parent Properties
            var parentProperties = await SeedParentPropertiesAsync(projects);

            // Step 7: Seed Child Properties
            var childProperties = await SeedChildPropertiesAsync(parentProperties, accounts);

            // Step 8: Seed Property Images
            await SeedPropertyImagesAsync(childProperties);

            // Step 9: Seed Property Documents
            await SeedPropertyDocumentsAsync(childProperties);

            // Step 10: Seed Auctions
            var auctions = await SeedAuctionsAsync(childProperties);

            // Step 11: Seed Bids
            await SeedBidsAsync(auctions, accounts);

            // Step 12: Seed Events
            await SeedEventsAsync(projects);

            // Step 13: Seed Notifications
            await SeedNotificationsAsync(accounts);

            // Step 14: Seed Chats
            var chats = await SeedChatsAsync(accounts, childProperties);

            // Step 15: Seed Chat Messages
            await SeedChatMessagesAsync(chats);

            // Step 16: Seed AI Chats
            var aiChats = await SeedAIChatsAsync(accounts);

            // Step 17: Seed AI Chat Messages
            await SeedAIChatMessagesAsync(aiChats);

            // Step 18: Seed Project Milestones
            await SeedProjectMilestonesAsync(projects);

            // Step 19: Seed Project Updates
            await SeedProjectUpdatesAsync(projects);

            // Step 20: Seed User Rewards
            await SeedUserRewardsAsync(accounts);

            // Step 21: Seed User Badges
            await SeedUserBadgesAsync(accounts);

            // Step 22: Seed Referrals
            await SeedReferralsAsync(accounts);

            // Step 23: Seed Property Views
            await SeedPropertyViewsAsync(childProperties, accounts);

            // Step 24: Seed Developer Ratings
            await SeedDeveloperRatingsAsync(accounts);

            // Step 25: Seed Property Price History
            await SeedPropertyPriceHistoryAsync(parentProperties, auctions);

            // Step 26: Seed User Documents
            await SeedUserDocumentsAsync(accounts);

            await _context.SaveChangesAsync();
            Console.WriteLine("✅ Complete Egyptian Real Estate Data Seeding Finished!");
        }

        private async Task ClearAllDataAsync()
        {
            Console.WriteLine("🗑️ Clearing existing data...");
            
            // Clear in reverse order to avoid foreign key constraints
            _context.AIChatMessages.RemoveRange(_context.AIChatMessages);
            _context.AIChats.RemoveRange(_context.AIChats);
            _context.ChatMessages.RemoveRange(_context.ChatMessages);
            _context.Chats.RemoveRange(_context.Chats);
            _context.Bids.RemoveRange(_context.Bids);
            _context.Auctions.RemoveRange(_context.Auctions);
            _context.PropertyViews.RemoveRange(_context.PropertyViews);
            _context.Referrals.RemoveRange(_context.Referrals);
            _context.UserBadges.RemoveRange(_context.UserBadges);
            _context.UserRewards.RemoveRange(_context.UserRewards);
            _context.ProjectUpdates.RemoveRange(_context.ProjectUpdates);
            _context.ProjectMilestones.RemoveRange(_context.ProjectMilestones);
            _context.DeveloperRatings.RemoveRange(_context.DeveloperRatings);
            _context.PropertyPriceHistories.RemoveRange(_context.PropertyPriceHistories);
            _context.PropertyDocs.RemoveRange(_context.PropertyDocs);
            _context.PropertyImages.RemoveRange(_context.PropertyImages);
            _context.ChildProperties.RemoveRange(_context.ChildProperties);
            _context.ParentProperties.RemoveRange(_context.ParentProperties);
            _context.Events.RemoveRange(_context.Events);
            _context.Notifications.RemoveRange(_context.Notifications);
            _context.UserDocs.RemoveRange(_context.UserDocs);
            _context.DeveloperProfiles.RemoveRange(_context.DeveloperProfiles);
            _context.Projects.RemoveRange(_context.Projects);
            _context.Accounts.RemoveRange(_context.Accounts);
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
            
            // Create 1 Admin
            accounts.Add(new Account
            {
                FirstName = "Admin",
                LastName = "User",
                Email = "admin@propertyflipper.com",
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("Admin123!"),
                PhoneNumber = "+201234567890",
                Type = AccountType.Admin,
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
                    Type = AccountType.Developer,
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
                    Type = AccountType.User,
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

        private async Task SeedDeveloperProfilesAsync(List<Account> accounts)
        {
            Console.WriteLine("🏢 Seeding Developer Profiles...");
            
            var developerAccounts = accounts.Where(a => a.Type == AccountType.Developer).ToList();
            var profiles = new List<DeveloperProfile>();
            
            for (int i = 0; i < developerAccounts.Count; i++)
            {
                var account = developerAccounts[i];
                var companyName = _egyptianDevelopers[i];
                
                profiles.Add(new DeveloperProfile
                {
                    AccountId = account.AccountId,
                    CompanyName = companyName,
                    Bio = $"Leading real estate developer in Egypt with over {_random.Next(5, 20)} years of experience in creating premium residential and commercial projects.",
                    ProfileImageUrl = $"https://images.unsplash.com/photo-{1500000000000 + i}?w=400&h=400&fit=crop&crop=face",
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
            
            var developerAccounts = accounts.Where(a => a.Type == AccountType.Developer).ToList();
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
                
                parentProperties.Add(new ParentProperty
                {
                    ProjectName = project.Name,
                    Bedrooms = bedrooms,
                    Bathrooms = bathrooms,
                    AreaSqm = areaSqm,
                    PropertyType = propertyType,
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
                // Create 2-8 child properties per parent
                var childCount = _random.Next(2, 9);
                
                for (int i = 0; i < childCount; i++)
                {
                    var owner = _random.Next(3) == 0 ? accounts.Where(a => a.Type == AccountType.User).FirstOrDefault() : null;
                    var phase = phases[_random.Next(phases.Length)];
                    var viewType = viewTypes[_random.Next(viewTypes.Length)];
                    var orientation = orientations[_random.Next(orientations.Length)];
                    
                    var childProperty = new ChildProperty
                    {
                        ParentPropertyId = parent.ParentPropertyId,
                        OwnerId = owner?.AccountId,
                        Phase = phase,
                        FloorNumber = parent.PropertyType == "Villa" ? 0 : _random.Next(1, 20),
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
                        Name = $"{parent.ProjectName} - {parent.PropertyType} {parent.Bedrooms}BR",
                        Description = $"Beautiful {parent.PropertyType.ToLower()} in {parent.ProjectName} with {parent.Bedrooms} bedrooms and {parent.Bathrooms} bathrooms.",
                        Location = $"{parent.ProjectName}, Egypt",
                        Category = parent.PropertyType,
                        ImageUrl = $"https://images.unsplash.com/photo-{1700000000000 + childProperties.Count}?w=800&h=600&fit=crop",
                        SquareFeet = (int)(parent.AreaSqm * 10.764), // Convert to sq ft
                        YearBuilt = DateTime.UtcNow.Year - _random.Next(0, 5),
                        IsApproved = _random.Next(4) != 0,
                        CreatedAt = parent.CreatedAt,
                        UpdatedAt = DateTime.UtcNow,
                        
                        // Inherited properties
                        Bedrooms = parent.Bedrooms,
                        Bathrooms = parent.Bathrooms,
                        PropertyType = parent.PropertyType,
                        Type = Enum.Parse<PropertyType>(parent.PropertyType),
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
                    propertyImages.Add(new PropertyImage
                    {
                        PropertyId = property.PropertyId,
                        ImageUrl = $"https://images.unsplash.com/photo-{1800000000000 + propertyImages.Count}?w=1200&h=800&fit=crop",
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
            var docTypes = new[] { "Floor Plan", "Legal Document", "Ownership Certificate", "Building Permit", "Insurance" };
            
            foreach (var property in childProperties.Where(p => p.OwnerId != null))
            {
                // Add 2-5 documents per owned property
                var docCount = _random.Next(2, 6);
                
                for (int i = 0; i < docCount; i++)
                {
                    propertyDocs.Add(new PropertyDoc
                    {
                        PropertyId = property.PropertyId,
                        DocType = docTypes[_random.Next(docTypes.Length)],
                        ImgUrl = $"https://images.unsplash.com/photo-{1900000000000 + propertyDocs.Count}?w=800&h=1000&fit=crop",
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
            var userAccounts = accounts.Where(a => a.Type == AccountType.User).ToList();
            
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
            var userAccounts = accounts.Where(a => a.Type == AccountType.User).ToList();
            var developerAccounts = accounts.Where(a => a.Type == AccountType.Developer).ToList();
            
            // Create 20-30 chats
            var chatCount = _random.Next(20, 31);
            
            for (int i = 0; i < chatCount; i++)
            {
                var user = userAccounts[_random.Next(userAccounts.Count)];
                var developer = developerAccounts[_random.Next(developerAccounts.Count)];
                var property = childProperties[_random.Next(childProperties.Count)];
                
                chats.Add(new Chat
                {
                    UserId = user.AccountId,
                    DeveloperId = developer.AccountId,
                    ProjectId = property.ProjectId,
                    IsActive = _random.Next(4) != 0,
                    CreatedAt = DateTime.UtcNow.AddDays(-_random.Next(0, 90)),
                    LastMessageAt = DateTime.UtcNow.AddDays(-_random.Next(0, 30))
                });
            }

            _context.Chats.AddRange(chats);
            await _context.SaveChangesAsync();
            return chats;
        }

        private async Task SeedChatMessagesAsync(List<Chat> chats)
        {
            Console.WriteLine("💭 Seeding Chat Messages...");
            
            var messages = new List<ChatMessage>();
            var sampleMessages = new[]
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
                "Is financing available?"
            };
            
            foreach (var chat in chats)
            {
                // Create 3-10 messages per chat
                var messageCount = _random.Next(3, 11);
                
                for (int i = 0; i < messageCount; i++)
                {
                    var isFromUser = _random.Next(2) == 0;
                    var senderId = isFromUser ? chat.UserId : chat.DeveloperId;
                    var message = sampleMessages[_random.Next(sampleMessages.Length)];
                    
                    messages.Add(new ChatMessage
                    {
                        ChatId = chat.ChatId,
                        SenderId = senderId,
                        Content = message,
                        PropertyId = (int?)chat.ProjectId,
                        CreatedAt = chat.CreatedAt.AddMinutes(_random.Next(0, 1440))
                    });
                }
            }

            _context.ChatMessages.AddRange(messages);
            await _context.SaveChangesAsync();
        }

        private async Task<List<AIChat>> SeedAIChatsAsync(List<Account> accounts)
        {
            Console.WriteLine("🤖 Seeding AI Chats...");
            
            var aiChats = new List<AIChat>();
            var userAccounts = accounts.Where(a => a.Type == AccountType.User).ToList();
            
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
                    updates.Add(new ProjectUpdate
                    {
                        ProjectId = project.ProjectId,
                        Title = $"Update {i + 1} - {project.Name}",
                        Content = $"Progress update for {project.Name}. Construction is proceeding according to schedule.",
                        ImageUrl = $"https://images.unsplash.com/photo-{2000000000000 + updates.Count}?w=800&h=600&fit=crop",
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
            
            foreach (var account in accounts.Where(a => a.Type == AccountType.User))
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
            
            foreach (var account in accounts.Where(a => a.Type == AccountType.User))
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
            var userAccounts = accounts.Where(a => a.Type == AccountType.User).ToList();
            
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
            var userAccounts = accounts.Where(a => a.Type == AccountType.User).ToList();
            
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
            var developerAccounts = accounts.Where(a => a.Type == AccountType.Developer).ToList();
            var userAccounts = accounts.Where(a => a.Type == AccountType.User).ToList();
            
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
            
            foreach (var account in accounts.Where(a => a.Type == AccountType.User))
            {
                // Create 2-4 documents per user
                var docCount = _random.Next(2, 5);
                
                for (int i = 0; i < docCount; i++)
                {
                    userDocs.Add(new UserDoc
                    {
                        UserId = account.AccountId,
                        DocType = docTypes[_random.Next(docTypes.Length)],
                        ImgUrl = $"https://images.unsplash.com/photo-{2100000000000 + userDocs.Count}?w=800&h=1000&fit=crop",
                        DeleteUrl = $"https://api.imgbb.com/1/delete/{_random.Next(100000, 999999)}",
                        UploadedAt = account.CreatedAt.AddDays(_random.Next(0, 30))
                    });
                }
            }

            _context.UserDocs.AddRange(userDocs);
            await _context.SaveChangesAsync();
        }
    }
}
