import 'package:flutter/material.dart';
// Use existing working pages to keep the app functional
import '../../pages/home_page.dart';
import '../../pages/auth_page.dart';
import '../../pages/profile_page.dart';
import '../../pages/valuate_page.dart';
import '../../pages/all_news_page.dart';
import '../../pages/news_detail_page.dart';
import '../../pages/explore_page.dart';
import '../../pages/market_page.dart';
import '../../pages/auctions_page.dart';
import '../../pages/add_property_page.dart';
import '../../pages/add_property_financial_page.dart';
import '../../pages/properties_management_page.dart';
import '../../models/news_article.dart';
import '../../pages/leaderboard_page.dart';
import '../../pages/onboarding/onboarding_page.dart';
import '../../pages/lives_page.dart';

/// Centralized app router
class AppRouter {
  // Route constants
  static const String root = '/';
  static const String home = '/home';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String profile = '/profile';
  static const String valuate = '/valuate';
  static const String allNews = '/all-news';
  static const String newsDetail = '/news';
  static const String explore = '/explore';
  static const String market = '/market';
  static const String auctions = '/auctions';
  static const String leaderboard = '/leaderboard';
  static const String lives = '/lives';
  static const String propertyManagement = '/properties';
  static const String addProperty = '/add-property';
  static const String addPropertyFinancial = '/add-property/financial';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case root:
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());

      // Onboarding route
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());

      // Auth routes
      case auth:
      case login:
        return MaterialPageRoute(builder: (_) => const AuthPage());

      case profile:
        return MaterialPageRoute(builder: (_) => const SettingsPage());

      case valuate:
        final propertyId = args is String ? args : (args is Map<String, dynamic> ? args['propertyId'] as String? : null);
        return MaterialPageRoute(
          builder: (_) => ValuatePage(propertyId: propertyId),
        );

      // News routes
      case allNews:
        return MaterialPageRoute(builder: (_) => const AllNewsPage());

      case explore:
        return MaterialPageRoute(builder: (_) => const ExplorePage());

      case market:
        return MaterialPageRoute(builder: (_) => const MarketPage());

      case leaderboard:
        int initialTabIndex = 0;
        if (args is Map<String, dynamic>) {
          final index = args['initialTabIndex'];
          if (index is int) {
            initialTabIndex = index;
          }
        }
        return MaterialPageRoute(
          builder: (_) => LeaderboardPage(initialTabIndex: initialTabIndex),
        );

      case auctions:
        return MaterialPageRoute(builder: (_) => const AuctionsPage());

      case lives:
        return MaterialPageRoute(builder: (_) => const LivesPage());

      case propertyManagement:
        return MaterialPageRoute(builder: (_) => const PropertiesManagementPage());

      case addProperty:
        return MaterialPageRoute(builder: (_) => const AddPropertyPage());

      case addPropertyFinancial:
        final args = settings.arguments;
        String? propertyId;
        String? propertyName;
        if (args is Map<String, dynamic>) {
          propertyId = args['propertyId'] as String?;
          propertyName = args['propertyName'] as String?;
        } else if (args is String) {
          propertyId = args;
        }
        return MaterialPageRoute(
          builder: (_) => AddPropertyFinancialPage(
            propertyId: propertyId,
            propertyName: propertyName,
          ),
        );

      default:
        // Handle dynamic news detail route
        if (settings.name != null && settings.name!.startsWith('/news/')) {
          final newsId = settings.name!.split('/').last;
          // For now, we'll create a placeholder news article
          // In a real app, you'd fetch the news article by ID
          final news = NewsArticle(
            newsArticleId: newsId,
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
