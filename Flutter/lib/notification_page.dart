import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/notification_service.dart';
import 'services/auction_service.dart';
import 'services/property_service.dart';
import 'models/notification.dart';
import 'models/property.dart';
import 'pages/auction_details_page.dart';

// Use the same color constants as main.dart for consistency
const Color kBg = AppColors.background;
const Color kCard = AppColors.surface;
const Color kPrimary = AppColors.primary;
const Color kAccent = AppColors.secondary;
const Color kText = AppColors.textPrimary;
const Color kGray = AppColors.background;
const Color kWhite = AppColors.surface;

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    // The Firestore listeners are already active via NotificationService
    // No need to call getNotifications() as real-time updates handle it
    print('📬 Notification page opened - Firestore listeners active');

    // Check if user is logged in and listeners are started
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    print(
      '📬 Current notifications count: ${notificationService.notifications.length}',
    );
  }

  Future<void> _loadNotifications() async {
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    await notificationService.getNotifications();
  }

  Future<void> _markAsRead(int notificationId) async {
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    await notificationService.markAsRead(notificationId);
  }

  Future<void> _markAllAsRead() async {
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    final response = await notificationService.markAllAsRead();

    if (response.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );
    final response = await notificationService.deleteNotification(
      notificationId,
    );

    if (response.success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
    }
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    // Mark as read first
    if (!notification.isRead) {
      await _markAsRead(notification.notificationId);
    }

    // Handle navigation based on notification type and related entities
    if (notification.auctionId != null) {
      // Navigate to auction details
      await _navigateToAuction(notification.auctionId!);
    } else if (notification.propertyId != null) {
      // Navigate to property details
      await _navigateToProperty(notification.propertyId!);
    } else {
      // Show popup with full notification details
      _showNotificationDialog(notification);
    }
  }

  Future<void> _navigateToAuction(int auctionId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: kPrimary)),
    );

    try {
      // Fetch auction details
      final response = await AuctionService.getAuction(auctionId);

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (response.success && response.data != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AuctionDetailsPage(auction: response.data!),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Auction not found'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading auction: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  Future<void> _navigateToProperty(int propertyId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: kPrimary)),
    );

    try {
      // Fetch property details
      final response = await PropertyService.getProperty(propertyId);

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (response.success && response.data != null) {
          // Show property details in a dialog
          _showPropertyDialog(response.data!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Property not found'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading property: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _showPropertyDialog(Property property) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Property Image
              if (property.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Image.network(
                    property.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: AppColors.background,
                      child: const Icon(
                        Icons.home,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              // Property Details
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: kAccent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location,
                            style: const TextStyle(fontSize: 14, color: kText),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (property.description.isNotEmpty)
                      Text(
                        property.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: kText,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildPropertyDetailChip(
                          Icons.bed,
                          '${property.bedrooms} Beds',
                        ),
                        const SizedBox(width: 8),
                        _buildPropertyDetailChip(
                          Icons.bathtub,
                          '${property.bathrooms} Baths',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildPropertyDetailChip(
                      Icons.square_foot,
                      '${property.squareFeet} sqft',
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: AppColors.surface,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16,
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
        ),
      ),
    );
  }

  Widget _buildPropertyDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kPrimary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: kPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingIcon(AppNotification notification) {
    // Show different icons based on what happens when tapped
    if (notification.auctionId != null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.gavel, color: kPrimary, size: 16),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, color: kPrimary, size: 12),
          ],
        ),
      );
    } else if (notification.propertyId != null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.home, color: AppColors.primary, size: 16),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 12),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.info_outline, color: kAccent, size: 20),
      );
    }
  }

  Widget _buildFooterMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary!, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notifications are automatically deleted after 14 days',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(AppNotification notification) {
    final icon = _getIconForNotificationType(notification.type);
    final color = _getColorForNotificationType(notification.type);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon and color
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: AppColors.surface, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.type.displayName,
                            style: const TextStyle(
                              color: AppColors.surface,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.getTimeAgo(),
                            style: TextStyle(
                              color: AppColors.surface.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 16,
                        color: kText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: AppColors.surface,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Got it',
                          style: TextStyle(
                            fontSize: 16,
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
        ),
      ),
    );
  }

  IconData _getIconForNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.bidPlaced:
        return Icons.gavel;
      case NotificationType.outbid:
        return Icons.warning;
      case NotificationType.auctionStarted:
        return Icons.add_box;
      case NotificationType.auctionEnding:
        return Icons.timer;
      case NotificationType.auctionWon:
        return Icons.check_circle;
      case NotificationType.auctionLost:
        return Icons.cancel;
      case NotificationType.eventReminder:
        return Icons.event;
      case NotificationType.publicEvent:
        return Icons.public;
      case NotificationType.auctionApproved:
        return Icons.check_circle;
      case NotificationType.auctionRejected:
        return Icons.cancel;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color _getColorForNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.bidPlaced:
        return kPrimary;
      case NotificationType.outbid:
        return Colors.redAccent;
      case NotificationType.auctionStarted:
        return Colors.blueAccent;
      case NotificationType.auctionEnding:
        return kAccent;
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
        return kPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: kPrimary),
        actions: [
          Consumer<NotificationService>(
            builder: (context, notificationService, child) {
              if (notificationService.notifications.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.done_all),
                onPressed: _markAllAsRead,
                tooltip: 'Mark all as read',
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          if (notificationService.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimary),
            );
          }

          if (notificationService.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet.',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadNotifications,
            color: kPrimary,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              itemCount:
                  notificationService.notifications.length + 1, // +1 for footer
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                // Show footer message after all notifications
                if (index == notificationService.notifications.length) {
                  return _buildFooterMessage();
                }

                // Show notification item
                final notification = notificationService.notifications[index];
                final icon = _getIconForNotificationType(notification.type);
                final color = _getColorForNotificationType(notification.type);

                return Dismissible(
                  key: Key(notification.notificationId.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) =>
                      _deleteNotification(notification.notificationId),
                  background: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: AppColors.surface,
                      size: 28,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: notification.isRead
                          ? const Color.fromARGB(255, 240, 240, 240)
                          : const Color.fromARGB(255, 232, 229, 229),
                      borderRadius: BorderRadius.circular(18),
                      border: notification.isRead
                          ? null
                          : Border.all(
                              color: kPrimary.withOpacity(0.3),
                              width: 2,
                            ),
                    ),
                    child: ListTile(
                      onTap: () => _handleNotificationTap(notification),
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.15),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                color: kPrimary,
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: kPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: TextStyle(
                              color: kText,
                              fontSize: 15,
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.getTimeAgo(),
                            style: const TextStyle(
                              color: kAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      trailing: _buildTrailingIcon(notification),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
