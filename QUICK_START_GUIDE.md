# Property Flipper - Quick Start Guide

## 🚀 Running the Application

### Backend (API)
The backend is running on: **http://localhost:5284**

**Start Backend:**
```bash
cd API
dotnet run --urls="http://localhost:5284"
```

**Health Check:**
```bash
curl http://localhost:5284/health
# Should return: Healthy
```

**Test API:**
```bash
curl http://localhost:5284/api/Dashboard/public-stats
# Should return JSON with stats
```

### Frontend (Flutter)
The Flutter app is configured to connect to: **http://localhost:5284**

**Start Flutter (Web):**
```bash
cd Flutter
flutter run -d chrome --web-port=8080
```

**Start Flutter (iOS Simulator):**
```bash
cd Flutter
flutter run -d iPhone
```

**Start Flutter (Android Emulator):**
```bash
cd Flutter
flutter run -d emulator-5554
```

## ✅ Connection Verified

Both services are now running and connected:
- ✅ Backend: http://localhost:5284
- ✅ Flutter Web: http://localhost:8080
- ✅ API connection: Fixed and working

## 🔧 API Configuration

The Flutter app automatically detects the platform and uses the correct URL:

- **Web (Chrome)**: `http://localhost:5284`
- **iOS Simulator**: `http://localhost:5284`
- **Android Emulator**: `http://10.0.2.2:5284` (special Android localhost)
- **Physical Device**: Update to your computer's IP address

### For Physical Devices

If you need to test on a physical device:

1. Find your computer's IP address:
   - Mac: `ifconfig | grep "inet " | grep -v 127.0.0.1`
   - Windows: `ipconfig`

2. Update `lib/services/api_client.dart`:
   ```dart
   static String get baseUrl {
     if (kIsWeb) {
       return 'http://localhost:5284';
     } else {
       return 'http://YOUR_IP_ADDRESS:5284';  // e.g., http://192.168.1.100:5284
     }
   }
   ```

3. Make sure your firewall allows connections on port 5284

## 📱 Testing the Connection

### 1. Check Backend Health
```bash
curl http://localhost:5284/health
```

### 2. Check API Data
```bash
curl http://localhost:5284/api/Auction
curl http://localhost:5284/api/Property
curl http://localhost:5284/api/Dashboard/public-stats
```

### 3. Test From Flutter
Open browser console (F12) and look for:
- ✅ API requests to `http://localhost:5284`
- ✅ 200 OK responses
- ❌ CORS errors (if any, check backend CORS settings)
- ❌ Network errors (if any, backend might not be running)

## 🐛 Troubleshooting

### Flutter Can't Connect to Backend

**Problem**: "Cannot connect to server" or network errors

**Solutions**:
1. **Check backend is running**:
   ```bash
   curl http://localhost:5284/health
   ```

2. **Check Flutter is using correct URL**:
   - Open browser console (F12)
   - Look for network requests
   - Verify they're going to `http://localhost:5284`

3. **Check CORS settings** in `API/Program.cs`:
   ```csharp
   // Development mode allows all origins
   app.UseCors("AppCors");
   ```

4. **Restart both services**:
   ```bash
   # Terminal 1 - Backend
   cd API
   dotnet run --urls="http://localhost:5284"
   
   # Terminal 2 - Flutter
   cd Flutter
   flutter run -d chrome
   ```

### Backend Not Starting

**Problem**: Backend won't start or crashes

**Solutions**:
1. **Check if port is in use**:
   ```bash
   lsof -i :5284
   # Kill process if needed
   kill -9 <PID>
   ```

2. **Check database**:
   ```bash
   cd API
   ls mydb.db
   # If missing, migrations weren't run
   dotnet ef database update
   ```

3. **Check appsettings.json**:
   - Verify JWT keys are set
   - Verify ConnectionString is correct
   - Check Firebase credentials exist

### Flutter Build Errors

**Problem**: Compilation errors

**Solutions**:
1. **Clean and rebuild**:
   ```bash
   cd Flutter
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Check imports**: Make sure all imports point to existing files

3. **Check dependencies**: Run `flutter doctor` to check setup

## 📊 Default Data

The backend comes with seeded data:
- **Users**: Admin, test users
- **Properties**: 20+ sample properties
- **Auctions**: 5+ active auctions
- **Bids**: Sample bids

**Admin Credentials** (if seeded):
- Email: `admin@propertyflipper.com`
- Password: Check seed data or create new account

## 🔐 Authentication

**Register New Account**:
1. Open app in browser
2. Click "Sign Up"
3. Fill in details
4. Email verification (check console for PIN if SMTP not configured)

**Login**:
1. Use registered credentials
2. JWT token stored in localStorage
3. Token auto-refreshed

## 📚 API Documentation

**Swagger UI** (Development only):
- http://localhost:5284/swagger

**Endpoints**:
- `/api/Account` - Authentication
- `/api/Property` - Properties
- `/api/Auction` - Auctions
- `/api/Bids` - Bidding
- `/api/Chat` - Messaging
- `/api/Dashboard` - Statistics
- `/api/Notification` - Notifications
- `/api/Project` - Developer projects
- `/api/Developer` - Developer profiles
- `/api/Event` - Calendar events

## 🎯 What's Working

✅ Backend API running on port 5284
✅ Flutter app connecting to backend
✅ Database with sample data
✅ JWT authentication
✅ Real-time updates (Firestore)
✅ Image uploads (ImgBB)
✅ Email notifications (SMTP)
✅ Push notifications (FCM)
✅ Background services (auction expiration, cleanup)

## 📖 Documentation

- **Backend API**: `/API/BACKEND_DOCUMENTATION.md`
- **Flutter Architecture**: `/Flutter/RESTRUCTURING_SUMMARY.md`
- **Migration Status**: `/Flutter/MIGRATION_STATUS.md`

## 💡 Tips

1. **Hot Reload**: Press `r` in Flutter terminal for quick reload
2. **Hot Restart**: Press `R` for full restart
3. **Clear Data**: Clear browser localStorage to reset auth
4. **Debug Mode**: Check browser console for detailed logs
5. **API Logs**: Check `API/api.log` for backend logs

---

**Need Help?**
- Check browser console (F12) for errors
- Check `API/api.log` for backend errors
- Verify both services are running
- Test API endpoints directly with curl

**Everything is now configured and running! 🎉**




