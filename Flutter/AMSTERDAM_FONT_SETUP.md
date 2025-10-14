# 🎨 Amsterdam Font Setup Guide

## ✅ What's Already Done

I've configured your Flutter app to use the **Amsterdam** font for all headers throughout the application:

### Files Modified:
1. ✅ **pubspec.yaml** - Added Amsterdam font configuration
2. ✅ **lib/theme/app_theme.dart** - Updated theme to use Amsterdam for:
   - `headlineLarge` (32px) - Main page titles
   - `headlineMedium` (24px) - Section headers
   - `titleLarge` (20px) - Card/widget titles
   - `titleMedium` (16px) - Small headers
   - `AppBar` titles (18px)

### What Uses Amsterdam Font Now:
- All page titles
- All section headers
- All card titles
- All app bar titles
- Any widget using `Theme.of(context).textTheme.headlineLarge/Medium/titleLarge/titleMedium`

### What Stays Poppins (Google Fonts):
- Body text (normal paragraphs)
- Buttons
- Input fields
- Small text

---

## ⏳ What YOU Need to Do

### Step 1: Download the Amsterdam Font

**Option A: DaFont (Most Popular)**
1. Go to: https://www.dafont.com/amsterdam.font
2. Click the blue "Download" button
3. Save the ZIP file to your Downloads folder

**Option B: FontSpace**
1. Go to: https://www.fontspace.com/amsterdam-font-f3989
2. Click "Download" button

**Option C: 1001 Fonts**
1. Go to: https://www.1001fonts.com/amsterdam-font.html
2. Click "Download" button

---

### Step 2: Extract and Copy Font Files

After downloading:

1. **Extract the ZIP file** - You'll see files like:
   - `Amsterdam.ttf` (or `Amsterdam-Regular.ttf`)
   - `Amsterdam-Bold.ttf` (might not exist, that's OK)
   - License file
   - README

2. **Copy the .ttf files** to this directory:
   ```
   /Users/s/Desktop/Business/Real estate/Proerty Flipper/Flutter/assets/fonts/
   ```

3. **Rename if needed:**
   - If you have `Amsterdam-Regular.ttf`, rename it to `Amsterdam.ttf`
   - If you don't have a bold version, that's fine - regular will be used for all weights

---

### Step 3: Run Flutter Commands

Open your terminal and run:

```bash
# Navigate to Flutter project
cd "/Users/s/Desktop/Business/Real estate/Proerty Flipper/Flutter"

# Get dependencies (this loads the font)
flutter pub get

# Clean build
flutter clean

# Run the app
flutter run
```

---

## 🔍 Verification

### How to Check if Amsterdam Font is Working:

1. **Run the app** after completing steps above
2. **Look at any page title** - it should look different (more stylized)
3. **Check the app bar** - the title should use Amsterdam font
4. **Compare headers vs body text** - headers should look distinct

### Expected Behavior:
```
┌─────────────────────────────────┐
│  Property Flipper  ← Amsterdam  │ (App Bar)
├─────────────────────────────────┤
│                                 │
│  Featured Properties ← Amsterdam│ (Header)
│                                 │
│  Browse our latest listings     │ (Body - Poppins)
│  and find your dream property.  │
│                                 │
└─────────────────────────────────┘
```

---

## 🐛 Troubleshooting

### Problem: Font Not Showing Up

**Solution 1: Check file location**
```bash
ls -la "/Users/s/Desktop/Business/Real estate/Proerty Flipper/Flutter/assets/fonts/"
```
You should see `Amsterdam.ttf` in the list.

**Solution 2: Check file name exactly**
- Must be named `Amsterdam.ttf` (case-sensitive)
- If your file is named differently, update `pubspec.yaml` line 108-110

**Solution 3: Clean and rebuild**
```bash
cd "/Users/s/Desktop/Business/Real estate/Proerty Flipper/Flutter"
flutter clean
flutter pub get
flutter run
```

**Solution 4: Hot restart vs Hot reload**
- Font changes require **hot restart** (not just hot reload)
- Press `R` (capital R) in terminal where flutter is running
- Or stop and restart the app completely

---

### Problem: Bold Font Not Working

If you don't have `Amsterdam-Bold.ttf`, update `pubspec.yaml`:

**Remove this line:**
```yaml
        - asset: assets/fonts/Amsterdam-Bold.ttf
          weight: 700
```

**Or duplicate the regular font:**
```yaml
    - family: Amsterdam
      fonts:
        - asset: assets/fonts/Amsterdam.ttf
          weight: 400
        - asset: assets/fonts/Amsterdam.ttf  # Use regular for bold too
          weight: 700
```

---

### Problem: Font Family Name Wrong

Some Amsterdam fonts use different family names. To check:

1. Open `Amsterdam.ttf` on your Mac (double-click)
2. Font Book will show the **actual font family name**
3. If it's different (e.g., "Amsterdam One"), update:

**In `pubspec.yaml`:**
```yaml
    - family: AmsterdamOne  # Change this to match
```

**In `app_theme.dart`:**
```dart
fontFamily: 'AmsterdamOne',  // Change all instances
```

---

## 📝 Alternative: If Amsterdam Font is Not Available

If you can't find the Amsterdam font, here are similar alternatives:

### From DaFont (Free):
1. **Bebas Neue** - Modern, bold, all-caps
   - https://www.dafont.com/bebas-neue.font
   
2. **Montserrat** - Clean, elegant (also in Google Fonts)
   - https://www.dafont.com/montserrat.font

3. **Coolvetica** - Retro, stylish
   - https://www.dafont.com/coolvetica.font

### Using Google Fonts Instead:
If you want to use a Google Font instead (easier, no download needed):

**Update `app_theme.dart`:**
```dart
// Replace this:
fontFamily: 'Amsterdam',

// With this (example with Bebas Neue):
fontFamily: GoogleFonts.bebasNeue().fontFamily,
```

**Then add to `pubspec.yaml` dependencies:**
```yaml
dependencies:
  google_fonts: ^6.2.1  # Already installed ✅
```

---

## 🎨 Customization

### Want to Use Amsterdam for Buttons Too?

**Update `app_theme.dart` around line 99:**
```dart
textStyle: const TextStyle(
  fontFamily: 'Amsterdam',  // Add this
  fontSize: 15,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.3,
),
```

### Want Different Font Sizes?

**Update `app_theme.dart` lines 27-53:**
```dart
headlineLarge: const TextStyle(
  fontFamily: 'Amsterdam',
  fontSize: 36,  // Make it bigger!
  ...
),
```

---

## 📂 File Structure After Setup

```
Flutter/
├── assets/
│   └── fonts/
│       ├── Amsterdam.ttf ← YOU ADD THIS
│       ├── Amsterdam-Bold.ttf ← OPTIONAL
│       └── README.md ← Already created
├── lib/
│   └── theme/
│       ├── app_theme.dart ← UPDATED ✅
│       └── app_colors.dart
├── pubspec.yaml ← UPDATED ✅
└── AMSTERDAM_FONT_SETUP.md ← THIS FILE
```

---

## ✅ Quick Checklist

- [ ] Downloaded Amsterdam font from DaFont or similar
- [ ] Extracted ZIP file
- [ ] Copied `Amsterdam.ttf` to `Flutter/assets/fonts/`
- [ ] Ran `flutter pub get`
- [ ] Ran `flutter clean`
- [ ] Restarted the app (hot restart, not reload)
- [ ] Verified headers look different from body text

---

## 🆘 Still Having Issues?

1. **Double-check file path:**
   ```bash
   ls -la "/Users/s/Desktop/Business/Real estate/Proerty Flipper/Flutter/assets/fonts/Amsterdam.ttf"
   ```
   Should show the file exists.

2. **Check pubspec.yaml syntax:**
   - Indentation must be exact (use spaces, not tabs)
   - Lines 105-111 should have proper YAML formatting

3. **Try a different font first:**
   - Download "Bebas Neue" from DaFont
   - Replace "Amsterdam" with "BebasNeue" everywhere
   - This will confirm the font loading system works

4. **Check Flutter console for errors:**
   ```
   flutter run
   ```
   Look for font-related error messages.

---

**Good luck! Your headers will look amazing with the Amsterdam font! 🎨**

