import 'package:flutter/material.dart';
// Use existing working pages to keep the app functional
import '../../pages/home_page.dart';
import '../../pages/auth_page.dart';
import '../../pages/profile_page.dart';
import '../../pages/valuate_page.dart';
import '../../pages/all_news_page.dart';
import '../../pages/news_detail_page.dart';
import '../../models/news_article.dart';

/// Centralized app router
class AppRouter {
  // Route constants
  static const String root = '/';
  static const String home = '/home';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String valuate = '/valuate';
  static const String allNews = '/all-news';
  static const String newsDetail = '/news';

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
        return MaterialPageRoute(builder: (_) => const SettingsPage());

      case valuate:
        return MaterialPageRoute(builder: (_) => const ValuatePage());

      // News routes
      case allNews:
        return MaterialPageRoute(builder: (_) => const AllNewsPage());

      default:
        // Handle dynamic news detail route
        if (settings.name != null && settings.name!.startsWith('/news/')) {
          final newsId = settings.name!.split('/').last;
          // For now, we'll create a placeholder news article
          // In a real app, you'd fetch the news article by ID
          final news = NewsArticle(
            newsArticleId: int.tryParse(newsId) ?? 0,
            title: 'Loading...',
            content: 'Loading article...',
            publishedDate: DateTime.now(),
            createdAt: DateTime.now(),
            isPublished: true,
            images: [],
          );
          return MaterialPageRoute(builder: (_) => NewsDetailPage(news: news));
        }
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
