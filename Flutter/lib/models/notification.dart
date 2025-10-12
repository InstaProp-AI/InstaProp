class AppNotification {
  final int notificationId;
  final int userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final int? auctionId;
  final int? bidId;
  final int? propertyId;
  final int? eventId;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.auctionId,
    this.bidId,
    this.propertyId,
    this.eventId,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      notificationId: json['notificationId'] ?? json['NotificationId'] ?? 0,
      userId: json['userId'] ?? json['UserId'] ?? 0,
      title: json['title'] ?? json['Title'] ?? '',
      message: json['message'] ?? json['Message'] ?? '',
      type: NotificationType.fromInt(json['type'] ?? json['Type'] ?? 0),
      isRead: json['isRead'] ?? json['IsRead'] ?? false,
      auctionId: json['auctionId'] ?? json['AuctionId'],
      bidId: json['bidId'] ?? json['BidId'],
      propertyId: json['propertyId'] ?? json['PropertyId'],
      eventId: json['eventId'] ?? json['EventId'],
      createdAt: DateTime.parse(
        json['createdAt'] ??
            json['CreatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
      readAt: json['readAt'] != null || json['ReadAt'] != null
          ? DateTime.parse(json['readAt'] ?? json['ReadAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.value,
      'isRead': isRead,
      'auctionId': auctionId,
      'bidId': bidId,
      'propertyId': propertyId,
      'eventId': eventId,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() > 1 ? 's' : ''} ago';
    }
  }
}

enum NotificationType {
  bidPlaced(0),
  outbid(1),
  auctionStarted(2),
  auctionEnding(3),
  auctionWon(4),
  auctionLost(5),
  eventReminder(6),
  publicEvent(7),
  auctionApproved(8),
  auctionRejected(9),
  general(10);

  final int value;
  const NotificationType(this.value);

  static NotificationType fromInt(int value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.general,
    );
  }

  String get displayName {
    switch (this) {
      case NotificationType.bidPlaced:
        return 'Bid Placed';
      case NotificationType.outbid:
        return 'Outbid';
      case NotificationType.auctionStarted:
        return 'Auction Started';
      case NotificationType.auctionEnding:
        return 'Auction Ending';
      case NotificationType.auctionWon:
        return 'Auction Won';
      case NotificationType.auctionLost:
        return 'Auction Lost';
      case NotificationType.eventReminder:
        return 'Event Reminder';
      case NotificationType.publicEvent:
        return 'Public Event';
      case NotificationType.auctionApproved:
        return 'Auction Approved';
      case NotificationType.auctionRejected:
        return 'Auction Rejected';
      case NotificationType.general:
        return 'Notification';
    }
  }
}
