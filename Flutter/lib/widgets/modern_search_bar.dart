import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Modern search bar with consistent styling
/// - Background: #F2F2F7
/// - Border radius: 12px
/// - Height: 40px
/// - Icon: #8E8E93 (left aligned)
/// - Placeholder: #8E8E93
class ModernSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final bool enabled;
  final FocusNode? focusNode;

  const ModernSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant, // #F2F2F7
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTap: onTap,
        enabled: enabled,
        focusNode: focusNode,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          fontFamily: 'SF Pro Text',
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.textSecondary, // #8E8E93
            fontSize: 15,
            fontFamily: 'SF Pro Text',
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary, // #8E8E93
            size: 20,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

