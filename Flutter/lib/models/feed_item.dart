enum FeedItemType {
  post,
  notification,
  community,
  news,
  auction,
  project,
  developer,
  member,
  dealHighlight,
  projectStory,
  investorMilestone,
  livestream,
  valuationPrompt,
  paymentReminder,
}

class FeedItem {
  final FeedItemType type;
  final dynamic data;
  final String id;

  FeedItem({required this.type, required this.data, required this.id});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}
