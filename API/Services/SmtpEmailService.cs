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
        private readonly string? _smtpServer;
        private readonly int _smtpPort;
        private readonly string? _senderEmail;
        private readonly string _senderName;
        private readonly string? _username;
        private readonly string? _password;
        private readonly bool _enableSsl;

        public SmtpEmailService(IConfiguration configuration, ILogger<SmtpEmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;

            // Read from environment variables first, then fall back to configuration
            // This allows Railway environment variables to override production config
            _smtpServer = GetConfigValue("EMAIL_SMTP_SERVER", "Email:SmtpServer");
            _smtpPort = int.Parse(GetConfigValue("EMAIL_SMTP_PORT", "Email:SmtpPort") ?? "587");
            _senderEmail = GetConfigValue("EMAIL_SENDER_EMAIL", "Email:SenderEmail");
            _senderName = GetConfigValue("EMAIL_SENDER_NAME", "Email:SenderName") ?? "Instaprop";
            _username = GetConfigValue("EMAIL_USERNAME", "Email:Username");
            _password = GetConfigValue("EMAIL_PASSWORD", "Email:Password");
            _enableSsl = bool.Parse(GetConfigValue("EMAIL_ENABLE_SSL", "Email:EnableSsl") ?? "true");

            // Check if email is properly configured (not empty and not placeholder values)
            var placeholderValues = new[] { "YOUR_APP_PASSWORD_HERE", "REPLACE_WITH_SMTP_USERNAME", "REPLACE_WITH_SMTP_PASSWORD", 
                                           "REPLACE_WITH_SMTP_SERVER", "REPLACE_WITH_SENDER_EMAIL", "noreply@yourdomain.com" };

            _isEnabled = !string.IsNullOrEmpty(_smtpServer) &&
                        !string.IsNullOrEmpty(_senderEmail) &&
                        !string.IsNullOrEmpty(_password) &&
                        !string.IsNullOrEmpty(_username) &&
                        !placeholderValues.Contains(_password, StringComparer.OrdinalIgnoreCase) &&
                        !placeholderValues.Contains(_username, StringComparer.OrdinalIgnoreCase) &&
                        !placeholderValues.Contains(_smtpServer, StringComparer.OrdinalIgnoreCase) &&
                        !placeholderValues.Contains(_senderEmail, StringComparer.OrdinalIgnoreCase);

            if (_isEnabled)
            {
                var configSource = Environment.GetEnvironmentVariable("EMAIL_SMTP_SERVER") != null ? "environment variables" : "configuration file";
                _logger.LogInformation("✅ SMTP Email Service enabled (using {ConfigSource})", configSource);
                _logger.LogInformation("   SMTP Server: {SmtpServer}:{SmtpPort}", _smtpServer ?? "unknown", _smtpPort);
                _logger.LogInformation("   Sender: {SenderEmail} ({SenderName})", _senderEmail ?? "unknown", _senderName);
            }
            else
            {
                _logger.LogWarning("⚠️ SMTP Email Service disabled - Check Email configuration");
                _logger.LogWarning("   Required: EMAIL_SMTP_SERVER (or Email:SmtpServer)");
                _logger.LogWarning("   Required: EMAIL_SENDER_EMAIL (or Email:SenderEmail)");
                _logger.LogWarning("   Required: EMAIL_USERNAME (or Email:Username)");
                _logger.LogWarning("   Required: EMAIL_PASSWORD (or Email:Password)");
            }
        }

        /// <summary>
        /// Gets configuration value from environment variable first, then falls back to configuration file
        /// </summary>
        private string? GetConfigValue(string envVarName, string configKey)
        {
            var envValue = Environment.GetEnvironmentVariable(envVarName);
            if (!string.IsNullOrEmpty(envValue))
            {
                return envValue;
            }
            return _configuration[configKey];
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
                message.From.Add(new MailboxAddress(_senderName, _senderEmail));

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
                    // Connect to SMTP server
                    await client.ConnectAsync(_smtpServer!, _smtpPort, _enableSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.None);

                    // Authenticate
                    await client.AuthenticateAsync(_username!, _password!);

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

