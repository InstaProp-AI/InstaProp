using System;
using System.Threading.Tasks;
using InstapropAPI.Models;

namespace InstapropAPI.Services
{
    /// <summary>
    /// Service for sending auction-related email notifications
    /// </summary>
    public class AuctionNotificationService
    {
        private readonly SmtpEmailService _smtpService;
        private readonly EmailTemplateService _templateService;
        private readonly ILogger<AuctionNotificationService> _logger;

        public AuctionNotificationService(
            SmtpEmailService smtpService,
            EmailTemplateService templateService,
            ILogger<AuctionNotificationService> logger)
        {
            _smtpService = smtpService;
            _templateService = templateService;
            _logger = logger;
        }

        /// <summary>
        /// Sends notification that an auction is starting soon
        /// </summary>
        public async Task<bool> SendAuctionStartingSoonNotification(
            string userEmail,
            string userName,
            Auction auction)
        {
            try
            {
                var subject = $"Auction Starting Soon: {auction.Property.Name}";
                var htmlBody = _templateService.GetAuctionStartingSoonEmail(
                    userName,
                    auction.Property.Name,
                    auction.Property.Location,
                    auction.StartPrice,
                    auction.StartAt,
                    auction.Property.ImageUrl ?? "https://via.placeholder.com/600x200",
                    auction.AuctionId.ToString()
                );

                var result = await _smtpService.SendEmailAsync(userEmail, userName, subject, htmlBody);
                
                if (result)
                    _logger.LogInformation($"✅ Auction starting notification sent to {userEmail}");
                
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to send auction starting notification to {userEmail}");
                return false;
            }
        }

        /// <summary>
        /// Sends notification that user has been outbid
        /// </summary>
        public async Task<bool> SendOutbidNotification(
            string userEmail,
            string userName,
            string propertyName,
            decimal userBid,
            decimal currentBid,
            DateTime auctionEndTime,
            int auctionId)
        {
            try
            {
                var subject = $"You've Been Outbid: {propertyName}";
                var htmlBody = _templateService.GetOutbidNotificationEmail(
                    userName,
                    propertyName,
                    userBid,
                    currentBid,
                    auctionEndTime,
                    auctionId
                );

                var result = await _smtpService.SendEmailAsync(userEmail, userName, subject, htmlBody);
                
                if (result)
                    _logger.LogInformation($"✅ Outbid notification sent to {userEmail}");
                
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to send outbid notification to {userEmail}");
                return false;
            }
        }

        /// <summary>
        /// Sends notification that user won the auction
        /// </summary>
        public async Task<bool> SendAuctionWonNotification(
            string userEmail,
            string userName,
            Auction auction,
            decimal winningBid)
        {
            try
            {
                var subject = $"🎉 Congratulations! You Won: {auction.Property.Name}";
                var htmlBody = _templateService.GetAuctionWonEmail(
                    userName,
                    auction.Property.Name,
                    auction.Property.Location,
                    winningBid,
                    auction.Property.ImageUrl ?? "https://via.placeholder.com/600x200",
                    auction.AuctionId.ToString()
                );

                var result = await _smtpService.SendEmailAsync(userEmail, userName, subject, htmlBody);
                
                if (result)
                    _logger.LogInformation($"✅ Auction won notification sent to {userEmail}");
                
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to send auction won notification to {userEmail}");
                return false;
            }
        }

        /// <summary>
        /// Sends payment reminder for won auction
        /// </summary>
        public async Task<bool> SendPaymentReminder(
            string userEmail,
            string userName,
            string propertyName,
            decimal amount,
            DateTime dueDate)
        {
            try
            {
                var daysRemaining = Math.Max(0, (int)(dueDate - DateTime.UtcNow).TotalDays);
                var subject = $"Payment Reminder: {propertyName} ({daysRemaining} days remaining)";
                
                var htmlBody = _templateService.GetPaymentReminderEmail(
                    userName,
                    propertyName,
                    amount,
                    dueDate,
                    daysRemaining
                );

                var result = await _smtpService.SendEmailAsync(userEmail, userName, subject, htmlBody);
                
                if (result)
                    _logger.LogInformation($"✅ Payment reminder sent to {userEmail}");
                
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to send payment reminder to {userEmail}");
                return false;
            }
        }
    }
}

