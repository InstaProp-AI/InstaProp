using System;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;

namespace PropertyFlipperAPI.Services
{
    /// <summary>
    /// Centralizes logic for creating, updating, and recalculating installment summaries
    /// so both property onboarding and calendar modules share the same data source.
    /// </summary>
    public class InstallmentSummaryService
    {
        private readonly AppDbContext _context;

        public InstallmentSummaryService(AppDbContext context)
        {
            _context = context;
        }

        public Task<InstallmentSummary?> GetSummaryAsync(int propertyId)
        {
            return _context.InstallmentSummaries
                .AsNoTracking()
                .FirstOrDefaultAsync(s => s.PropertyId == propertyId);
        }

        public async Task<InstallmentSummary> UpsertSummaryAsync(
            int propertyId,
            decimal contractedPrice,
            decimal totalPaid,
            decimal downPaymentPercent,
            int? termYears,
            DateTime? installmentEndDate = null,
            bool? isFullyPaid = null)
        {
            var summary = await _context.InstallmentSummaries
                .FirstOrDefaultAsync(s => s.PropertyId == propertyId);

            var remainingBalance = CalculateRemainingBalance(contractedPrice, totalPaid);
            var fullyPaid = isFullyPaid ?? remainingBalance <= 0;

            if (summary == null)
            {
                summary = new InstallmentSummary
                {
                    PropertyId = propertyId,
                    ContractedPrice = contractedPrice,
                    TotalPaid = totalPaid,
                    DownPaymentPercent = downPaymentPercent,
                    TermYears = termYears,
                    InstallmentEndDate = installmentEndDate,
                    RemainingBalance = remainingBalance,
                    IsFullyPaid = fullyPaid,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.InstallmentSummaries.Add(summary);
            }
            else
            {
                summary.ContractedPrice = contractedPrice;
                summary.TotalPaid = totalPaid;
                summary.DownPaymentPercent = downPaymentPercent;
                summary.TermYears = termYears;
                summary.InstallmentEndDate = installmentEndDate;
                summary.RemainingBalance = remainingBalance;
                summary.IsFullyPaid = fullyPaid;
                summary.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            return summary;
        }

        public async Task<InstallmentSummary?> UpdatePaidAmountAsync(int propertyId, decimal totalPaid)
        {
            var summary = await _context.InstallmentSummaries
                .FirstOrDefaultAsync(s => s.PropertyId == propertyId);

            if (summary == null) return null;

            summary.TotalPaid = totalPaid;
            summary.RemainingBalance = CalculateRemainingBalance(summary.ContractedPrice, totalPaid);
            summary.IsFullyPaid = summary.RemainingBalance <= 0;
            summary.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return summary;
        }

        private static decimal CalculateRemainingBalance(decimal contractedPrice, decimal totalPaid)
        {
            var remaining = contractedPrice - totalPaid;
            return remaining < 0 ? 0 : remaining;
        }

        public static decimal CalculateDownPaymentAmount(decimal contractedPrice, decimal downPaymentPercent)
        {
            return Math.Round(contractedPrice * (downPaymentPercent / 100m), 2);
        }
    }
}

