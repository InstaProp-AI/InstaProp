using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class SalesTeam
    {
        [Key]
        public Guid TeamId { get; set; }

        [Required]
        [MaxLength(200)]
        public string TeamName { get; set; } = string.Empty;

        [Required]
        public Guid DeveloperId { get; set; }

        [ForeignKey(nameof(DeveloperId))]
        public DeveloperAccount Developer { get; set; } = null!;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        // Navigation property - Sales members in this team
        public ICollection<SalesAccount> SalesMembers { get; set; } = new List<SalesAccount>();
    }
}




