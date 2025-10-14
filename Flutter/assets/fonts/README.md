# Amsterdam Font Installation

## Step 1: Download the Amsterdam Font

Since Amsterdam font is not available in Google Fonts, you need to download it from one of these sources:

### Option A: DaFont (Recommended)
1. Visit: https://www.dafont.com/amsterdam.font
2. Click "Download" button
3. Extract the ZIP file

### Option B: FontSpace
1. Visit: https://www.fontspace.com/amsterdam-font-f3989
2. Click "Download" button
3. Extract the ZIP file

### Option C: 1001 Fonts
1. Visit: https://www.1001fonts.com/amsterdam-font.html
2. Click "Download" button
3. Extract the ZIP file

## Step 2: Copy Font Files to This Directory

After downloading and extracting, you should have files like:
- `Amsterdam.ttf` (or `Amsterdam-Regular.ttf`)
- `Amsterdam-Bold.ttf` (if available)
- `Amsterdam-Italic.ttf` (if available)

**Copy these .ttf files to this directory:**
```
/Users/s/Desktop/Business/Real estate/Proerty Flipper/Flutter/assets/fonts/
```

## Step 3: Verify File Names

Make sure the files are named exactly as configured in `pubspec.yaml`:
- `Amsterdam.ttf` or `Amsterdam-Regular.ttf`
- `Amsterdam-Bold.ttf` (optional, for bold headers)

## Step 4: Run Flutter Commands

After copying the font files, run:
```bash
cd "/Users/s/Desktop/Business/Real estate/Proerty Flipper/Flutter"
flutter pub get
flutter clean
flutter run
```

## Current Status

✅ Fonts directory created  
⏳ Amsterdam font files - **YOU NEED TO DOWNLOAD AND ADD THESE**  
✅ pubspec.yaml configured  
✅ Theme updated to use Amsterdam for headers  

## Troubleshooting

**Problem: Font not showing up**
- Make sure font files are in the correct directory
- Check that file names match exactly in pubspec.yaml
- Run `flutter clean` and `flutter pub get`
- Restart your app completely

**Problem: Font looks wrong**
- Some Amsterdam fonts have different names (Amsterdam, AmsterdamOne, etc.)
- Update the `family` name in pubspec.yaml to match the actual font family name

