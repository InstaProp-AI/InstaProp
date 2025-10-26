import 'package:flutter/material.dart';
import '../models/feed_notification.dart';
import '../theme/app_colors.dart';
import 'mini_graph.dart';

class FeedNotificationCard extends StatelessWidget {
  final FeedNotification notification;
  final VoidCallback? onAction;

  const FeedNotificationCard({
    super.key,
    required this.notification,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getNotificationConfig(notification.type);

    // Check if we have metadata with property info
    final hasPropertyImage = notification.metadata?['propertyImage'] != null;
    final hasPriceData = notification.metadata?['priceHistory'] != null;
    final hasPaymentData = notification.metadata?['paymentHistory'] != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              config.color.withOpacity(0.1),
              config.color.withOpacity(0.05),
            ],
          ),
        ),
        child: _buildCardContent(
          config,
          hasPropertyImage,
          hasPriceData,
          hasPaymentData,
        ),
      ),
    );
  }

  Widget _buildCardContent(
    _NotificationConfig config,
    bool hasPropertyImage,
    bool hasPriceData,
    bool hasPaymentData,
  ) {
    // Outbid notification with property image and price trend
    if (notification.type == FeedNotificationType.outbid && hasPropertyImage) {
      return _buildOutbidCard(config);
    }

    // Payment due with payment history chart
    if (notification.type == FeedNotificationType.paymentDue &&
        hasPaymentData) {
      return _buildPaymentDueCard(config);
    }

    // Auction ending soon with property image overlay
    if (notification.type == FeedNotificationType.auctionEnding &&
        hasPropertyImage) {
      return _buildAuctionEndingCard(config);
    }

    // Achievement with large icon
    if (notification.type == FeedNotificationType.achievement ||
        notification.type == FeedNotificationType.milestone) {
      return _buildAchievementCard(config);
    }

    // Default card for other notifications
    return _buildDefaultCard(config);
  }

  Widget _buildOutbidCard(_NotificationConfig config) {
    final propertyImage = notification.metadata?['propertyImage'] as String?;
    final currentBid = notification.metadata?['currentBid'] as num?;
    final yourBid = notification.metadata?['yourBid'] as num?;

    // Safe parsing of price history list
    List<num>? priceHistory;
    try {
      final raw = notification.metadata?['priceHistory'];
      if (raw is List) {
        priceHistory = raw.map((e) => e as num).toList();
      }
    } catch (e) {
      print('Error parsing price history: $e');
      priceHistory = null;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Property thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 120,
              height: 160,
              child: propertyImage != null
                  ? Image.network(
                      propertyImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
          ),
          const SizedBox(width: 16),
          // Content and graph
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(config.icon, size: 20, color: config.color),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: config.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (currentBid != null && yourBid != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPriceLabel('Current', currentBid, config.color),
                      const SizedBox(width: 12),
                      _buildPriceLabel(
                        'Your Bid',
                        yourBid,
                        AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
                if (priceHistory != null && priceHistory.length >= 3) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: MiniGraph(
                        dataPoints: priceHistory,
                        height: 34,
                        lineColor: config.color,
                        areaColor: config.color.withOpacity(0.1),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: config.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      notification.actionText ?? 'Bid +\$1000',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDueCard(_NotificationConfig config) {
    final amount = notification.metadata?['amount'] as num?;
    final dueDate = notification.metadata?['dueDate'] as String?;

    // Safe parsing of payment history list
    List<num>? paymentHistory;
    try {
      final raw = notification.metadata?['paymentHistory'];
      if (raw is List) {
        paymentHistory = raw.map((e) => e as num).toList();
      }
    } catch (e) {
      print('Error parsing payment history: $e');
      paymentHistory = null;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: config.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(config.icon, color: config.color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (amount != null || dueDate != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (amount != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount Due',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: config.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (amount != null && dueDate != null)
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  if (dueDate != null) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Due Date',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dueDate,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (paymentHistory != null && paymentHistory.length >= 3) ...[
            SizedBox(
              height: 50,
              child: MiniGraph(
                dataPoints: paymentHistory,
                height: 50,
                lineColor: config.color,
                areaColor: config.color.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: config.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                notification.actionText ?? 'Pay Now',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionEndingCard(_NotificationConfig config) {
    final propertyImage = notification.metadata?['propertyImage'] as String?;
    final timeRemaining = notification.metadata?['timeRemaining'] as String?;
    final currentBid = notification.metadata?['currentBid'] as num?;
    final bidCount = notification.metadata?['bidCount'] as int?;

    return Stack(
      children: [
        // Property image
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 180,
            decoration: BoxDecoration(color: config.color.withOpacity(0.1)),
            child: propertyImage != null
                ? Image.network(
                    propertyImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderImage(height: 180),
                  )
                : _buildPlaceholderImage(height: 180),
          ),
        ),
        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),
        ),
        // Content overlay
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: config.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    timeRemaining ?? 'Ending Soon',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (currentBid != null)
                  Text(
                    'Current Bid: \$${currentBid.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                if (bidCount != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '$bidCount bids',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: config.color,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      notification.actionText ?? 'Place Bid',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(_NotificationConfig config) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Large animated badge
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [config.color, config.color.withOpacity(0.7)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            notification.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            notification.message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: config.color,
                side: BorderSide(color: config.color),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'View Profile',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCard(_NotificationConfig config) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: config.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(config.icon, color: config.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(notification.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (notification.actionText != null) ...[
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: config.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                notification.actionText!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceLabel(String label, num value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          '\$${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage({double height = 160}) {
    return Container(
      height: height,
      color: AppColors.border,
      child: const Center(
        child: Icon(Icons.image, size: 48, color: AppColors.textSecondary),
      ),
    );
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
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
}

class _NotificationConfig {
  final IconData icon;
  final Color color;

  _NotificationConfig({required this.icon, required this.color});
}
