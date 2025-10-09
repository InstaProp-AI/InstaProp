using System;
using System.Threading.Tasks;

namespace PropertyFlipperAPI.Services
{
    public class EmailVerificationService
    {
        private readonly Random _random = new Random();

        /// <summary>
        /// Generates a 6-digit PIN for email verification
        /// </summary>
        public string GenerateEmailPin()
        {
            return _random.Next(100000, 999999).ToString();
        }

        /// <summary>
        /// Sends verification email with PIN
        /// TODO: Implement actual email sending with your email service (SendGrid, SMTP, etc.)
        /// </summary>
        public async Task<bool> SendVerificationEmail(string email, string pin, string firstName)
        {
            // For now, just log the PIN (you'll replace this with actual email sending)
            Console.WriteLine($"===== EMAIL VERIFICATION =====");
            Console.WriteLine($"To: {email}");
            Console.WriteLine($"Subject: Verify Your Email - Property Flipper");
            Console.WriteLine($"");
            Console.WriteLine($"Hi {firstName},");
            Console.WriteLine($"");
            Console.WriteLine($"Your email verification PIN is: {pin}");
            Console.WriteLine($"This PIN will expire in 15 minutes.");
            Console.WriteLine($"");
            Console.WriteLine($"If you didn't request this, please ignore this email.");
            Console.WriteLine($"==============================");

            // TODO: Replace with actual email sending logic
            // Example with SendGrid:
            // var client = new SendGridClient(apiKey);
            // var msg = new SendGridMessage()
            // {
            //     From = new EmailAddress("noreply@propertyflipper.com", "Property Flipper"),
            //     Subject = "Verify Your Email",
            //     PlainTextContent = $"Your verification PIN is: {pin}",
            //     HtmlContent = $"<strong>Your verification PIN is: {pin}</strong>"
            // };
            // msg.AddTo(new EmailAddress(email));
            // await client.SendEmailAsync(msg);

            await Task.Delay(100); // Simulate async operation
            return true;
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
        /// TODO: Implement actual email sending with your email service
        /// </summary>
        public async Task<bool> SendPasswordResetEmail(string email, string firstName, string temporaryPassword)
        {
            // For now, just log the password (you'll replace this with actual email sending)
            Console.WriteLine($"===== PASSWORD RESET =====");
            Console.WriteLine($"To: {email}");
            Console.WriteLine($"Subject: Password Reset - Property Flipper");
            Console.WriteLine($"");
            Console.WriteLine($"Hi {firstName},");
            Console.WriteLine($"");
            Console.WriteLine($"You requested a password reset for your Property Flipper account.");
            Console.WriteLine($"");
            Console.WriteLine($"Your temporary password is: {temporaryPassword}");
            Console.WriteLine($"");
            Console.WriteLine($"IMPORTANT: You will be required to change this password upon your next login.");
            Console.WriteLine($"");
            Console.WriteLine($"If you didn't request this, please contact support immediately.");
            Console.WriteLine($"==============================");

            await Task.Delay(100); // Simulate async operation
            return true;
        }
    }
}

