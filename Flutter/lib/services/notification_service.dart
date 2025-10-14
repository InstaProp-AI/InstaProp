import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/notification.dart';
import 'firestore_service.dart';

class NotificationService extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  bool _isLoggedIn = false;
  int? _currentUserId;

  // Firestore real-time listeners
  StreamSubscription<List<AppNotification>>? _notificationsSubscription;

  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  // Fetch all notifications (public for non-logged-in, user-specific for logged-in)
  Future<ApiResponse<List<AppNotification>>> getNotifications({
    bool unreadOnly = false,
    bool? isLoggedIn, // Made nullable to use internal state if not provided
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Use provided isLoggedIn or fall back to internal state
      final loggedIn = isLoggedIn ?? _isLoggedIn;

      String endpoint;

      if (!loggedIn) {
        // Get public notifications for non-logged-in users
        endpoint = '/api/notification/public';
      } else {
        // Get user-specific notifications
        endpoint = unreadOnly
            ? '/api/notification?unreadOnly=true'
            : '/api/notification';
      }

      final response = await ApiClient.getList(
        endpoint,
        AppNotification.fromJson,
      );

      if (response.success && response.data != null) {
        _notifications = response.data!;
        // Only update unread count for logged-in users
        if (loggedIn) {
          await _updateUnreadCount();
        } else {
          // For guests, count notifications as unread (since all are unread for guests)
          _unreadCount = response.data!.length;
        }
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return ApiResponse.error('Failed to fetch notifications: $e');
    }
  }

  // Get unread count
  Future<void> _updateUnreadCount() async {
    try {
      final response = await ApiClient.get(
        '/api/notification/unread-count',
        (data) => data['count'] as int,
      );

      if (response.success && response.data != null) {
        _unreadCount = response.data!;
        notifyListeners();
      }
    } catch (e) {
      print('Failed to update unread count: $e');
    }
  }

  // Mark notification as read
  Future<ApiResponse<bool>> markAsRead(int notificationId) async {
    try {
      final response = await ApiClient.put(
        '/api/notification/$notificationId/read',
        {},
        (data) => true,
      );

      if (response.success) {
        // Update local notification
        final index = _notifications.indexWhere(
          (n) => n.notificationId == notificationId,
        );
        if (index != -1) {
          _notifications[index] = AppNotification(
            notificationId: _notifications[index].notificationId,
            userId: _notifications[index].userId,
            title: _notifications[index].title,
            message: _notifications[index].message,
            type: _notifications[index].type,
            isRead: true,
            auctionId: _notifications[index].auctionId,
            bidId: _notifications[index].bidId,
            propertyId: _notifications[index].propertyId,
            eventId: _notifications[index].eventId,
            createdAt: _notifications[index].createdAt,
            readAt: DateTime.now(),
          );
          await _updateUnreadCount();
          notifyListeners();
        }
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<ApiResponse<bool>> markAllAsRead() async {
    try {
      final response = await ApiClient.put(
        '/api/notification/read-all',
        {},
        (data) => true,
      );

      if (response.success) {
        // Update all local notifications
        _notifications = _notifications
            .map(
              (n) => AppNotification(
                notificationId: n.notificationId,
                userId: n.userId,
                title: n.title,
                message: n.message,
                type: n.type,
                isRead: true,
                auctionId: n.auctionId,
                bidId: n.bidId,
                propertyId: n.propertyId,
                eventId: n.eventId,
                createdAt: n.createdAt,
                readAt: DateTime.now(),
              ),
            )
            .toList();
        _unreadCount = 0;
        notifyListeners();
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to mark all as read: $e');
    }
  }

  // Delete notification
  Future<ApiResponse<void>> deleteNotification(int notificationId) async {
    try {
      final response = await ApiClient.delete(
        '/api/notification/$notificationId',
      );

      if (response.success) {
        _notifications.removeWhere((n) => n.notificationId == notificationId);
        await _updateUnreadCount();
        notifyListeners();
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to delete notification: $e');
    }
  }

  // Clear all notifications
  void clear() {
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }

  // Refresh notifications (for pull-to-refresh)
  Future<void> refresh() async {
    await getNotifications();
  }

  /// Start Firestore real-time listeners for notifications
  void startNotificationListeners(int userId) {
    _currentUserId = userId;
    _isLoggedIn = true;

    print('🔥 Starting Firestore notification listener for user $userId');

    // Listen to user notifications in real-time
    _notificationsSubscription =
        FirestoreService.listenToUserNotifications(userId).listen(
          (notifications) {
            print(
              '🔥 Firestore: Received ${notifications.length} notifications for user $userId',
            );
            if (notifications.isNotEmpty) {
              print('🔔 Latest notification: ${notifications.first.title}');
              print(
                '🔔 Latest notification message: ${notifications.first.message}',
              );
            }
            _notifications = notifications;
            _unreadCount = notifications.where((n) => !n.isRead).length;
            print('📬 Unread notifications: $_unreadCount');
            notifyListeners();
          },
          onError: (error) {
            print('❌ Firestore notification listener error: $error');
            print('⚠️ Error details: ${error.toString()}');
            print('⚠️ Falling back to API for notifications...');
            // Fallback to API if Firestore fails
            getNotifications();
          },
        );
  }

  /// Stop Firestore listeners (when user logs out)
  void stopNotificationListeners() {
    print('🛑 Stopping Firestore notification listeners');
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
    _currentUserId = null;
    _isLoggedIn = false;
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}
