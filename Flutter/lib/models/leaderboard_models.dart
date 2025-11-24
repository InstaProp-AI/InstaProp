import 'dart:convert';

enum LeaderboardPeriod { thisWeek, lastWeek, allTime }

extension LeaderboardPeriodX on LeaderboardPeriod {
  String get apiValue {
    switch (this) {
      case LeaderboardPeriod.thisWeek:
        return 'thisWeek';
      case LeaderboardPeriod.lastWeek:
        return 'lastWeek';
      case LeaderboardPeriod.allTime:
        return 'allTime';
    }
  }

  static LeaderboardPeriod fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'lastweek':
      case 'previous':
        return LeaderboardPeriod.lastWeek;
      case 'alltime':
      case 'lifetime':
        return LeaderboardPeriod.allTime;
      case 'thisweek':
      case 'weekly':
      default:
        return LeaderboardPeriod.thisWeek;
    }
  }
}

class LeaderboardActivitySlice {
  final String category;
  final int count;
  final int points;

  const LeaderboardActivitySlice({
    required this.category,
    required this.count,
    required this.points,
  });

  factory LeaderboardActivitySlice.fromJson(Map<String, dynamic> json) {
    return LeaderboardActivitySlice(
      category: json['category'] ?? 'Activity',
      count: json['count'] ?? 0,
      points: json['points'] ?? 0,
    );
  }
}

class LeaderboardEntry {
  final String accountId;
  final String displayName;
  final String? avatarInitials;
  final int rank;
  final int points;
  final int totalRewards;
  final double cashbackAwarded;
  final double potentialCashback;
  final double? engagementScore;
  final int streakWeeks;
  final String? rewardSummary;
  final bool isRequester;
  final DateTime? lastRewardAt;
  final int? pointsToNextRank;
  final List<LeaderboardActivitySlice> activity;
  final Map<String, int> rewardTypeCounts;

  const LeaderboardEntry({
    required this.accountId,
    required this.displayName,
    required this.avatarInitials,
    required this.rank,
    required this.points,
    required this.totalRewards,
    required this.cashbackAwarded,
    required this.potentialCashback,
    required this.engagementScore,
    required this.streakWeeks,
    required this.rewardSummary,
    required this.isRequester,
    required this.lastRewardAt,
    required this.pointsToNextRank,
    required this.activity,
    required this.rewardTypeCounts,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    final activityJson = json['activity'] as List<dynamic>? ?? [];
    final rewardTypeJson = json['rewardTypeCounts'] as Map<String, dynamic>? ?? {};

    return LeaderboardEntry(
      accountId: parseId(json['accountId']),
      displayName: json['displayName'] ?? 'Player',
      avatarInitials: json['avatarInitials'],
      rank: json['rank'] ?? 0,
      points: json['points'] ?? 0,
      totalRewards: json['totalRewards'] ?? 0,
      cashbackAwarded: (json['cashbackAwarded'] ?? 0).toDouble(),
      potentialCashback: (json['potentialCashback'] ?? 0).toDouble(),
      engagementScore: json['engagementScore'] != null
          ? (json['engagementScore'] as num).toDouble()
          : null,
      streakWeeks: json['streakWeeks'] ?? 0,
      rewardSummary: json['rewardSummary'],
      isRequester: json['isRequester'] ?? false,
      lastRewardAt: json['lastRewardAt'] != null
          ? DateTime.tryParse(json['lastRewardAt'])
          : null,
      pointsToNextRank: json['pointsToNextRank'],
      activity: activityJson
          .map((item) => LeaderboardActivitySlice.fromJson(
              item is Map<String, dynamic> ? item : jsonDecode(jsonEncode(item))))
          .toList(),
      rewardTypeCounts: rewardTypeJson.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
    );
  }
}

class LeaderboardResponse {
  final LeaderboardPeriod period;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final String headline;
  final String subheading;
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? personalEntry;
  final List<String> momentumTips;

  const LeaderboardResponse({
    required this.period,
    required this.rangeStart,
    required this.rangeEnd,
    required this.headline,
    required this.subheading,
    required this.entries,
    required this.personalEntry,
    required this.momentumTips,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final entriesJson = json['entries'] as List<dynamic>? ?? [];
    final tipsJson = json['momentumTips'] as List<dynamic>? ?? [];

    return LeaderboardResponse(
      period: LeaderboardPeriodX.fromString(json['period']?.toString()),
      rangeStart: DateTime.tryParse(json['rangeStart'] ?? '') ?? DateTime.now(),
      rangeEnd: DateTime.tryParse(json['rangeEnd'] ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
      headline: json['headline'] ?? 'Leaderboard momentum',
      subheading: json['subheading'] ?? '',
      entries: entriesJson
          .map((item) => LeaderboardEntry.fromJson(
              item is Map<String, dynamic> ? item : jsonDecode(jsonEncode(item))))
          .toList(),
      personalEntry: json['personalEntry'] != null
          ? LeaderboardEntry.fromJson(
              json['personalEntry'] is Map<String, dynamic>
                  ? json['personalEntry']
                  : jsonDecode(jsonEncode(json['personalEntry'])),
            )
          : null,
      momentumTips: tipsJson.map((tip) => tip.toString()).toList(),
    );
  }
}

class LeaderboardHighlight {
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final String? headline;
  final String? summary;
  final LeaderboardEntry? first;
  final LeaderboardEntry? second;
  final LeaderboardEntry? third;

  const LeaderboardHighlight({
    required this.rangeStart,
    required this.rangeEnd,
    this.headline,
    this.summary,
    this.first,
    this.second,
    this.third,
  });

  factory LeaderboardHighlight.fromJson(Map<String, dynamic> json) {
    return LeaderboardHighlight(
      rangeStart: DateTime.tryParse(json['rangeStart'] ?? '') ?? DateTime.now(),
      rangeEnd:
          DateTime.tryParse(json['rangeEnd'] ?? '') ?? DateTime.now(),
      headline: json['headline'],
      summary: json['summary'],
      first: json['first'] != null
          ? LeaderboardEntry.fromJson(
              json['first'] is Map<String, dynamic>
                  ? json['first']
                  : jsonDecode(jsonEncode(json['first'])),
            )
          : null,
      second: json['second'] != null
          ? LeaderboardEntry.fromJson(
              json['second'] is Map<String, dynamic>
                  ? json['second']
                  : jsonDecode(jsonEncode(json['second'])),
            )
          : null,
      third: json['third'] != null
          ? LeaderboardEntry.fromJson(
              json['third'] is Map<String, dynamic>
                  ? json['third']
                  : jsonDecode(jsonEncode(json['third'])),
            )
          : null,
    );
  }
}

class LeaderboardHighlightsResponse {
  final LeaderboardHighlight? lastWeek;
  final LeaderboardHighlight? thisWeek;
  final LeaderboardEntry? personalThisWeek;
  final List<String> actionPrompts;

  const LeaderboardHighlightsResponse({
    this.lastWeek,
    this.thisWeek,
    this.personalThisWeek,
    required this.actionPrompts,
  });

  factory LeaderboardHighlightsResponse.fromJson(Map<String, dynamic> json) {
    final prompts = json['actionablePrompts'] as List<dynamic>? ?? [];

    return LeaderboardHighlightsResponse(
      lastWeek: json['lastWeek'] != null
          ? LeaderboardHighlight.fromJson(
              json['lastWeek'] is Map<String, dynamic>
                  ? json['lastWeek']
                  : jsonDecode(jsonEncode(json['lastWeek'])),
            )
          : null,
      thisWeek: json['thisWeek'] != null
          ? LeaderboardHighlight.fromJson(
              json['thisWeek'] is Map<String, dynamic>
                  ? json['thisWeek']
                  : jsonDecode(jsonEncode(json['thisWeek'])),
            )
          : null,
      personalThisWeek: json['personalThisWeek'] != null
          ? LeaderboardEntry.fromJson(
              json['personalThisWeek'] is Map<String, dynamic>
                  ? json['personalThisWeek']
                  : jsonDecode(jsonEncode(json['personalThisWeek'])),
            )
          : null,
      actionPrompts: prompts.map((p) => p.toString()).toList(),
    );
  }
}


