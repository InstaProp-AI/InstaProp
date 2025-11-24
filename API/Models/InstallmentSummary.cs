using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InstapropAPI.Models
{
    /// <summary>
    /// Stores the high-level installment / financing summary for a property.
    /// Tracks the original contract price, what has been paid to date, payment plan terms,
    /// and the remaining balance so that both resale and primary units share the same data source.
    /// </summary>
    public class InstallmentSummary
    {
        [Key]
        public Guid SummaryId { get; set; }

        [ForeignKey(nameof(Property))]
        public Guid PropertyId { get; set; }

        /// <summary>
        /// Total contract value agreed upon with the developer/seller.
        /// </summary>
        [Column(TypeName = "decimal(18,2)")]
        public decimal ContractedPrice { get; set; }

        /// <summary>
        /// Money that has already been paid (down payment + installments to date).
        /// </summary>
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalPaid { get; set; }

        /// <summary>
        /// Down payment expressed as a percentage of the contract value.
        /// </summary>
        [Column(TypeName = "decimal(5,2)")]
        public decimal DownPaymentPercent { get; set; }

        /// <summary>
        /// Total number of years in the installment plan (e.g., 10 years plan).
        /// </summary>
        public int? TermYears { get; set; }

        /// <summary>
        /// Optional calendar date representing when the installment plan is expected to end.
        /// </summary>
        public DateTime? InstallmentEndDate { get; set; }

        /// <summary>
        /// Indicates if the property is fully paid (no outstanding balance).
        /// </summary>
        public bool IsFullyPaid { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal RemainingBalance { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public virtual ChildProperty? Property { get; set; }
    }
}

