# 🎨 Font Configuration Guide

## Current Setup

### **Soft Cantle** (Stylized Font)
**Used for: TITLES ONLY**
- `titleLarge` (20px) - Card titles, widget titles
- `titleMedium` (16px) - Small titles, section labels

### **Roboto** (Default System Font)
**Used for: EVERYTHING ELSE**
- `headlineLarge` (32px) - Main page headers
- `headlineMedium` (24px) - Section headers
- `bodyLarge` (16px) - Paragraph text
- `bodyMedium` (14px) - Secondary text
- `bodySmall` (12px) - Small text
- App bar titles
- All buttons
- All input fields
- Navigation items

---

## Usage in Your Code

### To Use Soft Cantle (Titles):

```dart
Text(
  'Property Title',
  style: Theme.of(context).textTheme.titleLarge, // Soft Cantle
)

Text(
  'Small Title',
  style: Theme.of(context).textTheme.titleMedium, // Soft Cantle
)
```

### To Use Default Roboto (Everything Else):

```dart
// Headlines (big page headers)
Text(
  'Featured Properties',
  style: Theme.of(context).textTheme.headlineLarge, // Roboto
)

// Body text
Text(
  'Description goes here...',
  style: Theme.of(context).textTheme.bodyLarge, // Roboto
)

// Or simply don't specify a style - defaults to Roboto
Text('Simple text'), // Roboto by default
```

---

## Design Philosophy

✨ **Soft Cantle** = Eye-catching titles that stand out  
📖 **Roboto** = Clean, readable text for content

This creates a nice contrast:
- Titles grab attention with style
- Content is easy to read

---

## Files Modified

1. **pubspec.yaml** (lines 105-109)
   - Added Soft Cantle font

2. **lib/theme/app_theme.dart**
   - Removed Google Fonts dependency
   - Set Soft Cantle for titleLarge and titleMedium
   - Default Roboto for everything else

---

## Font Files

Located in: `assets/fonts/`
- ✅ `Soft Cantle.ttf` (183 KB) - **ACTIVE**
- ⚪ `Brilliant Soulmate.otf` (136 KB) - not used, can delete
- ⚪ `AmsterdamTwoSlantTtf-EapXj.ttf` (102 KB) - not used, can delete

---

## Hot Restart Required

After font changes, you must **Hot Restart** (not just hot reload):
- Press `R` (capital R) in terminal
- Or stop and run `flutter run` again

---

## Customization

### Want Soft Cantle on more elements?

Edit `lib/theme/app_theme.dart` and add `fontFamily: 'SoftCantle'` to any TextStyle.

Example:
```dart
headlineLarge: const TextStyle(
  fontFamily: 'SoftCantle', // Add this line
  fontSize: 32,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
),
```

### Want a different simple font?

Replace default Roboto by setting a fontFamily for TextStyles that don't have one, or use Google Fonts:

```dart
dependencies:
  google_fonts: ^6.2.1  # Already in pubspec
```

Then in theme:
```dart
bodyLarge: GoogleFonts.roboto(fontSize: 16, ...),
```

---

## Troubleshooting

**Font not showing?**
1. Run `flutter clean`
2. Run `flutter pub get`
3. Hot **RESTART** (capital R), not reload
4. Check file exists: `ls assets/fonts/Soft\ Cantle.ttf`

**Want to change font?**
1. Add new .ttf/.otf file to `assets/fonts/`
2. Update `pubspec.yaml` with new font family name
3. Update `app_theme.dart` to use new font family
4. Run `flutter pub get` and `flutter clean`

