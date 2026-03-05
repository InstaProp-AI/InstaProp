using InstapropAPI.Models.Financial;

namespace InstapropAPI.Services
{
    public interface IFinancialService
    {
        /// <summary>Gets or creates a balance record for the given account.</summary>
        Task<UserBalance> GetOrCreateBalanceAsync(Guid accountId, string? ipAddress = null);

        /// <summary>Creates a pending deposit transaction (e.g. auction win preserving price).</summary>
        Task<FinancialTransaction> CreatePendingDepositAsync(
            Guid accountId,
            decimal amount,
            string currency,
            Guid referenceId,
            string referenceType,
            string description,
            string? ipAddress = null);

        /// <summary>Confirms a pending transaction (called by payment gateway webhook or admin).</summary>
        Task<FinancialTransaction> ConfirmTransactionAsync(
            Guid transactionId,
            Guid confirmedByAdminId,
            string? gatewayReference = null,
            string? ipAddress = null);

        /// <summary>Rejects a pending transaction and clears pending balance.</summary>
        Task<FinancialTransaction> RejectTransactionAsync(
            Guid transactionId,
            Guid rejectedByAdminId,
            string reason,
            string? ipAddress = null);

        /// <summary>Reverses a confirmed transaction and adjusts balances accordingly.</summary>
        Task<FinancialTransaction> ReverseTransactionAsync(
            Guid transactionId,
            Guid reversedByAdminId,
            string reason,
            string? ipAddress = null);

        /// <summary>Applies a manual credit or debit from the admin panel.</summary>
        Task<FinancialTransaction> ApplyManualAdjustmentAsync(
            Guid accountId,
            decimal amount,
            TransactionType type,
            string description,
            Guid adminId,
            string? ipAddress = null);

        Task<UserBalance?> GetBalanceAsync(Guid accountId);
        Task<List<FinancialTransaction>> GetTransactionsAsync(Guid accountId, int page = 1, int pageSize = 20);
        Task<List<FinancialTransaction>> GetPendingTransactionsAsync(int page = 1, int pageSize = 50);
        Task<List<UserBalance>> GetAllBalancesAsync(int page = 1, int pageSize = 50);
    }
}
