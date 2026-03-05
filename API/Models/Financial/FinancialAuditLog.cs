using System.ComponentModel.DataAnnotations;

namespace InstapropAPI.Models.Financial
{
    /// <summary>
    /// Immutable append-only audit trail. Rows are never updated or deleted.
    /// Every balance or transaction change writes a new row here.
    /// </summary>
    public class FinancialAuditLog
    {
        [Key]
        public Guid AuditId { get; set; }

        /// <summary>"UserBalance" or "Transaction"</summary>
        [Required]
        [MaxLength(50)]
        public string EntityType { get; set; } = string.Empty;

        [Required]
        public Guid EntityId { get; set; }

        /// <summary>"Created", "Updated", or "Reversed"</summary>
        [Required]
        [MaxLength(20)]
        public string Action { get; set; } = string.Empty;

        /// <summary>JSON snapshot of the entity before the change. Null for Create actions.</summary>
        public string? OldValues { get; set; }

        /// <summary>JSON snapshot of the entity after the change.</summary>
        public string? NewValues { get; set; }

        public Guid? PerformedByAdminId { get; set; }

        public DateTime PerformedAt { get; set; } = DateTime.UtcNow;

        [MaxLength(45)]
        public string? IpAddress { get; set; }
    }
}
