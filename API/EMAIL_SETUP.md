# Email Service Setup for Production

## Overview

The email service has been updated to read configuration from **environment variables first**, then fall back to configuration files. 

**Good news**: Your email credentials are already configured in `appsettings.json` and have been copied to `appsettings.Production.json`. The service should work automatically!

## Option 1: Use Configuration File (Already Done ✅)

The credentials are already set in `appsettings.Production.json`:
- SmtpServer: smtp.gmail.com
- SenderEmail: salesteam@wrealestateconsultants.com
- Username: salesteam@wrealestateconsultants.com
- Password: olrjbotelrbcntlq

**The email service should work immediately** when deployed to Railway using these values.

## Option 2: Use Environment Variables (Recommended for Security)

If you prefer to use environment variables (more secure, can be changed without redeploying), add these in your Railway dashboard (Settings → Variables):

```
EMAIL_SMTP_SERVER=smtp.gmail.com
EMAIL_SMTP_PORT=587
EMAIL_SENDER_EMAIL=salesteam@wrealestateconsultants.com
EMAIL_SENDER_NAME=Instaprop
EMAIL_USERNAME=salesteam@wrealestateconsultants.com
EMAIL_PASSWORD=olrjbotelrbcntlq
EMAIL_ENABLE_SSL=true
```

**Note**: Environment variables take priority over configuration files if both are set.

## Gmail Setup

If you're using Gmail, you need to:

1. **Enable 2-Factor Authentication** on your Google account
2. **Generate an App Password**:
   - Go to [Google Account Settings](https://myaccount.google.com/)
   - Security → 2-Step Verification → App passwords
   - Generate a new app password for "Mail"
   - Use this 16-character password (not your regular Gmail password)

3. **Use the App Password** in the `EMAIL_PASSWORD` environment variable

## How It Works

1. The service checks environment variables first (e.g., `EMAIL_SMTP_SERVER`)
2. If not found, it falls back to configuration file (e.g., `Email:SmtpServer`)
3. This allows Railway environment variables to override `appsettings.Production.json`

## Verification

After setting the environment variables:

1. Deploy to Railway
2. Check the logs - you should see:
   ```
   ✅ SMTP Email Service enabled (using environment variables)
      SMTP Server: smtp.gmail.com:587
      Sender: salesteam@wrealestateconsultants.com (Instaprop)
   ```

3. Test email sending using the test endpoint:
   ```
   POST /api/EmailTest/send/verification/your-email@example.com
   ```

## Troubleshooting

### Email Service Disabled

If you see:
```
⚠️ SMTP Email Service disabled - Check Email configuration
```

Check:
- All required environment variables are set in Railway
- No placeholder values (like "REPLACE_WITH_SMTP_PASSWORD")
- Gmail App Password is correct (16 characters, no spaces)

### Email Sending Fails

Check Railway logs for detailed error messages. Common issues:
- **Authentication failed**: Wrong password or username
- **Connection timeout**: Firewall blocking SMTP port 587
- **SSL/TLS error**: Try setting `EMAIL_ENABLE_SSL=false` (not recommended for Gmail)

## Alternative: SendGrid or Other SMTP Providers

You can use any SMTP provider by changing the environment variables:

```
EMAIL_SMTP_SERVER=smtp.sendgrid.net
EMAIL_SMTP_PORT=587
EMAIL_SENDER_EMAIL=noreply@yourdomain.com
EMAIL_USERNAME=apikey
EMAIL_PASSWORD=your-sendgrid-api-key
EMAIL_ENABLE_SSL=true
```

