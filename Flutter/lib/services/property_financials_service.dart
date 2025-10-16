import 'api_client.dart';

class PropertyFinancialsService {
  static Future<ApiResponse<PropertyFinancials>> getFinancials(
    int propertyId, {
    double? marketValue,
  }) async {
    final query = marketValue != null ? '?marketValue=${marketValue}' : '';
    return await ApiClient.get(
      '/api/property/$propertyId/financials$query',
      PropertyFinancials.fromJson,
    );
  }
}

class PropertyFinancials {
  final int propertyId;
  final double sumInstallments;
  final double paidSoFar;
  final double remainingInstallments;
  final double remainingToPay;
  final double? buyingPrice;
  final double? marketValue;
  final double? roiPercent;

  PropertyFinancials({
    required this.propertyId,
    required this.sumInstallments,
    required this.paidSoFar,
    required this.remainingInstallments,
    required this.remainingToPay,
    this.buyingPrice,
    this.marketValue,
    this.roiPercent,
  });

  static PropertyFinancials fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return PropertyFinancials(
      propertyId: json['propertyId'] ?? json['PropertyId'] ?? 0,
      sumInstallments: toDouble(
        json['sumInstallments'] ?? json['SumInstallments'],
      ),
      paidSoFar: toDouble(json['paidSoFar'] ?? json['PaidSoFar']),
      remainingInstallments: toDouble(
        json['remainingInstallments'] ?? json['RemainingInstallments'],
      ),
      remainingToPay: toDouble(
        json['remainingToPay'] ?? json['RemainingToPay'],
      ),
      buyingPrice: json['buyingPrice'] != null
          ? toDouble(json['buyingPrice'])
          : null,
      marketValue: json['marketValue'] != null
          ? toDouble(json['marketValue'])
          : null,
      roiPercent: json['roiPercent'] != null
          ? toDouble(json['roiPercent'])
          : null,
    );
  }
}
