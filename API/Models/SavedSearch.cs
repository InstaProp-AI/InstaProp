using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    public class SavedSearch
    {
        [Key]
        public Guid SearchId { get; set; }

        [Required]
        public Guid AccountId { get; set; }

        [ForeignKey(nameof(AccountId))]
        public AccountBase Account { get; set; } = null!;

        [Required]
        [MaxLength(100)]
        public string SearchName { get; set; } = string.Empty;

        [Required]
        public string Filters { get; set; } = string.Empty; // JSON string of filter criteria

        public bool NotifyOnMatch { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? LastNotifiedAt { get; set; }
    }
}

