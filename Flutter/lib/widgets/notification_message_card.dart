import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../theme/app_colors.dart';

class NotificationMessageCard extends StatelessWidget {
  final AppNotification notification;
  final Function(String action)? onActionTap;
  final bool isRead;

  const NotificationMessageCard({
    super.key,
    required this.notification,
    this.onActionTap,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _getIconForNotificationType(notification.type);
    final color = _getColorForNotificationType(notification.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 50),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? AppColors.surface : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: isRead ? 1 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.type.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      notification.getTimeAgo(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            notification.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Message
          Text(
            notification.message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          // Action buttons
          const SizedBox(height: 16),
          _buildActionButtons(notification.type, color),
        ],
      ),
    );
  }

  Widget _buildActionButtons(NotificationType type, Color color) {
    final buttons = _getActionButtonsForType(type);

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons
          .map(
            (button) => _buildActionButton(
              button['label']!,
              button['action']!,
              color,
              button['isPrimary'] ?? false,
            ),
          )
          .toList(),
    );
  }

  Widget _buildActionButton(
    String label,
    String action,
    Color color,
    bool isPrimary,
  ) {
    return ElevatedButton(
      onPressed: () => onActionTap?.call(action),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : color.withOpacity(0.1),
        foregroundColor: isPrimary ? Colors.white : color,
        elevation: isPrimary ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isPrimary
              ? BorderSide.none
              : BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getActionButtonsForType(NotificationType type) {
    switch (type) {
      case NotificationType.outbid:
        return [
          {'label': 'Bid +\$1000', 'action': 'quick_bid', 'isPrimary': true},
          {'label': 'View Auction', 'action': 'view_auction'},
          {'label': 'Dismiss', 'action': 'dismiss'},
        ];
      case NotificationType.bidPlaced:
        return [
          {
            'label': 'View Auction',
            'action': 'view_auction',
            'isPrimary': true,
          },
          {'label': 'Dismiss', 'action': 'dismiss'},
        ];
      case NotificationType.auctionStarted:
        return [
          {
            'label': 'View Auction',
            'action': 'view_auction',
            'isPrimary': true,
          },
          {'label': 'Place Bid', 'action': 'place_bid'},
          {'label': 'Dismiss', 'action': 'dismiss'},
        ];
      case NotificationType.auctionEnding:
        return [
          {'label': 'Quick Bid', 'action': 'quick_bid', 'isPrimary': true},
          {'label': 'View Auction', 'action': 'view_auction'},
          {'label': 'Dismiss', 'action': 'dismiss'},
        ];
      case NotificationType.auctionWon:
        return [
          {
            'label': 'View Details',
            'action': 'view_auction',
            'isPrimary': true,
          },
          {'label': 'Dismiss', 'action': 'dismiss'},
        ];
      case NotificationType.auctionLost:
        return [
          {'label': 'Find Similar', 'action': 'find_similar'},
          {'label': 'Dismiss', 'action': 'dismiss'},
        ];
      case NotificationType.eventReminder:
        return [
          {'label': 'View Event', 'action': 'view_event', 'isPrimary': true},
          {'label': 'Dismiss', 'action': 'dismiss'},
        ];
      case NotificationType.publicEvent:
      case NotificationType.general:
        return [
          {'label': 'Learn More', 'action': 'learn_more'},
          {'label': 'Dismiss', 'action': 'dismiss'},
        ];
      case NotificationType.auctionApproved:
        return [
          {
            'label': 'View Auction',
            'action': 'view_auction',
            'isPrimary': true,
          },
          {'label': 'Dismiss', 'action': 'dismiss'},
        ];
      case NotificationType.auctionRejected:
        return [
          {'label': 'View Details', 'action': 'view_auction'},
          {'label': 'Dismiss', 'action': 'dismiss'},
        ];
    }
  }

  IconData _getIconForNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.bidPlaced:
        return Icons.gavel;
      case NotificationType.outbid:
        return Icons.warning_rounded;
      case NotificationType.auctionStarted:
        return Icons.play_circle_filled_rounded;
      case NotificationType.auctionEnding:
        return Icons.timer;
      case NotificationType.auctionWon:
        return Icons.celebration_rounded;
      case NotificationType.auctionLost:
        return Icons.sentiment_dissatisfied_rounded;
      case NotificationType.eventReminder:
        return Icons.event;
      case NotificationType.publicEvent:
        return Icons.campaign_rounded;
      case NotificationType.auctionApproved:
        return Icons.check_circle_rounded;
      case NotificationType.auctionRejected:
        return Icons.cancel_rounded;
      case NotificationType.general:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.bidPlaced:
        return AppColors.primary;
      case NotificationType.outbid:
        return Colors.redAccent;
      case NotificationType.auctionStarted:
        return Colors.blueAccent;
      case NotificationType.auctionEnding:
        return Colors.orangeAccent;
      case NotificationType.auctionWon:
        return Colors.green;
      case NotificationType.auctionLost:
        return Colors.red;
      case NotificationType.eventReminder:
        return Colors.orange;
      case NotificationType.publicEvent:
        return Colors.blue;
      case NotificationType.auctionApproved:
        return Colors.green;
      case NotificationType.auctionRejected:
        return Colors.red;
      case NotificationType.general:
        return AppColors.primary;
    }
  }
}
