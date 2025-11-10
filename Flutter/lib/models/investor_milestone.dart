class InvestorMilestone {
  final int achievementId;
  final int accountId;
  final String investorName;
  final String title;
  final String? description;
  final DateTime earnedAt;
  final int pointsAwarded;
  final int portfolioCount;
  final double totalBuyInValue;
  final int reputationPoints;
  final String initials;

  InvestorMilestone({
    required this.achievementId,
    required this.accountId,
    required this.investorName,
    required this.title,
    required this.description,
    required this.earnedAt,
    required this.pointsAwarded,
    required this.portfolioCount,
    required this.totalBuyInValue,
    required this.reputationPoints,
    required this.initials,
  });

  factory InvestorMilestone.fromJson(Map<String, dynamic> json) {
    return InvestorMilestone(
      achievementId: (json['achievementId'] ?? 0) as int,
      accountId: (json['accountId'] ?? 0) as int,
      investorName: (json['investorName'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      earnedAt: DateTime.parse(
        json['earnedAt'] ?? DateTime.now().toIso8601String(),
      ),
      pointsAwarded: (json['pointsAwarded'] ?? 0) as int,
      portfolioCount: (json['portfolioCount'] ?? 0) as int,
      totalBuyInValue: (json['totalBuyInValue'] ?? 0).toDouble(),
      reputationPoints: (json['reputationPoints'] ?? 0) as int,
      initials: (json['initials'] ?? '') as String,
    );
  }
}

