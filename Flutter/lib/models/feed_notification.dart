enum FeedNotificationType {
  outbid,
  auctionEnding,
  auctionRequest,
  bidPlaced,
  auctionWon,
  auctionApproved,
  propertyInspection,
  paymentDue,
  newEvent,
  achievement,
  newFollower,
  auctionStarted,
  priceDrop,
  milestone,
  aiSuggestion,
  referral,
}

class FeedNotification {
  final FeedNotificationType type;
  final String title;
  final String message;
  final String? actionText;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  FeedNotification({
    required this.type,
    required this.title,
    required this.message,
    this.actionText,
    required this.createdAt,
    this.metadata,
  });

  String get id => '${type.name}_${createdAt.millisecondsSinceEpoch}';
}
