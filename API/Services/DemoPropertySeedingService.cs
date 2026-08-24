using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;

namespace InstapropAPI.Services
{
    /// <summary>
    /// Egypt-only demo market seeding with real developer/project names and free Unsplash/Pexels images.
    /// </summary>
    public class DemoPropertySeedingService
    {
        private readonly AppDbContext _context;

        public DemoPropertySeedingService(AppDbContext context)
        {
            _context = context;
        }

        private static string Unsplash(string photoId, int w = 1200, int h = 800) =>
            $"https://images.unsplash.com/photo-{photoId}?w={w}&h={h}&fit=crop&auto=format&q=80";

        private static string Pexels(string id, int w = 1200, int h = 800) =>
            $"https://images.pexels.com/photos/{id}/pexels-photo-{id}.jpeg?auto=compress&cs=tinysrgb&w={w}&h={h}";

        private record DeveloperDef(string Company, string Email, string Phone);

        private record ProjectDef(string Name, string Company, string Location, string Description);

        private record PropertyDef(
            string UnitLabel,
            string ProjectName,
            string Description,
            PropertyType Type,
            int Bedrooms,
            int Bathrooms,
            int AreaSqm,
            decimal PriceEgp,
            string MainImage,
            string[] GalleryImages,
            bool NileView = false,
            bool GardenView = false,
            bool SeaView = false,
            bool HasPool = false,
            string FinishingType = "Finished",
            string Phase = "Phase 1");

        private static readonly DeveloperDef[] EgyptianDevelopers =
        {
            new("Palm Hills Developments", "contact@palmhillsdevelopments.com", "+20235309000"),
            new("Emaar Misr", "info@emaarmisr.com", "+20235356100"),
            new("TMG Holding", "info@tmgholding.com", "+20235356100"),
            new("SODIC", "info@sodic.com", "+20238255000"),
            new("Mountain View", "info@mountainviewegypt.com", "+20235309000"),
            new("Hyde Park Developments", "info@hydeparkdevelopments.com", "+20235309000"),
            new("Tatweer Misr", "info@tatweermisr.com", "+20235309000"),
            new("Ora Developers", "info@oradevelopers.com", "+20235309000"),
        };

        private static readonly ProjectDef[] EgyptianProjects =
        {
            new("Palm Hills New Cairo", "Palm Hills Developments", "New Cairo, Egypt",
                "Flagship gated community in New Cairo by Palm Hills with parks, clubhouse, and premium finishing."),
            new("Mivida", "Emaar Misr", "New Cairo, Egypt",
                "Emaar Misr mixed-use destination in New Cairo with The Place retail and landscaped boulevards."),
            new("Madinaty", "TMG Holding", "New Cairo, Egypt",
                "TMG's fully integrated city in New Cairo with schools, hospitals, and open green spaces."),
            new("Eastown", "SODIC", "New Cairo, Egypt",
                "SODIC residential compound in New Cairo near AUC with serviced apartments and retail."),
            new("Mountain View iCity", "Mountain View", "6th October City, Egypt",
                "Mountain View's iCity on 6th October with contemporary architecture and family amenities."),
            new("Hyde Park New Cairo", "Hyde Park Developments", "New Cairo, Egypt",
                "Hyde Park compound featuring lagoons, sports clubs, and wide landscaped promenades."),
            new("Marassi", "Emaar Misr", "North Coast, Egypt",
                "Emaar Misr Mediterranean resort on the North Coast with marina, beach, and hotel partners."),
            new("Villette", "SODIC", "New Cairo, Egypt",
                "SODIC's Villette community inspired by French urban design in the heart of New Cairo."),
            new("Uptown Cairo", "Emaar Misr", "New Cairo, Egypt",
                "Emaar Misr hillside community in New Cairo with elevated views and cold weather microclimate."),
            new("Hacienda Bay", "Palm Hills Developments", "North Coast, Egypt",
                "Palm Hills North Coast resort with beach access, pools, and summer chalet inventory."),
            new("Il Monte Galala", "Tatweer Misr", "Ain Sokhna, Egypt",
                "Tatweer Misr mountain-and-sea resort in Ain Sokhna with cable car and adventure amenities."),
            new("Zed East", "Ora Developers", "New Cairo, Egypt",
                "Ora Developers' Zed East with business hub, retail strip, and contemporary residential blocks."),
        };

        private static readonly PropertyDef[] EgyptianProperties =
        {
            new("Building 12 Apt 304", "Palm Hills New Cairo",
                "3-bedroom garden-view apartment in Palm Hills New Cairo with clubhouse access and underground parking.",
                PropertyType.Apartment, 3, 2, 168, 5_200_000m,
                Unsplash("1564013799919-bc007da7807a"),
                new[] { Unsplash("1600210492486-724fe5c67fb0", 1200, 900), Unsplash("1556911223-bff1c7754a7a", 1200, 900), Unsplash("1616594039964-4086a34a1f2a", 1200, 900) },
                GardenView: true, HasPool: true),

            new("The Place Building 3 Apt 502", "Mivida",
                "Corner 2-bedroom apartment in Mivida overlooking The Place boulevard with Emaar finishing standards.",
                PropertyType.Apartment, 2, 2, 132, 4_350_000m,
                Unsplash("1600596542810-ff374b12c26e"),
                new[] { Unsplash("1600566753190-17f0baa2a6c3", 1200, 900), Pexels("2102587", 1200, 900), Unsplash("1560448204-e02f11c3d0e2", 1200, 900) },
                HasPool: true),

            new("Open Area Villa 18", "Madinaty",
                "Standalone 4-bedroom villa in Madinaty Open Area with private garden and TMG community facilities.",
                PropertyType.Villa, 4, 3, 340, 11_800_000m,
                Unsplash("1600047509358-9dc75507daeb"),
                new[] { Unsplash("1600566752355-35792bedcfea", 1200, 900), Unsplash("1512917774080-9991f1c4c750", 1200, 900), Pexels("323780", 1200, 900) },
                GardenView: true, HasPool: true),

            new("Parkside Apt 210", "Eastown",
                "Fully finished 2-bedroom apartment in SODIC Eastown near AUC with concierge and gym access.",
                PropertyType.ServicedApartment, 2, 2, 128, 3_850_000m,
                Pexels("2102590"),
                new[] { Pexels("1732418", 1200, 900), Unsplash("1600585152915-d208b94cde02", 1200, 900), Unsplash("1556911223-bff1c7754a7a", 1200, 900) }),

            new("iCity Park Building 8 Apt 601", "Mountain View iCity",
                "3-bedroom duplex-style apartment in Mountain View iCity with double-height living and pool views.",
                PropertyType.Duplex, 3, 3, 205, 6_400_000m,
                Unsplash("1600585154520-86fd880bc1d1"),
                new[] { Unsplash("1568605114967-8130f3a36994", 1200, 900), Unsplash("1600210492486-724fe5c67fb0", 1200, 900), Pexels("1732414", 1200, 900) },
                GardenView: true, HasPool: true, Phase: "Phase 2"),

            new("Lagoon District Apt 415", "Hyde Park New Cairo",
                "3-bedroom apartment in Hyde Park lagoon district with promenade access and sports club membership.",
                PropertyType.Apartment, 3, 2, 175, 5_600_000m,
                Pexels("1396122"),
                new[] { Unsplash("1600566753086-8c67b97e8e5e", 1200, 900), Unsplash("1556911223-bff1c7754a7a", 1200, 900), Unsplash("1616594039964-4086a34a1f2a", 1200, 900) },
                HasPool: true),

            new("Marina Residences Block C Apt 102", "Marassi",
                "North Coast 2-bedroom chalet in Emaar Marassi with sea-view terrace and beach club access.",
                PropertyType.Chalet, 2, 2, 115, 4_500_000m,
                Pexels("2102589"),
                new[] { Pexels("2102587", 1200, 900), Unsplash("1600607687939-ce8a6c25118c", 1200, 900), Unsplash("1600585154340-be6161a56a0b", 1200, 900) },
                SeaView: true, HasPool: true),

            new("Villette Park Villa 7", "Villette",
                "4-bedroom townhouse in SODIC Villette with rooftop terrace and French-inspired street layout.",
                PropertyType.Townhouse, 4, 3, 255, 8_900_000m,
                Pexels("323776"),
                new[] { Unsplash("1600596542810-ff374b12c26e", 1200, 900), Unsplash("1560448204-e02f11c3d0e2", 1200, 900), Unsplash("1600566753190-17f0baa2a6c3", 1200, 900) },
                GardenView: true),

            new("The Crest Penthouse 1", "Uptown Cairo",
                "Premium penthouse in Emaar Uptown Cairo with elevated Cairo skyline views and cold-weather location.",
                PropertyType.Penthouse, 4, 4, 290, 19_500_000m,
                Unsplash("1512915922686-57c11dde9b6b"),
                new[] { Unsplash("1600607687644-aac4c5191e0d", 1200, 900), Unsplash("1600585152915-d208b94cde02", 1200, 900), Pexels("2102590", 1200, 900) },
                NileView: true),

            new("Hacienda White Chalet B-22", "Hacienda Bay",
                "Summer chalet in Palm Hills Hacienda Bay with pool access and private North Coast beach strip.",
                PropertyType.Chalet, 2, 2, 108, 3_950_000m,
                Unsplash("1600607687924-4b2e6b2295ed"),
                new[] { Pexels("2102589", 1200, 900), Unsplash("1600047509358-9dc75507daeb", 1200, 900), Pexels("323775", 1200, 900) },
                SeaView: true, HasPool: true),

            new("Galala Heights Villa 4", "Il Monte Galala",
                "5-bedroom Red Sea villa in Tatweer Misr Il Monte Galala with private pool and marina proximity.",
                PropertyType.Villa, 5, 4, 390, 15_800_000m,
                Unsplash("1600607687924-4b2e6b2295ed"),
                new[] { Unsplash("1512917774080-9991f1c4c750", 1200, 900), Pexels("323775", 1200, 900), Unsplash("1600210492486-724fe5c67fb0", 1200, 900) },
                SeaView: true, GardenView: true, HasPool: true),

            new("Business Hub Tower Apt 908", "Zed East",
                "3-bedroom apartment in Ora Zed East business hub with retail strip access and smart-home readiness.",
                PropertyType.Apartment, 3, 2, 162, 4_950_000m,
                Unsplash("1568605114967-8130f3a36994"),
                new[] { Unsplash("1600585154340-be6161a56a0b", 1200, 900), Unsplash("1556911223-bff1c7754a7a", 1200, 900), Pexels("1732414", 1200, 900) }),
        };

        public async Task<(int Developers, int Projects, int Properties, int Images, int Auctions)> ResetAndSeedEgyptianMarketAsync()
        {
            await EnsureRolesAsync();
            await EnableAllFeatureFlagsAsync();
            await ClearPropertyMarketDataAsync();
            await NormalizeExistingProjectsToEgyptAsync();

            var developers = await EnsureDevelopersAsync();
            var projects = await EnsureProjectsAsync(developers);
            var properties = await SeedPropertiesAsync(projects, developers);
            var imageCount = await SeedImagesAsync(properties);
            var auctionCount = await SeedAuctionsAsync(properties);

            return (developers.Count, projects.Count, properties.Count, imageCount, auctionCount);
        }

        public async Task<int> EnableAllFeatureFlagsAsync()
        {
            return await _context.FeatureFlags.ExecuteUpdateAsync(s =>
                s.SetProperty(f => f.IsEnabled, true));
        }

        private async Task ClearPropertyMarketDataAsync()
        {
            var propertyIds = await _context.Properties.Select(p => p.PropertyId).ToListAsync();
            if (propertyIds.Count == 0)
            {
                await _context.Projects.ExecuteDeleteAsync();
                return;
            }

            var auctionIds = await _context.Auctions
                .Where(a => propertyIds.Contains(a.PropertyId))
                .Select(a => a.AuctionId)
                .ToListAsync();

            if (auctionIds.Count > 0)
                await _context.Bids.Where(b => auctionIds.Contains(b.AuctionId)).ExecuteDeleteAsync();

            await _context.Auctions.Where(a => propertyIds.Contains(a.PropertyId)).ExecuteDeleteAsync();
            await _context.PropertyPriceHistories.Where(ph => propertyIds.Contains(ph.PropertyId)).ExecuteDeleteAsync();
            await _context.PropertyViews.Where(pv => propertyIds.Contains(pv.PropertyId)).ExecuteDeleteAsync();
            await _context.PropertyValuations.Where(pv => propertyIds.Contains(pv.PropertyId)).ExecuteDeleteAsync();
            await _context.PropertyImages.Where(pi => propertyIds.Contains(pi.PropertyId)).ExecuteDeleteAsync();
            await _context.PropertyDocs.Where(pd => propertyIds.Contains(pd.PropertyId)).ExecuteDeleteAsync();
            await _context.InstallmentSummaries.Where(i => propertyIds.Contains(i.PropertyId)).ExecuteDeleteAsync();
            await _context.Properties.ExecuteDeleteAsync();
            await _context.Projects.ExecuteDeleteAsync();
        }

        private async Task NormalizeExistingProjectsToEgyptAsync()
        {
            await _context.Projects
                .Where(p => p.Country != "EG")
                .ExecuteUpdateAsync(s => s.SetProperty(p => p.Country, "EG"));
        }

        private async Task EnsureRolesAsync()
        {
            var existing = await _context.Roles.Select(r => r.RoleId).ToListAsync();
            var roles = new[]
            {
                new Role { RoleId = Role.USER_ROLE_ID, RoleName = "User", Description = "Regular user", CreatedAt = DateTime.UtcNow },
                new Role { RoleId = Role.DEVELOPER_ROLE_ID, RoleName = "Developer", Description = "Property developer", CreatedAt = DateTime.UtcNow },
                new Role { RoleId = Role.ADMIN_ROLE_ID, RoleName = "Admin", Description = "System administrator", CreatedAt = DateTime.UtcNow },
                new Role { RoleId = Role.SALES_ROLE_ID, RoleName = "Sales", Description = "Sales team member", CreatedAt = DateTime.UtcNow }
            };

            var toAdd = roles.Where(r => !existing.Contains(r.RoleId)).ToList();
            if (toAdd.Count > 0)
            {
                await _context.Roles.AddRangeAsync(toAdd);
                await _context.SaveChangesAsync();
            }
        }

        private async Task<Dictionary<string, DeveloperAccount>> EnsureDevelopersAsync()
        {
            var map = new Dictionary<string, DeveloperAccount>();
            foreach (var def in EgyptianDevelopers)
            {
                var existing = await _context.DeveloperAccounts
                    .FirstOrDefaultAsync(d => d.Email == def.Email);

                if (existing != null)
                {
                    map[def.Company] = existing;
                    continue;
                }

                var developer = new DeveloperAccount
                {
                    FirstName = def.Company,
                    LastName = "",
                    Email = def.Email,
                    PhoneNumber = def.Phone,
                    RoleId = Role.DEVELOPER_ROLE_ID,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("Dev123!"),
                    Status = VerificationStatus.Verified,
                    EmailVerified = true,
                    PhoneVerified = true,
                    TimeZone = "Africa/Cairo",
                    CreatedAt = DateTime.UtcNow.AddYears(-3)
                };
                await _context.DeveloperAccounts.AddAsync(developer);
                map[def.Company] = developer;
            }

            await _context.SaveChangesAsync();
            return map;
        }

        private async Task<Dictionary<string, Project>> EnsureProjectsAsync(Dictionary<string, DeveloperAccount> developers)
        {
            var map = new Dictionary<string, Project>();
            foreach (var def in EgyptianProjects)
            {
                var developer = developers[def.Company];
                var project = new Project
                {
                    Name = def.Name,
                    Description = def.Description,
                    Location = def.Location,
                    Country = "EG",
                    IsActive = true,
                    DeveloperId = developer.AccountId,
                    CreatedAt = DateTime.UtcNow.AddMonths(-24)
                };
                await _context.Projects.AddAsync(project);
                map[def.Name] = project;
            }

            await _context.SaveChangesAsync();
            return map;
        }

        private async Task<List<Property>> SeedPropertiesAsync(
            Dictionary<string, Project> projects,
            Dictionary<string, DeveloperAccount> developers)
        {
            var properties = new List<Property>();
            var now = DateTime.UtcNow;
            var unitCounter = 101;

            foreach (var def in EgyptianProperties)
            {
                var project = projects[def.ProjectName];
                var projectMeta = EgyptianProjects.First(p => p.Name == def.ProjectName);
                var developer = developers[projectMeta.Company];

                properties.Add(new Property
                {
                    OwnerId = developer.AccountId,
                    ProjectId = project.ProjectId,
                    ProjectName = def.ProjectName,
                    Name = $"{def.ProjectName} - {def.UnitLabel}",
                    Description = def.Description,
                    Location = project.Location ?? "Egypt",
                    ImageUrl = def.MainImage,
                    SquareFeet = (int)(def.AreaSqm * 10.764),
                    YearBuilt = 2024,
                    Bedrooms = def.Bedrooms,
                    Bathrooms = def.Bathrooms,
                    Type = def.Type,
                    Status = PropertyStatus.Approved,
                    FinishingType = def.FinishingType,
                    Phase = def.Phase,
                    FloorNumber = def.Type is PropertyType.Villa or PropertyType.Townhouse ? 0 : unitCounter % 12 + 1,
                    UnitNumber = unitCounter.ToString("D3"),
                    BuyingPrice = def.PriceEgp,
                    BuyingDate = now.AddMonths(-6),
                    DeliveryDate = now.AddMonths(12),
                    ParkingSlots = def.Bedrooms >= 4 ? 2 : 1,
                    HasStorageRoom = true,
                    HasPool = def.HasPool,
                    HasGym = true,
                    HasSecurity = true,
                    HasParking = true,
                    HasPlayground = true,
                    HasClubhouse = def.HasPool,
                    HasBalcony = def.Type != PropertyType.Villa,
                    HasGarden = def.GardenView || def.Type is PropertyType.Villa or PropertyType.Townhouse,
                    NileView = def.NileView,
                    GardenView = def.GardenView,
                    SeaView = def.SeaView,
                    IsApproved = true,
                    CreatedAt = now.AddDays(-unitCounter),
                    UpdatedAt = now
                });
                unitCounter++;
            }

            await _context.Properties.AddRangeAsync(properties);
            await _context.SaveChangesAsync();
            return properties;
        }

        private async Task<int> SeedImagesAsync(List<Property> properties)
        {
            var images = new List<PropertyImage>();
            var imageTypes = new[] { "Main", "Living Room", "Kitchen", "Bedroom", "Exterior" };

            foreach (var property in properties)
            {
                var def = EgyptianProperties.First(d => property.Name == $"{d.ProjectName} - {d.UnitLabel}");
                var urls = new[] { def.MainImage }.Concat(def.GalleryImages).ToArray();

                for (var i = 0; i < urls.Length; i++)
                {
                    images.Add(new PropertyImage
                    {
                        PropertyId = property.PropertyId,
                        ImageUrl = urls[i],
                        ImageType = imageTypes[Math.Min(i, imageTypes.Length - 1)],
                        IsMainImage = i == 0,
                        DisplayOrder = i,
                        CreatedAt = DateTime.UtcNow
                    });
                }
            }

            await _context.PropertyImages.AddRangeAsync(images);
            await _context.SaveChangesAsync();
            return images.Count;
        }

        private async Task<int> SeedAuctionsAsync(List<Property> properties)
        {
            var auctions = new List<Auction>();
            var now = DateTime.UtcNow;

            foreach (var property in properties.Take(6))
            {
                var startPrice = (property.BuyingPrice ?? 3_000_000m) * 0.85m;
                auctions.Add(new Auction
                {
                    PropertyId = property.PropertyId,
                    StartPrice = startPrice,
                    CurrentPrice = startPrice * 1.08m,
                    StartAt = now.AddHours(-6),
                    Duration = 72,
                    Status = "Active",
                    BidCount = 3,
                    CreatedAt = now.AddDays(-2)
                });
            }

            await _context.Auctions.AddRangeAsync(auctions);
            await _context.SaveChangesAsync();
            return auctions.Count;
        }
    }
}
