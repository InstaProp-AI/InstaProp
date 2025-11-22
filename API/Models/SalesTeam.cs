using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class SalesTeam
    {
        [Key]
        public long TeamId { get; set; }

        [Required]
        [MaxLength(200)]
        public string TeamName { get; set; } = string.Empty;

        [Required]
        public long DeveloperId { get; set; }

        [ForeignKey(nameof(DeveloperId))]
        public Account Developer { get; set; } = null!;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        // Navigation property - Sales members in this team
        public ICollection<Account> SalesMembers { get; set; } = new List<Account>();
    }
}


