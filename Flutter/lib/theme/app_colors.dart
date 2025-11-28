import 'package:flutter/material.dart';

/// App Color Palette - Modern, Minimalist iOS-Style Design System
///
/// Color Philosophy:
/// - iOS Blue: Clean, modern, professional
/// - Light Gray Background: Soft, comfortable
/// - Pure White Cards: Clean, minimal
/// - Near Black Text: Excellent readability
class AppColors {
  // ========================================================================
  // PRIMARY COLORS - Core brand colors
  // ========================================================================
  static const Color primary = Color(0xFF007AFF); // iOS Blue
  static const Color secondary = Color(0xFF8E8E93); // Gray
  static const Color background = Color(0xFFF8F9FA); // Light Gray
  static const Color textPrimary = Color(0xFF1C1C1E); // Near Black

  // ========================================================================
  // SURFACE & CONTRAST COLORS
  // ========================================================================
  static const Color surface = Color(0xFFFFFFFF); // Pure White (Card Background)
  static const Color surfaceVariant = Color(0xFFF2F2F7); // Light Gray Fill
  static const Color onPrimary = Color(0xFFFFFFFF); // White on primary
  static const Color onSecondary = Color(0xFFFFFFFF); // White on secondary
  static const Color onBackground = textPrimary;
  static const Color onSurface = textPrimary;

  // ========================================================================
  // SEMANTIC COLORS
  // ========================================================================
  static const Color success = Color(0xFF34C759); // Success Green
  static const Color error = Color(0xFFFF3B30); // Error Red
  static const Color warning = Color(0xFFFF9500); // Warning Orange
  static const Color info = Color(0xFF007AFF); // Info Blue (same as primary)
  static const Color accent = Color(0xFFAF52DE); // Accent Purple

  // ========================================================================
  // TEXT COLORS
  // ========================================================================
  static const Color textSecondary = Color(0xFF8E8E93); // Gray
  static const Color textTertiary = Color(0xFFC7C7CC); // Light Gray
  static const Color textDisabled = Color(0xFFC7C7CC); // Light Gray (disabled)
  static const Color textLink = primary; // iOS Blue

  // ========================================================================
  // BORDER COLORS
  // ========================================================================
  static const Color border = Color(0xFFE5E5EA); // Very Light Gray
  static const Color borderLight = Color(0xFFE5E5EA); // Same as border
  static const Color borderDark = Color(0xFFE5E5EA); // Same as border
  static const Color borderFocused = primary; // iOS Blue

  // ========================================================================
  // STATUS COLORS
  // ========================================================================
  static const Color active = primary; // iOS Blue
  static const Color inactive = Color(0xFF8E8E93); // Gray
  static const Color hover = Color(0xFFF2F2F7); // Light Gray Fill
  static const Color disabled = Color(0xFFF2F2F7); // Light Gray Fill
  static const Color disabledText = Color(0xFFC7C7CC); // Light Gray Text

  // ========================================================================
  // SHADOW COLORS (Subtle shadows only)
  // ========================================================================
  static Color shadowCard = const Color(0xFF000000).withOpacity(0.06); // Subtle card shadow
  static Color shadowSubtle = const Color(0xFF000000).withOpacity(0.04); // Very subtle shadow

  // ========================================================================
  // UTILITY COLORS
  // ========================================================================
  static const Color divider = Color(0xFFE5E5EA); // Very Light Gray
  static const Color overlay = Color(0x80000000); // Semi-transparent black
  static const Color backdrop = Color(0xB3000000); // Modal backdrop

  // ========================================================================
  // DARK MODE COLORS (Maintained for compatibility)
  // ========================================================================
  static const Color darkBackground = Color(0xFF000000); // Pure Black
  static const Color darkSurface = Color(0xFF121212); // Surface Black
  static const Color darkSurfaceVariant = Color(0xFF1E1E1E); // Slightly Lighter
  static const Color darkBorder = Color(0xFF262626); // Dark Border
  static const Color darkTextPrimary = Color(0xFFF5F5F5); // Light Gray
  static const Color darkTextSecondary = Color(0xFFB3B3B3); // Medium Gray
  static const Color darkTextTertiary = Color(0xFF8E8E8E); // Dimmed Gray

  // Helper method to get colors based on theme mode
  static Color getBackground(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkBackground : background;
  }

  static Color getSurface(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkSurface : surface;
  }

  static Color getTextPrimary(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkTextPrimary : textPrimary;
  }

  static Color getTextSecondary(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkTextSecondary : textSecondary;
  }

  static Color getBorder(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkBorder : border;
  }

  // Prevent instantiation
  AppColors._();
}
