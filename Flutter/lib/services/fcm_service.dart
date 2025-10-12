import 'package:firebase_messaging/firebase_messaging.dart';

/// Firebase Cloud Messaging (FCM) Service
/// Handles push notifications for the app
class FcmService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static String? _fcmToken;

  /// Initialize FCM and request permissions
  static Future<void> initialize() async {
    try {
      // Request notification permissions (iOS)
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM: User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️ FCM: User granted provisional permission');
      } else {
        print('❌ FCM: User declined or has not accepted permission');
        return;
      }

      // Get the FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        print('📱 FCM Token: $_fcmToken');
        // TODO: Send this token to your backend server to store it
        // await ApiService.post('/account/fcm-token', {'token': _fcmToken});
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('🔄 FCM Token refreshed: $newToken');
        // TODO: Send updated token to backend
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (when app is in background but not terminated)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

      // Handle notification when app is opened from terminated state
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpened(initialMessage);
      }

      print('✅ FCM Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📩 Foreground Message received:');
    print('  Title: ${message.notification?.title}');
    print('  Body: ${message.notification?.body}');
    print('  Data: ${message.data}');

    // You can show a local notification here or update UI
    // For now, just logging the message
  }

  /// Handle message opened from notification tap
  static void _handleMessageOpened(RemoteMessage message) {
    print('👆 Notification tapped:');
    print('  Title: ${message.notification?.title}');
    print('  Body: ${message.notification?.body}');
    print('  Data: ${message.data}');

    // Navigate to specific screen based on notification data
    final String? type = message.data['type'];
    final String? auctionId = message.data['auctionId'];

    if (type == 'auction' && auctionId != null) {
      print('🏠 Navigate to auction: $auctionId');
      // TODO: Navigate to auction details page
      // navigatorKey.currentState?.pushNamed('/auction-details', arguments: auctionId);
    }
  }

  /// Subscribe to a topic (e.g., 'all_users', 'new_auctions')
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Get the current FCM token
  static String? getToken() {
    return _fcmToken;
  }

  /// Delete FCM token (on logout)
  static Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      print('✅ FCM token deleted');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }
}

/// Background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Background Message received:');
  print('  Title: ${message.notification?.title}');
  print('  Body: ${message.notification?.body}');
  print('  Data: ${message.data}');
}
