using System;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Collections.Generic;

namespace InstapropAPI.Services
{
    public class PhoneVerificationService
    {
        private readonly Random _random = new Random();
        private readonly IConfiguration _configuration;
        private readonly ILogger<PhoneVerificationService> _logger;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly string? _accountSid;
        private readonly string? _authToken;
        private readonly string? _phoneNumber;
        private readonly string? _messagingServiceSid;
        private readonly bool _isEnabled;

        public PhoneVerificationService(
            IConfiguration configuration,
            ILogger<PhoneVerificationService> logger,
            IHttpClientFactory httpClientFactory)
        {
            _configuration = configuration;
            _logger = logger;
            _httpClientFactory = httpClientFactory;

            // Read SMS configuration
            _accountSid = _configuration["SMS:AccountSid"];
            _authToken = _configuration["SMS:AuthToken"];
            _phoneNumber = _configuration["SMS:PhoneNumber"];
            _messagingServiceSid = _configuration["SMS:MessagingServiceSid"];
            _isEnabled = !string.IsNullOrEmpty(_accountSid) && 
                        !string.IsNullOrEmpty(_authToken) && 
                        (!string.IsNullOrEmpty(_phoneNumber) || !string.IsNullOrEmpty(_messagingServiceSid));

            if (_isEnabled)
            {
                _logger.LogInformation("✅ SMS Service enabled (Twilio)");
            }
            else
            {
                _logger.LogWarning("⚠️ SMS Service disabled - Missing configuration (AccountSid, AuthToken, or PhoneNumber)");
            }
        }

        /// <summary>
        /// Generates a 6-digit PIN for phone verification
        /// </summary>
        public string GeneratePhonePin()
        {
            return _random.Next(100000, 999999).ToString();
        }

        /// <summary>
        /// Formats phone number to E.164 format (required by Twilio)
        /// E.164 format: +[country code][subscriber number including area code]
        /// Example: +12345678901 (US), +201234567890 (Egypt)
        /// </summary>
        private string FormatPhoneNumber(string phoneNumber)
        {
            if (string.IsNullOrWhiteSpace(phoneNumber))
                return phoneNumber;

            // Remove all whitespace first
            var cleaned = phoneNumber.Trim();

            // Check if it already starts with +
            bool hasPlus = cleaned.StartsWith("+");
            
            // Remove all non-digit characters (including spaces, dashes, parentheses, etc.)
            // but preserve the + if it exists
            var digitsOnly = new System.Text.StringBuilder();
            if (hasPlus)
            {
                digitsOnly.Append("+");
            }
            
            foreach (char c in cleaned)
            {
                if (char.IsDigit(c))
                {
                    digitsOnly.Append(c);
                }
            }

            var result = digitsOnly.ToString();

            // If it already starts with +, validate and return
            if (result.StartsWith("+"))
            {
                // E.164 requires: + followed by 1-15 digits
                var digitsAfterPlus = result.Substring(1);
                if (digitsAfterPlus.Length >= 1 && digitsAfterPlus.Length <= 15)
                {
                    return result;
                }
                else
                {
                    _logger.LogWarning("Phone number with + has invalid length: {PhoneNumber} (digits: {DigitCount})", 
                        phoneNumber, digitsAfterPlus.Length);
                    return result; // Return anyway, let Twilio validate
                }
            }

            // If it starts with 00 (international format), replace with +
            if (result.StartsWith("00") && result.Length > 2)
            {
                return "+" + result.Substring(2);
            }

            // Handle Egyptian numbers (country code 20)
            // Egyptian numbers can be stored as:
            // - 01205858069 (with leading 0, should become +201205858069)
            // - 201205858069 (without leading 0, should become +201205858069)
            // - 1205858069 (missing country code, should become +201205858069)
            if (result.StartsWith("0") && result.Length == 12)
            {
                // Egyptian number with leading 0: remove 0 and add +20
                return "+20" + result.Substring(1);
            }
            else if (result.StartsWith("20") && result.Length == 12)
            {
                // Egyptian number with country code but no +
                return "+" + result;
            }
            else if (result.Length == 10 && !result.StartsWith("1"))
            {
                // 10 digits not starting with 1: likely Egyptian number missing country code
                return "+20" + result;
            }

            // If no + and no 00, try to determine country code
            // Common cases:
            // - 10 digits: US/Canada (+1)
            // - 11 digits starting with 1: US/Canada (+1)
            // - Otherwise: assume user forgot country code, but we'll try with + anyway
            
            if (result.Length == 10)
            {
                // 10 digits: assume US/Canada
                return "+1" + result;
            }
            else if (result.Length == 11 && result.StartsWith("1"))
            {
                // 11 digits starting with 1: US/Canada (already has country code)
                return "+" + result;
            }
            else if (result.Length >= 7 && result.Length <= 15)
            {
                // Valid length for international number, add + and assume country code is included
                return "+" + result;
            }
            else
            {
                // Invalid length, log warning but return formatted anyway
                _logger.LogWarning("Phone number has unusual length: {PhoneNumber} (digits: {DigitCount}), formatting as: +{Formatted}", 
                    phoneNumber, result.Length, result);
                return "+" + result;
            }
        }

        /// <summary>
        /// Sends verification SMS with PIN using Twilio API
        /// </summary>
        public async Task<bool> SendVerificationSMS(string phoneNumber, string pin, string firstName)
        {
            if (!_isEnabled)
            {
                _logger.LogWarning("SMS sending skipped - Service not configured");
                // In development, still log the PIN for testing
                _logger.LogInformation($"===== SMS VERIFICATION (DEV MODE) =====");
                _logger.LogInformation($"To: {phoneNumber}");
                _logger.LogInformation($"PIN: {pin}");
                _logger.LogInformation($"============================");
                return false;
            }

            try
            {
                // Format phone number to E.164 format
                var formattedPhone = FormatPhoneNumber(phoneNumber);
                
                if (string.IsNullOrWhiteSpace(formattedPhone))
                {
                    _logger.LogError("Invalid phone number provided: {PhoneNumber}", phoneNumber);
                    return false;
                }

                // Validate E.164 format: must start with + and have 1-15 digits after
                if (!formattedPhone.StartsWith("+"))
                {
                    _logger.LogError("Phone number does not start with +: {FormattedPhone} (original: {OriginalPhone})", 
                        formattedPhone, phoneNumber);
                    return false;
                }

                var digitsAfterPlus = formattedPhone.Substring(1);
                if (string.IsNullOrWhiteSpace(digitsAfterPlus) || digitsAfterPlus.Length < 1 || digitsAfterPlus.Length > 15)
                {
                    _logger.LogError("Phone number has invalid length: {FormattedPhone} (digits: {DigitCount}, original: {OriginalPhone})", 
                        formattedPhone, digitsAfterPlus.Length, phoneNumber);
                    return false;
                }

                // Log the formatted number for debugging
                _logger.LogInformation("Phone number formatted: {OriginalPhone} -> {FormattedPhone}", 
                    phoneNumber, formattedPhone);

                // Construct verification message
                // Use simple, short message to avoid carrier filtering
                // Keep it minimal to reduce spam filter triggers
                var messageBody = $"Your Instaprop PIN: {pin}";

                // Create HTTP client
                var httpClient = _httpClientFactory.CreateClient();
                
                // Twilio API endpoint
                var apiUrl = $"https://api.twilio.com/2010-04-01/Accounts/{_accountSid}/Messages.json";

                // Create Basic Auth header (Account SID as username, Auth Token as password)
                var authValue = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_accountSid}:{_authToken}"));
                httpClient.DefaultRequestHeaders.Authorization = 
                    new System.Net.Http.Headers.AuthenticationHeaderValue("Basic", authValue);

                // Prepare form data
                var formData = new List<KeyValuePair<string, string>>
                {
                    new KeyValuePair<string, string>("To", formattedPhone),
                    new KeyValuePair<string, string>("Body", messageBody)
                };

                // Use Messaging Service SID if available (better deliverability), otherwise use From phone number
                if (!string.IsNullOrEmpty(_messagingServiceSid))
                {
                    formData.Add(new KeyValuePair<string, string>("MessagingServiceSid", _messagingServiceSid));
                    _logger.LogInformation("Using Messaging Service SID: {MessagingServiceSid}", _messagingServiceSid);
                }
                else if (!string.IsNullOrEmpty(_phoneNumber))
                {
                    formData.Add(new KeyValuePair<string, string>("From", _phoneNumber));
                    _logger.LogInformation("Using From phone number: {PhoneNumber}", _phoneNumber);
                }
                else
                {
                    _logger.LogError("Neither MessagingServiceSid nor PhoneNumber is configured");
                    return false;
                }

                var formContent = new FormUrlEncodedContent(formData);

                // Send SMS via Twilio API
                _logger.LogInformation("Sending SMS to {PhoneNumber} via Twilio", formattedPhone);
                var response = await httpClient.PostAsync(apiUrl, formContent);
                var responseContent = await response.Content.ReadAsStringAsync();

                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation("SMS sent successfully to {PhoneNumber}", formattedPhone);
                    return true;
                }
                else
                {
                    // Try to parse Twilio error response
                    try
                    {
                        using var jsonDoc = JsonDocument.Parse(responseContent);
                        var errorMessage = jsonDoc.RootElement.TryGetProperty("message", out var messageProp) 
                            ? messageProp.GetString() 
                            : "Unknown error";
                        var errorCode = jsonDoc.RootElement.TryGetProperty("code", out var codeProp) 
                            ? codeProp.GetInt32() 
                            : 0;

                        _logger.LogError("Twilio API error: Code {ErrorCode}, Message: {ErrorMessage}, Status: {StatusCode}", 
                            errorCode, errorMessage, response.StatusCode);
                    }
                    catch
                    {
                        _logger.LogError("Twilio API error: Status {StatusCode}, Response: {Response}", 
                            response.StatusCode, responseContent);
                    }
                    
                    return false;
                }
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "Network error while sending SMS to {PhoneNumber}", phoneNumber);
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error while sending SMS to {PhoneNumber}", phoneNumber);
                return false;
            }
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

