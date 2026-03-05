using Microsoft.EntityFrameworkCore;
using InstapropAPI.Models.Financial;

namespace InstapropAPI.Data
{
    /// <summary>
    /// Isolated DbContext for the financial database.
    /// Uses a separate connection string (FINANCIAL_DATABASE_URL env var).
    /// Zero public endpoints reference this context directly —
    /// all access goes through IFinancialService.
    /// </summary>
    public class FinancialDbContext : DbContext
    {
        public FinancialDbContext(DbContextOptions<FinancialDbContext> options) : base(options) { }

        public DbSet<UserBalance> UserBalances { get; set; }
        public DbSet<FinancialTransaction> Transactions { get; set; }
        public DbSet<FinancialAuditLog> AuditLogs { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<UserBalance>(entity =>
            {
                entity.HasKey(e => e.BalanceId);
                entity.Property(e => e.BalanceId).ValueGeneratedOnAdd();
                entity.Property(e => e.CurrentBalance).HasColumnType("decimal(18,2)");
                entity.Property(e => e.PendingBalance).HasColumnType("decimal(18,2)");
                entity.Property(e => e.Currency).HasMaxLength(10).HasDefaultValue("EGP");
                entity.Property(e => e.Notes).HasMaxLength(1000);
                entity.HasIndex(e => e.AccountId).IsUnique(); // one balance record per user
            });

            modelBuilder.Entity<FinancialTransaction>(entity =>
            {
                entity.HasKey(e => e.TransactionId);
                entity.Property(e => e.TransactionId).ValueGeneratedOnAdd();
                entity.Property(e => e.Amount).HasColumnType("decimal(18,2)");
                entity.Property(e => e.BalanceBefore).HasColumnType("decimal(18,2)");
                entity.Property(e => e.BalanceAfter).HasColumnType("decimal(18,2)");
                entity.Property(e => e.Currency).HasMaxLength(10).HasDefaultValue("EGP");
                entity.Property(e => e.TransactionType).HasConversion<string>().HasMaxLength(50);
                entity.Property(e => e.Status).HasConversion<string>().HasMaxLength(20);
                entity.Property(e => e.ReferenceType).HasMaxLength(50);
                entity.Property(e => e.Description).HasMaxLength(500);
                entity.Property(e => e.PaymentGatewayReference).HasMaxLength(200);
                entity.Property(e => e.ReversalReason).HasMaxLength(500);
                entity.HasIndex(e => e.AccountId);
                entity.HasIndex(e => e.Status);
                entity.HasIndex(e => e.CreatedAt);
                entity.HasIndex(e => e.ReferenceId);
            });

            modelBuilder.Entity<FinancialAuditLog>(entity =>
            {
                entity.HasKey(e => e.AuditId);
                entity.Property(e => e.AuditId).ValueGeneratedOnAdd();
                entity.Property(e => e.EntityType).HasMaxLength(50);
                entity.Property(e => e.Action).HasMaxLength(20);
                entity.Property(e => e.IpAddress).HasMaxLength(45);
                entity.HasIndex(e => e.EntityId);
                entity.HasIndex(e => e.PerformedAt);
            });
        }
    }
}
