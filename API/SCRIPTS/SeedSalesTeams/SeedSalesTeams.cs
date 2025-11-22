using System;
using Npgsql;
using System.Linq;

class SeedSalesTeams
{
    static void Main()
    {
        // Get connection string from environment or use default
        string? databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");
        string connectionString;
        
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
                connectionString = $"Host={host};Port={port};Database={database};Username={username};Password={password};SslMode=Require";
                Console.WriteLine($"🗄️ Using PostgreSQL from DATABASE_URL: {host}:{port}/{database}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to parse DATABASE_URL: {ex.Message}");
                connectionString = "Host=metro.proxy.rlwy.net;Port=11995;Database=railway;Username=postgres;Password=HBTSCgKSqPkVINVjFCYYZRvXLMgpSiSD;SslMode=Require";
                Console.WriteLine($"⚠️ Falling back to default connection string");
            }
        }
        else
        {
            connectionString = "Host=metro.proxy.rlwy.net;Port=11995;Database=railway;Username=postgres;Password=HBTSCgKSqPkVINVjFCYYZRvXLMgpSiSD;SslMode=Require";
            Console.WriteLine($"🗄️ Using default PostgreSQL connection string");
        }
        
        long DEVELOPER_ROLE_ID = 7823647823647823L;
        long SALES_ROLE_ID = 6723546723546723L;
        
        Console.WriteLine("🌱 Starting Sales Teams Seeding...");
        
        try
        {
            using (var conn = new NpgsqlConnection(connectionString))
            {
                conn.Open();
                Console.WriteLine("✅ Connected to database");
                
                // Check if SalesTeams table exists
                using (var cmd = new NpgsqlCommand())
                {
                    cmd.Connection = conn;
                    cmd.CommandText = @"
                        SELECT EXISTS (
                            SELECT 1 FROM information_schema.tables 
                            WHERE table_name = 'SalesTeams'
                        );
                    ";
                    var tableExists = (bool)cmd.ExecuteScalar()!;
                    
                    if (!tableExists)
                    {
                        Console.WriteLine("❌ SalesTeams table does not exist. Please run migrations first.");
                        Console.WriteLine("   Run: dotnet ef database update");
                        return;
                    }
                    Console.WriteLine("✅ SalesTeams table exists");
                }
                
                // Get all developers
                var developers = new System.Collections.Generic.List<(long AccountId, string FirstName, string LastName)>();
                using (var cmd = new NpgsqlCommand())
                {
                    cmd.Connection = conn;
                    cmd.CommandText = @"
                        SELECT ""AccountId"", ""FirstName"", ""LastName""
                        FROM ""Accounts""
                        WHERE ""RoleId"" = @roleId;
                    ";
                    cmd.Parameters.AddWithValue("@roleId", DEVELOPER_ROLE_ID);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            developers.Add((
                                reader.GetInt64(0),
                                reader.GetString(1),
                                reader.GetString(2)
                            ));
                        }
                    }
                }
                
                Console.WriteLine($"📊 Found {developers.Count} developers");
                
                if (developers.Count == 0)
                {
                    Console.WriteLine("⚠️ No developers found. Cannot create teams.");
                    return;
                }
                
                // Get all sales accounts
                var salesAccounts = new System.Collections.Generic.List<(long AccountId, long? AssignedDeveloperId, long? SalesTeamId)>();
                using (var cmd = new NpgsqlCommand())
                {
                    cmd.Connection = conn;
                    cmd.CommandText = @"
                        SELECT ""AccountId"", ""AssignedDeveloperId"", ""SalesTeamId""
                        FROM ""Accounts""
                        WHERE ""RoleId"" = @roleId;
                    ";
                    cmd.Parameters.AddWithValue("@roleId", SALES_ROLE_ID);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            salesAccounts.Add((
                                reader.GetInt64(0),
                                reader.IsDBNull(1) ? (long?)null : reader.GetInt64(1),
                                reader.IsDBNull(2) ? (long?)null : reader.GetInt64(2)
                            ));
                        }
                    }
                }
                
                Console.WriteLine($"👥 Found {salesAccounts.Count} sales accounts");
                
                int teamsCreated = 0;
                int salesAssigned = 0;
                
                // Create teams for each developer and assign sales accounts
                foreach (var developer in developers)
                {
                    // Check if developer already has teams
                    int existingTeamCount = 0;
                    long? firstTeamId = null;
                    using (var cmd = new NpgsqlCommand())
                    {
                        cmd.Connection = conn;
                        cmd.CommandText = @"
                            SELECT ""TeamId""
                            FROM ""SalesTeams""
                            WHERE ""DeveloperId"" = @developerId
                            ORDER BY ""CreatedAt""
                            LIMIT 1;
                        ";
                        cmd.Parameters.AddWithValue("@developerId", developer.AccountId);
                        var result = cmd.ExecuteScalar();
                        if (result != null && result != DBNull.Value)
                        {
                            firstTeamId = (long)result;
                            existingTeamCount = 1;
                        }
                    }
                    
                    if (existingTeamCount > 0 && firstTeamId.HasValue)
                    {
                        Console.WriteLine($"ℹ️ Developer {developer.FirstName} {developer.LastName} already has team(s). Assigning unassigned sales...");
                        
                        // Assign unassigned sales accounts to first team
                        var unassignedSales = salesAccounts
                            .Where(s => s.AssignedDeveloperId == developer.AccountId && s.SalesTeamId == null)
                            .ToList();
                        
                        foreach (var sales in unassignedSales)
                        {
                            using (var cmd = new NpgsqlCommand())
                            {
                                cmd.Connection = conn;
                                cmd.CommandText = @"
                                    UPDATE ""Accounts""
                                    SET ""SalesTeamId"" = @teamId
                                    WHERE ""AccountId"" = @accountId
                                    AND ""SalesTeamId"" IS NULL;
                                ";
                                cmd.Parameters.AddWithValue("@teamId", firstTeamId.Value);
                                cmd.Parameters.AddWithValue("@accountId", sales.AccountId);
                                var rowsAffected = cmd.ExecuteNonQuery();
                                if (rowsAffected > 0)
                                {
                                    salesAssigned++;
                                }
                            }
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
                        using (var cmd = new NpgsqlCommand())
                        {
                            cmd.Connection = conn;
                            cmd.CommandText = @"
                                INSERT INTO ""SalesTeams"" (""TeamName"", ""DeveloperId"", ""CreatedAt"")
                                VALUES (@teamName, @developerId, NOW())
                                RETURNING ""TeamId"";
                            ";
                            cmd.Parameters.AddWithValue("@teamName", "Sales Team 1");
                            cmd.Parameters.AddWithValue("@developerId", developer.AccountId);
                            var teamId = (long)cmd.ExecuteScalar()!;
                            teamsCreated++;
                            Console.WriteLine($"✅ Created default team for {developer.FirstName} {developer.LastName} (no sales accounts yet)");
                        }
                        continue;
                    }
                    
                    // Create teams based on sales account count
                    // If <= 5 sales accounts, create 1 team
                    // If > 5, create multiple teams with ~5 members each
                    int teamCount = developerSales.Count <= 5 ? 1 : (int)Math.Ceiling(developerSales.Count / 5.0);
                    
                    for (int i = 0; i < teamCount; i++)
                    {
                        long teamId;
                        using (var cmd = new NpgsqlCommand())
                        {
                            cmd.Connection = conn;
                            cmd.CommandText = @"
                                INSERT INTO ""SalesTeams"" (""TeamName"", ""DeveloperId"", ""CreatedAt"")
                                VALUES (@teamName, @developerId, NOW())
                                RETURNING ""TeamId"";
                            ";
                            cmd.Parameters.AddWithValue("@teamName", $"Sales Team {i + 1}");
                            cmd.Parameters.AddWithValue("@developerId", developer.AccountId);
                            teamId = (long)cmd.ExecuteScalar()!;
                            teamsCreated++;
                        }
                        
                        // Assign sales accounts to this team (5 per team)
                        var teamSales = developerSales.Skip(i * 5).Take(5).ToList();
                        foreach (var sales in teamSales)
                        {
                            using (var cmd = new NpgsqlCommand())
                            {
                                cmd.Connection = conn;
                                cmd.CommandText = @"
                                    UPDATE ""Accounts""
                                    SET ""SalesTeamId"" = @teamId
                                    WHERE ""AccountId"" = @accountId;
                                ";
                                cmd.Parameters.AddWithValue("@teamId", teamId);
                                cmd.Parameters.AddWithValue("@accountId", sales.AccountId);
                                cmd.ExecuteNonQuery();
                                salesAssigned++;
                            }
                        }
                        
                        Console.WriteLine($"✅ Created Sales Team {i + 1} for {developer.FirstName} {developer.LastName} with {teamSales.Count} members");
                    }
                }
                
                Console.WriteLine("\n📊 Seeding Summary:");
                Console.WriteLine($"   ✅ Teams created: {teamsCreated}");
                Console.WriteLine($"   ✅ Sales accounts assigned: {salesAssigned}");
                Console.WriteLine($"\n🎉 Sales Teams seeding completed successfully!");
            }
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

