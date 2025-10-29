import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Instagram-style animation constants and curves
/// Provides smooth, addictive animations throughout the app
class AppAnimations {
  // ========================================================================
  // ANIMATION DURATIONS
  // ========================================================================
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 800);

  // Heart animation duration (for like double-tap)
  static const Duration heartAnimation = Duration(milliseconds: 600);

  // Page transition durations
  static const Duration pageTransition = Duration(milliseconds: 400);

  // Loading animation
  static const Duration shimmerDuration = Duration(milliseconds: 1200);

  // ========================================================================
  // CURVES
  // ========================================================================

  /// Default ease in-out curve (for general transitions)
  static const Curve defaultCurve = Curves.easeInOut;

  /// Smooth decelerate (for navigation transitions)
  static const Curve decelerate = Curves.decelerate;

  /// Ease out cubic (for page transitions)
  static const Curve easeOutCubic = Curves.easeOutCubic;

  /// Instagram-style spring curve (bouncy, natural)
  static const Curve spring = Curves.elasticOut;

  /// Fast out slow in (Material Design standard)
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  /// Accelerate decelerate (for modal animations)
  static const Curve accelerateDecelerate = Curves.easeInOutCubic;

  // ========================================================================
  // INSTAGRAM-STYLE ANIMATION PRESETS
  // ========================================================================

  /// Like animation curve (heart pop)
  static Curve get likeCurve => Curves.elasticOut;

  /// Double-tap heart explosion
  static Animation<double> createHeartAnimation(
    AnimationController controller,
  ) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
  }

  /// Fade in animation for feed items
  static Animation<double> createFadeInAnimation(
    AnimationController controller,
  ) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));
  }

  /// Slide up animation (for bottom sheets, comments)
  static Animation<Offset> createSlideUpAnimation(
    AnimationController controller,
  ) {
    return Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
  }

  /// Scale animation (for button press feedback)
  static Animation<double> createScaleAnimation(
    AnimationController controller,
  ) {
    return Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn));
  }

  // ========================================================================
  // HAPTIC FEEDBACK HELPERS
  // ========================================================================

  /// Light impact (for button taps)
  static Future<void> lightImpact() => HapticFeedback.lightImpact();

  /// Medium impact (for like, save)
  static Future<void> mediumImpact() => HapticFeedback.mediumImpact();

  /// Heavy impact (for important actions)
  static Future<void> heavyImpact() => HapticFeedback.heavyImpact();

  /// Selection feedback (for selections)
  static Future<void> selectionClick() => HapticFeedback.selectionClick();

  // ========================================================================
  // ANIMATION HELPERS
  // ========================================================================

  /// Create a staggered animation for list items (Instagram-style)
  static Animation<double> createStaggeredAnimation(
    AnimationController controller,
    int index, {
    int itemCount = 1,
    Duration delay = const Duration(milliseconds: 50),
  }) {
    // Calculate the delay for this item
    final staggerDelay = (index * delay.inMilliseconds / itemCount).round();

    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          staggerDelay / controller.duration!.inMilliseconds,
          1.0,
          curve: Curves.easeOut,
        ),
      ),
    );
  }

  // ========================================================================
  // PAGE TRANSITIONS
  // ========================================================================

  /// Instagram-style fade transition
  static Route<T> fadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: pageTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Slide up transition (for modals)
  static Route<T> slideUpRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: pageTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  // ========================================================================
  // EASING FUNCTIONS FOR CUSTOM ANIMATIONS
  // ========================================================================

  /// Elastic bounce effect (for heart animation)
  static double elasticBounce(double t) {
    const c4 = (2 * 3.14159) / 3;
    return t == 0
        ? 0
        : t == 1
        ? 1
        : t < 0.5
        ? -(pow(2, 20 * t - 10) * sin((20 * t - 11.125) * c4)) / 2
        : (pow(2, -20 * t + 10) * sin((20 * t - 11.125) * c4)) / 2 + 1;
  }

  /// Smooth ease out quint
  static double easeOutQuint(double t) {
    return 1 - pow(1 - t, 5);
  }
}

// Helper function for pow since Dart's math library requires import
double pow(double base, num exponent) {
  if (exponent == 0) return 1.0;
  if (base == 0) return 0.0;

  double result = 1.0;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}

// Helper function for sin
double sin(double radians) {
  // Approximate sine using Taylor series
  if (radians.abs() < 0.0001) return radians;

  double result = 0;
  for (int i = 0; i < 10; i++) {
    int sign = i.isEven ? 1 : -1;
    int power = 2 * i + 1;
    result += sign * (pow(radians, power) / _factorial(power));
  }
  return result;
}

int _factorial(int n) {
  if (n <= 1) return 1;
  int result = 1;
  for (int i = 2; i <= n; i++) {
    result *= i;
  }
  return result;
}
