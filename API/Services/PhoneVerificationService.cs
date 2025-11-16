using System;
using System.Threading.Tasks;

namespace InstapropAPI.Services
{
    public class PhoneVerificationService
    {
        private readonly Random _random = new Random();

        /// <summary>
        /// Generates a 6-digit PIN for phone verification
        /// </summary>
        public string GeneratePhonePin()
        {
            return _random.Next(100000, 999999).ToString();
        }

        /// <summary>
        /// Sends verification SMS with PIN
        /// TODO: Implement actual SMS sending with your SMS service (Twilio, AWS SNS, etc.)
        /// </summary>
        public async Task<bool> SendVerificationSMS(string phoneNumber, string pin, string firstName)
        {
            // For now, just log the PIN (you'll replace this with actual SMS sending)
            Console.WriteLine($"===== SMS VERIFICATION =====");
            Console.WriteLine($"To: {phoneNumber}");
            Console.WriteLine($"");
            Console.WriteLine($"Hi {firstName},");
            Console.WriteLine($"Your Instaprop verification code is: {pin}");
            Console.WriteLine($"Valid for 15 minutes.");
            Console.WriteLine($"============================");

            // TODO: Replace with actual SMS sending logic
            // Example with Twilio:
            // var accountSid = _configuration["Twilio:AccountSid"];
            // var authToken = _configuration["Twilio:AuthToken"];
            // TwilioClient.Init(accountSid, authToken);
            // 
            // var message = await MessageResource.CreateAsync(
            //     body: $"Your Instaprop verification code is: {pin}. Valid for 15 minutes.",
            //     from: new Twilio.Types.PhoneNumber(_configuration["Twilio:PhoneNumber"]),
            //     to: new Twilio.Types.PhoneNumber(phoneNumber)
            // );

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
    }
}

