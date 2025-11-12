class Faq {
  final int faqId;
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
    return Faq(
      faqId: json['faqId'] ?? 0,
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      displayOrder: json['displayOrder'] ?? 0,
    );
  }
}
