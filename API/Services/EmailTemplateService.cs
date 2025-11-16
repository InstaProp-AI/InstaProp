using System;
using System.Text;

namespace InstapropAPI.Services
{
    /// <summary>
    /// Service for generating branded HTML email templates
    /// </summary>
    public class EmailTemplateService
    {
        private const string BrandColor = "#2563eb"; // Blue
        private const string AccentColor = "#f59e0b"; // Orange
        private const string TextColor = "#1f2937"; // Dark gray
        private const string LightBgColor = "#f3f4f6"; // Light gray

        /// <summary>
        /// Gets the base HTML template with header and footer
        /// </summary>
        private string GetBaseTemplate(string title, string content)
        {
            return $@"
<!DOCTYPE html>
<html lang=""en"">
<head>
    <meta charset=""UTF-8"">
    <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">
    <title>{title}</title>
    <style>
        body {{
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background-color: {LightBgColor};
            color: {TextColor};
        }}
        .email-container {{
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
        }}
        .header {{
            background: linear-gradient(135deg, {BrandColor} 0%, #1e40af 100%);
            padding: 30px 20px;
            text-align: center;
        }}
        .header h1 {{
            color: #ffffff;
            margin: 0;
            font-size: 28px;
            font-weight: 700;
        }}
        .header p {{
            color: #e0e7ff;
            margin: 5px 0 0 0;
            font-size: 14px;
        }}
        .content {{
            padding: 40px 30px;
        }}
        .content h2 {{
            color: {TextColor};
            font-size: 24px;
            margin-top: 0;
            margin-bottom: 20px;
        }}
        .content p {{
            color: #4b5563;
            font-size: 16px;
            line-height: 1.6;
            margin-bottom: 15px;
        }}
        .code-box {{
            background-color: {LightBgColor};
            border-left: 4px solid {BrandColor};
            padding: 20px;
            margin: 25px 0;
            text-align: center;
        }}
        .code {{
            font-size: 32px;
            font-weight: 700;
            color: {BrandColor};
            letter-spacing: 8px;
            font-family: 'Courier New', monospace;
        }}
        .button {{
            display: inline-block;
            background-color: {BrandColor};
            color: #ffffff !important;
            padding: 14px 32px;
            text-decoration: none;
            border-radius: 6px;
            font-weight: 600;
            margin: 20px 0;
            text-align: center;
        }}
        .button:hover {{
            background-color: #1e40af;
        }}
        .info-box {{
            background-color: #eff6ff;
            border: 1px solid #bfdbfe;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
        }}
        .warning-box {{
            background-color: #fef3c7;
            border: 1px solid #fde68a;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
        }}
        .success-box {{
            background-color: #d1fae5;
            border: 1px solid #a7f3d0;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
        }}
        .property-card {{
            border: 1px solid #e5e7eb;
            border-radius: 8px;
            overflow: hidden;
            margin: 20px 0;
        }}
        .property-image {{
            width: 100%;
            height: 200px;
            object-fit: cover;
        }}
        .property-details {{
            padding: 20px;
        }}
        .property-details h3 {{
            margin: 0 0 10px 0;
            color: {TextColor};
        }}
        .property-price {{
            font-size: 24px;
            font-weight: 700;
            color: {AccentColor};
            margin: 10px 0;
        }}
        .footer {{
            background-color: {LightBgColor};
            padding: 30px 20px;
            text-align: center;
        }}
        .footer p {{
            color: #6b7280;
            font-size: 14px;
            margin: 5px 0;
        }}
        .footer a {{
            color: {BrandColor};
            text-decoration: none;
        }}
        .divider {{
            border: 0;
            border-top: 1px solid #e5e7eb;
            margin: 30px 0;
        }}
    </style>
</head>
<body>
    <div class=""email-container"">
        <div class=""header"">
            <h1>🏠 Instaprop</h1>
            <p>Your Premier Real Estate Auction Platform</p>
        </div>
        <div class=""content"">
            {content}
        </div>
        <div class=""footer"">
            <p><strong>Instaprop</strong></p>
            <p>© {DateTime.UtcNow.Year} Instaprop. All rights reserved.</p>
            <p>
                <a href=""https://propertyflipper.com/help"">Help Center</a> | 
                <a href=""https://propertyflipper.com/contact"">Contact Us</a> | 
                <a href=""https://propertyflipper.com/unsubscribe"">Unsubscribe</a>
            </p>
            <p style=""font-size: 12px; color: #9ca3af; margin-top: 15px;"">
                This email was sent because you have an account with Instaprop.<br>
                Please do not reply to this automated email.
            </p>
        </div>
    </div>
</body>
</html>";
        }

        /// <summary>
        /// Welcome email for new users
        /// </summary>
        public string GetWelcomeEmail(string firstName)
        {
            var content = $@"
                <h2>Welcome to Instaprop, {firstName}! 🎉</h2>
                <p>We're thrilled to have you join our community of real estate investors and developers.</p>
                
                <div class=""success-box"">
                    <p style=""margin: 0;""><strong>✅ Your account has been created successfully!</strong></p>
                </div>

                <p>Instaprop is your gateway to discovering and bidding on premium real estate opportunities. Here's what you can do:</p>
                
                <div style=""margin: 20px 0;"">
                    <p style=""margin: 10px 0;"">🏡 <strong>Browse Properties</strong> - Explore our curated selection of properties</p>
                    <p style=""margin: 10px 0;"">💰 <strong>Place Bids</strong> - Participate in live auctions</p>
                    <p style=""margin: 10px 0;"">📊 <strong>Track Investments</strong> - Monitor your bidding activity</p>
                    <p style=""margin: 10px 0;"">🔔 <strong>Get Notifications</strong> - Stay updated on auction status</p>
                </div>

                <div style=""text-align: center; margin: 30px 0;"">
                    <a href=""https://propertyflipper.com/properties"" class=""button"">Start Browsing Properties</a>
                </div>

                <hr class=""divider"">

                <h3>Next Steps:</h3>
                <ol style=""color: #4b5563; line-height: 1.8;"">
                    <li><strong>Verify your email</strong> - Check for our verification email</li>
                    <li><strong>Complete your profile</strong> - Add your details and preferences</li>
                    <li><strong>Upload KYC documents</strong> - Required for bidding on properties</li>
                    <li><strong>Start exploring</strong> - Browse available properties and auctions</li>
                </ol>

                <div class=""info-box"">
                    <p style=""margin: 0; font-size: 14px;"">
                        <strong>💡 Pro Tip:</strong> Complete your KYC verification early to avoid delays when you're ready to bid!
                    </p>
                </div>

                <p>If you have any questions, our support team is here to help.</p>
                <p>Happy bidding!</p>
                <p style=""margin-top: 30px;""><strong>The Instaprop Team</strong></p>
            ";

            return GetBaseTemplate("Welcome to Instaprop", content);
        }

        /// <summary>
        /// Email verification with PIN code
        /// </summary>
        public string GetEmailVerificationEmail(string firstName, string pin)
        {
            var content = $@"
                <h2>Verify Your Email Address</h2>
                <p>Hi {firstName},</p>
                <p>Thank you for signing up for Instaprop! To complete your registration, please verify your email address using the code below:</p>
                
                <div class=""code-box"">
                    <p style=""margin: 0 0 10px 0; font-size: 14px; color: #6b7280;"">Your Verification Code</p>
                    <div class=""code"">{pin}</div>
                    <p style=""margin: 10px 0 0 0; font-size: 14px; color: #6b7280;"">Expires in 15 minutes</p>
                </div>

                <p>Enter this code in the app to verify your email address.</p>

                <div class=""warning-box"">
                    <p style=""margin: 0; font-size: 14px;"">
                        <strong>⚠️ Security Notice:</strong> If you didn't create an account with Instaprop, please ignore this email.
                    </p>
                </div>

                <p>This verification code will expire in 15 minutes for security purposes.</p>
                <p>Best regards,<br><strong>The Instaprop Team</strong></p>
            ";

            return GetBaseTemplate("Verify Your Email - Instaprop", content);
        }

        /// <summary>
        /// Password reset email with temporary password
        /// </summary>
        public string GetPasswordResetEmail(string firstName, string temporaryPassword)
        {
            var content = $@"
                <h2>Password Reset Request</h2>
                <p>Hi {firstName},</p>
                <p>We received a request to reset your password for your Instaprop account.</p>
                
                <div class=""code-box"">
                    <p style=""margin: 0 0 10px 0; font-size: 14px; color: #6b7280;"">Your Temporary Password</p>
                    <div class=""code"" style=""font-size: 28px; letter-spacing: 4px;"">{temporaryPassword}</div>
                    <p style=""margin: 10px 0 0 0; font-size: 14px; color: #6b7280;"">Valid for 24 hours</p>
                </div>

                <div class=""warning-box"">
                    <p style=""margin: 0 0 10px 0;""><strong>⚠️ Important:</strong></p>
                    <ul style=""margin: 0; padding-left: 20px;"">
                        <li>You will be required to change this password upon your next login</li>
                        <li>This temporary password expires in 24 hours</li>
                        <li>Your old password will no longer work</li>
                    </ul>
                </div>

                <div style=""text-align: center; margin: 30px 0;"">
                    <a href=""https://propertyflipper.com/login"" class=""button"">Login Now</a>
                </div>

                <div class=""info-box"">
                    <p style=""margin: 0; font-size: 14px;"">
                        <strong>🔒 Security Tip:</strong> Choose a strong password that's unique to Instaprop and includes a mix of letters, numbers, and symbols.
                    </p>
                </div>

                <hr class=""divider"">

                <p><strong>Didn't request this?</strong></p>
                <p>If you didn't request a password reset, please contact our support team immediately at <a href=""mailto:support@propertyflipper.com"">support@propertyflipper.com</a>. Your account may be compromised.</p>

                <p>Best regards,<br><strong>The Instaprop Security Team</strong></p>
            ";

            return GetBaseTemplate("Password Reset - Instaprop", content);
        }

        /// <summary>
        /// Account lockout notification
        /// </summary>
        public string GetAccountLockoutEmail(string firstName, DateTime lockedUntil)
        {
            var minutesRemaining = Math.Ceiling((lockedUntil - DateTime.UtcNow).TotalMinutes);
            
            var content = $@"
                <h2>Account Temporarily Locked</h2>
                <p>Hi {firstName},</p>
                
                <div class=""warning-box"">
                    <p style=""margin: 0 0 10px 0;""><strong>⚠️ Security Alert</strong></p>
                    <p style=""margin: 0;"">Your account has been temporarily locked due to multiple failed login attempts.</p>
                </div>

                <p><strong>Locked Until:</strong> {lockedUntil:MMMM dd, yyyy HH:mm} UTC</p>
                <p><strong>Time Remaining:</strong> Approximately {minutesRemaining} minutes</p>

                <div class=""info-box"">
                    <p style=""margin: 0 0 10px 0;""><strong>🔐 What happened?</strong></p>
                    <p style=""margin: 0;"">For your security, we temporarily lock accounts after 5 failed login attempts. This helps protect your account from unauthorized access.</p>
                </div>

                <h3>What to do next:</h3>
                <ol style=""color: #4b5563; line-height: 1.8;"">
                    <li><strong>Wait for the lockout period to expire</strong> (approximately 30 minutes)</li>
                    <li><strong>Try logging in again</strong> with the correct password</li>
                    <li><strong>Use the ""Forgot Password"" option</strong> if you can't remember your password</li>
                </ol>

                <div style=""text-align: center; margin: 30px 0;"">
                    <a href=""https://propertyflipper.com/forgot-password"" class=""button"">Reset Password</a>
                </div>

                <hr class=""divider"">

                <p><strong>⚠️ Didn't try to log in?</strong></p>
                <p>If you didn't attempt to log in, your account may be at risk. Please:</p>
                <ul style=""color: #4b5563; line-height: 1.8;"">
                    <li>Change your password immediately after the lockout expires</li>
                    <li>Enable two-factor authentication (coming soon)</li>
                    <li>Contact our security team at <a href=""mailto:security@propertyflipper.com"">security@propertyflipper.com</a></li>
                </ul>

                <p>Best regards,<br><strong>The Instaprop Security Team</strong></p>
            ";

            return GetBaseTemplate("Account Locked - Instaprop", content);
        }

        /// <summary>
        /// Auction starting soon notification
        /// </summary>
        public string GetAuctionStartingSoonEmail(string firstName, string propertyName, string propertyLocation, 
            decimal startPrice, DateTime startTime, string propertyImageUrl, int auctionId)
        {
            var hoursUntilStart = Math.Ceiling((startTime - DateTime.UtcNow).TotalHours);
            
            var content = $@"
                <h2>Auction Starting Soon! ⏰</h2>
                <p>Hi {firstName},</p>
                <p>An auction you're watching is starting soon!</p>

                <div class=""property-card"">
                    <img src=""{propertyImageUrl}"" alt=""{propertyName}"" class=""property-image"" onerror=""this.src='https://via.placeholder.com/600x200/2563eb/ffffff?text=Property+Image'"">
                    <div class=""property-details"">
                        <h3>{propertyName}</h3>
                        <p style=""color: #6b7280; margin: 5px 0;"">📍 {propertyLocation}</p>
                        <div class=""property-price"">${startPrice:N0}</div>
                        <p style=""margin: 5px 0; font-size: 14px; color: #6b7280;"">Starting Price</p>
                    </div>
                </div>

                <div class=""info-box"">
                    <p style=""margin: 0 0 10px 0;""><strong>⏰ Auction Details:</strong></p>
                    <p style=""margin: 5px 0;""><strong>Starts:</strong> {startTime:MMMM dd, yyyy HH:mm} UTC</p>
                    <p style=""margin: 5px 0;""><strong>Time Until Start:</strong> In {hoursUntilStart} hours</p>
                </div>

                <div style=""text-align: center; margin: 30px 0;"">
                    <a href=""https://propertyflipper.com/auctions/{auctionId}"" class=""button"">View Auction Details</a>
                </div>

                <div class=""success-box"">
                    <p style=""margin: 0; font-size: 14px;"">
                        <strong>💡 Pro Tip:</strong> Review the property details and set your maximum bid before the auction starts!
                    </p>
                </div>

                <p>Don't miss out on this opportunity!</p>
                <p>Best regards,<br><strong>The Instaprop Team</strong></p>
            ";

            return GetBaseTemplate("Auction Starting Soon - Instaprop", content);
        }

        /// <summary>
        /// Outbid notification
        /// </summary>
        public string GetOutbidNotificationEmail(string firstName, string propertyName, decimal yourBid, 
            decimal currentBid, DateTime auctionEndTime, int auctionId)
        {
            var hoursRemaining = Math.Ceiling((auctionEndTime - DateTime.UtcNow).TotalHours);
            
            var content = $@"
                <h2>You've Been Outbid! 🔔</h2>
                <p>Hi {firstName},</p>
                <p>Someone has placed a higher bid on a property you're bidding on.</p>

                <div class=""warning-box"">
                    <p style=""margin: 0 0 10px 0;""><strong>⚡ Quick Update:</strong></p>
                    <p style=""margin: 5px 0;""><strong>Property:</strong> {propertyName}</p>
                    <p style=""margin: 5px 0;""><strong>Your Bid:</strong> ${yourBid:N0}</p>
                    <p style=""margin: 5px 0;""><strong>Current High Bid:</strong> <span style=""color: {AccentColor}; font-weight: 700;"">${currentBid:N0}</span></p>
                    <p style=""margin: 5px 0;""><strong>Auction Ends:</strong> In {hoursRemaining} hours</p>
                </div>

                <p>Don't let this opportunity slip away! Place a higher bid now to stay in the running.</p>

                <div style=""text-align: center; margin: 30px 0;"">
                    <a href=""https://propertyflipper.com/auctions/{auctionId}"" class=""button"">Place a New Bid</a>
                </div>

                <div class=""info-box"">
                    <p style=""margin: 0; font-size: 14px;"">
                        <strong>💰 Bidding Strategy:</strong> Consider your maximum budget and the property's value. Don't get caught up in a bidding war beyond your means.
                    </p>
                </div>

                <p>Good luck!</p>
                <p>Best regards,<br><strong>The Instaprop Team</strong></p>
            ";

            return GetBaseTemplate("You've Been Outbid - Instaprop", content);
        }

        /// <summary>
        /// Auction won notification
        /// </summary>
        public string GetAuctionWonEmail(string firstName, string propertyName, string propertyLocation, 
            decimal winningBid, string propertyImageUrl, int auctionId)
        {
            var content = $@"
                <h2>Congratulations! You Won! 🎉🏆</h2>
                <p>Hi {firstName},</p>
                <p><strong>Exciting news!</strong> You've won the auction for:</p>

                <div class=""property-card"">
                    <img src=""{propertyImageUrl}"" alt=""{propertyName}"" class=""property-image"" onerror=""this.src='https://via.placeholder.com/600x200/2563eb/ffffff?text=Property+Image'"">
                    <div class=""property-details"">
                        <h3>{propertyName}</h3>
                        <p style=""color: #6b7280; margin: 5px 0;"">📍 {propertyLocation}</p>
                        <div class=""property-price"">${winningBid:N0}</div>
                        <p style=""margin: 5px 0; font-size: 14px; color: #6b7280;"">Your Winning Bid</p>
                    </div>
                </div>

                <div class=""success-box"">
                    <p style=""margin: 0 0 10px 0;""><strong>🎊 What's Next?</strong></p>
                    <ol style=""margin: 5px 0; padding-left: 20px;"">
                        <li>Our team will contact you within 24 hours</li>
                        <li>Complete the payment process</li>
                        <li>Schedule the property handover</li>
                    </ol>
                </div>

                <div style=""text-align: center; margin: 30px 0;"">
                    <a href=""https://propertyflipper.com/my-properties"" class=""button"">View Your Properties</a>
                </div>

                <hr class=""divider"">

                <h3>Important Information:</h3>
                <div class=""info-box"">
                    <p style=""margin: 0 0 10px 0;""><strong>💳 Payment Details:</strong></p>
                    <p style=""margin: 5px 0;"">• <strong>Amount Due:</strong> ${winningBid:N0}</p>
                    <p style=""margin: 5px 0;"">• <strong>Payment Deadline:</strong> 7 days from auction end</p>
                    <p style=""margin: 5px 0;"">• <strong>Payment Methods:</strong> Bank transfer, Wire transfer</p>
                </div>

                <div class=""warning-box"">
                    <p style=""margin: 0;""><strong>⚠️ Important:</strong> Failure to complete payment within the specified timeframe may result in forfeiture of the property and potential account restrictions.</p>
                </div>

                <p>Congratulations on your successful bid! We look forward to helping you with your new property.</p>
                <p>Best regards,<br><strong>The Instaprop Team</strong></p>
            ";

            return GetBaseTemplate("Congratulations! You Won - Instaprop", content);
        }

        /// <summary>
        /// Payment reminder
        /// </summary>
        public string GetPaymentReminderEmail(string firstName, string propertyName, decimal amount, 
            DateTime dueDate, int daysRemaining)
        {
            var urgencyClass = daysRemaining <= 2 ? "warning-box" : "info-box";
            
            var content = $@"
                <h2>Payment Reminder 💰</h2>
                <p>Hi {firstName},</p>
                <p>This is a friendly reminder about your pending payment for the property you won.</p>

                <div class=""{urgencyClass}"">
                    <p style=""margin: 0 0 10px 0;""><strong>{(daysRemaining <= 2 ? "⚠️ Urgent:" : "💡 Reminder:")}</strong></p>
                    <p style=""margin: 5px 0;""><strong>Property:</strong> {propertyName}</p>
                    <p style=""margin: 5px 0;""><strong>Amount Due:</strong> <span style=""font-size: 20px; font-weight: 700;"">${amount:N0}</span></p>
                    <p style=""margin: 5px 0;""><strong>Due Date:</strong> {dueDate:MMMM dd, yyyy}</p>
                    <p style=""margin: 5px 0;""><strong>Days Remaining:</strong> <span style=""font-weight: 700; color: {(daysRemaining <= 2 ? "#dc2626" : "#2563eb")};"">{daysRemaining} days</span></p>
                </div>

                <div style=""text-align: center; margin: 30px 0;"">
                    <a href=""https://propertyflipper.com/payments"" class=""button"">Make Payment</a>
                </div>

                <h3>Payment Options:</h3>
                <ul style=""color: #4b5563; line-height: 1.8;"">
                    <li><strong>Bank Transfer:</strong> Direct transfer to our account</li>
                    <li><strong>Wire Transfer:</strong> International wire transfers accepted</li>
                    <li><strong>Certified Check:</strong> Contact us for mailing address</li>
                </ul>

                <div class=""info-box"">
                    <p style=""margin: 0 0 10px 0;""><strong>📞 Need Help?</strong></p>
                    <p style=""margin: 0;"">If you have questions about payment or need to arrange an alternative payment schedule, please contact our payments team at <a href=""mailto:payments@propertyflipper.com"">payments@propertyflipper.com</a> or call (555) 123-4567.</p>
                </div>

                {(daysRemaining <= 2 ? @"
                <div class=""warning-box"">
                    <p style=""margin: 0;""><strong>⚠️ Important:</strong> Failure to complete payment by the due date may result in forfeiture of the property and potential account restrictions. Please act promptly to avoid any issues.</p>
                </div>
                " : "")}

                <p>Thank you for your prompt attention to this matter.</p>
                <p>Best regards,<br><strong>The Instaprop Payments Team</strong></p>
            ";

            return GetBaseTemplate("Payment Reminder - Instaprop", content);
        }
    }
}

