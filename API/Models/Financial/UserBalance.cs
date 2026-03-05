using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models.Financial
{
    public class UserBalance
    {
        [Key]
        public Guid BalanceId { get; set; }

        /// <summary>Mirrors AccountId from the main database. No cross-DB FK enforced.</summary>
        [Required]
        public Guid AccountId { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal CurrentBalance { get; set; } = 0;

        /// <summary>Amount reserved for in-flight deposit confirmations.</summary>
        [Column(TypeName = "decimal(18,2)")]
        public decimal PendingBalance { get; set; } = 0;

        /// <summary>Currency code. Defaults to EGP. Add more currencies without schema change.</summary>
        [MaxLength(10)]
        public string Currency { get; set; } = "EGP";

        public DateTime LastUpdatedAt { get; set; } = DateTime.UtcNow;

        /// <summary>Internal admin-only notes. Never exposed to the user.</summary>
        [MaxLength(1000)]
        public string? Notes { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
