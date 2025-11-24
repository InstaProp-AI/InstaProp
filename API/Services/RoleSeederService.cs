using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;

namespace InstapropAPI.Services
{
    public class RoleSeederService
    {
        private readonly AppDbContext _context;

        public RoleSeederService(AppDbContext context)
        {
            _context = context;
        }

        public async Task SeedRolesAsync()
        {
            Console.WriteLine("🔐 Seeding Roles with non-guessable 64-bit IDs...");

            // Check if roles already exist
            var hasRoles = await _context.Roles.AnyAsync();
            if (hasRoles)
            {
                Console.WriteLine("ℹ️ Roles already exist. Skipping seeding.");
                return;
            }

            var roles = new List<Role>
            {
                new Role
                {
                    RoleId = Role.USER_ROLE_ID,
                    RoleName = "User",
                    Description = "Regular user account",
                    CreatedAt = DateTime.UtcNow
                },
                new Role
                {
                    RoleId = Role.DEVELOPER_ROLE_ID,
                    RoleName = "Developer",
                    Description = "Developer account with project management permissions",
                    CreatedAt = DateTime.UtcNow
                },
                new Role
                {
                    RoleId = Role.ADMIN_ROLE_ID,
                    RoleName = "Admin",
                    Description = "Administrator account with full system access",
                    CreatedAt = DateTime.UtcNow
                },
                new Role
                {
                    RoleId = Role.SALES_ROLE_ID,
                    RoleName = "Sales",
                    Description = "Sales team account with chat and customer management permissions",
                    CreatedAt = DateTime.UtcNow
                }
            };

            // Use a transaction to ensure atomicity
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Double check inside transaction
                var existingRoles = await _context.Roles.CountAsync();
                if (existingRoles > 0)
                {
                    Console.WriteLine("ℹ️ Roles already exist (detected in transaction). Skipping seeding.");
                    await transaction.RollbackAsync();
                    return;
                }

                _context.Roles.AddRange(roles);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
                
                Console.WriteLine($"✅ Seeded {roles.Count} roles with non-guessable IDs:");
                foreach (var role in roles)
                {
                    Console.WriteLine($"   - {role.RoleName}: {role.RoleId}");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ Role seeding failed (possibly already seeded): {ex.Message}");
                await transaction.RollbackAsync();
            }
        }
    }
}



