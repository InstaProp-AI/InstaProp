import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/feed_notification.dart';
import '../theme/app_colors.dart';
import 'progressive_network_image.dart';

/// Instagram Story-style notification card with swipe-to-dismiss
class FeedNotificationCard extends StatefulWidget {
  final FeedNotification notification;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const FeedNotificationCard({
    super.key,
    required this.notification,
    this.onAction,
    this.onDismiss,
  });

  @override
  State<FeedNotificationCard> createState() => _FeedNotificationCardState();
}

class _FeedNotificationCardState extends State<FeedNotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    HapticFeedback.lightImpact();
    await _slideController.forward();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getNotificationConfig(widget.notification.type);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Check metadata
    final hasPropertyImage =
        widget.notification.metadata?['propertyImage'] != null;
    final propertyImage =
        widget.notification.metadata?['propertyImage'] as String?;

    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 200) {
            _handleDismiss();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: config.color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: widget.onAction,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Icon with gradient background
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [config.color, config.color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(config.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.notification.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(widget.notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Property thumbnail or action button
                  if (hasPropertyImage && propertyImage != null)
                    ProgressiveNetworkImage(
                      imageUrl: propertyImage,
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(8),
                      placeholder: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.image,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    )
                  else if (widget.notification.actionText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: config.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.notification.actionText!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  _NotificationConfig _getNotificationConfig(FeedNotificationType type) {
    switch (type) {
      case FeedNotificationType.outbid:
        return _NotificationConfig(icon: Icons.gavel, color: AppColors.error);
      case FeedNotificationType.auctionEnding:
        return _NotificationConfig(icon: Icons.timer, color: AppColors.warning);
      case FeedNotificationType.auctionRequest:
        return _NotificationConfig(
          icon: Icons.request_quote,
          color: AppColors.primary,
        );
      case FeedNotificationType.bidPlaced:
        return _NotificationConfig(
          icon: Icons.notifications_active,
          color: AppColors.success,
        );
      case FeedNotificationType.auctionWon:
        return _NotificationConfig(
          icon: Icons.emoji_events,
          color: Colors.amber,
        );
      case FeedNotificationType.auctionApproved:
        return _NotificationConfig(
          icon: Icons.check_circle,
          color: AppColors.success,
        );
      case FeedNotificationType.propertyInspection:
        return _NotificationConfig(
          icon: Icons.calendar_today,
          color: Colors.blue,
        );
      case FeedNotificationType.paymentDue:
        return _NotificationConfig(
          icon: Icons.payment,
          color: Colors.deepOrange,
        );
      case FeedNotificationType.newEvent:
        return _NotificationConfig(icon: Icons.event, color: Colors.purple);
      case FeedNotificationType.achievement:
        return _NotificationConfig(
          icon: Icons.military_tech,
          color: Colors.amber,
        );
      case FeedNotificationType.communityInvite:
        return _NotificationConfig(icon: Icons.group_add, color: Colors.teal);
      case FeedNotificationType.newFollower:
        return _NotificationConfig(
          icon: Icons.person_add,
          color: Colors.indigo,
        );
      case FeedNotificationType.postLiked:
        return _NotificationConfig(icon: Icons.favorite, color: Colors.pink);
      case FeedNotificationType.commentReply:
        return _NotificationConfig(icon: Icons.comment, color: Colors.cyan);
      case FeedNotificationType.auctionStarted:
        return _NotificationConfig(
          icon: Icons.new_releases,
          color: Colors.lightGreen,
        );
      case FeedNotificationType.priceDrop:
        return _NotificationConfig(
          icon: Icons.trending_down,
          color: AppColors.success,
        );
      case FeedNotificationType.trendingPost:
        return _NotificationConfig(
          icon: Icons.local_fire_department,
          color: Colors.deepOrange,
        );
      case FeedNotificationType.milestone:
        return _NotificationConfig(icon: Icons.stars, color: Colors.amber);
      case FeedNotificationType.aiSuggestion:
        return _NotificationConfig(
          icon: Icons.auto_awesome,
          color: Colors.deepPurple,
        );
      case FeedNotificationType.referral:
        return _NotificationConfig(
          icon: Icons.card_giftcard,
          color: AppColors.success,
        );
    }
  }
}

class _NotificationConfig {
  final IconData icon;
  final Color color;

  _NotificationConfig({required this.icon, required this.color});
}
