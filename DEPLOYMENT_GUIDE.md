# Deployment Guide - Instaprop

This guide walks you through deploying the backend to Railway and building mobile apps.

## Prerequisites

1. Railway account (create at https://railway.app)
2. Flutter SDK installed
3. **Android SDK** for APK builds
   - Install Android Studio
   - Set `ANDROID_HOME` environment variable
   - Accept Android licenses: `flutter doctor --android-licenses`
4. **Xcode (macOS only)** for IPA builds
5. **Apple Developer account** ($99/year) for iOS IPA signing

### Verify Setup

Run `flutter doctor` to check your setup:
```bash
flutter doctor
```

Fix any issues before building.

## Step 1: Deploy Backend to Railway

### 1.1 Create Railway Account and Project

1. Go to https://railway.app and sign up/login
2. Click "New Project"
3. Select "Deploy from GitHub repo" or "Empty Project"

### 1.2 Add PostgreSQL Database

1. In your Railway project, click "+ New"
2. Select "Database" → "Add PostgreSQL"
3. Railway will automatically create a PostgreSQL database
4. Note the connection details (you'll need the `DATABASE_URL`)

### 1.3 Deploy Backend Service

1. In Railway project, click "+ New" → "GitHub Repo" (or upload code)
2. Select your repository and the `API` folder
3. Railway will detect the Dockerfile and start building

### 1.4 Configure Environment Variables

In Railway dashboard, go to your service → Variables tab, and add:

```
JWT_SECRET=your-secure-random-string-min-32-chars
DATABASE_URL=postgresql://user:pass@host:port/db (auto-provided by Railway)
ASPNETCORE_ENVIRONMENT=Production
PORT=8080 (Railway sets this automatically)
```

**Important:** Generate a secure JWT_SECRET:
```bash
# On Linux/Mac:
openssl rand -hex 32

# Or use any secure random string generator
```

### 1.5 Get Your Railway URL

1. After deployment, Railway will provide a URL like: `https://your-app-name.railway.app`
2. Copy this URL - you'll need it for the Flutter app

## Step 2: Update Flutter App with Railway URL

### 2.1 Update API Client

1. Open `Flutter/lib/services/api_client.dart`
2. Find the line: `static const String productionBaseUrl = 'https://YOUR-RAILWAY-APP-NAME.railway.app';`
3. Replace `YOUR-RAILWAY-APP-NAME` with your actual Railway app name
4. Ensure `useProductionUrl = true` (already set)

Example:
```dart
static const String productionBaseUrl = 'https://instaprop-api.railway.app';
```

## Step 3: Build Android APK

### 3.1 Build Release APK

```bash
cd Flutter
flutter clean
flutter pub get
flutter build apk --release
```

### 3.2 Find Your APK

The APK will be located at:
```
Flutter/build/app/outputs/flutter-apk/app-release.apk
```

### 3.3 Distribute APK

1. Share the APK file via email, cloud storage, or direct transfer
2. Users need to:
   - Enable "Install from Unknown Sources" in Android settings
   - Open the APK file to install

## Step 4: Build iOS IPA

### 4.1 Apple Developer Setup (One-time)

1. Sign up at https://developer.apple.com ($99/year)
2. Create an App ID in Apple Developer portal
3. Create provisioning profiles for your app

### 4.2 Configure Xcode Signing

1. Open `Flutter/ios/Runner.xcworkspace` in Xcode
2. Select "Runner" in project navigator
3. Go to "Signing & Capabilities" tab
4. Select your Team (Apple Developer account)
5. Xcode will automatically manage certificates

### 4.3 Build IPA

```bash
cd Flutter
flutter clean
flutter pub get
flutter build ipa --release
```

### 4.4 Find Your IPA

The IPA will be located at:
```
Flutter/build/ios/ipa/app1.ipa
```

### 4.5 Distribute IPA

**Option 1: Direct Installation (Sideloading)**
- Use tools like AltStore, Sideloadly, or Xcode
- Requires Apple Developer account
- Users need to trust developer certificate on device

**Option 2: TestFlight (Recommended)**
- Upload IPA to App Store Connect
- Distribute via TestFlight for beta testing
- Users install via TestFlight app

**Option 3: App Store**
- Submit for App Store review
- Public distribution

## Troubleshooting

### Backend Issues

**Database Connection Failed:**
- Verify `DATABASE_URL` is set correctly in Railway
- Check Railway PostgreSQL service is running

**CORS Errors:**
- Backend is configured to allow all origins for mobile apps
- If issues persist, check Railway logs

**JWT Errors:**
- Ensure `JWT_SECRET` is set in Railway environment variables
- Must be at least 32 characters

### Flutter Build Issues

**Android Build Fails:**
- Run `flutter doctor` to check Android setup
- Ensure Android SDK is properly installed
- Check `android/app/build.gradle.kts` for errors

**iOS Build Fails:**
- Ensure Xcode is installed and updated
- Run `flutter doctor` to check iOS setup
- Verify Apple Developer account is configured
- Check signing in Xcode

**API Connection Issues:**
- Verify Railway URL is correct in `api_client.dart`
- Check `useProductionUrl = true`
- Test Railway URL in browser: `https://your-app.railway.app/swagger`

## Environment Variables Reference

### Railway Backend Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `JWT_SECRET` | Secret key for JWT tokens | `your-32-char-secret` |
| `DATABASE_URL` | PostgreSQL connection (auto-set) | `postgresql://...` |
| `ASPNETCORE_ENVIRONMENT` | Environment mode | `Production` |
| `PORT` | Server port (auto-set) | `8080` |

### Optional Variables

| Variable | Description |
|----------|-------------|
| `OPENAI_API_KEY` | OpenAI API key (if using AI features) |
| `IMGBB_API_KEY` | ImgBB API key (for image uploads) |

## Next Steps

1. ✅ Deploy backend to Railway
2. ✅ Update Flutter app with Railway URL
3. ✅ Build and test APK
4. ✅ Build and test IPA
5. ✅ Distribute to users

## Support

For issues:
- Check Railway deployment logs
- Check Flutter build logs
- Verify all environment variables are set
- Test API endpoints via Swagger: `https://your-app.railway.app/swagger`

