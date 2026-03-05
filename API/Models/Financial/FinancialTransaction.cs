using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models.Financial
{
    public enum TransactionType
    {
        AuctionDeposit,
        ManualCredit,
        ManualDebit,
        Fee,
        Refund,
        PaymentGatewayConfirmation
    }

    public enum TransactionStatus
    {
        Pending,
        Confirmed,
        Rejected,
        Reversed
    }

    public class FinancialTransaction
    {
        [Key]
        public Guid TransactionId { get; set; }

        [Required]
        public Guid AccountId { get; set; }

        [Required]
        public TransactionType TransactionType { get; set; }

        [Required]
        public TransactionStatus Status { get; set; } = TransactionStatus.Pending;

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        [MaxLength(10)]
        public string Currency { get; set; } = "EGP";

        /// <summary>Balance snapshot before this transaction was applied.</summary>
        [Column(TypeName = "decimal(18,2)")]
        public decimal BalanceBefore { get; set; }

        /// <summary>Balance snapshot after this transaction was applied.</summary>
        [Column(TypeName = "decimal(18,2)")]
        public decimal BalanceAfter { get; set; }

        /// <summary>Links to the entity that triggered this transaction (e.g. AuctionId).</summary>
        public Guid? ReferenceId { get; set; }

        /// <summary>Describes what ReferenceId refers to (e.g. "Auction", "ManualAdmin").</summary>
        [MaxLength(50)]
        public string? ReferenceType { get; set; }

        /// <summary>Internal description. Never shown to end users.</summary>
        [MaxLength(500)]
        public string? Description { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        /// <summary>Set when an admin manually performs a credit or debit.</summary>
        public Guid? CreatedByAdminId { get; set; }

        /// <summary>Will hold the payment gateway's own transaction reference once integrated.</summary>
        [MaxLength(200)]
        public string? PaymentGatewayReference { get; set; }

        public bool IsReversed { get; set; } = false;
        public DateTime? ReversedAt { get; set; }

        [MaxLength(500)]
        public string? ReversalReason { get; set; }
    }
}
