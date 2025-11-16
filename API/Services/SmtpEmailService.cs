using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using System;
using System.Threading.Tasks;

namespace InstapropAPI.Services
{
    /// <summary>
    /// Service for sending emails via SMTP (Gmail)
    /// </summary>
    public class SmtpEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<SmtpEmailService> _logger;
        private readonly bool _isEnabled;

        public SmtpEmailService(IConfiguration configuration, ILogger<SmtpEmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;

            // Check if email is properly configured
            var smtpServer = configuration["Email:SmtpServer"];
            var senderEmail = configuration["Email:SenderEmail"];
            var password = configuration["Email:Password"];

            _isEnabled = !string.IsNullOrEmpty(smtpServer) &&
                        !string.IsNullOrEmpty(senderEmail) &&
                        !string.IsNullOrEmpty(password) &&
                        password != "YOUR_APP_PASSWORD_HERE";

            if (_isEnabled)
            {
                _logger.LogInformation("✅ SMTP Email Service enabled");
            }
            else
            {
                _logger.LogWarning("⚠️ SMTP Email Service disabled - Check appsettings.json Email configuration");
            }
        }

        /// <summary>
        /// Sends an email with HTML content
        /// </summary>
        public async Task<bool> SendEmailAsync(string toEmail, string toName, string subject, string htmlBody, string? plainTextBody = null)
        {
            if (!_isEnabled)
            {
                _logger.LogInformation($"📧 [Email Disabled] Would send to: {toEmail}");
                _logger.LogInformation($"   Subject: {subject}");
                return false;
            }

            try
            {
                var message = new MimeMessage();

                // From
                var senderEmail = _configuration["Email:SenderEmail"];
                var senderName = _configuration["Email:SenderName"] ?? "Instaprop";
                message.From.Add(new MailboxAddress(senderName, senderEmail));

                // To
                message.To.Add(new MailboxAddress(toName, toEmail));

                // Subject
                message.Subject = subject;

                // Body
                var bodyBuilder = new BodyBuilder
                {
                    HtmlBody = htmlBody,
                    TextBody = plainTextBody ?? StripHtml(htmlBody)
                };
                message.Body = bodyBuilder.ToMessageBody();

                // Send
                using (var client = new SmtpClient())
                {
                    var smtpServer = _configuration["Email:SmtpServer"];
                    var smtpPort = int.Parse(_configuration["Email:SmtpPort"] ?? "587");
                    var username = _configuration["Email:Username"];
                    var password = _configuration["Email:Password"];
                    var enableSsl = bool.Parse(_configuration["Email:EnableSsl"] ?? "true");

                    // Connect to SMTP server
                    await client.ConnectAsync(smtpServer, smtpPort, enableSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.None);

                    // Authenticate
                    await client.AuthenticateAsync(username, password);

                    // Send
                    await client.SendAsync(message);

                    // Disconnect
                    await client.DisconnectAsync(true);

                    _logger.LogInformation($"✅ Email sent successfully to: {toEmail}");
                    _logger.LogInformation($"   Subject: {subject}");
                    
                    return true;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Failed to send email to: {toEmail}");
                _logger.LogError($"   Subject: {subject}");
                _logger.LogError($"   Error: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Strips HTML tags for plain text version
        /// </summary>
        private string StripHtml(string html)
        {
            if (string.IsNullOrEmpty(html))
                return string.Empty;

            // Simple HTML stripping - removes tags
            var text = System.Text.RegularExpressions.Regex.Replace(html, "<.*?>", string.Empty);
            
            // Decode HTML entities
            text = System.Net.WebUtility.HtmlDecode(text);
            
            // Clean up multiple spaces and line breaks
            text = System.Text.RegularExpressions.Regex.Replace(text, @"\s+", " ");
            text = text.Trim();
            
            return text;
        }
    }
}

