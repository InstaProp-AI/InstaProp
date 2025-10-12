import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';

class LoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: foregroundColor ?? AppColors.surface,
          disabledBackgroundColor: AppColors.secondary,
          disabledForegroundColor: AppColors.secondary,
          padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.secondary,
                  ),
                ),
              )
            : child,
      ),
    );
  }
}
