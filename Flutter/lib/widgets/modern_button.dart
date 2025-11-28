import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_animations.dart';

/// Modern button variants following the design system
enum ModernButtonType {
  primary,
  secondary,
  text,
}

/// Modern button widget with consistent styling
/// - Primary: Solid #007AFF, white text, 12px radius, 48px height
/// - Secondary: White background, #007AFF border, #007AFF text
/// - Text: No background, #007AFF text
/// - Disabled: #F2F2F7 background, #C7C7CC text
class ModernButton extends StatefulWidget {
  final String text;
  final ModernButtonType type;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const ModernButton({
    super.key,
    required this.text,
    this.type = ModernButtonType.primary,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.padding,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.defaultCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Widget buttonContent;
    if (widget.isLoading) {
      buttonContent = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.type == ModernButtonType.primary
                ? Colors.white
                : AppColors.primary,
          ),
        ),
      );
    } else {
      buttonContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: 20,
              color: _getTextColor(),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            widget.text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'SF Pro Text',
              color: _getTextColor(),
            ),
          ),
        ],
      );
    }

    final button = GestureDetector(
      onTapDown: isDisabled ? null : _handleTapDown,
      onTapUp: isDisabled ? null : _handleTapUp,
      onTapCancel: isDisabled ? null : _handleTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width ?? double.infinity,
          height: 48,
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(12),
            border: widget.type == ModernButtonType.secondary
                ? Border.all(color: AppColors.primary, width: 1)
                : null,
          ),
          child: Center(child: buttonContent),
        ),
      ),
    );

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: button,
    );
  }

  Color _getBackgroundColor() {
    if (widget.onPressed == null || widget.isLoading) {
      return AppColors.disabled;
    }
    switch (widget.type) {
      case ModernButtonType.primary:
        return AppColors.primary;
      case ModernButtonType.secondary:
        return Colors.white;
      case ModernButtonType.text:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    if (widget.onPressed == null || widget.isLoading) {
      return AppColors.disabledText;
    }
    switch (widget.type) {
      case ModernButtonType.primary:
        return Colors.white;
      case ModernButtonType.secondary:
        return AppColors.primary;
      case ModernButtonType.text:
        return AppColors.primary;
    }
  }
}

