using System;
using BCrypt.Net;
using Npgsql;

class CreateAdminAccount
{
    static void Main()
    {
        // Database connection string
        string connectionString = "Host=metro.proxy.rlwy.net;Port=11995;Database=railway;Username=postgres;Password=HBTSCgKSqPkVINVjFCYYZRvXLMgpSiSD;SslMode=Require";
        
        // Admin account details
        string email = "admin@propertyflipper.com";
        string password = "Admin123!";
        string firstName = "Admin";
        string lastName = "User";
        string phoneNumber = "+1234567890";
        long adminRoleId = 9823749823749823L; // Admin Role ID
        
        // Generate BCrypt hash
        string hashedPassword = BCrypt.Net.BCrypt.HashPassword(password);
        Console.WriteLine($"Generated password hash: {hashedPassword}");
        
        try
        {
            using (var conn = new NpgsqlConnection(connectionString))
            {
                conn.Open();
                Console.WriteLine("✅ Connected to database");
                
                // Ensure Admin role exists
                using (var cmd = new NpgsqlCommand())
                {
                    cmd.Connection = conn;
                    cmd.CommandText = @"
                        INSERT INTO ""Roles"" (""RoleId"", ""RoleName"", ""Description"", ""CreatedAt"")
                        VALUES (@roleId, @roleName, @description, NOW())
                        ON CONFLICT (""RoleId"") DO NOTHING;
                    ";
                    cmd.Parameters.AddWithValue("@roleId", adminRoleId);
                    cmd.Parameters.AddWithValue("@roleName", "Admin");
                    cmd.Parameters.AddWithValue("@description", "Administrator account with full system access");
                    cmd.ExecuteNonQuery();
                    Console.WriteLine("✅ Admin role ensured");
                }
                
                // Check if account already exists
                bool accountExists = false;
                using (var cmd = new NpgsqlCommand())
                {
                    cmd.Connection = conn;
                    cmd.CommandText = "SELECT COUNT(*) FROM \"Accounts\" WHERE LOWER(\"Email\") = LOWER(@email)";
                    cmd.Parameters.AddWithValue("@email", email);
                    accountExists = Convert.ToInt64(cmd.ExecuteScalar()) > 0;
                }
                
                if (accountExists)
                {
                    // Update existing account to admin
                    using (var cmd = new NpgsqlCommand())
                    {
                        cmd.Connection = conn;
                        cmd.CommandText = @"
                            UPDATE ""Accounts""
                            SET ""RoleId"" = @roleId,
                                ""HashedPassword"" = @hashedPassword,
                                ""UpdatedAt"" = NOW()
                            WHERE LOWER(""Email"") = LOWER(@email)
                        ";
                        cmd.Parameters.AddWithValue("@roleId", adminRoleId);
                        cmd.Parameters.AddWithValue("@hashedPassword", hashedPassword);
                        cmd.Parameters.AddWithValue("@email", email);
                        int rowsAffected = cmd.ExecuteNonQuery();
                        Console.WriteLine($"✅ Updated existing account to admin (rows affected: {rowsAffected})");
                    }
                }
                else
                {
                    // Create new admin account
                    using (var cmd = new NpgsqlCommand())
                    {
                        cmd.Connection = conn;
                        cmd.CommandText = @"
                            INSERT INTO ""Accounts"" (
                                ""FirstName"",
                                ""LastName"",
                                ""Email"",
                                ""PhoneNumber"",
                                ""RoleId"",
                                ""HashedPassword"",
                                ""Status"",
                                ""EmailVerified"",
                                ""PhoneVerified"",
                                ""RequiresPasswordChange"",
                                ""IsSuspended"",
                                ""FailedLoginAttempts"",
                                ""TotalEarnedPoints"",
                                ""CurrentPoints"",
                                ""ReputationPoints"",
                                ""PostCount"",
                                ""CommentCount"",
                                ""LikesReceived"",
                                ""ShowInDirectory"",
                                ""CreatedAt"",
                                ""UpdatedAt""
                            )
                            VALUES (
                                @firstName,
                                @lastName,
                                @email,
                                @phoneNumber,
                                @roleId,
                                @hashedPassword,
                                2,
                                true,
                                true,
                                false,
                                false,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                0,
                                true,
                                NOW(),
                                NOW()
                            )
                        ";
                        cmd.Parameters.AddWithValue("@firstName", firstName);
                        cmd.Parameters.AddWithValue("@lastName", lastName);
                        cmd.Parameters.AddWithValue("@email", email.ToLower());
                        cmd.Parameters.AddWithValue("@phoneNumber", phoneNumber);
                        cmd.Parameters.AddWithValue("@roleId", adminRoleId);
                        cmd.Parameters.AddWithValue("@hashedPassword", hashedPassword);
                        cmd.ExecuteNonQuery();
                        Console.WriteLine("✅ Admin account created successfully!");
                    }
                }
                
                Console.WriteLine("\n📝 Login Credentials:");
                Console.WriteLine($"   Email: {email}");
                Console.WriteLine($"   Password: {password}");
                Console.WriteLine("\n✅ Done!");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Error: {ex.Message}");
            Console.WriteLine($"Stack trace: {ex.StackTrace}");
            Environment.Exit(1);
        }
    }
}

