import 'package:flutter/material.dart';
import '../../core/router/app_router.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_colors.dart';

/// Final informative onboarding screen
class OnboardingCompletePage extends StatelessWidget {
  final VoidCallback? onComplete;

  const OnboardingCompletePage({
    super.key,
    this.onComplete,
  });

  Future<void> _skipAndExplore(BuildContext context) async {
    // Complete onboarding and allow browsing without login
    await OnboardingService.setOnboardingComplete();
    if (context.mounted) {
      AppRouter.navigateAndRemoveUntil(context, AppRouter.home);
      onComplete?.call();
    }
  }

  void _signUpNow(BuildContext context) {
    // Navigate to auth page
    AppRouter.navigateAndRemoveUntil(context, AppRouter.auth);
    onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon at top
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.accent.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.handshake_rounded,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 40),
          // Informative message
          Text(
            'Join Instaprop Today',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'If you want to join and track your investments, monitor your portfolio, participate in live auctions, and make smart real estate decisions, sign up now to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const Spacer(),
          // Sign Up Now button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _signUpNow(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign Up Now',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Skip and Explore Now button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => _skipAndExplore(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(
                  color: AppColors.border,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Skip and Explore Now',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
