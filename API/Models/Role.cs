using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class Role
    {
        [Key]
        public long RoleId { get; set; } // 64-bit ID - Large non-sequential number for security

        [Required]
        [MaxLength(50)]
        public string RoleName { get; set; } = string.Empty; // "User", "Developer", "Admin"

        [MaxLength(500)]
        public string? Description { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property
        public ICollection<Account> Accounts { get; set; } = new List<Account>();

        // Constant role IDs (hardcoded, non-guessable large numbers)
        // These are generated once and stored - attackers cannot guess them
        public const long USER_ROLE_ID = 8923748923748923L;        // User role ID
        public const long DEVELOPER_ROLE_ID = 7823647823647823L;  // Developer role ID  
        public const long ADMIN_ROLE_ID = 9823749823749823L;      // Admin role ID
    }
}


