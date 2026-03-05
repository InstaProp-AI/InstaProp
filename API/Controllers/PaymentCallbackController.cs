using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using InstapropAPI.Attributes;
using InstapropAPI.Services;

namespace InstapropAPI.Controllers
{
    /// <summary>
    /// Internal endpoint for payment gateway webhooks.
    /// Admin-auth only — never exposed publicly.
    /// The actual gateway integration (Paymob, Fawry, etc.) will be wired here later.
    /// </summary>
    [ApiController]
    [Route("api/internal/payment-callback")]
    [Authorize]
    [AdminAuthorize]
    public class PaymentCallbackController : ControllerBase
    {
        private readonly IFinancialService _financialService;
        private readonly ILogger<PaymentCallbackController> _logger;

        public PaymentCallbackController(IFinancialService financialService, ILogger<PaymentCallbackController> logger)
        {
            _financialService = financialService;
            _logger = logger;
        }

        /// <summary>
        /// Stub endpoint for payment gateway webhook confirmation.
        /// Currently admin-only manual trigger. Wire real gateway payload here later.
        /// </summary>
        [HttpPost("confirm")]
        public async Task<IActionResult> ConfirmPayment([FromBody] ConfirmPaymentRequest request)
        {
            try
            {
                var adminId = GetAdminId();
                var ip = HttpContext.Connection.RemoteIpAddress?.ToString();

                var tx = await _financialService.ConfirmTransactionAsync(
                    request.TransactionId,
                    adminId,
                    request.GatewayReference,
                    ip);

                _logger.LogInformation("Payment confirmed for transaction {TxId} by admin {AdminId}", request.TransactionId, adminId);

                return Ok(new
                {
                    success = true,
                    message = "Transaction confirmed successfully.",
                    transactionId = tx.TransactionId,
                    status = tx.Status.ToString(),
                    balanceAfter = tx.BalanceAfter
                });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to confirm payment for transaction {TxId}", request.TransactionId);
                return StatusCode(500, new { success = false, message = "Failed to confirm payment." });
            }
        }

        /// <summary>Reject a pending payment (e.g. failed or disputed).</summary>
        [HttpPost("reject")]
        public async Task<IActionResult> RejectPayment([FromBody] RejectPaymentRequest request)
        {
            try
            {
                var adminId = GetAdminId();
                var ip = HttpContext.Connection.RemoteIpAddress?.ToString();

                var tx = await _financialService.RejectTransactionAsync(
                    request.TransactionId,
                    adminId,
                    request.Reason,
                    ip);

                return Ok(new
                {
                    success = true,
                    message = "Transaction rejected.",
                    transactionId = tx.TransactionId,
                    status = tx.Status.ToString()
                });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to reject transaction {TxId}", request.TransactionId);
                return StatusCode(500, new { success = false, message = "Failed to reject transaction." });
            }
        }

        private Guid GetAdminId()
        {
            var claim = User.Claims.FirstOrDefault(c => c.Type == "uid")?.Value;
            return claim != null ? Guid.Parse(claim) : Guid.Empty;
        }
    }

    public class ConfirmPaymentRequest
    {
        public Guid TransactionId { get; set; }
        public string? GatewayReference { get; set; }
    }

    public class RejectPaymentRequest
    {
        public Guid TransactionId { get; set; }
        public string Reason { get; set; } = string.Empty;
    }
}
