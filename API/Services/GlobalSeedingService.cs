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
    /// <summary>
    /// Egypt-only seeding helpers. InstaProp targets the Egyptian real estate market exclusively.
    /// </summary>
    public class GlobalSeedingService
    {
        private readonly AppDbContext _context;
        private readonly Random _random = new Random();

        public GlobalSeedingService(AppDbContext context)
        {
            _context = context;
        }

        #region Global Data Constants

        // Country Data with pricing ranges and details
        private readonly List<CountryData> Countries = new List<CountryData>
        {
            new CountryData { Code = "US", Name = "United States", Currency = "USD", Timezone = "America/New_York", MinPrice = 200000, MaxPrice = 5000000, CityPrefix = "+1" },
            new CountryData { Code = "CA", Name = "Canada", Currency = "USD", Timezone = "America/Toronto", MinPrice = 180000, MaxPrice = 3500000, CityPrefix = "+1" },
            new CountryData { Code = "GB", Name = "United Kingdom", Currency = "USD", Timezone = "Europe/London", MinPrice = 300000, MaxPrice = 4000000, CityPrefix = "+44" },
            new CountryData { Code = "DE", Name = "Germany", Currency = "USD", Timezone = "Europe/Berlin", MinPrice = 250000, MaxPrice = 3000000, CityPrefix = "+49" },
            new CountryData { Code = "FR", Name = "France", Currency = "USD", Timezone = "Europe/Paris", MinPrice = 280000, MaxPrice = 3500000, CityPrefix = "+33" },
            new CountryData { Code = "ES", Name = "Spain", Currency = "USD", Timezone = "Europe/Madrid", MinPrice = 200000, MaxPrice = 2500000, CityPrefix = "+34" },
            new CountryData { Code = "IT", Name = "Italy", Currency = "USD", Timezone = "Europe/Rome", MinPrice = 220000, MaxPrice = 2800000, CityPrefix = "+39" },
            new CountryData { Code = "NL", Name = "Netherlands", Currency = "USD", Timezone = "Europe/Amsterdam", MinPrice = 270000, MaxPrice = 3200000, CityPrefix = "+31" },
            new CountryData { Code = "AE", Name = "United Arab Emirates", Currency = "USD", Timezone = "Asia/Dubai", MinPrice = 150000, MaxPrice = 8000000, CityPrefix = "+971" },
            new CountryData { Code = "SA", Name = "Saudi Arabia", Currency = "USD", Timezone = "Asia/Riyadh", MinPrice = 180000, MaxPrice = 4000000, CityPrefix = "+966" },
            new CountryData { Code = "QA", Name = "Qatar", Currency = "USD", Timezone = "Asia/Qatar", MinPrice = 200000, MaxPrice = 5000000, CityPrefix = "+974" },
            new CountryData { Code = "BH", Name = "Bahrain", Currency = "USD", Timezone = "Asia/Bahrain", MinPrice = 150000, MaxPrice = 2000000, CityPrefix = "+973" }
        };

        // Cities per country
        private readonly Dictionary<string, List<CityData>> CitiesByCountry = new Dictionary<string, List<CityData>>
        {
            ["US"] = new List<CityData>
            {
                new CityData { Name = "New York", Lat = 40.7128, Lng = -74.0060, Description = "The city that never sleeps" },
                new CityData { Name = "Los Angeles", Lat = 34.0522, Lng = -118.2437, Description = "Entertainment capital" },
                new CityData { Name = "Miami", Lat = 25.7617, Lng = -80.1918, Description = "Tropical paradise" },
                new CityData { Name = "San Francisco", Lat = 37.7749, Lng = -122.4194, Description = "Tech hub" },
                new CityData { Name = "Chicago", Lat = 41.8781, Lng = -87.6298, Description = "Architectural marvel" }
            },
            ["CA"] = new List<CityData>
            {
                new CityData { Name = "Toronto", Lat = 43.651070, Lng = -79.347015, Description = "Multicultural metropolis" },
                new CityData { Name = "Vancouver", Lat = 49.2827, Lng = -123.1207, Description = "Coastal beauty" },
                new CityData { Name = "Montreal", Lat = 45.5017, Lng = -73.5673, Description = "European charm" }
            },
            ["GB"] = new List<CityData>
            {
                new CityData { Name = "London", Lat = 51.5074, Lng = -0.1278, Description = "Global city" },
                new CityData { Name = "Manchester", Lat = 53.4808, Lng = -2.2426, Description = "Industrial heritage" },
                new CityData { Name = "Birmingham", Lat = 52.4862, Lng = -1.8904, Description = "Second city" }
            },
            ["DE"] = new List<CityData>
            {
                new CityData { Name = "Berlin", Lat = 52.5200, Lng = 13.4050, Description = "Capital city" },
                new CityData { Name = "Munich", Lat = 48.1351, Lng = 11.5820, Description = "Bavaria's capital" },
                new CityData { Name = "Frankfurt", Lat = 50.1109, Lng = 8.6821, Description = "Financial capital" }
            },
            ["FR"] = new List<CityData>
            {
                new CityData { Name = "Paris", Lat = 48.8566, Lng = 2.3522, Description = "City of lights" },
                new CityData { Name = "Lyon", Lat = 45.7640, Lng = 4.8357, Description = "Culinary excellence" },
                new CityData { Name = "Marseille", Lat = 43.2965, Lng = 5.3698, Description = "Mediterranean port" }
            },
            ["ES"] = new List<CityData>
            {
                new CityData { Name = "Barcelona", Lat = 41.3851, Lng = 2.1734, Description = "Modernist architecture" },
                new CityData { Name = "Madrid", Lat = 40.4168, Lng = -3.7038, Description = "Spanish capital" },
                new CityData { Name = "Valencia", Lat = 39.4699, Lng = -0.3763, Description = "Modern design" }
            },
            ["IT"] = new List<CityData>
            {
                new CityData { Name = "Rome", Lat = 41.9028, Lng = 12.4964, Description = "Eternal city" },
                new CityData { Name = "Milan", Lat = 45.4642, Lng = 9.1900, Description = "Fashion capital" },
                new CityData { Name = "Florence", Lat = 43.7696, Lng = 11.2558, Description = "Renaissance art" }
            },
            ["NL"] = new List<CityData>
            {
                new CityData { Name = "Amsterdam", Lat = 52.3676, Lng = 4.9041, Description = "Canal city" },
                new CityData { Name = "Rotterdam", Lat = 51.9225, Lng = 4.47917, Description = "Modern architecture" },
                new CityData { Name = "The Hague", Lat = 52.0705, Lng = 4.3007, Description = "Political capital" }
            },
            ["AE"] = new List<CityData>
            {
                new CityData { Name = "Dubai", Lat = 25.2048, Lng = 55.2708, Description = "Luxury destination" },
                new CityData { Name = "Abu Dhabi", Lat = 24.4539, Lng = 54.3773, Description = "UAE capital" },
                new CityData { Name = "Sharjah", Lat = 25.3463, Lng = 55.4209, Description = "Cultural capital" }
            },
            ["SA"] = new List<CityData>
            {
                new CityData { Name = "Riyadh", Lat = 24.7136, Lng = 46.6753, Description = "Capital city" },
                new CityData { Name = "Jeddah", Lat = 21.5433, Lng = 39.1728, Description = "Red Sea gateway" },
                new CityData { Name = "Mecca", Lat = 21.3891, Lng = 39.8579, Description = "Holy city" }
            },
            ["QA"] = new List<CityData>
            {
                new CityData { Name = "Doha", Lat = 25.2854, Lng = 51.5310, Description = "Capital city" },
                new CityData { Name = "Al Wakrah", Lat = 25.1648, Lng = 51.6003, Description = "Historic port town" },
                new CityData { Name = "Lusail", Lat = 25.4329, Lng = 51.5085, Description = "Smart city" }
            },
            ["BH"] = new List<CityData>
            {
                new CityData { Name = "Manama", Lat = 26.2285, Lng = 50.5860, Description = "Capital city" },
                new CityData { Name = "Muharraq", Lat = 26.2574, Lng = 50.6119, Description = "Island city" },
                new CityData { Name = "Riffa", Lat = 26.1299, Lng = 50.5550, Description = "Royal residence" }
            }
        };

        // Real developer companies by region
        private readonly Dictionary<string, List<string>> DeveloperCompaniesByRegion = new Dictionary<string, List<string>>
        {
            ["US"] = new List<string> { "Related Companies", "Hines", "Brookfield Properties", "Tishman Speyer", "Boston Properties", "Lennar Corporation", "Toll Brothers", "Pulte Homes" },
            ["CA"] = new List<string> { "Brookfield Properties", "Cadillac Fairview", "Oxford Properties", "Bentall Kennedy", "Concert Properties", "Polygon Homes" },
            ["GB"] = new List<string> { "British Land", "Land Securities", "Canary Wharf Group", "Berkeley Group", "Barratt Developments", "Taylor Wimpey" },
            ["DE"] = new List<string> { "Vonovia", "LEG Immobilien", "Deutsche Wohnen", "TAG Immobilien", "Union Investment", "PATRIZIA" },
            ["FR"] = new List<string> { "Nexity", "Bouygues Immobilier", "Kaufman & Broad", "Vinci Immobilier", "Eiffage Immobilier", "Icade" },
            ["ES"] = new List<string> { "Merlin Properties", "Colonial", "Metrovacesa", "Neinor Homes", "Aedas Homes", "Vía Célere" },
            ["IT"] = new List<string> { "Generali Properties", "Prelios", "IGD", "Risanamento", "Gabetti", "Hines Italia" },
            ["NL"] = new List<string> { "Vesteda", "Bouwinvest", "Syntrus Achmea Real Estate", "CBRE Global Investors", "Amvest" },
            ["AE"] = new List<string> { "Emaar Properties", "Nakheel", "DAMAC Properties", "Aldar Properties", "Meraas", "Sobha Realty", "Azizi Developments", "Deyaar" },
            ["SA"] = new List<string> { "Dar Al Arkan", "Roshn", "Jabal Omar Development", "Emaar The Economic City", "Al Akaria", "Red Sea Global" },
            ["QA"] = new List<string> { "Barwa Real Estate", "Qatari Diar", "UDC", "Ezdan Holding Group", "Aamal Company" },
            ["BH"] = new List<string> { "Edamah", "Diyar Al Muharraq", "Bin Faqeeh", "GFH Financial Group", "Seef Properties" }
        };

        // International person names
        private readonly List<(string First, string Last)> PersonNames = new List<(string, string)>
        {
            ("James", "Anderson"), ("Michael", "Johnson"), ("Robert", "Williams"), ("John", "Brown"), ("David", "Miller"),
            ("William", "Davis"), ("Richard", "Garcia"), ("Joseph", "Rodriguez"), ("Thomas", "Wilson"), ("Charles", "Martinez"),
            ("Christopher", "Taylor"), ("Daniel", "Thomas"), ("Matthew", "Moore"), ("Anthony", "Jackson"), ("Donald", "Martin"),
            ("Mark", "Lee"), ("Paul", "Thompson"), ("Steven", "White"), ("Andrew", "Harris"), ("Kenneth", "Clark"),
            ("Mary", "Anderson"), ("Patricia", "Johnson"), ("Jennifer", "Williams"), ("Linda", "Brown"), ("Barbara", "Miller"),
            ("Elizabeth", "Davis"), ("Susan", "Garcia"), ("Jessica", "Rodriguez"), ("Sarah", "Wilson"), ("Karen", "Martinez"),
            ("Nancy", "Taylor"), ("Lisa", "Thomas"), ("Betty", "Moore"), ("Margaret", "Jackson"), ("Sandra", "Martin"),
            ("Ashley", "Lee"), ("Dorothy", "Thompson"), ("Kimberly", "White"), ("Emily", "Harris"), ("Donna", "Clark"),
            ("Michelle", "Lewis"), ("Carol", "Robinson"), ("Amanda", "Walker"), ("Melissa", "Young"), ("Deborah", "Allen")
        };

        // Unsplash photo IDs
        private readonly string[] UnsplashPropertyIds = new[]
        {
            "1600596542810-ff374b12c26e", "1600566753190-17f0baa2a6c3", "1600585154340-be6161a56a0b",
            "1600607687920-4e2a09cf159d", "1512917774080-9991f1c4c750", "1600566752355-35792bedcfea",
            "1568605114967-8130f3a36994", "1560448204-e02f11c3d0e2", "1564013799919-bc007da7807a",
            "1512915922686-57c11dde9b6b", "1512915922638-c9f7f0ae9d2b", "1600607687644-aac4c5191e0d"
        };

        // Pexels photo IDs
        private readonly string[] PexelsPropertyIds = new[]
        {
            "323780", "323775", "323772", "323776", "323781", "1732414", "1732418", "1732421",
            "2102587", "2102589", "2102590", "3797991", "3797995", "3797996", "5997992", "5997993"
        };

        #endregion

        #region Helper Methods

        private string GetUnsplashUrl(string photoId, int width = 800, int height = 600)
        {
            return $"https://images.unsplash.com/photo-{photoId}?w={width}&h={height}&fit=crop&auto=format&q=80";
        }

        private string GetPexelsUrl(string photoId, int width = 800, int height = 600)
        {
            return $"https://images.pexels.com/photos/{photoId}/pexels-photo-{photoId}.jpeg?auto=compress&cs=tinysrgb&w={width}&h={height}";
        }

        private string GetRandomImageUrl(int width = 800, int height = 600)
        {
            if (_random.Next(2) == 0)
            {
                var photoId = UnsplashPropertyIds[_random.Next(UnsplashPropertyIds.Length)];
                return GetUnsplashUrl(photoId, width, height);
            }
            else
            {
                var photoId = PexelsPropertyIds[_random.Next(PexelsPropertyIds.Length)];
                return GetPexelsUrl(photoId, width, height);
            }
        }

        private CountryData GetRandomCountry()
        {
            return Countries[_random.Next(Countries.Count)];
        }

        private CityData GetRandomCity(string countryCode)
        {
            if (CitiesByCountry.ContainsKey(countryCode))
            {
                var cities = CitiesByCountry[countryCode];
                return cities[_random.Next(cities.Count)];
            }
            return CitiesByCountry["US"][0];
        }

        private string GetRandomDeveloperName(string countryCode)
        {
            if (DeveloperCompaniesByRegion.ContainsKey(countryCode))
            {
                var companies = DeveloperCompaniesByRegion[countryCode];
                return companies[_random.Next(companies.Count)];
            }
            return "Global Properties Development";
        }

        private (string First, string Last) GetRandomPersonName()
        {
            return PersonNames[_random.Next(PersonNames.Count)];
        }

        private string GetPhoneNumber(string countryCode)
        {
            var country = Countries.FirstOrDefault(c => c.Code == countryCode);
            var prefix = country?.CityPrefix ?? "+1";
            var number = _random.Next(100000000, 999999999);
            return $"{prefix}{number}";
        }

        private decimal GetRealisticPrice(string countryCode, PropertyType propertyType, int areaSqm)
        {
            var country = Countries.FirstOrDefault(c => c.Code == countryCode);
            if (country == null) return 500000;

            var basePrice = country.MinPrice + (_random.Next((int)(country.MaxPrice - country.MinPrice)));
            
            var typeMultiplier = propertyType switch
            {
                PropertyType.Villa => 1.5m,
                PropertyType.Penthouse => 1.8m,
                PropertyType.Office => 1.2m,
                PropertyType.Retail => 0.9m,
                _ => 1.0m
            };

            var sizeMultiplier = areaSqm / 100m;
            return Math.Round(basePrice * typeMultiplier * (sizeMultiplier / 10), 0);
        }

        private string GetRandomProjectName(string countryCode, CityData city)
        {
            var prefixes = new[] { "The", "Elite", "Luxury", "Premium", "Grand", "Royal", "Imperial", "Metropolitan" };
            var types = new[] { "Residences", "Towers", "Plaza", "Heights", "Gardens", "District", "Square", "Vista" };
            
            var prefix = prefixes[_random.Next(prefixes.Length)];
            var type = types[_random.Next(types.Length)];
            
            return $"{prefix} {city.Name} {type}";
        }

        #endregion

        #region Pre-Seed Test Method (1/10 Scale)

        public async Task PreSeedTestDataAsync(bool skipClear = false)
        {
            Console.WriteLine("🇪🇬 Starting Egypt-only market seed...");
            Console.WriteLine("================================================");

            // Egypt-only MVP: always reset property market and seed curated Egyptian data.
            // skipClear is kept for API compatibility but non-Egyptian demo data is never seeded.
            _ = skipClear;

            var demoSeeder = new DemoPropertySeedingService(_context);
            var result = await demoSeeder.ResetAndSeedEgyptianMarketAsync();

            Console.WriteLine("\n================================================");
            Console.WriteLine("✅ Egypt-only market seed completed!");
            Console.WriteLine($"   📊 Summary:");
            Console.WriteLine($"   - Developers: {result.Developers}");
            Console.WriteLine($"   - Projects: {result.Projects}");
            Console.WriteLine($"   - Properties: {result.Properties}");
            Console.WriteLine($"   - Images: {result.Images}");
            Console.WriteLine($"   - Auctions: {result.Auctions}");
            Console.WriteLine("================================================\n");
        }

        #endregion

        #region Test Seeding Methods

        private async Task SeedRolesAsync()
        {
            var rolesToAdd = new List<Role>();
            var existingRoleIds = await _context.Roles.Select(r => r.RoleId).ToListAsync();

            var allRoles = new List<Role>
            {
                new Role { RoleId = Role.USER_ROLE_ID, RoleName = "User", Description = "Regular user", CreatedAt = DateTime.UtcNow },
                new Role { RoleId = Role.DEVELOPER_ROLE_ID, RoleName = "Developer", Description = "Property developer", CreatedAt = DateTime.UtcNow },
                new Role { RoleId = Role.ADMIN_ROLE_ID, RoleName = "Admin", Description = "System administrator", CreatedAt = DateTime.UtcNow },
                new Role { RoleId = Role.SALES_ROLE_ID, RoleName = "Sales", Description = "Sales team member", CreatedAt = DateTime.UtcNow }
            };

            foreach (var role in allRoles)
            {
                if (!existingRoleIds.Contains(role.RoleId))
                {
                    rolesToAdd.Add(role);
                }
            }

            if (rolesToAdd.Any())
            {
                await _context.Roles.AddRangeAsync(rolesToAdd);
                await _context.SaveChangesAsync();
                Console.WriteLine($"   ✅ Created {rolesToAdd.Count} roles");
            }
            else
            {
                Console.WriteLine("   ℹ️ All roles already exist, skipping...");
            }
        }

        private async Task<List<AccountBase>> SeedTestAccountsAsync()
        {
            var accounts = new List<AccountBase>();

            // Check existing developers and users
            var existingDevelopers = await _context.Accounts
                .Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID)
                .CountAsync();
            var existingUsers = await _context.Accounts
                .Where(a => a.RoleId == Role.USER_ROLE_ID)
                .CountAsync();

            // Create 2-3 developers (only if we don't have enough)
            var targetDevCount = _random.Next(2, 4);
            var devCount = Math.Max(0, targetDevCount - existingDevelopers);
            
            for (int i = 0; i < devCount; i++)
            {
                var country = GetRandomCountry();
                var (firstName, lastName) = GetRandomPersonName();

                var developer = new DeveloperAccount
                {
                    FirstName = firstName,
                    LastName = lastName,
                    Email = $"{firstName.ToLower()}.{lastName.ToLower()}.dev{i}@company.com",
                    PhoneNumber = GetPhoneNumber(country.Code),
                    RoleId = Role.DEVELOPER_ROLE_ID,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("Dev123!"),
                    Status = VerificationStatus.Verified,
                    EmailVerified = true,
                    PhoneVerified = true,
                    TimeZone = country.Timezone,
                    CreatedAt = DateTime.UtcNow.AddMonths(-_random.Next(6, 36))
                };
                accounts.Add(developer);
            }

            // Create 15 users (only if we don't have enough)
            var targetUserCount = 15;
            var userCount = Math.Max(0, targetUserCount - existingUsers);
            
            for (int i = 0; i < userCount; i++)
            {
                var country = GetRandomCountry();
                var (firstName, lastName) = GetRandomPersonName();

                var user = new UserAccount
                {
                    FirstName = firstName,
                    LastName = lastName,
                    Email = $"{firstName.ToLower()}.{lastName.ToLower()}{i}@email.com",
                    PhoneNumber = GetPhoneNumber(country.Code),
                    RoleId = Role.USER_ROLE_ID,
                    HashedPassword = BCrypt.Net.BCrypt.HashPassword("User123!"),
                    Status = i < 10 ? VerificationStatus.Verified : VerificationStatus.Pending,
                    EmailVerified = i < 10,
                    PhoneVerified = i < 10,
                    TimeZone = country.Timezone,
                    CurrentPoints = _random.Next(0, 5000),
                    TotalEarnedPoints = _random.Next(0, 10000),
                    CreatedAt = DateTime.UtcNow.AddMonths(-_random.Next(1, 24))
                };
                accounts.Add(user);
            }

            if (accounts.Any())
            {
                await _context.Accounts.AddRangeAsync(accounts);
                await _context.SaveChangesAsync();
            }

            // Return all accounts (existing + newly created)
            var allAccounts = await _context.Accounts
                .Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID || a.RoleId == Role.USER_ROLE_ID)
                .ToListAsync();
            return allAccounts;
        }

        private async Task<List<Project>> SeedTestProjectsAsync(List<AccountBase> developers)
        {
            if (developers.Count == 0)
            {
                Console.WriteLine("   ⚠️ No developers available, skipping projects...");
                return await _context.Projects.ToListAsync();
            }

            var existingProjects = await _context.Projects.CountAsync();
            var targetProjectCount = _random.Next(5, 9);
            var projectCount = Math.Max(0, targetProjectCount - existingProjects);

            var projects = new List<Project>();

            for (int i = 0; i < projectCount; i++)
            {
                var developer = developers[_random.Next(developers.Count)];
                var country = GetRandomCountry();
                var city = GetRandomCity(country.Code);

                var project = new Project
                {
                    Name = GetRandomProjectName(country.Code, city),
                    Description = $"A premier development in {city.Name}, {country.Name}. Features state-of-the-art amenities and modern architecture.",
                    Location = $"{city.Name}, {country.Name}",
                    Country = country.Code,
                    IsActive = true,
                    DeveloperId = developer.AccountId,
                    CreatedAt = DateTime.UtcNow.AddMonths(-_random.Next(6, 30))
                };
                projects.Add(project);
            }

            if (projects.Any())
            {
                await _context.Projects.AddRangeAsync(projects);
                await _context.SaveChangesAsync();
            }

            return await _context.Projects.ToListAsync();
        }

        private async Task<List<Property>> SeedTestPropertiesAsync(List<Project> projects)
        {
            if (projects.Count == 0)
            {
                Console.WriteLine("   ⚠️ No projects available, skipping properties...");
                return await _context.Properties.ToListAsync();
            }

            var projectIds = projects.Select(p => p.ProjectId).ToList();
            var existingCount = await _context.Properties
                .Where(p => p.ProjectId.HasValue && projectIds.Contains(p.ProjectId.Value))
                .CountAsync();
            var targetCount = _random.Next(20, 31);
            var remainingCount = Math.Max(0, targetCount - existingCount);

            var properties = new List<Property>();
            var propsPerProject = Math.Max(1, remainingCount / projects.Count);

            foreach (var project in projects)
            {
                if (remainingCount <= 0) break;

                var bedrooms = _random.Next(1, 5);
                var bathrooms = _random.Next(1, 4);
                var areaSqm = _random.Next(80, 300);

                for (int i = 0; i < propsPerProject && properties.Count < remainingCount; i++)
                {
                    var property = new Property
                    {
                        ProjectId = project.ProjectId,
                        ProjectName = project.Name,
                        Name = $"{project.Name} - Unit {i + 1}",
                        Description = $"Beautiful {areaSqm}sqm apartment with {bedrooms} bedrooms",
                        Location = project.Location ?? "Unknown",
                        ImageUrl = GetRandomImageUrl(1200, 800),
                        SquareFeet = (int)(areaSqm * 10.764),
                        YearBuilt = DateTime.UtcNow.Year,
                        Bedrooms = bedrooms,
                        Bathrooms = bathrooms,
                        Type = PropertyType.Apartment,
                        Status = PropertyStatus.Approved,
                        FinishingType = "Finished",
                        HasPool = _random.Next(2) == 1,
                        HasGym = _random.Next(2) == 1,
                        HasSecurity = true,
                        HasParking = true,
                        HasGarden = _random.Next(2) == 1,
                        HasPlayground = _random.Next(2) == 1,
                        FloorNumber = _random.Next(1, 20),
                        UnitNumber = $"{i + 1}0{_random.Next(1, 10)}",
                        Phase = $"Phase {_random.Next(1, 4)}",
                        IsApproved = true,
                        CreatedAt = project.CreatedAt.AddDays(_random.Next(1, 30))
                    };
                    properties.Add(property);
                }
            }

            if (properties.Any())
            {
                await _context.Properties.AddRangeAsync(properties);
                await _context.SaveChangesAsync();
            }

            return await _context.Properties.ToListAsync();
        }

        private async Task SeedTestPropertyImagesAsync(List<Property> properties)
        {
            if (properties.Count == 0)
            {
                Console.WriteLine("   ⚠️ No properties available, skipping images...");
                return;
            }

            var existingImages = await _context.PropertyImages
                .Where(pi => properties.Select(cp => cp.PropertyId).Contains(pi.PropertyId))
                .CountAsync();
            
            // Only add images if properties don't have enough (at least 3 per property)
            var targetImageCount = properties.Count * 5; // Average 5 images per property
            if (existingImages >= targetImageCount)
            {
                Console.WriteLine($"   ℹ️ Properties already have {existingImages} images, skipping...");
                return;
            }

            var images = new List<PropertyImage>();

            foreach (var property in properties)
            {
                // Check if property already has images
                var propertyImageCount = await _context.PropertyImages
                    .Where(pi => pi.PropertyId == property.PropertyId)
                    .CountAsync();
                
                if (propertyImageCount >= 4) continue; // Skip if already has enough images

                var imageCount = Math.Min(4, 8 - propertyImageCount); // Add up to 4 more images
                for (int i = 0; i < imageCount; i++)
                {
                    images.Add(new PropertyImage
                    {
                        PropertyId = property.PropertyId,
                        ImageUrl = GetRandomImageUrl(1200, 900),
                        ImageType = i == 0 ? "Main" : "Gallery",
                        IsMainImage = i == 0,
                        DisplayOrder = i,
                        CreatedAt = property.CreatedAt.AddDays(_random.Next(0, 5))
                    });
                }
            }

            if (images.Any())
            {
                await _context.PropertyImages.AddRangeAsync(images);
                await _context.SaveChangesAsync();
                Console.WriteLine($"   ✅ Created {images.Count} property images");
            }
            else
            {
                Console.WriteLine("   ℹ️ All properties already have images, skipping...");
            }
        }

        private async Task<List<Auction>> SeedTestAuctionsAsync(List<Property> properties)
        {
            if (properties.Count == 0)
            {
                Console.WriteLine("   ⚠️ No properties available, skipping auctions...");
                return await _context.Auctions.ToListAsync();
            }

            var existingAuctions = await _context.Auctions.CountAsync();
            var targetAuctionCount = 10;
            if (existingAuctions >= targetAuctionCount)
            {
                Console.WriteLine($"   ℹ️ Already have {existingAuctions} auctions, skipping...");
                return await _context.Auctions.ToListAsync();
            }

            var availableProps = properties
                .Where(p => p.Status == PropertyStatus.Approved && 
                           !_context.Auctions.Any(a => a.PropertyId == p.PropertyId))
                .Take(targetAuctionCount - existingAuctions)
                .ToList();

            var auctions = new List<Auction>();

            foreach (var property in availableProps)
            {
                var country = Countries.FirstOrDefault(c => property.Location.Contains(c.Name)) ?? GetRandomCountry();
                var areaSqm = property.SquareFeet > 0 ? (int)(property.SquareFeet / 10.764) : 100;
                var basePrice = GetRealisticPrice(country.Code, property.Type, areaSqm);
                var startPrice = basePrice * 0.7m;

                var auction = new Auction
                {
                    PropertyId = property.PropertyId,
                    StartPrice = startPrice,
                    CurrentPrice = startPrice + (startPrice * _random.Next(0, 20) / 100m),
                    StartAt = DateTime.UtcNow.AddDays(-_random.Next(0, 15)),
                    Duration = _random.Next(7, 30) * 24,
                    Status = "Active",
                    BidCount = _random.Next(3, 15),
                    CreatedAt = DateTime.UtcNow.AddDays(-_random.Next(1, 20))
                };
                auctions.Add(auction);
            }

            if (auctions.Any())
            {
                await _context.Auctions.AddRangeAsync(auctions);
                await _context.SaveChangesAsync();
            }

            return await _context.Auctions.ToListAsync();
        }

        private async Task<int> SeedTestBidsAsync(List<Auction> auctions, List<AccountBase> users)
        {
            if (auctions.Count == 0 || users.Count == 0)
            {
                Console.WriteLine("   ⚠️ No auctions or users available, skipping bids...");
                return await _context.Bids.CountAsync();
            }

            var existingBids = await _context.Bids.CountAsync();
            var targetBids = 80;
            var remainingBids = Math.Max(0, targetBids - existingBids);

            if (remainingBids == 0)
            {
                Console.WriteLine($"   ℹ️ Already have {existingBids} bids, skipping...");
                return existingBids;
            }

            var bids = new List<Bid>();
            var bidsPerAuction = Math.Max(1, remainingBids / auctions.Count);

            foreach (var auction in auctions)
            {
                if (remainingBids <= 0) break;
                
                var auctionBidCount = await _context.Bids
                    .Where(b => b.AuctionId == auction.AuctionId)
                    .CountAsync();
                
                var bidCount = Math.Min(bidsPerAuction, remainingBids);
                var currentBid = auction.StartPrice;

                for (int i = 0; i < bidCount; i++)
                {
                    var increment = currentBid * _random.Next(5, 15) / 100m;
                    currentBid += increment;

                    bids.Add(new Bid
                    {
                        AuctionId = auction.AuctionId,
                        BidderId = users[_random.Next(users.Count)].AccountId,
                        BidAmount = currentBid,
                        CreatedAt = auction.StartAt.AddHours(_random.Next(1, auction.Duration))
                    });
                    remainingBids--;
                }
            }

            if (bids.Any())
            {
                await _context.Bids.AddRangeAsync(bids);
                await _context.SaveChangesAsync();
            }

            return await _context.Bids.CountAsync();
        }

        private async Task SeedTestFaqsAsync()
        {
            var existingFaqs = await _context.Faqs.CountAsync();
            if (existingFaqs >= 5)
            {
                Console.WriteLine($"   ℹ️ Already have {existingFaqs} FAQs, skipping...");
                return;
            }

            var allFaqs = new List<Faq>
            {
                new Faq { Question = "How do I participate in auctions?", Answer = "Create an account, complete KYC verification, and start bidding on active auctions.", DisplayOrder = 1, CreatedAt = DateTime.UtcNow },
                new Faq { Question = "What payment methods are accepted?", Answer = "We accept bank transfers, credit cards, and cryptocurrency. All prices are in USD.", DisplayOrder = 2, CreatedAt = DateTime.UtcNow },
                new Faq { Question = "Can I invest from any country?", Answer = "Yes! Our platform supports investors from over 50 countries with cross-border transactions.", DisplayOrder = 3, CreatedAt = DateTime.UtcNow },
                new Faq { Question = "What are the fees?", Answer = "Platform fee is 2% of transaction value. All fees are displayed before bidding.", DisplayOrder = 4, CreatedAt = DateTime.UtcNow },
                new Faq { Question = "How long does KYC take?", Answer = "KYC verification typically takes 24-48 hours after document submission.", DisplayOrder = 5, CreatedAt = DateTime.UtcNow }
            };

            var existingQuestions = await _context.Faqs.Select(f => f.Question).ToListAsync();
            var faqsToAdd = allFaqs.Where(f => !existingQuestions.Contains(f.Question)).ToList();

            if (faqsToAdd.Any())
            {
                await _context.Faqs.AddRangeAsync(faqsToAdd);
                await _context.SaveChangesAsync();
                Console.WriteLine($"   ✅ Created {faqsToAdd.Count} FAQs");
            }
            else
            {
                Console.WriteLine("   ℹ️ All FAQs already exist, skipping...");
            }
        }

        private async Task SeedTestNewsAsync(List<AccountBase> developers)
        {
            if (developers.Count == 0)
            {
                Console.WriteLine("   ⚠️ No developers available, skipping news...");
                return;
            }

            var existingNews = await _context.NewsArticles.CountAsync();
            var targetNewsCount = 8;
            if (existingNews >= targetNewsCount)
            {
                Console.WriteLine($"   ℹ️ Already have {existingNews} news articles, skipping...");
                return;
            }

            var articles = new List<NewsArticle>();
            var remainingCount = targetNewsCount - existingNews;
            
            for (int i = 0; i < remainingCount; i++)
            {
                var dev = developers[_random.Next(developers.Count)];
                var country = GetRandomCountry();
                var city = GetRandomCity(country.Code);

                articles.Add(new NewsArticle
                {
                    Title = $"New Development Launched in {city.Name}",
                    Content = $"Exciting news from {city.Name}, {country.Name}! Our latest project features modern amenities and prime location. Pre-launch offers available.",
                    Category = "Project Launch",
                    PublishedDate = DateTime.UtcNow.AddDays(-_random.Next(1, 30)),
                    IsPublished = true,
                    DeveloperId = dev.AccountId,
                    CreatedAt = DateTime.UtcNow.AddDays(-_random.Next(2, 35))
                });
            }

            if (articles.Any())
            {
                await _context.NewsArticles.AddRangeAsync(articles);
                await _context.SaveChangesAsync();

                var images = new List<NewsImage>();
                foreach (var article in articles)
            {
                for (int i = 0; i < 3; i++)
                {
                    images.Add(new NewsImage
                    {
                        NewsArticleId = article.NewsArticleId,
                        ImageUrl = GetRandomImageUrl(1200, 600),
                        DisplayOrder = i
                    });
                }
            }
                await _context.NewsImages.AddRangeAsync(images);
                await _context.SaveChangesAsync();
                Console.WriteLine($"   ✅ Created {articles.Count} news articles with {images.Count} images");
            }
        }

        private async Task<List<SalesTeam>> SeedTestSalesTeamsAsync(List<AccountBase> developers)
        {
            if (developers.Count == 0)
            {
                Console.WriteLine("   ⚠️ No developers available, skipping sales teams...");
                return await _context.SalesTeams.ToListAsync();
            }

            var existingTeams = await _context.SalesTeams
                .Where(st => developers.Select(d => d.AccountId).Contains(st.DeveloperId))
                .ToListAsync();
            var existingTeamNames = existingTeams.Select(t => t.TeamName).ToList();

            var salesTeams = new List<SalesTeam>();
            var teamNames = new[] { "Premium Sales", "Luxury Division", "International Sales", "VIP Relations", "Corporate Sales" };

            foreach (var developer in developers)
            {
                var developerTeams = existingTeams.Where(t => t.DeveloperId == developer.AccountId).Count();
                var targetTeamCount = _random.Next(1, 3);
                var teamCount = Math.Max(0, targetTeamCount - developerTeams);

                for (int i = 0; i < teamCount; i++)
                {
                    var teamName = teamNames[_random.Next(teamNames.Length)];
                    var uniqueTeamName = $"{teamName} - {developer.FirstName} {developer.LastName}";
                    
                    // Check if this exact team name already exists for this developer
                    if (existingTeamNames.Contains(uniqueTeamName))
                        continue;
                    
                    var team = new SalesTeam
                    {
                        TeamId = Guid.NewGuid(),
                        TeamName = uniqueTeamName,
                        DeveloperId = developer.AccountId,
                        CreatedAt = developer.CreatedAt.AddDays(_random.Next(1, 30))
                    };
                    salesTeams.Add(team);
                    existingTeamNames.Add(uniqueTeamName);
                }
            }

            if (salesTeams.Any())
            {
                await _context.SalesTeams.AddRangeAsync(salesTeams);
                await _context.SaveChangesAsync();
            }

            return await _context.SalesTeams.ToListAsync();
        }

        private async Task<List<SalesAccount>> SeedTestSalesAccountsAsync(List<AccountBase> developers, List<SalesTeam> salesTeams)
        {
            if (developers.Count == 0 || salesTeams.Count == 0)
            {
                Console.WriteLine("   ⚠️ No developers or sales teams available, skipping sales accounts...");
                return await _context.SalesAccounts.ToListAsync();
            }

            var existingSalesAccounts = await _context.SalesAccounts.CountAsync();
            var targetCount = 6; // 5-6 sales accounts as requested
            if (existingSalesAccounts >= targetCount)
            {
                Console.WriteLine($"   ℹ️ Already have {existingSalesAccounts} sales accounts, skipping...");
                return await _context.SalesAccounts.ToListAsync();
            }

            var salesAccounts = new List<SalesAccount>();
            var remainingCount = targetCount - existingSalesAccounts;
            var salesPerDeveloper = Math.Max(1, remainingCount / developers.Count);

            foreach (var developer in developers)
            {
                if (remainingCount <= 0) break;
                var developerTeams = salesTeams.Where(t => t.DeveloperId == developer.AccountId).ToList();
                if (developerTeams.Count == 0) continue;

                var salesCount = Math.Min(salesPerDeveloper, remainingCount);
                for (int i = 0; i < salesCount && remainingCount > 0; i++)
                {
                    var country = GetRandomCountry();
                    var (firstName, lastName) = GetRandomPersonName();
                    var team = developerTeams[_random.Next(developerTeams.Count)];

                    var salesAccount = new SalesAccount
                    {
                        FirstName = firstName,
                        LastName = lastName,
                        Email = $"{firstName.ToLower()}.{lastName.ToLower()}.sales{i}@{developer.Email.Split('@')[1]}",
                        PhoneNumber = GetPhoneNumber(country.Code),
                        RoleId = Role.SALES_ROLE_ID,
                        HashedPassword = BCrypt.Net.BCrypt.HashPassword("Sales123!"),
                        Status = VerificationStatus.Verified,
                        EmailVerified = true,
                        PhoneVerified = true,
                        AssignedDeveloperId = developer.AccountId,
                        SalesTeamId = team.TeamId,
                        TimeZone = country.Timezone,
                        CreatedAt = team.CreatedAt.AddDays(_random.Next(1, 15))
                    };
                    salesAccounts.Add(salesAccount);
                    remainingCount--;
                }
            }

            if (salesAccounts.Any())
            {
                await _context.SalesAccounts.AddRangeAsync(salesAccounts);
                await _context.SaveChangesAsync();
            }

            return await _context.SalesAccounts.ToListAsync();
        }

        private async Task SeedTestDeveloperPermissionsAsync(List<AccountBase> developers)
        {
            if (developers.Count == 0)
            {
                Console.WriteLine("   ⚠️ No developers available, skipping permissions...");
                return;
            }

            var existingPermissions = await _context.DeveloperPermissions
                .Where(dp => developers.Select(d => d.AccountId).Contains(dp.DeveloperId))
                .Select(dp => new { dp.DeveloperId, dp.FeatureName })
                .ToListAsync();

            var permissions = new List<DeveloperPermission>();
            var features = new[] { "Projects", "Properties", "Analytics", "News", "Auctions", "Leaderboard", "Notifications", "PriceHistory", "FullAnalytics", "Rewards", "Valuation", "Chats" };

            foreach (var developer in developers)
            {
                // All developers get basic features enabled
                var basicFeatures = new[] { "Projects", "Properties", "Analytics" };
                foreach (var feature in basicFeatures)
                {
                    var exists = existingPermissions.Any(ep => ep.DeveloperId == developer.AccountId && ep.FeatureName == feature);
                    if (!exists)
                    {
                        permissions.Add(new DeveloperPermission
                        {
                            DeveloperId = developer.AccountId,
                            FeatureName = feature,
                            IsEnabled = true,
                            CreatedAt = developer.CreatedAt
                        });
                    }
                }

                // Random additional features enabled
                var additionalFeatures = features.Except(basicFeatures).OrderBy(x => _random.Next()).Take(_random.Next(3, 7));
                foreach (var feature in additionalFeatures)
                {
                    var exists = existingPermissions.Any(ep => ep.DeveloperId == developer.AccountId && ep.FeatureName == feature);
                    if (!exists)
                    {
                        permissions.Add(new DeveloperPermission
                        {
                            DeveloperId = developer.AccountId,
                            FeatureName = feature,
                            IsEnabled = _random.Next(2) == 1, // 50% chance enabled
                            CreatedAt = developer.CreatedAt.AddDays(_random.Next(1, 10))
                        });
                    }
                }
            }

            if (permissions.Any())
            {
                await _context.DeveloperPermissions.AddRangeAsync(permissions);
                await _context.SaveChangesAsync();
            }
        }

        private async Task<int> SeedTestDeveloperRatingsAsync(List<AccountBase> developers, List<AccountBase> users)
        {
            if (developers.Count == 0 || users.Count == 0)
            {
                Console.WriteLine("   ⚠️ No developers or users available, skipping ratings...");
                return await _context.DeveloperRatings.CountAsync();
            }

            var existingRatings = await _context.DeveloperRatings.CountAsync();
            var targetRatings = 10;
            if (existingRatings >= targetRatings)
            {
                Console.WriteLine($"   ℹ️ Already have {existingRatings} ratings, skipping...");
                return existingRatings;
            }

            var ratings = new List<DeveloperRating>();
            var remainingRatings = targetRatings - existingRatings;

            for (int i = 0; i < remainingRatings; i++)
            {
                var developer = developers[_random.Next(developers.Count)];
                var user = users[_random.Next(users.Count)];

                var rating = new DeveloperRating
                {
                    DeveloperId = developer.AccountId,
                    UserId = user.AccountId,
                    Rating = _random.Next(3, 6), // 3-5 stars
                    Comment = new[] { 
                        "Great communication and service!", 
                        "Professional and responsive team.",
                        "Excellent property quality.",
                        "Smooth transaction process.",
                        "Highly recommended developer.",
                        "Outstanding customer support."
                    }[_random.Next(6)],
                    RatingType = _random.Next(2) == 0 ? RatingType.Chat : RatingType.Purchase,
                    CreatedAt = DateTime.UtcNow.AddDays(-_random.Next(1, 90))
                };
                ratings.Add(rating);
            }

            if (ratings.Any())
            {
                await _context.DeveloperRatings.AddRangeAsync(ratings);
                await _context.SaveChangesAsync();
            }

            return await _context.DeveloperRatings.CountAsync();
        }

        private async Task SeedTestDeveloperProfilesAsync(List<AccountBase> developers)
        {
            if (developers.Count == 0)
            {
                Console.WriteLine("   ⚠️ No developers available, skipping profiles...");
                return;
            }

            var existingProfiles = await _context.DeveloperProfiles
                .Where(dp => developers.Select(d => d.AccountId).Contains(dp.AccountId))
                .Select(dp => dp.AccountId)
                .ToListAsync();

            var profiles = new List<DeveloperProfile>();

            foreach (var developer in developers)
            {
                // Skip if profile already exists
                if (existingProfiles.Contains(developer.AccountId))
                    continue;

                var country = GetRandomCountry();
                var companyName = GetRandomDeveloperName(country.Code);

                var profile = new DeveloperProfile
                {
                    ProfileId = Guid.NewGuid(),
                    AccountId = developer.AccountId,
                    CompanyName = companyName,
                    Bio = $"Leading real estate developer specializing in premium properties across {country.Name}. With years of experience, we deliver exceptional quality and innovative designs.",
                    ProfileImageUrl = GetRandomImageUrl(400, 400),
                    Rating = (decimal)(_random.Next(35, 50) / 10.0), // 3.5 - 5.0 rating
                    TotalRatings = _random.Next(10, 50),
                    PortfolioDescription = $"Our portfolio includes luxury residential and commercial developments in prime locations. We focus on sustainable design and modern amenities.",
                    CreatedAt = developer.CreatedAt,
                    UpdatedAt = DateTime.UtcNow.AddDays(-_random.Next(1, 30))
                };
                profiles.Add(profile);
            }

            if (profiles.Any())
            {
                await _context.DeveloperProfiles.AddRangeAsync(profiles);
                await _context.SaveChangesAsync();
            }
        }

        private async Task<int> SeedPropertyPriceHistoryAsync(List<Property> properties, List<Auction> auctions)
        {
            if (properties.Count == 0)
            {
                Console.WriteLine("   ⚠️ No properties available, skipping price history...");
                return 0;
            }

            var existingHistory = await _context.PropertyPriceHistories
                .Select(ph => ph.PropertyId)
                .Distinct()
                .ToListAsync();

            var priceHistories = new List<PropertyPriceHistory>();
            var now = DateTime.UtcNow;

            foreach (var property in properties)
            {
                if (existingHistory.Contains(property.PropertyId))
                    continue;

                var monthsToGenerate = 18;
                var basePrice = properties.IndexOf(property) % 2 == 0
                    ? 500000m + (_random.Next(0, 500000))
                    : 800000m + (_random.Next(0, 700000));

                for (int i = monthsToGenerate; i >= 0; i--)
                {
                    var priceDate = now.AddMonths(-i);
                    
                    var monthVariation = (decimal)(_random.Next(-5, 15)) / 100m;
                    var trendFactor = 1.0m + (decimal)(monthsToGenerate - i) * 0.01m;
                    var price = basePrice * (1.0m + monthVariation) * trendFactor;
                    
                    price = Math.Max(price, basePrice * 0.7m);
                    price = Math.Min(price, basePrice * 1.5m);

                    var source = i % 3 == 0 ? PriceSource.AuctionWin 
                        : i % 3 == 1 ? PriceSource.Listing 
                        : PriceSource.DirectSale;

                    var priceHistory = new PropertyPriceHistory
                    {
                        PriceHistoryId = Guid.NewGuid(),
                        PropertyId = property.PropertyId,
                        Price = Math.Round(price, 2),
                        PriceDate = priceDate,
                        Source = source,
                        CreatedAt = now.AddMonths(-i)
                    };

                    if (source == PriceSource.AuctionWin && auctions.Any())
                    {
                        var relatedAuction = auctions
                            .FirstOrDefault(a => a.PropertyId == property.PropertyId);
                        if (relatedAuction != null)
                        {
                            priceHistory.AuctionId = relatedAuction.AuctionId;
                        }
                    }

                    priceHistories.Add(priceHistory);
                }
            }

            if (priceHistories.Any())
            {
                await _context.PropertyPriceHistories.AddRangeAsync(priceHistories);
                await _context.SaveChangesAsync();
            }

            return priceHistories.Count;
        }

        private async Task<int> SeedGoldPriceAsync()
        {
            var existingGoldPrices = await _context.GoldPrices
                .Select(gp => new { gp.Year, gp.Month })
                .ToListAsync();

            var goldPrices = new List<GoldPrice>();
            var now = DateTime.UtcNow;
            var basePricePerGram = 2000m; // Base price in EGP per gram

            // Generate gold prices for the last 24 months
            for (int i = 24; i >= 0; i--)
            {
                var priceDate = now.AddMonths(-i);
                var year = priceDate.Year;
                var month = priceDate.Month;

                // Skip if already exists
                if (existingGoldPrices.Any(gp => gp.Year == year && gp.Month == month))
                    continue;

                // Create realistic gold price trend with variations
                var monthVariation = (decimal)(_random.Next(-3, 8)) / 100m; // -3% to +8% variation
                var trendFactor = 1.0m + (decimal)(24 - i) * 0.008m; // Slight upward trend over time
                var pricePerGram = basePricePerGram * (1.0m + monthVariation) * trendFactor;
                
                // Ensure price is positive and reasonable (between 1800 and 2500 EGP per gram)
                pricePerGram = Math.Max(pricePerGram, 1800m);
                pricePerGram = Math.Min(pricePerGram, 2500m);

                var goldPrice = new GoldPrice
                {
                    GoldPriceId = Guid.NewGuid(),
                    PricePerGram = Math.Round(pricePerGram, 2),
                    Year = year,
                    Month = month,
                    Date = new DateTime(year, month, 1),
                    Source = GoldPriceSource.Manual,
                    CreatedAt = priceDate,
                    UpdatedAt = priceDate
                };

                goldPrices.Add(goldPrice);
            }

            if (goldPrices.Any())
            {
                await _context.GoldPrices.AddRangeAsync(goldPrices);
                await _context.SaveChangesAsync();
            }

            return goldPrices.Count;
        }

        private async Task<int> SeedTestLiveStreamsAsync(List<AccountBase> developers)
        {
            if (developers.Count == 0)
            {
                Console.WriteLine("   ⚠️ No developers available, skipping live streams...");
                return 0;
            }

            var existingStreams = await _context.LiveStreams
                .Select(s => s.StreamId)
                .ToListAsync();

            var liveStreams = new List<LiveStream>();
            var now = DateTime.UtcNow;

            // Create 2-3 live streams for demo
            var streamTitles = new[]
            {
                "Exclusive Property Tour - New Cairo Development",
                "Live Q&A: Investment Opportunities in Dubai",
                "Virtual Property Showcase - Luxury Apartments"
            };

            var streamDescriptions = new[]
            {
                "Join us for an exclusive tour of our latest development project in New Cairo. See the properties, amenities, and ask questions in real-time!",
                "Get expert insights on the best investment opportunities in Dubai's real estate market. Ask our team anything!",
                "Experience luxury living with our virtual property showcase. See stunning apartments with premium finishes and world-class amenities."
            };

            var streamUrls = new[]
            {
                "https://example.com/stream/new-cairo-tour",
                "https://example.com/stream/dubai-investment-qa",
                "https://example.com/stream/luxury-apartments"
            };

            var thumbnailUrls = new[]
            {
                "https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800",
                "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800",
                "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800"
            };

            for (int i = 0; i < Math.Min(3, developers.Count); i++)
            {
                var developer = developers[i];
                var streamId = Guid.NewGuid();

                // Skip if already exists
                if (existingStreams.Contains(streamId))
                    continue;

                var startTime = now.AddHours(-_random.Next(0, 2)); // Started 0-2 hours ago
                var viewerCount = _random.Next(50, 500); // Random viewer count

                var stream = new LiveStream
                {
                    StreamId = streamId,
                    DeveloperId = developer.AccountId,
                    Title = streamTitles[i % streamTitles.Length],
                    Description = streamDescriptions[i % streamDescriptions.Length],
                    StreamUrl = streamUrls[i % streamUrls.Length],
                    ThumbnailUrl = thumbnailUrls[i % thumbnailUrls.Length],
                    Status = "Live",
                    ViewerCount = viewerCount,
                    StartTime = startTime,
                    EndTime = null,
                    CreatedAt = startTime
                };

                liveStreams.Add(stream);
            }

            if (liveStreams.Any())
            {
                await _context.LiveStreams.AddRangeAsync(liveStreams);
                await _context.SaveChangesAsync();
            }

            return liveStreams.Count;
        }

        private async Task ClearAllDataAsync()
        {
            _context.PropertyPriceHistories.RemoveRange(_context.PropertyPriceHistories);
            _context.GoldPrices.RemoveRange(_context.GoldPrices);
            _context.StreamChatMessages.RemoveRange(_context.StreamChatMessages);
            _context.StreamViewers.RemoveRange(_context.StreamViewers);
            _context.LiveStreams.RemoveRange(_context.LiveStreams);
            _context.DeveloperRatings.RemoveRange(_context.DeveloperRatings);
            _context.DeveloperPermissions.RemoveRange(_context.DeveloperPermissions);
            _context.DeveloperProfiles.RemoveRange(_context.DeveloperProfiles);
            _context.SalesAccounts.RemoveRange(_context.SalesAccounts);
            _context.SalesTeams.RemoveRange(_context.SalesTeams);
            _context.NewsImages.RemoveRange(_context.NewsImages);
            _context.NewsArticles.RemoveRange(_context.NewsArticles);
            _context.Bids.RemoveRange(_context.Bids);
            _context.Auctions.RemoveRange(_context.Auctions);
            _context.PropertyImages.RemoveRange(_context.PropertyImages);
            _context.Properties.RemoveRange(_context.Properties);
            _context.Projects.RemoveRange(_context.Projects);
            _context.Faqs.RemoveRange(_context.Faqs);
            _context.Accounts.RemoveRange(_context.Accounts);

            await _context.SaveChangesAsync();
            Console.WriteLine("   ✅ Data cleared successfully");
        }

        #endregion

        #region Helper Classes

        public class CountryData
        {
            public string Code { get; set; } = string.Empty;
            public string Name { get; set; } = string.Empty;
            public string Currency { get; set; } = string.Empty;
            public string Timezone { get; set; } = string.Empty;
            public decimal MinPrice { get; set; }
            public decimal MaxPrice { get; set; }
            public string CityPrefix { get; set; } = string.Empty;
        }

        public class CityData
        {
            public string Name { get; set; } = string.Empty;
            public double Lat { get; set; }
            public double Lng { get; set; }
            public string Description { get; set; } = string.Empty;
        }

        #endregion
    }
}
