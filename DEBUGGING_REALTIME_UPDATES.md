# Debugging Real-Time Updates

## Current Situation
- ✅ Backend is writing to Firestore (you confirmed bid data is there)
- ❌ Frontend is not updating the current price in the UI

## Step-by-Step Debugging

### Step 1: Check Browser Console Logs

1. Open your Flutter web app in Chrome
2. Press `F12` to open Developer Tools
3. Go to the **Console** tab
4. Navigate to an auction details page
5. **Look for these messages when the page loads:**

   ```
   🔥 Starting Firestore listeners for auction [ID]
   🔥 Firestore: Received auction [ID] data: [list of fields]
   🔥 Firestore: currentPrice = [value], bidCount = [value]
   ```

6. **Now place a bid and watch for:**

   ```
   🔥 Firestore: Auction updated - Price: $[amount], Bids: [count]
   🔥 Firestore: Updating _currentAuction in setState...
   ✅ Firestore: _currentAuction updated successfully! New price: $[amount]
   ```

### Step 2: Check for Errors

**Look for any of these error messages:**

- `❌ Error parsing auction from Firestore:` - This means data format mismatch
- `⚠️ Firestore: Received null auction update` - This means parsing failed
- `⚠️ Firestore: Auction [ID] document does not exist` - Document not found
- `❌ Firestore auction listener error:` - Connection or permission error

### Step 3: Verify Firestore Data Structure

1. Go to Firebase Console: https://console.firebase.google.com/
2. Click on your project: **property-flipper-5164d**
3. Go to **Firestore Database** in the left menu
4. Navigate to the `auctions` collection
5. Click on a document (the auction ID)

**Verify these fields exist (case-sensitive!):**
```
✓ auctionId (number)
✓ currentPrice (number) ← This is KEY!
✓ bidCount (number) ← This too!
✓ status (string)
✓ startAt (string in ISO 8601 format)
✓ createdAt (string in ISO 8601 format)
✓ property (object/map)
```

**⚠️ Common Issues:**
- Field names with wrong case: `CurrentPrice` instead of `currentPrice`
- Fields missing completely
- Wrong data types (string instead of number)

### Step 4: Check Field Case Sensitivity

Run this in your browser console while on the auction page:

```javascript
// This will show you what fields Firestore is sending
console.log('Checking Firestore data...');
```

### Step 5: Verify Hot Reload

After I made the logging changes, you need to:
1. **Stop** your Flutter web app (Ctrl+C if running from terminal)
2. **Restart** it with: `flutter run -d chrome`
3. Or do a **Hot Restart** (Shift+R in the terminal, or click 🔄 in VS Code)

**Hot Reload (r) is NOT enough** - you need **Hot Restart (Shift+R)**

## Common Causes & Solutions

### Cause 1: Old Code Running (Most Likely!)

**Solution:** Hot restart the app
```bash
# In terminal where Flutter is running, press:
Shift + R
# Or restart completely:
flutter run -d chrome --dart-define=FLUTTER_WEB_USE_SKIA=true
```

### Cause 2: Data Format Mismatch

**Symptom:** You see `❌ Error parsing auction from Firestore` in console

**Solution:** Check Firestore console (Step 3 above) - verify field names are camelCase

### Cause 3: Listener Not Active

**Symptom:** No "🔥" messages in console at all

**Solution:** Check Firebase initialization:
1. Is `firebase_options.dart` file present?
2. Is Firebase initialized in `main.dart`?

### Cause 4: Firestore Security Rules

**Symptom:** `❌ Firestore auction listener error: permission denied`

**Solution:** Check Firestore rules:
1. Go to Firebase Console → Firestore Database → Rules tab
2. Make sure read is allowed (at least for testing):
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true; // For testing only!
       }
     }
   }
   ```

### Cause 5: Network Issues

**Symptom:** No messages at all, even after hot restart

**Solution:** Check browser Network tab:
1. F12 → Network tab
2. Look for WebSocket connections to `firestore.googleapis.com`
3. Check if any requests are failing

## Quick Test

Run this test to verify everything:

1. **Open TWO browser windows:**
   - Window A: Chrome normal
   - Window B: Chrome incognito (or another browser)

2. **Login with two different accounts**

3. **Both windows navigate to the SAME auction**

4. **Window A: Place a bid**

5. **Check both windows:**
   - Window A console: Should show `✅ Firestore: _currentAuction updated`
   - Window B console: Should ALSO show `✅ Firestore: _currentAuction updated`
   - Both UIs: Should show the new current price

## Expected Console Output (Success)

When everything works, you should see:

```
🔥 Starting Firestore listeners for auction 55
🔥 Firestore: Received auction 55 data: [auctionId, currentPrice, bidCount, ...]
🔥 Firestore: currentPrice = 100000, bidCount = 5

[User places bid of 100500]

🔥 Firestore: Auction updated - Price: $100500, Bids: 6
🔥 Firestore: Updating _currentAuction in setState...
✅ Firestore: _currentAuction updated successfully! New price: $100500

🔥 Firestore: Received 6 bids
```

## What to Report Back

After checking the above, please share:

1. **Console logs** (copy/paste the 🔥 and ❌ messages)
2. **Which step failed** (1-5 above)
3. **Screenshot of Firestore document** (showing field names and values)
4. **Did hot restart help?** (Yes/No)

## Backend Logging

Also check your API logs (terminal where dotnet is running):

```bash
# Look for these messages:
✅ Updated auction 55 in Firestore
✅ Added bid 123 to auction 55 in Firestore
```

If you see these, backend is working! Issue is in Flutter.

## Quick Fix Checklist

- [ ] Hot restart Flutter app (Shift+R)
- [ ] Check browser console for logs
- [ ] Verify Firestore has data with correct field names
- [ ] Check Firebase security rules allow read
- [ ] Try in incognito/private browsing
- [ ] Clear browser cache and reload
- [ ] Check API logs show Firestore success messages


