class Faq {
  final String faqId;
  final String question;
  final String answer;
  final int displayOrder;

  Faq({
    required this.faqId,
    required this.question,
    required this.answer,
    required this.displayOrder,
  });

  factory Faq.fromJson(Map<String, dynamic> json) {
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return Faq(
      faqId: parseId(json['faqId']),
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      displayOrder: json['displayOrder'] ?? 0,
    );
  }
}
