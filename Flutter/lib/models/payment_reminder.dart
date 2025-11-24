class PaymentReminder {
  final String eventId;
  final String? propertyId;
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
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    String? parseOptionalId(dynamic id) {
      if (id == null) return null;
      if (id is String) return id.isEmpty ? null : id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return PaymentReminder(
      eventId: parseId(json['eventId']),
      propertyId: parseOptionalId(json['propertyId']),
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

