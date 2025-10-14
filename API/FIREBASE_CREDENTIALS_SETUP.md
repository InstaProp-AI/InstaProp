# Firebase Credentials Setup Guide

## Problem
The auction details page is not updating when new bids are placed because Firebase/Firestore real-time sync is disabled due to missing credentials.

## Solution
You need to download your Firebase service account credentials and place them in the API directory.

## Steps to Get Firebase Credentials

### 1. Go to Firebase Console
Visit: https://console.firebase.google.com/

### 2. Select Your Project
- Select project: `property-flipper-5164d`

### 3. Navigate to Project Settings
- Click the gear icon ⚙️ next to "Project Overview"
- Click "Project settings"

### 4. Go to Service Accounts
- Click the "Service accounts" tab at the top

### 5. Generate New Private Key
- Scroll down to "Firebase Admin SDK" section
- Click "Generate new private key"
- Click "Generate key" in the confirmation dialog
- A JSON file will be downloaded (e.g., `property-flipper-5164d-firebase-adminsdk-xxxxx-xxxxxxxxxx.json`)

### 6. Place the File in API Directory
- Rename the downloaded file to: `firebase-credentials.json`
- Copy it to: `/Users/s/Desktop/Business/Real estate/Proerty Flipper/API/firebase-credentials.json`
- ⚠️ **IMPORTANT**: Add this file to `.gitignore` to keep your credentials secure!

### 7. Restart Your API
After placing the credentials file:
```bash
cd "/Users/s/Desktop/Business/Real estate/Proerty Flipper/API"
dotnet run
```

### 8. Verify Firestore is Enabled
Check the API logs for this message:
```
✅ Firestore initialized for project: property-flipper-5164d
```

If you see this, Firestore is working! If you see:
```
⚠️ Firestore disabled - No project ID configured
```
or
```
❌ Failed to initialize Firestore
```
Then the credentials file is not being read correctly.

## Security Notes

### DO NOT commit firebase-credentials.json to Git!
Add this to your `.gitignore`:
```
# Firebase credentials
firebase-credentials.json
```

### For Production
Use environment variables or a secure secret manager instead of a JSON file.

## What This Fixes

Once Firebase credentials are set up:
- ✅ Backend will push auction updates to Firestore when bids are placed
- ✅ Backend will push bid data to Firestore in real-time
- ✅ Flutter app will receive instant updates via Firestore listeners
- ✅ Auction details page will update immediately when new bids are placed
- ✅ Auction list will update in real-time across all devices
- ✅ Notifications will sync instantly

## Alternative: Test Without Firebase

If you can't set up Firebase right now, the app will still work but will use polling instead of real-time updates:
- The auction details page refreshes every 5 minutes (fallback polling)
- Users can pull-to-refresh to manually update
- Updates are not instant but functional

However, for the best user experience, Firebase real-time sync is highly recommended!

