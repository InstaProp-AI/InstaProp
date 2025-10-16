/// Firebase configuration
class FirebaseConfig {
  // Firestore Collections
  static const String auctionsCollection = 'auctions';
  static const String bidsCollection = 'bids';
  static const String notificationsCollection = 'notifications';
  static const String chatsCollection = 'chats';
  static const String chatMessagesCollection = 'messages';
  static const String usersCollection = 'users';

  // FCM Topics
  static const String allUsersTopic = 'all_users';
  static const String newAuctionsTopic = 'new_auctions';
  static const String auctionUpdatesTopic = 'auction_updates';

  // FCM Message Types
  static const String newAuctionType = 'new_auction';
  static const String newBidType = 'new_bid';
  static const String auctionEndedType = 'auction_ended';
  static const String outbidType = 'outbid';
  static const String chatMessageType = 'chat_message';

  // Real-time Update Settings
  static const Duration firestoreTimeout = Duration(seconds: 10);
  static const bool enableOfflinePersistence = true;

  FirebaseConfig._(); // Prevent instantiation
}

