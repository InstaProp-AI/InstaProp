using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Npgsql;
using InstapropAPI.Data;
using InstapropAPI.Models;

namespace InstapropAPI.SCRIPTS.SeedSalesTeams
{
    class Program
    {
        static async Task Main(string[] args)
        {
            Console.WriteLine("🌱 Starting Sales Teams Seeding...");

            // Load configuration
            var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
                .AddEnvironmentVariables()
                .Build();

            // Get connection string
            var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");
            var connectionString = configuration.GetConnectionString("DefaultConnection");

            string finalConnectionString;
            if (!string.IsNullOrEmpty(databaseUrl))
            {
                try
                {
                    var uri = new Uri(databaseUrl);
                    var host = uri.Host;
                    var port = uri.Port > 0 ? uri.Port : 5432;
                    var database = uri.LocalPath.TrimStart('/');
                    var username = !string.IsNullOrEmpty(uri.UserInfo) ? uri.UserInfo.Split(':')[0] : "";
                    var password = !string.IsNullOrEmpty(uri.UserInfo) && uri.UserInfo.Split(':').Length > 1
                        ? uri.UserInfo.Split(':')[1] : "";

                    finalConnectionString = $"Host={host};Port={port};Database={database};Username={username};Password={password};SslMode=Require";
                    Console.WriteLine($"🗄️ Using PostgreSQL from DATABASE_URL: {host}:{port}/{database}");
                }
                catch (Exception ex)
                {
                    throw new Exception($"CRITICAL: Failed to parse DATABASE_URL environment variable. Error: {ex.Message}");
                }
            }
            else if (!string.IsNullOrEmpty(connectionString) && connectionString.Contains("Host="))
            {
                finalConnectionString = connectionString;
                Console.WriteLine($"🗄️ Using PostgreSQL from connection string");
            }
            else
            {
                throw new Exception("CRITICAL: No database connection configured. Set DATABASE_URL environment variable or configure PostgreSQL connection string in appsettings.json");
            }

            // Setup DbContext
            var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
            optionsBuilder.UseNpgsql(finalConnectionString);

            using var context = new AppDbContext(optionsBuilder.Options);

            try
            {
                // Test connection and check if SalesTeams table exists
                try
                {
                    await context.Database.ExecuteSqlRawAsync("SELECT 1 FROM \"SalesTeams\" LIMIT 1");
                    Console.WriteLine("✅ SalesTeams table exists");
                }
                catch
                {
                    Console.WriteLine("❌ SalesTeams table does not exist. Please run migrations first.");
                    Console.WriteLine("   Run: dotnet ef database update");
                    return;
                }

                // Get all developers
                var developers = await context.Accounts
                    .Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID)
                    .ToListAsync();

                Console.WriteLine($"📊 Found {developers.Count} developers");

                if (developers.Count == 0)
                {
                    Console.WriteLine("⚠️ No developers found. Cannot create teams.");
                    return;
                }

                // Get all sales accounts
                var salesAccounts = await context.Accounts
                    .Where(a => a.RoleId == Role.SALES_ROLE_ID)
                    .ToListAsync();

                Console.WriteLine($"👥 Found {salesAccounts.Count} sales accounts");

                int teamsCreated = 0;
                int salesAssigned = 0;

                // Create teams for each developer and assign sales accounts
                foreach (var developer in developers)
                {
                    // Check if developer already has teams
                    var existingTeams = await context.SalesTeams
                        .Where(t => t.DeveloperId == developer.AccountId)
                        .ToListAsync();

                    if (existingTeams.Any())
                    {
                        Console.WriteLine($"ℹ️ Developer {developer.FirstName} {developer.LastName} already has {existingTeams.Count} team(s). Skipping...");
                        
                        // Assign unassigned sales accounts to first team
                        var firstTeam = existingTeams.First();
                        var unassignedSales = salesAccounts
                            .Where(s => s.AssignedDeveloperId == developer.AccountId && s.SalesTeamId == null)
                            .ToList();

                        foreach (var sales in unassignedSales)
                        {
                            sales.SalesTeamId = firstTeam.TeamId;
                            salesAssigned++;
                        }

                        continue;
                    }

                    // Get sales accounts assigned to this developer
                    var developerSales = salesAccounts
                        .Where(s => s.AssignedDeveloperId == developer.AccountId)
                        .ToList();

                    if (developerSales.Count == 0)
                    {
                        // Create a default team even if no sales accounts
                        var defaultTeam = new SalesTeam
                        {
                            TeamName = $"Sales Team 1",
                            DeveloperId = developer.AccountId,
                            CreatedAt = DateTime.UtcNow
                        };
                        context.SalesTeams.Add(defaultTeam);
                        await context.SaveChangesAsync();
                        teamsCreated++;
                        Console.WriteLine($"✅ Created default team for {developer.FirstName} {developer.LastName} (no sales accounts yet)");
                        continue;
                    }

                    // Create teams based on sales account count
                    // If <= 5 sales accounts, create 1 team
                    // If > 5, create multiple teams with ~5 members each
                    int teamCount = developerSales.Count <= 5 ? 1 : (int)Math.Ceiling(developerSales.Count / 5.0);

                    for (int i = 0; i < teamCount; i++)
                    {
                        var team = new SalesTeam
                        {
                            TeamName = $"Sales Team {i + 1}",
                            DeveloperId = developer.AccountId,
                            CreatedAt = DateTime.UtcNow
                        };
                        context.SalesTeams.Add(team);
                        await context.SaveChangesAsync(); // Save to get TeamId
                        teamsCreated++;

                        // Assign sales accounts to this team (5 per team)
                        var teamSales = developerSales.Skip(i * 5).Take(5).ToList();
                        foreach (var sales in teamSales)
                        {
                            sales.SalesTeamId = team.TeamId;
                            salesAssigned++;
                        }

                        Console.WriteLine($"✅ Created {team.TeamName} for {developer.FirstName} {developer.LastName} with {teamSales.Count} members");
                    }
                }

                // Save all changes
                await context.SaveChangesAsync();

                Console.WriteLine("\n📊 Seeding Summary:");
                Console.WriteLine($"   ✅ Teams created: {teamsCreated}");
                Console.WriteLine($"   ✅ Sales accounts assigned: {salesAssigned}");
                Console.WriteLine($"\n🎉 Sales Teams seeding completed successfully!");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"\n❌ Error during seeding: {ex.Message}");
                Console.WriteLine($"   Stack trace: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"   Inner exception: {ex.InnerException.Message}");
                }
                throw;
            }
        }
    }
}

