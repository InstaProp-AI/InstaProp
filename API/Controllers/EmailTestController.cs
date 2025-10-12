using Microsoft.AspNetCore.Mvc;
using PropertyFlipperAPI.Services;
using PropertyFlipperAPI.Models;
using System;
using System.Threading.Tasks;

namespace PropertyFlipperAPI.Controllers
{
    /// <summary>
    /// Test controller for sending email template previews
    /// WARNING: Remove or protect this controller in production!
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    public class EmailTestController : ControllerBase
    {
        private readonly EmailVerificationService _emailService;
        private readonly AuctionNotificationService _auctionService;
        private readonly EmailTemplateService _templateService;

        public EmailTestController(
            EmailVerificationService emailService,
            AuctionNotificationService auctionService,
            EmailTemplateService templateService)
        {
            _emailService = emailService;
            _auctionService = auctionService;
            _templateService = templateService;
        }

        /// <summary>
        /// Sends all 8 email templates to a test email address
        /// </summary>
        [HttpPost("send-all/{email}")]
        public async Task<IActionResult> SendAllTemplates(string email)
        {
            var results = new List<string>();

            try
            {
                // 1. Welcome Email
                var welcome = await _emailService.SendWelcomeEmail(email, "Abraam");
                results.Add(welcome ? "✅ Welcome Email sent" : "❌ Welcome Email failed");
                await Task.Delay(2000); // Wait 2 seconds between emails

                // 2. Email Verification
                var verification = await _emailService.SendVerificationEmail(email, "123456", "Abraam");
                results.Add(verification ? "✅ Email Verification sent" : "❌ Email Verification failed");
                await Task.Delay(2000);

                // 3. Password Reset
                var reset = await _emailService.SendPasswordResetEmail(email, "Abraam", "TempPass123");
                results.Add(reset ? "✅ Password Reset sent" : "❌ Password Reset failed");
                await Task.Delay(2000);

                // 4. Account Lockout
                var lockout = await _emailService.SendAccountLockoutEmail(email, "Abraam", DateTime.UtcNow.AddMinutes(30));
                results.Add(lockout ? "✅ Account Lockout sent" : "❌ Account Lockout failed");
                await Task.Delay(2000);

                // 5. Auction Starting Soon (mock auction)
                var mockAuction = new Auction
                {
                    AuctionId = 1,
                    StartPrice = 450000,
                    StartAt = DateTime.UtcNow.AddHours(12),
                    Property = new Property
                    {
                        PropertyId = 1,
                        Name = "Luxury Beachfront Villa",
                        Location = "Miami Beach, FL",
                        ImageUrl = "https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=600"
                    }
                };
                var auctionStarting = await _auctionService.SendAuctionStartingSoonNotification(
                    email, "Abraam", mockAuction);
                results.Add(auctionStarting ? "✅ Auction Starting Soon sent" : "❌ Auction Starting Soon failed");
                await Task.Delay(2000);

                // 6. Outbid Notification
                var outbid = await _auctionService.SendOutbidNotification(
                    email, "Abraam", "Luxury Beachfront Villa",
                    450000, 475000, DateTime.UtcNow.AddHours(24), 1);
                results.Add(outbid ? "✅ Outbid Notification sent" : "❌ Outbid Notification failed");
                await Task.Delay(2000);

                // 7. Auction Won
                var won = await _auctionService.SendAuctionWonNotification(
                    email, "Abraam", mockAuction, 500000);
                results.Add(won ? "✅ Auction Won sent" : "❌ Auction Won failed");
                await Task.Delay(2000);

                // 8. Payment Reminder
                var payment = await _auctionService.SendPaymentReminder(
                    email, "Abraam", "Luxury Beachfront Villa",
                    500000, DateTime.UtcNow.AddDays(3));
                results.Add(payment ? "✅ Payment Reminder sent" : "❌ Payment Reminder failed");

                return Ok(new
                {
                    success = true,
                    message = $"All email templates sent to {email}",
                    results = results,
                    note = "Check your inbox and spam folder. Emails may take a few moments to arrive."
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    message = "Error sending emails",
                    error = ex.Message,
                    results = results
                });
            }
        }

        /// <summary>
        /// Preview email template HTML (for testing design)
        /// </summary>
        [HttpGet("preview/{template}")]
        public IActionResult PreviewTemplate(string template)
        {
            var html = template.ToLower() switch
            {
                "welcome" => _templateService.GetWelcomeEmail("Abraam"),
                "verification" => _templateService.GetEmailVerificationEmail("Abraam", "123456"),
                "reset" => _templateService.GetPasswordResetEmail("Abraam", "TempPass123"),
                "lockout" => _templateService.GetAccountLockoutEmail("Abraam", DateTime.UtcNow.AddMinutes(30)),
                "auction-starting" => _templateService.GetAuctionStartingSoonEmail("Abraam", "Luxury Villa", 
                    "Miami Beach, FL", 450000, DateTime.UtcNow.AddHours(12), 
                    "https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=600", 1),
                "outbid" => _templateService.GetOutbidNotificationEmail("Abraam", "Luxury Villa",
                    450000, 475000, DateTime.UtcNow.AddHours(24), 1),
                "won" => _templateService.GetAuctionWonEmail("Abraam", "Luxury Villa",
                    "Miami Beach, FL", 500000, "https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=600", 1),
                "payment" => _templateService.GetPaymentReminderEmail("Abraam", "Luxury Villa",
                    500000, DateTime.UtcNow.AddDays(3), 3),
                _ => "<h1>Template not found</h1><p>Available templates: welcome, verification, reset, lockout, auction-starting, outbid, won, payment</p>"
            };

            return Content(html, "text/html");
        }

        /// <summary>
        /// Send a single template test
        /// </summary>
        [HttpPost("send/{template}/{email}")]
        public async Task<IActionResult> SendSingleTemplate(string template, string email)
        {
            try
            {
                bool result = false;
                var templateName = template.ToLower();

                switch (templateName)
                {
                    case "welcome":
                        result = await _emailService.SendWelcomeEmail(email, "Test User");
                        break;
                    case "verification":
                        result = await _emailService.SendVerificationEmail(email, "123456", "Test User");
                        break;
                    case "reset":
                        result = await _emailService.SendPasswordResetEmail(email, "Test User", "TempPass123");
                        break;
                    case "lockout":
                        result = await _emailService.SendAccountLockoutEmail(email, "Test User", DateTime.UtcNow.AddMinutes(30));
                        break;
                    default:
                        return BadRequest($"Unknown template: {template}");
                }

                return Ok(new
                {
                    success = result,
                    message = result ? $"{template} email sent to {email}" : "Email failed to send",
                    template = template,
                    recipient = email
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }
}

