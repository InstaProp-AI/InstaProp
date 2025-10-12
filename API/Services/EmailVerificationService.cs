using System;
using System.Threading.Tasks;

namespace PropertyFlipperAPI.Services
{
    public class EmailVerificationService
    {
        private readonly Random _random = new Random();
        private readonly SmtpEmailService _smtpService;
        private readonly EmailTemplateService _templateService;

        public EmailVerificationService(SmtpEmailService smtpService, EmailTemplateService templateService)
        {
            _smtpService = smtpService;
            _templateService = templateService;
        }

        /// <summary>
        /// Generates a 6-digit PIN for email verification
        /// </summary>
        public string GenerateEmailPin()
        {
            return _random.Next(100000, 999999).ToString();
        }

        /// <summary>
        /// Sends verification email with PIN
        /// </summary>
        public async Task<bool> SendVerificationEmail(string email, string pin, string firstName)
        {
            var subject = "Verify Your Email - Property Flipper";
            var htmlBody = _templateService.GetEmailVerificationEmail(firstName, pin);

            return await _smtpService.SendEmailAsync(email, firstName, subject, htmlBody);
        }

        /// <summary>
        /// Validates the PIN expiry time (15 minutes from generation)
        /// </summary>
        public bool IsPinValid(DateTime? pinExpiry)
        {
            if (pinExpiry == null) return false;
            return DateTime.UtcNow <= pinExpiry.Value;
        }

        /// <summary>
        /// Gets PIN expiry time (15 minutes from now)
        /// </summary>
        public DateTime GetPinExpiry()
        {
            return DateTime.UtcNow.AddMinutes(15);
        }

        /// <summary>
        /// Sends password reset email with temporary password
        /// </summary>
        public async Task<bool> SendPasswordResetEmail(string email, string firstName, string temporaryPassword)
        {
            var subject = "Password Reset - Property Flipper";
            var htmlBody = _templateService.GetPasswordResetEmail(firstName, temporaryPassword);

            return await _smtpService.SendEmailAsync(email, firstName, subject, htmlBody);
        }

        /// <summary>
        /// Sends account lockout notification email
        /// </summary>
        public async Task<bool> SendAccountLockoutEmail(string email, string firstName, DateTime lockedUntil)
        {
            var subject = "Account Temporarily Locked - Property Flipper";
            var htmlBody = _templateService.GetAccountLockoutEmail(firstName, lockedUntil);

            return await _smtpService.SendEmailAsync(email, firstName, subject, htmlBody);
        }

        /// <summary>
        /// Sends welcome email to new users
        /// </summary>
        public async Task<bool> SendWelcomeEmail(string email, string firstName)
        {
            var subject = "Welcome to Property Flipper! 🎉";
            var htmlBody = _templateService.GetWelcomeEmail(firstName);

            return await _smtpService.SendEmailAsync(email, firstName, subject, htmlBody);
        }
    }
}


