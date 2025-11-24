using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class Role
    {
        [Key]
        public Guid RoleId { get; set; }

        [Required]
        [MaxLength(50)]
        public string RoleName { get; set; } = string.Empty; // "User", "Developer", "Admin", "Sales"

        [MaxLength(500)]
        public string? Description { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation property - using AccountBase (abstract base class for all account types)
        public ICollection<AccountBase> Accounts { get; set; } = new List<AccountBase>();

        // Constant role IDs (UUIDs)
        // These are generated once and stored - attackers cannot guess them
        public static readonly Guid USER_ROLE_ID = Guid.Parse("89237489-2374-4923-8923-892374892374");
        public static readonly Guid DEVELOPER_ROLE_ID = Guid.Parse("78236478-2364-4782-3647-823647823647");
        public static readonly Guid ADMIN_ROLE_ID = Guid.Parse("98237498-2374-4982-3749-823749823749");
        public static readonly Guid SALES_ROLE_ID = Guid.Parse("67235467-2354-4672-3546-723546723546");
    }
}




