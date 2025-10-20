# 📱 Physical Device Setup Guide

## ✅ What Was Fixed

1. **Flutter API Client** - Now uses your Mac's IP: `192.168.1.16:5284`
2. **Backend Configuration** - Listens on all network interfaces (`0.0.0.0`)
3. **CORS Settings** - Allows requests from your device

## 🚀 How to Run

### Step 1: Start Backend (in Terminal 1)

```bash
cd "/Users/s/Desktop/Business/Real estate/Proerty Flipper/API"
dotnet run --launch-profile http
```

**Expected output:**
```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://0.0.0.0:5284
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
```

### Step 2: Verify Backend is Accessible

Open a **new terminal** and test:

```bash
curl http://192.168.1.16:5284/api/health
```

**Expected:** Should return "Healthy" or similar response

### Step 3: Run Flutter App (in Terminal 2)

Make sure your device is connected wirelessly:

```bash
# Check device is connected
adb devices
# Should show: 192.168.1.14:5555    device

# Navigate to Flutter project
cd "/Users/s/Desktop/Business/Real estate/Proerty Flipper/Flutter"

# Run the app
flutter run
```

### Step 4: Select Your Device

When prompted, select your physical device (not the emulator):
```
[1]: sdk gphone64 arm64 (emulator-5554)
[2]: SM-XXXXX (192.168.1.14:5555)    <-- SELECT THIS ONE
```

## 🔧 Troubleshooting

### Issue: "Failed to connect to backend"

**Solution 1 - Check Backend is Running:**
```bash
lsof -i :5284
# Should show PropertyFlipperAPI listening on *:5284
```

**Solution 2 - Check Firewall:**
```bash
# On Mac, allow incoming connections on port 5284
# System Preferences → Security & Privacy → Firewall → Firewall Options
# Add dotnet and allow incoming connections
```

**Solution 3 - Test from Device Browser:**
- Open Chrome on your phone
- Navigate to: `http://192.168.1.16:5284/api/health`
- Should see: "Healthy" or similar

### Issue: "Device not found"

**Reconnect wirelessly:**
```bash
adb connect 192.168.1.14:5555
flutter devices
```

### Issue: "CORS Error"

The CORS settings have been updated. Just restart the backend:
```bash
# Stop backend (Ctrl+C in Terminal 1)
# Start again:
cd API
dotnet run --launch-profile http
```

## 📝 Important Notes

### Your Network Configuration:
- **Mac IP:** `192.168.1.16`
- **Phone IP:** `192.168.1.14`
- **Backend Port:** `5284`

### Requirements:
- ✅ Both devices on **same WiFi network**
- ✅ Backend running on Mac
- ✅ Phone connected wirelessly via ADB
- ✅ Mac firewall allows port 5284

### When Your IP Changes:

If your Mac's IP changes (e.g., different WiFi network), update:

```dart
// In: Flutter/lib/services/api_client.dart
// Line 55: Change to new IP
return 'http://NEW_IP_HERE:5284';
```

## 🎯 Quick Start (Every Time)

```bash
# Terminal 1 - Start Backend
cd "/Users/s/Desktop/Business/Real estate/Proerty Flipper/API"
dotnet run --launch-profile http

# Terminal 2 - Run Flutter (after backend starts)
cd "/Users/s/Desktop/Business/Real estate/Proerty Flipper/Flutter"
flutter run
```

## ✨ Testing Checklist

- [ ] Backend running and showing: `Now listening on: http://0.0.0.0:5284`
- [ ] Can access `http://192.168.1.16:5284/api/health` from Mac browser
- [ ] Can access `http://192.168.1.16:5284/api/health` from phone browser
- [ ] `adb devices` shows your phone connected
- [ ] `flutter devices` shows your phone
- [ ] App runs and can fetch data from backend

## 🔥 Common Commands

```bash
# Check what's on port 5284
lsof -i :5284

# Kill all backend processes
pkill -f PropertyFlipperAPI

# Check ADB connection
adb devices

# Reconnect ADB wirelessly
adb connect 192.168.1.14:5555

# Check Flutter devices
flutter devices

# Run Flutter with specific device
flutter run -d 192.168.1.14:5555

# Hot reload (while app is running)
Press 'r' in terminal

# Hot restart (while app is running)
Press 'R' in terminal
```

## 🎉 Success!

If everything is working, you should now be able to:
- ✅ Develop wirelessly on your physical device
- ✅ App connects to backend running on your Mac
- ✅ Hot reload works instantly
- ✅ Debug features work normally

Happy coding! 🚀

