class Poll {
  final int pollId;
  final String question;
  final List<PollOption> options;
  final int totalVotes;
  final DateTime? endsAt;
  final bool hasVoted;
  final List<int>? userVoteOptionIndexes;
  final bool isMultipleChoice;
  final bool allowChangeVote;
  final bool showResultsBeforeVote;
  final String? imageUrl;

  Poll({
    required this.pollId,
    required this.question,
    required this.options,
    this.totalVotes = 0,
    this.endsAt,
    this.hasVoted = false,
    this.userVoteOptionIndexes,
    this.isMultipleChoice = false,
    this.allowChangeVote = true,
    this.showResultsBeforeVote = true,
    this.imageUrl,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      pollId: json['pollId'] ?? 0,
      question: json['question'] ?? '',
      options:
          (json['options'] as List<dynamic>?)
              ?.map((o) => PollOption.fromJson(o))
              .toList() ??
          [],
      totalVotes: json['totalVotes'] ?? 0,
      endsAt: json['endsAt'] != null ? DateTime.parse(json['endsAt']) : null,
      hasVoted: (json['userSelections'] != null) && ((json['userSelections'] as List).isNotEmpty),
      userVoteOptionIndexes: (json['userSelections'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
      isMultipleChoice: json['isMultipleChoice'] ?? false,
      allowChangeVote: json['allowChangeVote'] ?? true,
      showResultsBeforeVote: json['showResultsBeforeVote'] ?? true,
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pollId': pollId,
      'question': question,
      'options': options.map((o) => o.toJson()).toList(),
      'totalVotes': totalVotes,
      'endsAt': endsAt?.toIso8601String(),
      'hasVoted': hasVoted,
      'userSelections': userVoteOptionIndexes,
      'isMultipleChoice': isMultipleChoice,
      'allowChangeVote': allowChangeVote,
      'showResultsBeforeVote': showResultsBeforeVote,
      'imageUrl': imageUrl,
    };
  }

  bool get isExpired {
    if (endsAt == null) return false;
    return DateTime.now().isAfter(endsAt!);
  }
}

class PollOption {
  final String text;
  final int voteCount;
  final double percentage;

  PollOption({required this.text, this.voteCount = 0, this.percentage = 0.0});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      text: json['text'] ?? json['optionText'] ?? '',
      voteCount: json['voteCount'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'voteCount': voteCount, 'percentage': percentage};
  }
}

