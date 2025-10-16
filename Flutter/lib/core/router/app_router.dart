import 'package:flutter/material.dart';
// Use existing working pages to keep the app functional
import '../../pages/home_page.dart';
import '../../pages/auth_page.dart';
import '../../pages/profile_page.dart';
import '../../pages/valuate_page.dart';

/// Centralized app router
class AppRouter {
  // Route constants
  static const String root = '/';
  static const String home = '/home';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String valuate = '/valuate';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // final args = settings.arguments; // reserved for future use

    switch (settings.name) {
      case root:
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());

      // Auth routes
      case auth:
      case login:
        return MaterialPageRoute(builder: (_) => const AuthPage());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());

      case valuate:
        return MaterialPageRoute(builder: (_) => const ValuatePage());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
    }
  }

  /// Navigate to route
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  /// Navigate and replace
  static Future<T?> navigateAndReplace<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, Object?>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate and remove all previous routes
  static Future<T?> navigateAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Go back
  static void goBack(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }

  /// Check if can go back
  static bool canGoBack(BuildContext context) {
    return Navigator.canPop(context);
  }
}
