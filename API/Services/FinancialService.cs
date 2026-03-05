using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using InstapropAPI.Data;
using InstapropAPI.Models.Financial;

namespace InstapropAPI.Services
{
    public class FinancialService : IFinancialService
    {
        private readonly FinancialDbContext _db;
        private readonly ILogger<FinancialService> _logger;

        public FinancialService(FinancialDbContext db, ILogger<FinancialService> logger)
        {
            _db = db;
            _logger = logger;
        }

        public async Task<UserBalance> GetOrCreateBalanceAsync(Guid accountId, string? ipAddress = null)
        {
            var balance = await _db.UserBalances.FirstOrDefaultAsync(b => b.AccountId == accountId);
            if (balance != null) return balance;

            balance = new UserBalance
            {
                BalanceId = Guid.NewGuid(),
                AccountId = accountId,
                CurrentBalance = 0,
                PendingBalance = 0,
                Currency = "EGP",
                CreatedAt = DateTime.UtcNow,
                LastUpdatedAt = DateTime.UtcNow
            };

            _db.UserBalances.Add(balance);

            var auditLog = new FinancialAuditLog
            {
                AuditId = Guid.NewGuid(),
                EntityType = "UserBalance",
                EntityId = balance.BalanceId,
                Action = "Created",
                OldValues = null,
                NewValues = JsonSerializer.Serialize(new { balance.AccountId, balance.CurrentBalance, balance.PendingBalance, balance.Currency }),
                PerformedAt = DateTime.UtcNow,
                IpAddress = ipAddress
            };
            _db.AuditLogs.Add(auditLog);

            await _db.SaveChangesAsync();
            _logger.LogInformation("Created balance record for account {AccountId}", accountId);
            return balance;
        }

        public async Task<FinancialTransaction> CreatePendingDepositAsync(
            Guid accountId,
            decimal amount,
            string currency,
            Guid referenceId,
            string referenceType,
            string description,
            string? ipAddress = null)
        {
            var balance = await GetOrCreateBalanceAsync(accountId, ipAddress);

            var oldPending = balance.PendingBalance;
            balance.PendingBalance += amount;
            balance.LastUpdatedAt = DateTime.UtcNow;

            var tx = new FinancialTransaction
            {
                TransactionId = Guid.NewGuid(),
                AccountId = accountId,
                TransactionType = TransactionType.AuctionDeposit,
                Status = TransactionStatus.Pending,
                Amount = amount,
                Currency = currency,
                BalanceBefore = balance.CurrentBalance,
                BalanceAfter = balance.CurrentBalance,
                ReferenceId = referenceId,
                ReferenceType = referenceType,
                Description = description,
                CreatedAt = DateTime.UtcNow
            };
            _db.Transactions.Add(tx);

            _db.AuditLogs.Add(BuildAuditLog("UserBalance", balance.BalanceId, "Updated",
                new { PendingBalance = oldPending },
                new { balance.PendingBalance },
                null, ipAddress));

            _db.AuditLogs.Add(BuildAuditLog("Transaction", tx.TransactionId, "Created",
                null,
                new { tx.TransactionType, tx.Status, tx.Amount, tx.ReferenceId, tx.ReferenceType },
                null, ipAddress));

            await _db.SaveChangesAsync();
            _logger.LogInformation("Pending deposit EGP {Amount} created for account {AccountId}, ref {Ref}", amount, accountId, referenceId);
            return tx;
        }

        public async Task<FinancialTransaction> ConfirmTransactionAsync(
            Guid transactionId,
            Guid confirmedByAdminId,
            string? gatewayReference = null,
            string? ipAddress = null)
        {
            var tx = await _db.Transactions.FindAsync(transactionId)
                ?? throw new InvalidOperationException($"Transaction {transactionId} not found.");

            if (tx.Status != TransactionStatus.Pending)
                throw new InvalidOperationException($"Transaction {transactionId} is not in Pending state (current: {tx.Status}).");

            var balance = await GetOrCreateBalanceAsync(tx.AccountId, ipAddress);

            var oldStatus = tx.Status;
            var oldCurrent = balance.CurrentBalance;
            var oldPending = balance.PendingBalance;

            tx.Status = TransactionStatus.Confirmed;
            tx.PaymentGatewayReference = gatewayReference;
            tx.BalanceAfter = balance.CurrentBalance + tx.Amount;

            balance.CurrentBalance += tx.Amount;
            balance.PendingBalance = Math.Max(0, balance.PendingBalance - tx.Amount);
            balance.LastUpdatedAt = DateTime.UtcNow;

            _db.AuditLogs.Add(BuildAuditLog("Transaction", tx.TransactionId, "Updated",
                new { Status = oldStatus.ToString() },
                new { Status = tx.Status.ToString(), tx.PaymentGatewayReference },
                confirmedByAdminId, ipAddress));

            _db.AuditLogs.Add(BuildAuditLog("UserBalance", balance.BalanceId, "Updated",
                new { CurrentBalance = oldCurrent, PendingBalance = oldPending },
                new { balance.CurrentBalance, balance.PendingBalance },
                confirmedByAdminId, ipAddress));

            await _db.SaveChangesAsync();
            _logger.LogInformation("Transaction {TxId} confirmed by admin {AdminId}", transactionId, confirmedByAdminId);
            return tx;
        }

        public async Task<FinancialTransaction> RejectTransactionAsync(
            Guid transactionId,
            Guid rejectedByAdminId,
            string reason,
            string? ipAddress = null)
        {
            var tx = await _db.Transactions.FindAsync(transactionId)
                ?? throw new InvalidOperationException($"Transaction {transactionId} not found.");

            if (tx.Status != TransactionStatus.Pending)
                throw new InvalidOperationException($"Transaction {transactionId} is not in Pending state.");

            var balance = await GetOrCreateBalanceAsync(tx.AccountId, ipAddress);

            var oldPending = balance.PendingBalance;
            var oldStatus = tx.Status;

            tx.Status = TransactionStatus.Rejected;
            tx.ReversalReason = reason;
            balance.PendingBalance = Math.Max(0, balance.PendingBalance - tx.Amount);
            balance.LastUpdatedAt = DateTime.UtcNow;

            _db.AuditLogs.Add(BuildAuditLog("Transaction", tx.TransactionId, "Updated",
                new { Status = oldStatus.ToString() },
                new { Status = tx.Status.ToString(), tx.ReversalReason },
                rejectedByAdminId, ipAddress));

            _db.AuditLogs.Add(BuildAuditLog("UserBalance", balance.BalanceId, "Updated",
                new { PendingBalance = oldPending },
                new { balance.PendingBalance },
                rejectedByAdminId, ipAddress));

            await _db.SaveChangesAsync();
            _logger.LogInformation("Transaction {TxId} rejected by admin {AdminId}: {Reason}", transactionId, rejectedByAdminId, reason);
            return tx;
        }

        public async Task<FinancialTransaction> ReverseTransactionAsync(
            Guid transactionId,
            Guid reversedByAdminId,
            string reason,
            string? ipAddress = null)
        {
            var tx = await _db.Transactions.FindAsync(transactionId)
                ?? throw new InvalidOperationException($"Transaction {transactionId} not found.");

            if (tx.Status != TransactionStatus.Confirmed)
                throw new InvalidOperationException($"Only confirmed transactions can be reversed.");

            if (tx.IsReversed)
                throw new InvalidOperationException($"Transaction {transactionId} is already reversed.");

            var balance = await GetOrCreateBalanceAsync(tx.AccountId, ipAddress);

            var oldCurrent = balance.CurrentBalance;

            tx.IsReversed = true;
            tx.ReversedAt = DateTime.UtcNow;
            tx.ReversalReason = reason;
            tx.Status = TransactionStatus.Reversed;

            balance.CurrentBalance = Math.Max(0, balance.CurrentBalance - tx.Amount);
            balance.LastUpdatedAt = DateTime.UtcNow;

            _db.AuditLogs.Add(BuildAuditLog("Transaction", tx.TransactionId, "Reversed",
                new { Status = "Confirmed" },
                new { Status = "Reversed", tx.ReversalReason },
                reversedByAdminId, ipAddress));

            _db.AuditLogs.Add(BuildAuditLog("UserBalance", balance.BalanceId, "Updated",
                new { CurrentBalance = oldCurrent },
                new { balance.CurrentBalance },
                reversedByAdminId, ipAddress));

            await _db.SaveChangesAsync();
            _logger.LogInformation("Transaction {TxId} reversed by admin {AdminId}", transactionId, reversedByAdminId);
            return tx;
        }

        public async Task<FinancialTransaction> ApplyManualAdjustmentAsync(
            Guid accountId,
            decimal amount,
            TransactionType type,
            string description,
            Guid adminId,
            string? ipAddress = null)
        {
            var balance = await GetOrCreateBalanceAsync(accountId, ipAddress);

            var oldCurrent = balance.CurrentBalance;

            if (type == TransactionType.ManualCredit)
                balance.CurrentBalance += amount;
            else if (type == TransactionType.ManualDebit)
                balance.CurrentBalance = Math.Max(0, balance.CurrentBalance - amount);

            balance.LastUpdatedAt = DateTime.UtcNow;

            var tx = new FinancialTransaction
            {
                TransactionId = Guid.NewGuid(),
                AccountId = accountId,
                TransactionType = type,
                Status = TransactionStatus.Confirmed,
                Amount = amount,
                Currency = balance.Currency,
                BalanceBefore = oldCurrent,
                BalanceAfter = balance.CurrentBalance,
                Description = description,
                CreatedAt = DateTime.UtcNow,
                CreatedByAdminId = adminId
            };
            _db.Transactions.Add(tx);

            _db.AuditLogs.Add(BuildAuditLog("Transaction", tx.TransactionId, "Created",
                null,
                new { tx.TransactionType, tx.Status, tx.Amount, tx.Description },
                adminId, ipAddress));

            _db.AuditLogs.Add(BuildAuditLog("UserBalance", balance.BalanceId, "Updated",
                new { CurrentBalance = oldCurrent },
                new { balance.CurrentBalance },
                adminId, ipAddress));

            await _db.SaveChangesAsync();
            return tx;
        }

        public async Task<UserBalance?> GetBalanceAsync(Guid accountId)
            => await _db.UserBalances.FirstOrDefaultAsync(b => b.AccountId == accountId);

        public async Task<List<FinancialTransaction>> GetTransactionsAsync(Guid accountId, int page = 1, int pageSize = 20)
            => await _db.Transactions
                .Where(t => t.AccountId == accountId)
                .OrderByDescending(t => t.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

        public async Task<List<FinancialTransaction>> GetPendingTransactionsAsync(int page = 1, int pageSize = 50)
            => await _db.Transactions
                .Where(t => t.Status == TransactionStatus.Pending)
                .OrderByDescending(t => t.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

        public async Task<List<UserBalance>> GetAllBalancesAsync(int page = 1, int pageSize = 50)
            => await _db.UserBalances
                .OrderByDescending(b => b.CurrentBalance)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

        private static FinancialAuditLog BuildAuditLog(
            string entityType, Guid entityId, string action,
            object? oldValues, object? newValues,
            Guid? adminId, string? ipAddress)
        {
            return new FinancialAuditLog
            {
                AuditId = Guid.NewGuid(),
                EntityType = entityType,
                EntityId = entityId,
                Action = action,
                OldValues = oldValues != null ? JsonSerializer.Serialize(oldValues) : null,
                NewValues = newValues != null ? JsonSerializer.Serialize(newValues) : null,
                PerformedByAdminId = adminId,
                PerformedAt = DateTime.UtcNow,
                IpAddress = ipAddress
            };
        }
    }
}
