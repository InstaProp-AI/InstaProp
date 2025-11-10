class PaymentReminder {
  final int eventId;
  final int? propertyId;
  final String? propertyName;
  final double? amount;
  final DateTime eventDate;
  final int daysUntilDue;
  final bool isReminderSet;

  PaymentReminder({
    required this.eventId,
    this.propertyId,
    this.propertyName,
    this.amount,
    required this.eventDate,
    required this.daysUntilDue,
    required this.isReminderSet,
  });

  factory PaymentReminder.fromJson(Map<String, dynamic> json) {
    return PaymentReminder(
      eventId: json['eventId'] ?? 0,
      propertyId: json['propertyId'],
      propertyName: json['propertyName'],
      amount: json['amount'] != null
          ? (json['amount'] as num).toDouble()
          : null,
      eventDate: DateTime.parse(
        json['eventDate'] ?? DateTime.now().toIso8601String(),
      ),
      daysUntilDue: json['daysUntilDue'] ?? 0,
      isReminderSet: json['isReminderSet'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'amount': amount,
      'eventDate': eventDate.toIso8601String(),
      'daysUntilDue': daysUntilDue,
      'isReminderSet': isReminderSet,
    };
  }
}

