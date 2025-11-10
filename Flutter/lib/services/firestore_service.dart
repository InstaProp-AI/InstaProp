import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_status.dart';
import '../models/auction.dart';
import '../models/bid.dart';
import '../models/notification.dart';

/// Firestore Service for real-time data synchronization
class FirestoreService {
  static FirebaseFirestore? _firestoreOrNull() {
    if (!FirebaseStatus.isReady) {
      return null;
    }

    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      print('Firestore instance unavailable: $e');
      return null;
    }
  }

  // ============================================
  // AUCTION LISTENERS
  // ============================================

  /// Listen to a specific auction in real-time
  /// Returns a stream that emits auction updates
  static Stream<Auction?> listenToAuction(int auctionId) {
    final firestore = _firestoreOrNull();
    if (firestore == null) {
      return Stream<Auction?>.value(null);
    }

    return firestore
        .collection('auctions')
        .doc(auctionId.toString())
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            print('⚠️ Firestore: Auction $auctionId document does not exist');
            return null;
          }

          try {
            final data = snapshot.data()!;
            print(
              '🔥 Firestore: Received auction $auctionId data: ${data.keys}',
            );
            print(
              '🔥 Firestore: currentPrice = ${data['currentPrice']}, bidCount = ${data['bidCount']}',
            );
            return Auction.fromJson(data);
          } catch (e, stackTrace) {
            print('❌ Error parsing auction from Firestore: $e');
            print('❌ Stack trace: $stackTrace');
            print('❌ Data received: ${snapshot.data()}');
            return null;
          }
        });
  }

  /// Listen to all auctions (for home page)
  /// Returns a stream that emits list of auctions
  static Stream<List<Auction>> listenToAllAuctions() {
    final firestore = _firestoreOrNull();
    if (firestore == null) {
      return Stream<List<Auction>>.value([]);
    }

    return firestore.collection('auctions').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return Auction.fromJson(doc.data());
            } catch (e) {
              print('Error parsing auction ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Auction>()
          .toList();
    });
  }

  /// Listen to active auctions only
  static Stream<List<Auction>> listenToActiveAuctions() {
    final firestore = _firestoreOrNull();
    if (firestore == null) {
      return Stream<List<Auction>>.value([]);
    }

    return firestore
        .collection('auctions')
        .where('status', isEqualTo: 'Active')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return Auction.fromJson(doc.data());
                } catch (e) {
                  print('Error parsing auction ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<Auction>()
              .toList();
        });
  }

  // ============================================
  // BID LISTENERS
  // ============================================

  /// Listen to bids for a specific auction
  /// Returns a stream that emits list of bids
  static Stream<List<Bid>> listenToAuctionBids(int auctionId) {
    final firestore = _firestoreOrNull();
    if (firestore == null) {
      return Stream<List<Bid>>.value([]);
    }

    return firestore
        .collection('auctions')
        .doc(auctionId.toString())
        .collection('bids')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return Bid.fromJson(doc.data());
                } catch (e) {
                  print('Error parsing bid ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<Bid>()
              .toList();
        });
  }

  // ============================================
  // NOTIFICATION LISTENERS
  // ============================================

  /// Listen to notifications for a specific user
  /// Returns a stream that emits list of notifications
  static Stream<List<AppNotification>> listenToUserNotifications(int userId) {
    final firestore = _firestoreOrNull();
    if (firestore == null) {
      return Stream<List<AppNotification>>.value([]);
    }

    print('🔥 Setting up Firestore listener for user $userId notifications');
    return firestore
        .collection('users')
        .doc(userId.toString())
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to last 50 notifications
        .snapshots()
        .map((snapshot) {
          print(
            '🔥 Firestore: User $userId notifications snapshot - ${snapshot.docs.length} documents',
          );

          final notifications = snapshot.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  print('📬 Parsing notification ${doc.id}: ${data['title']}');
                  return AppNotification.fromJson(data);
                } catch (e, stackTrace) {
                  print('❌ Error parsing notification ${doc.id}: $e');
                  print('❌ Data: ${doc.data()}');
                  print('❌ Stack trace: $stackTrace');
                  return null;
                }
              })
              .whereType<AppNotification>()
              .toList();

          print('✅ Successfully parsed ${notifications.length} notifications');
          return notifications;
        });
  }

  /// Listen to unread notifications count
  static Stream<int> listenToUnreadNotificationCount(int userId) {
    final firestore = _firestoreOrNull();
    if (firestore == null) {
      return Stream<int>.value(0);
    }

    return firestore
        .collection('users')
        .doc(userId.toString())
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ============================================
  // WRITE OPERATIONS (Optional - if needed on client side)
  // ============================================

  /// Mark notification as read (client-side update)
  /// Note: Backend should handle this, but can be done client-side for immediate UI feedback
  static Future<void> markNotificationAsRead(
    int userId,
    int notificationId,
  ) async {
    final firestore = _firestoreOrNull();
    if (firestore == null) {
      print('Firestore unavailable, cannot mark notification as read.');
      return;
    }

    try {
      await firestore
          .collection('users')
          .doc(userId.toString())
          .collection('notifications')
          .doc(notificationId.toString())
          .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});
      print('✅ Marked notification $notificationId as read');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // ============================================
  // UTILITY METHODS
  // ============================================

  /// Get a single auction (one-time read, not real-time)
  static Future<Auction?> getAuction(int auctionId) async {
    final firestore = _firestoreOrNull();
    if (firestore == null) {
      return null;
    }

    try {
      final doc = await firestore
          .collection('auctions')
          .doc(auctionId.toString())
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return Auction.fromJson(doc.data()!);
    } catch (e) {
      print('Error fetching auction: $e');
      return null;
    }
  }

  /// Check if Firestore is available
  static Future<bool> isAvailable() async {
    final firestore = _firestoreOrNull();
    if (firestore == null) {
      return false;
    }

    try {
      await firestore.collection('_test').limit(1).get();
      return true;
    } catch (e) {
      print('Firestore is not available: $e');
      return false;
    }
  }
}
