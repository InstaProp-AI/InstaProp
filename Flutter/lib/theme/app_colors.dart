import 'package:flutter/material.dart';

/// App Color Palette - Clean, Modern Design System
///
/// Color Philosophy:
/// - Sky Blue: Professional, trustworthy, modern
/// - Slate Gray: Sophisticated neutral for balance
/// - Off-White: Soft, comfortable backgrounds
/// - Deep Charcoal: Excellent readability without harsh black
class AppColors {
  // ========================================================================
  // PRIMARY COLORS - Core brand colors
  // ========================================================================
  static const Color primary = Color(0xFF0EA5E9); // Sky Blue
  static const Color secondary = Color(0xFF64748B); // Slate Gray
  static const Color background = Color(0xFFFAFAFA); // Off-White
  static const Color textPrimary = Color(0xFF1E293B); // Deep Charcoal

  // ========================================================================
  // SURFACE & CONTRAST COLORS
  // ========================================================================
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Light Gray
  static const Color onPrimary = Color(0xFFFFFFFF); // White on primary
  static const Color onSecondary = Color(0xFFFFFFFF); // White on secondary
  static const Color onBackground = textPrimary;
  static const Color onSurface = textPrimary;

  // ========================================================================
  // SEMANTIC COLORS
  // ========================================================================
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color error = Color(0xFFEF4444); // Clean Red
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF3B82F6); // Blue

  // ========================================================================
  // TEXT COLORS
  // ========================================================================
  static const Color textSecondary = Color(0xFF64748B); // Slate
  static const Color textTertiary = Color(0xFF94A3B8); // Light Slate
  static const Color textDisabled = Color(0xFFCBD5E1); // Very Light Slate
  static const Color textLink = primary; // Sky Blue

  // ========================================================================
  // BORDER COLORS
  // ========================================================================
  static const Color border = Color(0xFFE2E8F0); // Soft Border
  static const Color borderLight = Color(0xFFF1F5F9); // Lighter Border
  static const Color borderDark = Color(0xFFCBD5E1); // Darker Border
  static const Color borderFocused = primary; // Sky Blue

  // ========================================================================
  // STATUS COLORS
  // ========================================================================
  static const Color active = primary; // Sky Blue
  static const Color inactive = Color(0xFFE2E8F0); // Soft Gray
  static const Color hover = Color(0xFFF8FAFC); // Subtle Hover
  static const Color disabled = Color(0xFFF1F5F9); // Light Gray

  // ========================================================================
  // GRADIENT COLORS
  // ========================================================================
  static const List<Color> primaryGradient = [
    Color(0xFF0284C7), // Deep Sky Blue
    Color(0xFF0EA5E9), // Sky Blue
    Color(0xFF06B6D4), // Cyan
    Color(0xFF22D3EE), // Bright Cyan
  ];

  static const List<Color> accentGradient = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
  ];

  static const List<Color> neutralGradient = [
    Color(0xFFF8FAFC), // Very Light
    Color(0xFFFFFFFF), // White
  ];

  // ========================================================================
  // SHADOW COLORS
  // ========================================================================
  static Color shadowPrimary = const Color(0xFF0EA5E9).withOpacity(0.15);
  static Color shadowSecondary = const Color(0xFF64748B).withOpacity(0.10);
  static Color shadowCard = const Color(0xFF1E293B).withOpacity(0.08);
  static Color shadowSubtle = const Color(0xFF1E293B).withOpacity(0.04);

  // ========================================================================
  // UTILITY COLORS
  // ========================================================================
  static const Color divider = Color(0xFFE2E8F0); // Subtle divider
  static const Color overlay = Color(0x80000000); // Semi-transparent black
  static const Color backdrop = Color(0xB3000000); // Modal backdrop

  // Prevent instantiation
  AppColors._();
}
