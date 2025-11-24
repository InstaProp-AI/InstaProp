class InstallmentSummary {
  final String summaryId;
  final String propertyId;
  final double contractedPrice;
  final double totalPaid;
  final double downPaymentPercent;
  final double downPaymentAmount;
  final int? termYears;
  final DateTime? installmentEndDate;
  final bool isFullyPaid;
  final double remainingBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  InstallmentSummary({
    required this.summaryId,
    required this.propertyId,
    required this.contractedPrice,
    required this.totalPaid,
    required this.downPaymentPercent,
    required this.downPaymentAmount,
    required this.termYears,
    required this.installmentEndDate,
    required this.isFullyPaid,
    required this.remainingBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InstallmentSummary.fromJson(Map<String, dynamic> json) {
    final contracted = (json['contractedPrice'] ?? 0).toDouble();
    final downPercent = (json['downPaymentPercent'] ?? 0).toDouble();
    final downAmount = json['downPaymentAmount'] != null
        ? (json['downPaymentAmount'] as num).toDouble()
        : contracted * (downPercent / 100);

    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return InstallmentSummary(
      summaryId: parseId(json['summaryId']),
      propertyId: parseId(json['propertyId']),
      contractedPrice: contracted,
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
      downPaymentPercent: downPercent,
      downPaymentAmount: downAmount,
      termYears: json['termYears'],
      installmentEndDate: json['installmentEndDate'] != null
          ? DateTime.parse(json['installmentEndDate'])
          : null,
      isFullyPaid: json['isFullyPaid'] ?? false,
      remainingBalance: (json['remainingBalance'] ?? 0).toDouble(),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summaryId': summaryId,
      'propertyId': propertyId,
      'contractedPrice': contractedPrice,
      'totalPaid': totalPaid,
      'downPaymentPercent': downPaymentPercent,
      'downPaymentAmount': downPaymentAmount,
      'termYears': termYears,
      'installmentEndDate': installmentEndDate?.toIso8601String(),
      'isFullyPaid': isFullyPaid,
      'remainingBalance': remainingBalance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class InstallmentSummaryPayload {
  final double? contractedPrice;
  final double? totalPaid;
  final double? downPaymentPercent;
  final int? termYears;
  final DateTime? installmentEndDate;
  final bool? isFullyPaid;

  const InstallmentSummaryPayload({
    this.contractedPrice,
    this.totalPaid,
    this.downPaymentPercent,
    this.termYears,
    this.installmentEndDate,
    this.isFullyPaid,
  });

  bool get hasRequiredData =>
      contractedPrice != null && contractedPrice! > 0;

  Map<String, dynamic> toJson() {
    return {
      'contractedPrice': contractedPrice,
      'totalPaid': totalPaid,
      'downPaymentPercent': downPaymentPercent,
      'termYears': termYears,
      'installmentEndDate': installmentEndDate?.toIso8601String(),
      'isFullyPaid': isFullyPaid,
    };
  }
}

