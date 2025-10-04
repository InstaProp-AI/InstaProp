using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;

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
            // Check if data already exists
            if (await _context.Users.AnyAsync() && await _context.Properties.AnyAsync() && await _context.Auctions.AnyAsync())
            {
                return; // Data already seeded
            }

            // Create demo users
            var users = new List<User>
            {
                new User
                {
                    FirstName = "John",
                    LastName = "Doe",
                    Email = "john@example.com",
                    PhoneNumber = "555-0101",
                    Gender = "Male",
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("password123"),
                    IsVerified = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-30)
                },
                new User
                {
                    FirstName = "Jane",
                    LastName = "Smith",
                    Email = "jane@example.com",
                    PhoneNumber = "555-0102",
                    Gender = "Female",
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("password123"),
                    IsVerified = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-25)
                },
                new User
                {
                    FirstName = "Mike",
                    LastName = "Johnson",
                    Email = "mike@example.com",
                    PhoneNumber = "555-0103",
                    Gender = "Male",
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("password123"),
                    IsVerified = false,
                    CreatedAt = DateTime.UtcNow.AddDays(-20)
                }
            };

            _context.Users.AddRange(users);
            await _context.SaveChangesAsync();

            // Create demo properties
            var properties = new List<Property>
            {
                new Property
                {
                    OwnerId = users[0].UserId,
                    Name = "Luxury Downtown Condo",
                    Description = "Beautiful modern condo in the heart of downtown with stunning city views.",
                    Location = "123 Main St, Downtown",
                    StartingPrice = 450000,
                    Bedrooms = 2,
                    Bathrooms = 2,
                    SquareFeet = 1200,
                    YearBuilt = 2020,
                    Category = "Condo",
                    ImageUrl = "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800",
                    IsApproved = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-15)
                },
                new Property
                {
                    OwnerId = users[1].UserId,
                    Name = "Historic Victorian Home",
                    Description = "Charming Victorian home with original features and modern updates.",
                    Location = "456 Oak Avenue, Historic District",
                    StartingPrice = 650000,
                    Bedrooms = 4,
                    Bathrooms = 3,
                    SquareFeet = 2800,
                    YearBuilt = 1895,
                    Category = "Single Family",
                    ImageUrl = "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800",
                    IsApproved = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-12)
                },
                new Property
                {
                    OwnerId = users[0].UserId,
                    Name = "Modern Townhouse",
                    Description = "Contemporary townhouse with open floor plan and private patio.",
                    Location = "789 Pine Street, Suburbs",
                    StartingPrice = 380000,
                    Bedrooms = 3,
                    Bathrooms = 2,
                    SquareFeet = 1800,
                    YearBuilt = 2018,
                    Category = "Townhouse",
                    ImageUrl = "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800",
                    IsApproved = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-10)
                },
                new Property
                {
                    OwnerId = users[2].UserId,
                    Name = "Cozy Starter Home",
                    Description = "Perfect starter home with updated kitchen and hardwood floors.",
                    Location = "321 Elm Drive, Residential",
                    StartingPrice = 275000,
                    Bedrooms = 2,
                    Bathrooms = 1,
                    SquareFeet = 1200,
                    YearBuilt = 1995,
                    Category = "Single Family",
                    ImageUrl = "https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800",
                    IsApproved = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-8)
                },
                new Property
                {
                    OwnerId = users[1].UserId,
                    Name = "Executive Penthouse",
                    Description = "Luxurious penthouse with panoramic city views and premium finishes.",
                    Location = "555 Sky Tower, Downtown",
                    StartingPrice = 1200000,
                    Bedrooms = 3,
                    Bathrooms = 3,
                    SquareFeet = 2500,
                    YearBuilt = 2022,
                    Category = "Condo",
                    ImageUrl = "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800",
                    IsApproved = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-5)
                }
            };

            _context.Properties.AddRange(properties);
            await _context.SaveChangesAsync();

            // Create demo auctions
            var auctions = new List<Auction>
            {
                new Auction
                {
                    PropertyId = properties[0].PropertyId,
                    StartAt = 450000,
                    CurrentPrice = 450000,
                    EndAt = DateTime.UtcNow.AddDays(2),
                    Duration = 72,
                    BuyNowPrice = 500000,
                    Status = "Active",
                    BidCount = 12,
                    CreatedAt = DateTime.UtcNow.AddDays(-5)
                },
                new Auction
                {
                    PropertyId = properties[1].PropertyId,
                    StartAt = 650000,
                    CurrentPrice = 650000,
                    EndAt = DateTime.UtcNow.AddDays(5),
                    Duration = 120,
                    BuyNowPrice = 750000,
                    Status = "Active",
                    BidCount = 8,
                    CreatedAt = DateTime.UtcNow.AddDays(-3)
                },
                new Auction
                {
                    PropertyId = properties[2].PropertyId,
                    StartAt = 380000,
                    CurrentPrice = 380000,
                    EndAt = DateTime.UtcNow.AddDays(1),
                    Duration = 48,
                    BuyNowPrice = 420000,
                    Status = "Active",
                    BidCount = 15,
                    CreatedAt = DateTime.UtcNow.AddDays(-2)
                },
                new Auction
                {
                    PropertyId = properties[3].PropertyId,
                    StartAt = 275000,
                    CurrentPrice = 275000,
                    EndAt = DateTime.UtcNow.AddDays(-1),
                    Duration = 72,
                    Status = "Ended",
                    BidCount = 6,
                    CreatedAt = DateTime.UtcNow.AddDays(-5)
                },
                new Auction
                {
                    PropertyId = properties[4].PropertyId,
                    StartAt = 1200000,
                    CurrentPrice = 1200000,
                    EndAt = DateTime.UtcNow.AddDays(7),
                    Duration = 168,
                    BuyNowPrice = 1500000,
                    Status = "Upcoming",
                    BidCount = 0,
                    CreatedAt = DateTime.UtcNow.AddDays(-1)
                }
            };

            _context.Auctions.AddRange(auctions);
            await _context.SaveChangesAsync();

            // Create demo bids
            var bids = new List<Bid>
            {
                new Bid
                {
                    AuctionId = auctions[0].AuctionId,
                    BidderId = users[1].UserId,
                    BidAmount = 460000,
                    CreatedAt = DateTime.UtcNow.AddDays(-4)
                },
                new Bid
                {
                    AuctionId = auctions[0].AuctionId,
                    BidderId = users[2].UserId,
                    BidAmount = 470000,
                    CreatedAt = DateTime.UtcNow.AddDays(-3)
                },
                new Bid
                {
                    AuctionId = auctions[0].AuctionId,
                    BidderId = users[1].UserId,
                    BidAmount = 475000,
                    CreatedAt = DateTime.UtcNow.AddDays(-2)
                },
                new Bid
                {
                    AuctionId = auctions[1].AuctionId,
                    BidderId = users[0].UserId,
                    BidAmount = 660000,
                    CreatedAt = DateTime.UtcNow.AddDays(-2)
                },
                new Bid
                {
                    AuctionId = auctions[1].AuctionId,
                    BidderId = users[2].UserId,
                    BidAmount = 680000,
                    CreatedAt = DateTime.UtcNow.AddDays(-1)
                },
                new Bid
                {
                    AuctionId = auctions[2].AuctionId,
                    BidderId = users[1].UserId,
                    BidAmount = 385000,
                    CreatedAt = DateTime.UtcNow.AddDays(-1)
                },
                new Bid
                {
                    AuctionId = auctions[2].AuctionId,
                    BidderId = users[0].UserId,
                    BidAmount = 390000,
                    CreatedAt = DateTime.UtcNow.AddHours(-12)
                },
                new Bid
                {
                    AuctionId = auctions[2].AuctionId,
                    BidderId = users[2].UserId,
                    BidAmount = 395000,
                    CreatedAt = DateTime.UtcNow.AddHours(-6)
                }
            };

            _context.Bids.AddRange(bids);
            await _context.SaveChangesAsync();
        }
    }
}
