import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CommunityEmptyState extends StatelessWidget {
  final bool isJoined;
  final VoidCallback? onPost;

  const CommunityEmptyState({super.key, required this.isJoined, this.onPost});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.forum_outlined,
                      size: 64,
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              isJoined ? 'No posts yet' : 'Join to see posts',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              isJoined
                  ? 'Be the first to share something with the community!'
                  : 'Join this community to start seeing and creating posts.',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (isJoined) ...[
              const SizedBox(height: 24),
              // Create post button
              ElevatedButton.icon(
                onPressed: onPost,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Create First Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

