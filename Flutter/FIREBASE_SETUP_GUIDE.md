# Firebase Setup Guide for Real-Time Updates

## ⚠️ Important: Firebase Configuration Required

The real-time updates feature requires Firebase to be properly configured. Follow these steps to enable instant updates for auctions and bids.

## 🚀 Quick Setup (5 minutes)

### Step 1: Install Firebase CLI

```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login
```

### Step 2: Initialize Firebase in Your Flutter Project

```bash
# Navigate to your Flutter project directory
cd "/Users/s/Desktop/Business/Real estate/Proerty Flipper/Flutter"

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

This will:
- Create a Firebase project (or select existing one)
- Generate `firebase_options.dart` with your configuration
- Set up Firebase for iOS, Android, and Web

### Step 3: Update main.dart

Replace the current `main.dart` content with:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'pages/home_page.dart';
import 'pages/auth_page.dart';
import 'pages/profile_page.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const PropertyFlipperApp());
}

class PropertyFlipperApp extends StatelessWidget {
  const PropertyFlipperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final appState = AppState();
        appState.init();
        return appState;
      },
      child: Builder(
        builder: (context) {
          final appState = Provider.of<AppState>(context, listen: false);
          return ChangeNotifierProvider.value(
            value: appState.notificationService,
            child: MaterialApp(
              title: 'Property Flipper',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              home: const AppRouter(),
              routes: {
                '/auth': (context) => const AuthPage(),
                '/profile': (context) => const ProfilePage(),
              },
            ),
          );
        },
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
```

### Step 4: Configure Firestore Security Rules

In your Firebase Console (https://console.firebase.google.com):

1. Go to **Firestore Database**
2. Click **Rules** tab
3. Use these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Auctions - Read-only for all users (written by backend only)
    match /auctions/{auctionId} {
      allow read: if true;  // Public read access
      allow write: if false; // Backend only (via Admin SDK)
      
      // Bids subcollection
      match /bids/{bidId} {
        allow read: if true;  // Public read access
        allow write: if false; // Backend only
      }
    }
    
    // User notifications
    match /users/{userId}/notifications/{notificationId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false; // Backend only
    }
  }
}
```

4. Click **Publish**

### Step 5: Test the Setup

Run your app:

```bash
flutter run
```

Check the console for these messages:
```
🔥 Starting Firestore real-time listeners for auctions...
```

If you see errors about Firebase not being initialized, make sure you completed Steps 2-3.

## 🔧 Alternative Setup (Manual Configuration)

If `flutterfire configure` doesn't work, you can manually create `firebase_options.dart`:

### 1. Get Your Firebase Config

From Firebase Console → Project Settings → Your apps:

**For Web:**
```javascript
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT.appspot.com",
  messagingSenderId: "123456789",
  appId: "YOUR_APP_ID"
};
```

**For Android:**
Download `google-services.json` → Place in `android/app/`

**For iOS:**
Download `GoogleService-Info.plist` → Place in `ios/Runner/`

### 2. Create firebase_options.dart

Create `lib/firebase_options.dart`:

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT.appspot.com',
    iosBundleId: 'com.yourcompany.app1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT.appspot.com',
    iosBundleId: 'com.yourcompany.app1',
  );
}
```

## 🔍 Verification Checklist

After setup, verify everything works:

- [ ] Firebase initialized in `main.dart`
- [ ] `firebase_options.dart` exists
- [ ] App runs without Firebase errors
- [ ] Console shows: `🔥 Starting Firestore real-time listeners...`
- [ ] Firestore rules configured in Firebase Console
- [ ] Backend writes to Firestore collections

## 🧪 Testing Real-Time Updates

### Test 1: Auction Updates
1. Open auction list in app
2. In backend/admin dashboard, update an auction
3. Should see instant update in app (no refresh needed)

### Test 2: Bid Updates
1. Open auction details in app
2. Place a bid from another device/browser
3. Should see bid appear instantly in first app

### Console Output You Should See:
```
🔥 Starting Firestore real-time listeners for auctions...
🔥 Starting Firestore listeners for auction 123
🔥 Firestore: Received 5 auctions
🔥 Firestore: Auction updated - Price: $450000, Bids: 5
🔥 Firestore: Received 5 bids
```

## 🚨 Troubleshooting

### Error: "Firebase not initialized"
**Solution**: Make sure you added `await Firebase.initializeApp()` in `main.dart`

### Error: "firebase_options.dart not found"
**Solution**: Run `flutterfire configure` or create the file manually

### No real-time updates appearing
**Solutions**:
1. Check Firebase Console → Firestore for data
2. Verify backend is writing to Firestore
3. Check security rules allow read access
4. Look for errors in console logs

### Error: "Permission denied"
**Solution**: Update Firestore security rules to allow read access

### App works but no Firestore logs
**Solution**: Backend might not be writing to Firestore. Check backend Firestore integration.

## 📚 Additional Resources

- [Firebase Flutter Setup](https://firebase.google.com/docs/flutter/setup)
- [FlutterFire Documentation](https://firebase.flutter.dev)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Cloud Firestore](https://firebase.google.com/docs/firestore)

## 🎯 What Happens After Setup?

Once Firebase is configured:

1. **App starts** → Connects to Firestore
2. **Firestore listens** → Streams auction/bid data
3. **Backend updates database** → Writes to Firestore
4. **Firestore pushes updates** → All connected apps receive instantly
5. **UI updates automatically** → Users see changes in real-time

## ⚡ Performance Notes

- **First Load**: Slightly slower (1-2s) due to Firestore connection
- **Updates**: Instant (< 1 second latency)
- **Offline**: Falls back to API polling automatically
- **Battery**: Much better than constant polling
- **Data Usage**: Minimal (only updates are sent, not full data)

---

**Ready to enable real-time updates?** Start with Step 1 and you'll have instant auction updates in 5 minutes! 🚀

