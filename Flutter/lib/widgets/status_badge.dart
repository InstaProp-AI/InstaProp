import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Status badge/pill with consistent styling
/// - Border radius: 20px (fully rounded)
/// - Padding: 6px 12px
/// - Font: 12px semibold
/// - Colors based on status (success/warning/error/primary)
enum StatusType {
  success,
  warning,
  error,
  info,
  accent,
  neutral,
}

class StatusBadge extends StatelessWidget {
  final String text;
  final StatusType type;
  final Color? customColor;
  final Color? customTextColor;

  const StatusBadge({
    super.key,
    required this.text,
    this.type = StatusType.neutral,
    this.customColor,
    this.customTextColor,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    if (customColor != null) {
      backgroundColor = customColor!;
      textColor = customTextColor ?? Colors.white;
    } else {
      switch (type) {
        case StatusType.success:
          backgroundColor = AppColors.success;
          textColor = Colors.white;
          break;
        case StatusType.warning:
          backgroundColor = AppColors.warning;
          textColor = Colors.white;
          break;
        case StatusType.error:
          backgroundColor = AppColors.error;
          textColor = Colors.white;
          break;
        case StatusType.info:
          backgroundColor = AppColors.primary;
          textColor = Colors.white;
          break;
        case StatusType.accent:
          backgroundColor = AppColors.accent;
          textColor = Colors.white;
          break;
        case StatusType.neutral:
          backgroundColor = AppColors.surfaceVariant;
          textColor = AppColors.textSecondary;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'SF Pro Text',
          color: textColor,
        ),
      ),
    );
  }
}

