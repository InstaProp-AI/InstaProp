enum ReactionType {
  like,
  celebrate,
  insightful,
  helpful,
  love,
  thankYou;

  static ReactionType? fromString(String? value) {
    if (value == null) return null;
    return ReactionType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == value.toLowerCase(),
      orElse: () => ReactionType.like,
    );
  }

  String get displayName {
    switch (this) {
      case ReactionType.like:
        return 'Like';
      case ReactionType.celebrate:
        return 'Celebrate';
      case ReactionType.insightful:
        return 'Insightful';
      case ReactionType.helpful:
        return 'Helpful';
      case ReactionType.love:
        return 'Love';
      case ReactionType.thankYou:
        return 'Thank You';
    }
  }
}

