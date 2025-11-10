import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firebase_status.dart';
import '../models/chat_message.dart';

class ChatFirestoreService {
  FirebaseFirestore? _firestoreOrNull() {
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

  // Stream messages for a specific chat (real-time)
  Stream<List<ChatMessage>> streamChatMessages(int chatId) {
    final firestore = _firestoreOrNull();
    if (firestore == null) {
      return Stream<List<ChatMessage>>.value([]);
    }

    try {
      return firestore
          .collection('chats')
          .doc(chatId.toString())
          .collection('messages')
          .snapshots()
          .map((snapshot) {
            final messages = snapshot.docs.map((doc) {
              final data = doc.data();
              // Convert Firestore Timestamp to ISO string if needed
              final createdAt = data['createdAt'];
              if (createdAt != null && createdAt is Timestamp) {
                data['createdAt'] = createdAt.toDate().toIso8601String();
              }
              final expiresAt = data['expiresAt'];
              if (expiresAt != null && expiresAt is Timestamp) {
                data['expiresAt'] = expiresAt.toDate().toIso8601String();
              }
              return ChatMessage.fromFirestore(data);
            }).toList();
            // Sort client-side by createdAt ascending to avoid mixed-type index issues
            messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            return messages;
          });
    } catch (e) {
      print('Error streaming chat messages: $e');
      return Stream.value([]);
    }
  }

  // Get unread count for a specific chat
  Stream<int> streamUnreadCount(int chatId, int currentUserId) {
    final firestore = _firestoreOrNull();
    if (firestore == null) {
      return Stream<int>.value(0);
    }

    try {
      return firestore
          .collection('chats')
          .doc(chatId.toString())
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      print('Error streaming unread count: $e');
      return Stream.value(0);
    }
  }

  // Listen to chat updates (for chat list)
  Stream<Map<String, dynamic>?> streamChatUpdates(int chatId) {
    final firestore = _firestoreOrNull();
    if (firestore == null) {
      return Stream<Map<String, dynamic>?>.value(null);
    }

    try {
      return firestore
          .collection('chats')
          .doc(chatId.toString())
          .snapshots()
          .map((snapshot) {
            if (snapshot.exists) {
              return snapshot.data();
            }
            return null;
          });
    } catch (e) {
      print('Error streaming chat updates: $e');
      return Stream.value(null);
    }
  }

  // Subscribe to FCM topic for user-specific notifications
  Future<void> subscribeToUserTopic(int userId) async {
    // This would be implemented with FCM messaging
    // For now, just a placeholder
    print('Subscribed to user_$userId topic');
  }

  // Unsubscribe from FCM topic
  Future<void> unsubscribeFromUserTopic(int userId) async {
    // This would be implemented with FCM messaging
    // For now, just a placeholder
    print('Unsubscribed from user_$userId topic');
  }

  // Check if Firestore is available
  Future<bool> isAvailable() async {
    final firestore = _firestoreOrNull();
    if (firestore == null) {
      return false;
    }

    try {
      await firestore.collection('test').limit(1).get();
      return true;
    } catch (e) {
      print('Firestore not available: $e');
      return false;
    }
  }
}
