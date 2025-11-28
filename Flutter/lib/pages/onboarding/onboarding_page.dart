import 'package:flutter/material.dart';
import '../../services/onboarding_service.dart';
import '../../core/router/app_router.dart';
import '../../theme/app_colors.dart';
import 'widgets/intro_screen.dart';
import 'widgets/page_indicator.dart';
import 'onboarding_complete_page.dart';

/// Main onboarding page with swipeable intro screens
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  static const int _totalPages = 5; // 4 intro pages + 1 signup page
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _skipToEnd() async {
    // Complete onboarding and allow browsing without login
    await OnboardingService.setOnboardingComplete();
    if (mounted) {
      // Navigate to home page (allows browsing without login)
      AppRouter.navigateAndRemoveUntil(
        context,
        AppRouter.home,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    await OnboardingService.setOnboardingComplete();
    if (mounted) {
      // Navigate to home page (allows browsing without login)
      AppRouter.navigateAndRemoveUntil(
        context,
        AppRouter.home,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // PageView with intro screens
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                // Screen 1: Welcome
                IntroScreen(
                  screenIndex: 0,
                  headline: 'Discover Your Dream Property',
                  subtitle:
                      'Browse thousands of properties, connect with developers, and invest smartly',
                ),
                // Screen 2: Smart Search
                IntroScreen(
                  screenIndex: 1,
                  headline: 'Smart Property Search',
                  subtitle:
                      'Advanced filters, interactive maps, and AI-powered recommendations',
                ),
                // Screen 3: Live Auctions
                IntroScreen(
                  screenIndex: 2,
                  headline: 'Live Auctions & Deals',
                  subtitle:
                      'Participate in real-time auctions, get exclusive deals, never miss an opportunity',
                ),
                // Screen 4: Portfolio Management
                IntroScreen(
                  screenIndex: 3,
                  headline: 'Track Your Investments',
                  subtitle:
                      'Monitor portfolio, analyze market trends, maximize returns',
                ),
                // Final screen: Sign up / Login
                OnboardingCompletePage(
                  onComplete: _completeOnboarding,
                ),
              ],
            ),
            // Skip button (top-right, hide on last page)
            if (_currentPage < _totalPages - 1)
              Positioned(
                top: 16,
                right: 24,
                child: _buildSkipButton(),
              ),
            // Page indicators (bottom center, show on all pages)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: OnboardingPageIndicator(
                  controller: _pageController,
                  pageCount: _totalPages,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _skipToEnd,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        'Skip',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
