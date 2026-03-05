using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using InstapropAPI.Data;
using InstapropAPI.Models.Financial;
using InstapropAPI.Services;
using Xunit;

namespace InstapropAPI.Tests;

public class FinancialServiceTests
{
    private static FinancialDbContext BuildFinancialContext()
    {
        var options = new DbContextOptionsBuilder<FinancialDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new FinancialDbContext(options);
    }

    private static FinancialService BuildService(FinancialDbContext db)
        => new FinancialService(db, NullLogger<FinancialService>.Instance);

    // ─── GetOrCreateBalance ───────────────────────────────────────────────────

    [Fact]
    public async Task GetOrCreateBalance_Creates_NewRecord_WhenNotExists()
    {
        using var db = BuildFinancialContext();
        var svc = BuildService(db);

        var accountId = Guid.NewGuid();
        var balance = await svc.GetOrCreateBalanceAsync(accountId);

        Assert.Equal(accountId, balance.AccountId);
        Assert.Equal(0, balance.CurrentBalance);
        Assert.Equal(0, balance.PendingBalance);
        Assert.Equal("EGP", balance.Currency);

        // Audit log must be written
        var audit = await db.AuditLogs.FirstOrDefaultAsync(a => a.EntityId == balance.BalanceId);
        Assert.NotNull(audit);
        Assert.Equal("Created", audit!.Action);
    }

    [Fact]
    public async Task GetOrCreateBalance_Returns_ExistingRecord()
    {
        using var db = BuildFinancialContext();
        var svc = BuildService(db);

        var accountId = Guid.NewGuid();
        var first = await svc.GetOrCreateBalanceAsync(accountId);
        var second = await svc.GetOrCreateBalanceAsync(accountId);

        Assert.Equal(first.BalanceId, second.BalanceId);
    }

    // ─── CreatePendingDeposit ────────────────────────────────────────────────

    [Fact]
    public async Task CreatePendingDeposit_AddsToPendingBalance()
    {
        using var db = BuildFinancialContext();
        var svc = BuildService(db);

        var accountId = Guid.NewGuid();
        await svc.CreatePendingDepositAsync(accountId, 5000m, "EGP", Guid.NewGuid(), "Auction", "Test deposit");

        var balance = await svc.GetBalanceAsync(accountId);
        Assert.NotNull(balance);
        Assert.Equal(0, balance!.CurrentBalance);
        Assert.Equal(5000m, balance.PendingBalance);
    }

    [Fact]
    public async Task CreatePendingDeposit_Creates_Transaction_With_PendingStatus()
    {
        using var db = BuildFinancialContext();
        var svc = BuildService(db);

        var accountId = Guid.NewGuid();
        var tx = await svc.CreatePendingDepositAsync(accountId, 3000m, "EGP", Guid.NewGuid(), "Auction", "Deposit");

        Assert.Equal(TransactionStatus.Pending, tx.Status);
        Assert.Equal(TransactionType.AuctionDeposit, tx.TransactionType);
        Assert.Equal(3000m, tx.Amount);
        Assert.Equal(accountId, tx.AccountId);
    }

    // ─── ConfirmTransaction ──────────────────────────────────────────────────

    [Fact]
    public async Task ConfirmTransaction_Moves_Amount_To_CurrentBalance()
    {
        using var db = BuildFinancialContext();
        var svc = BuildService(db);

        var accountId = Guid.NewGuid();
        var adminId = Guid.NewGuid();
        var tx = await svc.CreatePendingDepositAsync(accountId, 5000m, "EGP", Guid.NewGuid(), "Auction", "Deposit");

        var confirmed = await svc.ConfirmTransactionAsync(tx.TransactionId, adminId, "GW-REF-001");

        var balance = await svc.GetBalanceAsync(accountId);
        Assert.Equal(TransactionStatus.Confirmed, confirmed.Status);
        Assert.Equal("GW-REF-001", confirmed.PaymentGatewayReference);
        Assert.Equal(5000m, balance!.CurrentBalance);
        Assert.Equal(0, balance.PendingBalance);
    }

    [Fact]
    public async Task ConfirmTransaction_Throws_When_AlreadyConfirmed()
    {
        using var db = BuildFinancialContext();
        var svc = BuildService(db);

        var accountId = Guid.NewGuid();
        var adminId = Guid.NewGuid();
        var tx = await svc.CreatePendingDepositAsync(accountId, 1000m, "EGP", Guid.NewGuid(), "Auction", "Deposit");
        await svc.ConfirmTransactionAsync(tx.TransactionId, adminId);

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => svc.ConfirmTransactionAsync(tx.TransactionId, adminId));
    }

    // ─── RejectTransaction ───────────────────────────────────────────────────

    [Fact]
    public async Task RejectTransaction_Clears_PendingBalance()
    {
        using var db = BuildFinancialContext();
        var svc = BuildService(db);

        var accountId = Guid.NewGuid();
        var adminId = Guid.NewGuid();
        var tx = await svc.CreatePendingDepositAsync(accountId, 2000m, "EGP", Guid.NewGuid(), "Auction", "Deposit");

        await svc.RejectTransactionAsync(tx.TransactionId, adminId, "Fraudulent payment");

        var balance = await svc.GetBalanceAsync(accountId);
        Assert.Equal(0, balance!.CurrentBalance);
        Assert.Equal(0, balance.PendingBalance);

        var updated = await db.Transactions.FindAsync(tx.TransactionId);
        Assert.Equal(TransactionStatus.Rejected, updated!.Status);
    }

    // ─── ReverseTransaction ──────────────────────────────────────────────────

    [Fact]
    public async Task ReverseTransaction_Deducts_From_CurrentBalance()
    {
        using var db = BuildFinancialContext();
        var svc = BuildService(db);

        var accountId = Guid.NewGuid();
        var adminId = Guid.NewGuid();
        var tx = await svc.CreatePendingDepositAsync(accountId, 5000m, "EGP", Guid.NewGuid(), "Auction", "Deposit");
        await svc.ConfirmTransactionAsync(tx.TransactionId, adminId);

        await svc.ReverseTransactionAsync(tx.TransactionId, adminId, "Cancellation");

        var balance = await svc.GetBalanceAsync(accountId);
        Assert.Equal(0, balance!.CurrentBalance);

        var updated = await db.Transactions.FindAsync(tx.TransactionId);
        Assert.Equal(TransactionStatus.Reversed, updated!.Status);
        Assert.True(updated.IsReversed);
    }

    [Fact]
    public async Task ReverseTransaction_Throws_When_ReversedTwice()
    {
        using var db = BuildFinancialContext();
        var svc = BuildService(db);

        var accountId = Guid.NewGuid();
        var adminId = Guid.NewGuid();
        var tx = await svc.CreatePendingDepositAsync(accountId, 5000m, "EGP", Guid.NewGuid(), "Auction", "Deposit");
        await svc.ConfirmTransactionAsync(tx.TransactionId, adminId);
        await svc.ReverseTransactionAsync(tx.TransactionId, adminId, "First reversal");

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => svc.ReverseTransactionAsync(tx.TransactionId, adminId, "Second reversal"));
    }

    // ─── ManualAdjustment ────────────────────────────────────────────────────

    [Fact]
    public async Task ManualCredit_Increases_CurrentBalance()
    {
        using var db = BuildFinancialContext();
        var svc = BuildService(db);

        var accountId = Guid.NewGuid();
        var adminId = Guid.NewGuid();
        await svc.ApplyManualAdjustmentAsync(accountId, 1000m, TransactionType.ManualCredit, "Promo credit", adminId);

        var balance = await svc.GetBalanceAsync(accountId);
        Assert.Equal(1000m, balance!.CurrentBalance);
    }

    [Fact]
    public async Task ManualDebit_Decreases_CurrentBalance_NotBelow_Zero()
    {
        using var db = BuildFinancialContext();
        var svc = BuildService(db);

        var accountId = Guid.NewGuid();
        var adminId = Guid.NewGuid();
        await svc.ApplyManualAdjustmentAsync(accountId, 500m, TransactionType.ManualCredit, "Credit", adminId);
        await svc.ApplyManualAdjustmentAsync(accountId, 9999m, TransactionType.ManualDebit, "Over-debit", adminId);

        var balance = await svc.GetBalanceAsync(accountId);
        Assert.Equal(0, balance!.CurrentBalance); // Never goes below zero
    }

    // ─── AuditLog ────────────────────────────────────────────────────────────

    [Fact]
    public async Task AuditLog_Is_Written_For_Every_Operation()
    {
        using var db = BuildFinancialContext();
        var svc = BuildService(db);

        var accountId = Guid.NewGuid();
        var adminId = Guid.NewGuid();

        var tx = await svc.CreatePendingDepositAsync(accountId, 5000m, "EGP", Guid.NewGuid(), "Auction", "Deposit");
        await svc.ConfirmTransactionAsync(tx.TransactionId, adminId);

        var auditCount = await db.AuditLogs.CountAsync();
        // Create balance (1) + create tx (1) + confirm tx update (1) + balance update (1) = at least 4
        Assert.True(auditCount >= 4);
    }
}
