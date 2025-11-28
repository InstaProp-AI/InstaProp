import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../theme/app_colors.dart';

/// Custom page indicator dots for onboarding
class OnboardingPageIndicator extends StatelessWidget {
  final PageController controller;
  final int pageCount;

  const OnboardingPageIndicator({
    super.key,
    required this.controller,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    return SmoothPageIndicator(
      controller: controller,
      count: pageCount,
      effect: ExpandingDotsEffect(
        activeDotColor: AppColors.primary,
        dotColor: AppColors.border,
        dotHeight: 8,
        dotWidth: 8,
        expansionFactor: 2.5,
        spacing: 8,
        radius: 4,
      ),
    );
  }
}

/// Alternative simple dot indicator
class SimplePageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const SimplePageIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == currentPage
                ? AppColors.primary
                : AppColors.border,
          ),
        ),
      ),
    );
  }
}
