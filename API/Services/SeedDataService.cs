using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using BCrypt.Net;

namespace PropertyFlipperAPI.Services
{
    public class SeedDataService
    {
        private readonly AppDbContext _context;

        public SeedDataService(AppDbContext context)
        {
            _context = context;
        }

        public async Task SeedDataAsync()
        {
            // Clear existing data first
            _context.Bids.RemoveRange(_context.Bids);
            _context.Auctions.RemoveRange(_context.Auctions);
            _context.Properties.RemoveRange(_context.Properties);
            _context.Projects.RemoveRange(_context.Projects);
            _context.UserDocs.RemoveRange(_context.UserDocs);
            _context.Accounts.RemoveRange(_context.Accounts);
            await _context.SaveChangesAsync();

            // Create demo accounts (mix of users, developers, and admin)
            var accounts = new List<Account>
            {
                // Admin Account
                new Account
                {
                    FirstName = "System",
                    LastName = "Administrator",
                    Email = "admin@admin.com",
                    PhoneNumber = "555-0000",
                    Type = AccountType.Admin,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("11111111"),
                    Status = VerificationStatus.Verified,
                    CreatedAt = DateTime.UtcNow.AddDays(-365)
                },
                // Regular Users
                new Account
                {
                    FirstName = "John",
                    LastName = "Doe",
                    Email = "john@example.com",
                    PhoneNumber = "555-0101",
                    Type = AccountType.User,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("password123"),
                    Status = VerificationStatus.Verified,
                    CreatedAt = DateTime.UtcNow.AddDays(-30)
                },
                new Account
                {
                    FirstName = "Jane",
                    LastName = "Smith",
                    Email = "jane@example.com",
                    PhoneNumber = "555-0102",
                    Type = AccountType.User,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("password123"),
                    Status = VerificationStatus.Verified,
                    CreatedAt = DateTime.UtcNow.AddDays(-25)
                },
                new Account
                {
                    FirstName = "Mike",
                    LastName = "Johnson",
                    Email = "mike@example.com",
                    PhoneNumber = "555-0103",
                    Type = AccountType.User,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("password123"),
                    Status = VerificationStatus.NotVerified,
                    CreatedAt = DateTime.UtcNow.AddDays(-20)
                },
                new Account
                {
                    FirstName = "Sarah",
                    LastName = "Wilson",
                    Email = "sarah@example.com",
                    PhoneNumber = "555-0104",
                    Type = AccountType.User,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("password123"),
                    Status = VerificationStatus.Verified,
                    CreatedAt = DateTime.UtcNow.AddDays(-15)
                },
                new Account
                {
                    FirstName = "David",
                    LastName = "Brown",
                    Email = "david@example.com",
                    PhoneNumber = "555-0105",
                    Type = AccountType.User,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("password123"),
                    Status = VerificationStatus.Verified,
                    CreatedAt = DateTime.UtcNow.AddDays(-10)
                },
                new Account
                {
                    FirstName = "Lisa",
                    LastName = "Davis",
                    Email = "lisa@example.com",
                    PhoneNumber = "555-0106",
                    Type = AccountType.User,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("password123"),
                    Status = VerificationStatus.Verified,
                    CreatedAt = DateTime.UtcNow.AddDays(-8)
                },
                new Account
                {
                    FirstName = "Tom",
                    LastName = "Miller",
                    Email = "tom@example.com",
                    PhoneNumber = "555-0107",
                    Type = AccountType.User,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("password123"),
                    Status = VerificationStatus.NotVerified,
                    CreatedAt = DateTime.UtcNow.AddDays(-5)
                },
                new Account
                {
                    FirstName = "Emma",
                    LastName = "Garcia",
                    Email = "emma@example.com",
                    PhoneNumber = "555-0108",
                    Type = AccountType.User,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("password123"),
                    Status = VerificationStatus.Verified,
                    CreatedAt = DateTime.UtcNow.AddDays(-3)
                },

                // Developers
                new Account
                {
                    FirstName = "Alex",
                    LastName = "Developer",
                    Email = "alex@developer.com",
                    PhoneNumber = "555-0201",
                    Type = AccountType.Developer,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("developer123"),
                    Status = VerificationStatus.Verified,
                    CreatedAt = DateTime.UtcNow.AddDays(-25)
                },
                new Account
                {
                    FirstName = "Maria",
                    LastName = "Builder",
                    Email = "maria@builder.com",
                    PhoneNumber = "555-0202",
                    Type = AccountType.Developer,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("developer123"),
                    Status = VerificationStatus.Verified,
                    CreatedAt = DateTime.UtcNow.AddDays(-20)
                },
                new Account
                {
                    FirstName = "Robert",
                    LastName = "Construct",
                    Email = "robert@construct.com",
                    PhoneNumber = "555-0203",
                    Type = AccountType.Developer,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("developer123"),
                    Status = VerificationStatus.Verified,
                    CreatedAt = DateTime.UtcNow.AddDays(-15)
                },
                new Account
                {
                    FirstName = "Jennifer",
                    LastName = "Architect",
                    Email = "jennifer@architect.com",
                    PhoneNumber = "555-0204",
                    Type = AccountType.Developer,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("developer123"),
                    Status = VerificationStatus.Verified,
                    CreatedAt = DateTime.UtcNow.AddDays(-12)
                }
            };

            _context.Accounts.AddRange(accounts);
            await _context.SaveChangesAsync();

            // Create demo projects for developers
            var projects = new List<Project>
            {
                new Project
                {
                    DeveloperId = accounts.First(a => a.Email == "alex@developer.com").AccountId,
                    Name = "Luxury Beachfront Villas",
                    Description = "Exclusive collection of modern villas with ocean views and private beach access.",
                    Location = "Coastal Paradise, CA",
                    CreatedAt = DateTime.UtcNow.AddDays(-18)
                },
                new Project
                {
                    DeveloperId = accounts.First(a => a.Email == "alex@developer.com").AccountId,
                    Name = "Urban Loft Apartments",
                    Description = "Stylish loft apartments in the heart of the city with modern amenities.",
                    Location = "Downtown Metropolis, NY",
                    CreatedAt = DateTime.UtcNow.AddDays(-10)
                },
                new Project
                {
                    DeveloperId = accounts.First(a => a.Email == "maria@builder.com").AccountId,
                    Name = "Green Valley Estates",
                    Description = "Eco-friendly residential community with sustainable living features.",
                    Location = "Green Valley, OR",
                    CreatedAt = DateTime.UtcNow.AddDays(-15)
                },
                new Project
                {
                    DeveloperId = accounts.First(a => a.Email == "maria@builder.com").AccountId,
                    Name = "Mountain View Condos",
                    Description = "Luxury condominiums with panoramic mountain views.",
                    Location = "Mountain View, CO",
                    CreatedAt = DateTime.UtcNow.AddDays(-8)
                },
                new Project
                {
                    DeveloperId = accounts.First(a => a.Email == "robert@construct.com").AccountId,
                    Name = "Riverside Towers",
                    Description = "High-rise residential towers along the scenic riverfront.",
                    Location = "Riverside City, TX",
                    CreatedAt = DateTime.UtcNow.AddDays(-12)
                },
                new Project
                {
                    DeveloperId = accounts.First(a => a.Email == "jennifer@architect.com").AccountId,
                    Name = "Historic District Renovation",
                    Description = "Carefully restored historic buildings with modern amenities.",
                    Location = "Historic District, MA",
                    CreatedAt = DateTime.UtcNow.AddDays(-6)
                }
            };

            _context.Projects.AddRange(projects);
            await _context.SaveChangesAsync();

            // Create demo properties (mix of resale and primary)
            var properties = new List<Property>
            {
                // Resale Properties (by regular users)
                new Property
                {
                    OwnerId = accounts.First(a => a.Email == "john@example.com").AccountId,
                    Name = "Cozy Family Home",
                    Description = "A lovely 3-bedroom house perfect for a growing family with a large backyard.",
                    Location = "123 Suburbia Lane, Suburbia, CA",
                    Type = PropertyType.Resale,
                    Bedrooms = 3,
                    Bathrooms = 2,
                    SquareFeet = 1800,
                    YearBuilt = 2005,
                    Category = "Residential",
                    ImageUrl = "https://images.unsplash.com/photo-1582063289852-62f3e2047752?w=800",
                    Status = PropertyStatus.Approved,
                    CreatedAt = DateTime.UtcNow.AddDays(-15)
                },
                new Property
                {
                    OwnerId = accounts.First(a => a.Email == "jane@example.com").AccountId,
                    Name = "Modern Downtown Apartment",
                    Description = "Contemporary 2-bedroom apartment in the city center with city views.",
                    Location = "456 City Hub, Downtown, NY",
                    Type = PropertyType.Resale,
                    Bedrooms = 2,
                    Bathrooms = 2,
                    SquareFeet = 1200,
                    YearBuilt = 2018,
                    Category = "Apartment",
                    ImageUrl = "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800",
                    Status = PropertyStatus.Approved,
                    CreatedAt = DateTime.UtcNow.AddDays(-12)
                },
                new Property
                {
                    OwnerId = accounts.First(a => a.Email == "mike@example.com").AccountId,
                    Name = "Charming Victorian House",
                    Description = "Beautiful Victorian-style home with original features and modern updates.",
                    Location = "789 Heritage Street, Historic Town, MA",
                    Type = PropertyType.Resale,
                    Bedrooms = 4,
                    Bathrooms = 3,
                    SquareFeet = 2200,
                    YearBuilt = 1895,
                    Category = "Historic",
                    ImageUrl = "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800",
                    Status = PropertyStatus.Approved,
                    CreatedAt = DateTime.UtcNow.AddDays(-10)
                },
                new Property
                {
                    OwnerId = accounts.First(a => a.Email == "sarah@example.com").AccountId,
                    Name = "Luxury Penthouse",
                    Description = "Stunning penthouse with panoramic city views and premium finishes.",
                    Location = "321 Sky Tower, Metropolis, NY",
                    Type = PropertyType.Resale,
                    Bedrooms = 3,
                    Bathrooms = 3,
                    SquareFeet = 2500,
                    YearBuilt = 2020,
                    Category = "Luxury",
                    ImageUrl = "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800",
                    Status = PropertyStatus.Approved,
                    CreatedAt = DateTime.UtcNow.AddDays(-8)
                },
                new Property
                {
                    OwnerId = accounts.First(a => a.Email == "david@example.com").AccountId,
                    Name = "Rustic Cabin Retreat",
                    Description = "Peaceful cabin in the woods perfect for weekend getaways.",
                    Location = "654 Forest Road, Mountain View, CO",
                    Type = PropertyType.Resale,
                    Bedrooms = 2,
                    Bathrooms = 1,
                    SquareFeet = 900,
                    YearBuilt = 1990,
                    Category = "Cabin",
                    ImageUrl = "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800",
                    Status = PropertyStatus.Approved,
                    CreatedAt = DateTime.UtcNow.AddDays(-6)
                },
                new Property
                {
                    OwnerId = accounts.First(a => a.Email == "lisa@example.com").AccountId,
                    Name = "Beach House Paradise",
                    Description = "Beautiful beachfront property with direct beach access and ocean views.",
                    Location = "987 Ocean Drive, Beach City, FL",
                    Type = PropertyType.Resale,
                    Bedrooms = 3,
                    Bathrooms = 2,
                    SquareFeet = 1600,
                    YearBuilt = 2010,
                    Category = "Beach House",
                    ImageUrl = "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800",
                    Status = PropertyStatus.Approved,
                    CreatedAt = DateTime.UtcNow.AddDays(-4)
                },
                new Property
                {
                    OwnerId = accounts.First(a => a.Email == "tom@example.com").AccountId,
                    Name = "Fixer Upper Opportunity",
                    Description = "Great investment property that needs some TLC but has excellent potential.",
                    Location = "147 Renovation Street, Upcoming Area, TX",
                    Type = PropertyType.Resale,
                    Bedrooms = 2,
                    Bathrooms = 1,
                    SquareFeet = 1000,
                    YearBuilt = 1980,
                    Category = "Investment",
                    ImageUrl = "https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800",
                    Status = PropertyStatus.NotApproved,
                    CreatedAt = DateTime.UtcNow.AddDays(-2)
                },
                new Property
                {
                    OwnerId = accounts.First(a => a.Email == "emma@example.com").AccountId,
                    Name = "Modern Studio Apartment",
                    Description = "Efficient studio apartment with smart storage solutions and modern design.",
                    Location = "258 Studio Lane, Urban Center, CA",
                    Type = PropertyType.Resale,
                    Bedrooms = 1,
                    Bathrooms = 1,
                    SquareFeet = 600,
                    YearBuilt = 2015,
                    Category = "Studio",
                    ImageUrl = "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800",
                    Status = PropertyStatus.Approved,
                    CreatedAt = DateTime.UtcNow.AddDays(-1)
                },

                // Primary Properties (by developers, part of projects)
                new Property
                {
                    OwnerId = accounts.First(a => a.Email == "alex@developer.com").AccountId,
                    ProjectId = projects.First(p => p.Name == "Luxury Beachfront Villas").ProjectId,
                    Name = "Villa Ocean View A",
                    Description = "Stunning 4-bedroom villa with private beach access and infinity pool.",
                    Location = "Coastal Paradise, CA",
                    Type = PropertyType.Primary,
                    Bedrooms = 4,
                    Bathrooms = 4,
                    SquareFeet = 3500,
                    YearBuilt = 2023,
                    Category = "Villa",
                    ImageUrl = "https://images.unsplash.com/photo-1592595896551-f772cd1df4a7?w=800",
                    Status = PropertyStatus.Approved,
                    CreatedAt = DateTime.UtcNow.AddDays(-10)
                },
                new Property
                {
                    OwnerId = accounts.First(a => a.Email == "alex@developer.com").AccountId,
                    ProjectId = projects.First(p => p.Name == "Luxury Beachfront Villas").ProjectId,
                    Name = "Villa Ocean View B",
                    Description = "Luxurious 5-bedroom villa with panoramic ocean views and private garden.",
                    Location = "Coastal Paradise, CA",
                    Type = PropertyType.Primary,
                    Bedrooms = 5,
                    Bathrooms = 5,
                    SquareFeet = 4200,
                    YearBuilt = 2023,
                    Category = "Villa",
                    ImageUrl = "https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800",
                    Status = PropertyStatus.Approved,
                    CreatedAt = DateTime.UtcNow.AddDays(-8)
                },
                new Property
                {
                    OwnerId = accounts.First(a => a.Email == "alex@developer.com").AccountId,
                    ProjectId = projects.First(p => p.Name == "Urban Loft Apartments").ProjectId,
                    Name = "Loft Unit 301",
                    Description = "Spacious loft with high ceilings, exposed brick, and industrial design.",
                    Location = "Downtown Metropolis, NY",
                    Type = PropertyType.Primary,
                    Bedrooms = 2,
                    Bathrooms = 2,
                    SquareFeet = 1500,
                    YearBuilt = 2024,
                    Category = "Loft",
                    ImageUrl = "https://images.unsplash.com/photo-1513584684374-8bab748fcd90?w=800",
                    Status = PropertyStatus.Approved,
                    CreatedAt = DateTime.UtcNow.AddDays(-5)
                },
                new Property
                {
                    OwnerId = accounts.First(a => a.Email == "maria@builder.com").AccountId,
                    ProjectId = projects.First(p => p.Name == "Green Valley Estates").ProjectId,
                    Name = "Eco Home 1",
                    Description = "Sustainable home with solar panels, rainwater collection, and energy-efficient design.",
                    Location = "Green Valley, OR",
                    Type = PropertyType.Primary,
                    Bedrooms = 3,
                    Bathrooms = 2,
                    SquareFeet = 1800,
                    YearBuilt = 2024,
                    Category = "Eco-Friendly",
                    ImageUrl = "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800",
                    Status = PropertyStatus.Approved,
                    CreatedAt = DateTime.UtcNow.AddDays(-7)
                },
                new Property
                {
                    OwnerId = accounts.First(a => a.Email == "robert@construct.com").AccountId,
                    ProjectId = projects.First(p => p.Name == "Riverside Towers").ProjectId,
                    Name = "Tower Unit 15A",
                    Description = "High-floor apartment with stunning river views and premium amenities.",
                    Location = "Riverside City, TX",
                    Type = PropertyType.Primary,
                    Bedrooms = 2,
                    Bathrooms = 2,
                    SquareFeet = 1200,
                    YearBuilt = 2024,
                    Category = "High-Rise",
                    ImageUrl = "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800",
                    Status = PropertyStatus.Approved,
                    CreatedAt = DateTime.UtcNow.AddDays(-3)
                },
                new Property
                {
                    OwnerId = accounts.First(a => a.Email == "jennifer@architect.com").AccountId,
                    ProjectId = projects.First(p => p.Name == "Historic District Renovation").ProjectId,
                    Name = "Historic Brownstone Unit 2",
                    Description = "Beautifully restored historic brownstone with original details and modern amenities.",
                    Location = "Historic District, MA",
                    Type = PropertyType.Primary,
                    Bedrooms = 3,
                    Bathrooms = 2,
                    SquareFeet = 2000,
                    YearBuilt = 1890,
                    Category = "Historic",
                    ImageUrl = "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800",
                    Status = PropertyStatus.Approved,
                    CreatedAt = DateTime.UtcNow.AddDays(-1)
                }
            };

            _context.Properties.AddRange(properties);
            await _context.SaveChangesAsync();

            // Create demo auctions (linking to properties)
            var auctions = new List<Auction>
            {
                new Auction
                {
                    PropertyId = properties.First(p => p.Name == "Cozy Family Home").PropertyId,
                    StartPrice = 300000,
                    CurrentPrice = 320000,
                    StartAt = DateTime.UtcNow.AddDays(-2),
                    Duration = 168,
                    BuyNowPrice = 350000,
                    Status = "Active",
                    BidCount = 3,
                    CreatedAt = DateTime.UtcNow.AddDays(-2)
                },
                new Auction
                {
                    PropertyId = properties.First(p => p.Name == "Modern Downtown Apartment").PropertyId,
                    StartPrice = 450000,
                    CurrentPrice = 480000,
                    StartAt = DateTime.UtcNow.AddDays(-1),
                    Duration = 120,
                    BuyNowPrice = 520000,
                    Status = "Active",
                    BidCount = 5,
                    CreatedAt = DateTime.UtcNow.AddDays(-1)
                },
                new Auction
                {
                    PropertyId = properties.First(p => p.Name == "Charming Victorian House").PropertyId,
                    StartPrice = 550000,
                    CurrentPrice = 580000,
                    StartAt = DateTime.UtcNow.AddHours(-12),
                    Duration = 72,
                    BuyNowPrice = 620000,
                    Status = "Active",
                    BidCount = 2,
                    CreatedAt = DateTime.UtcNow.AddHours(-12)
                },
                new Auction
                {
                    PropertyId = properties.First(p => p.Name == "Luxury Penthouse").PropertyId,
                    StartPrice = 1200000,
                    CurrentPrice = 1250000,
                    StartAt = DateTime.UtcNow.AddDays(-1),
                    Duration = 240,
                    BuyNowPrice = 1400000,
                    Status = "Active",
                    BidCount = 1,
                    CreatedAt = DateTime.UtcNow.AddDays(-1)
                },
                new Auction
                {
                    PropertyId = properties.First(p => p.Name == "Beach House Paradise").PropertyId,
                    StartPrice = 800000,
                    CurrentPrice = 820000,
                    StartAt = DateTime.UtcNow.AddHours(-6),
                    Duration = 144,
                    BuyNowPrice = 900000,
                    Status = "Active",
                    BidCount = 4,
                    CreatedAt = DateTime.UtcNow.AddHours(-6)
                },
                new Auction
                {
                    PropertyId = properties.First(p => p.Name == "Modern Studio Apartment").PropertyId,
                    StartPrice = 200000,
                    CurrentPrice = 210000,
                    StartAt = DateTime.UtcNow.AddHours(-3),
                    Duration = 48,
                    BuyNowPrice = 230000,
                    Status = "Active",
                    BidCount = 2,
                    CreatedAt = DateTime.UtcNow.AddHours(-3)
                },
                // UPCOMING AUCTIONS (Future StartAt dates)
                new Auction
                {
                    PropertyId = properties.First(p => p.Name == "Lakefront Cabin").PropertyId,
                    StartPrice = 380000,
                    CurrentPrice = 380000,
                    StartAt = DateTime.UtcNow.AddDays(2),  // Starts in 2 days
                    Duration = 168,
                    BuyNowPrice = 420000,
                    Status = "Active",
                    BidCount = 0,
                    CreatedAt = DateTime.UtcNow
                },
                new Auction
                {
                    PropertyId = properties.First(p => p.Name == "Beachfront Property").PropertyId,
                    StartPrice = 750000,
                    CurrentPrice = 750000,
                    StartAt = DateTime.UtcNow.AddHours(12),  // Starts in 12 hours
                    Duration = 120,
                    BuyNowPrice = 850000,
                    Status = "Active",
                    BidCount = 0,
                    CreatedAt = DateTime.UtcNow
                },
                new Auction
                {
                    PropertyId = properties.First(p => p.Name == "Downtown Loft").PropertyId,
                    StartPrice = 425000,
                    CurrentPrice = 425000,
                    StartAt = DateTime.UtcNow.AddDays(5),  // Starts in 5 days
                    Duration = 96,
                    BuyNowPrice = 475000,
                    Status = "Active",
                    BidCount = 0,
                    CreatedAt = DateTime.UtcNow
                }
            };

            _context.Auctions.AddRange(auctions);
            await _context.SaveChangesAsync();

            // Create demo bids
            var bids = new List<Bid>
            {
                new Bid
                {
                    AuctionId = auctions.First(a => a.PropertyId == properties.First(p => p.Name == "Cozy Family Home").PropertyId).AuctionId,
                    BidderId = accounts.First(a => a.Email == "jane@example.com").AccountId,
                    BidAmount = 310000,
                    CreatedAt = DateTime.UtcNow.AddHours(-10)
                },
                new Bid
                {
                    AuctionId = auctions.First(a => a.PropertyId == properties.First(p => p.Name == "Cozy Family Home").PropertyId).AuctionId,
                    BidderId = accounts.First(a => a.Email == "mike@example.com").AccountId,
                    BidAmount = 315000,
                    CreatedAt = DateTime.UtcNow.AddHours(-8)
                },
                new Bid
                {
                    AuctionId = auctions.First(a => a.PropertyId == properties.First(p => p.Name == "Cozy Family Home").PropertyId).AuctionId,
                    BidderId = accounts.First(a => a.Email == "sarah@example.com").AccountId,
                    BidAmount = 320000,
                    CreatedAt = DateTime.UtcNow.AddHours(-5)
                },
                new Bid
                {
                    AuctionId = auctions.First(a => a.PropertyId == properties.First(p => p.Name == "Modern Downtown Apartment").PropertyId).AuctionId,
                    BidderId = accounts.First(a => a.Email == "john@example.com").AccountId,
                    BidAmount = 460000,
                    CreatedAt = DateTime.UtcNow.AddHours(-8)
                },
                new Bid
                {
                    AuctionId = auctions.First(a => a.PropertyId == properties.First(p => p.Name == "Modern Downtown Apartment").PropertyId).AuctionId,
                    BidderId = accounts.First(a => a.Email == "david@example.com").AccountId,
                    BidAmount = 470000,
                    CreatedAt = DateTime.UtcNow.AddHours(-6)
                },
                new Bid
                {
                    AuctionId = auctions.First(a => a.PropertyId == properties.First(p => p.Name == "Modern Downtown Apartment").PropertyId).AuctionId,
                    BidderId = accounts.First(a => a.Email == "lisa@example.com").AccountId,
                    BidAmount = 480000,
                    CreatedAt = DateTime.UtcNow.AddHours(-4)
                },
                new Bid
                {
                    AuctionId = auctions.First(a => a.PropertyId == properties.First(p => p.Name == "Charming Victorian House").PropertyId).AuctionId,
                    BidderId = accounts.First(a => a.Email == "emma@example.com").AccountId,
                    BidAmount = 560000,
                    CreatedAt = DateTime.UtcNow.AddHours(-10)
                },
                new Bid
                {
                    AuctionId = auctions.First(a => a.PropertyId == properties.First(p => p.Name == "Charming Victorian House").PropertyId).AuctionId,
                    BidderId = accounts.First(a => a.Email == "john@example.com").AccountId,
                    BidAmount = 580000,
                    CreatedAt = DateTime.UtcNow.AddHours(-6)
                },
                new Bid
                {
                    AuctionId = auctions.First(a => a.PropertyId == properties.First(p => p.Name == "Luxury Penthouse").PropertyId).AuctionId,
                    BidderId = accounts.First(a => a.Email == "sarah@example.com").AccountId,
                    BidAmount = 1250000,
                    CreatedAt = DateTime.UtcNow.AddHours(-12)
                },
                new Bid
                {
                    AuctionId = auctions.First(a => a.PropertyId == properties.First(p => p.Name == "Beach House Paradise").PropertyId).AuctionId,
                    BidderId = accounts.First(a => a.Email == "mike@example.com").AccountId,
                    BidAmount = 810000,
                    CreatedAt = DateTime.UtcNow.AddHours(-8)
                },
                new Bid
                {
                    AuctionId = auctions.First(a => a.PropertyId == properties.First(p => p.Name == "Beach House Paradise").PropertyId).AuctionId,
                    BidderId = accounts.First(a => a.Email == "david@example.com").AccountId,
                    BidAmount = 820000,
                    CreatedAt = DateTime.UtcNow.AddHours(-4)
                },
                new Bid
                {
                    AuctionId = auctions.First(a => a.PropertyId == properties.First(p => p.Name == "Modern Studio Apartment").PropertyId).AuctionId,
                    BidderId = accounts.First(a => a.Email == "tom@example.com").AccountId,
                    BidAmount = 205000,
                    CreatedAt = DateTime.UtcNow.AddHours(-6)
                },
                new Bid
                {
                    AuctionId = auctions.First(a => a.PropertyId == properties.First(p => p.Name == "Modern Studio Apartment").PropertyId).AuctionId,
                    BidderId = accounts.First(a => a.Email == "jane@example.com").AccountId,
                    BidAmount = 210000,
                    CreatedAt = DateTime.UtcNow.AddHours(-2)
                }
            };

            _context.Bids.AddRange(bids);
            await _context.SaveChangesAsync();
        }
    }
}