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

  // Get all properties' financials for portfolio aggregation
  static Future<List<PropertyFinancials>> getAllPropertiesFinancials(
    List<int> propertyIds,
  ) async {
    final financials = <PropertyFinancials>[];

    for (final id in propertyIds) {
      try {
        final response = await getFinancials(id);
        if (response.success && response.data != null) {
          financials.add(response.data!);
        }
      } catch (e) {
        print('Error fetching financials for property $id: $e');
      }
    }

    return financials;
  }

  // Calculate portfolio summary from individual financials
  static PortfolioSummary calculatePortfolioSummary(
    List<PropertyFinancials> financials,
  ) {
    if (financials.isEmpty) {
      return PortfolioSummary(
        totalNetValue: 0,
        totalAssets: 0,
        totalOwed: 0,
        totalEquity: 0,
        averageROI: 0,
        propertiesCount: 0,
      );
    }

    double totalAssets = 0;
    double totalOwed = 0;
    double totalEquity = 0;
    double totalROI = 0;
    int roiCount = 0;

    for (final f in financials) {
      totalAssets += f.marketValue ?? 0;
      totalOwed += f.remainingToPay;

      if (f.marketValue != null) {
        totalEquity += (f.marketValue! - f.remainingToPay);
      }

      if (f.roiPercent != null) {
        totalROI += f.roiPercent!;
        roiCount++;
      }
    }

    final averageROI = roiCount > 0 ? (totalROI / roiCount).toDouble() : 0.0;

    return PortfolioSummary(
      totalNetValue: totalEquity,
      totalAssets: totalAssets,
      totalOwed: totalOwed,
      totalEquity: totalEquity,
      averageROI: averageROI,
      propertiesCount: financials.length.toDouble(),
    );
  }
}

class PropertyFinancials {
  final int propertyId;
  final String? propertyName;
  final double sumInstallments;
  final double paidSoFar;
  final double remainingInstallments;
  final double remainingToPay;
  final double? buyingPrice;
  final double? contractedPrice;
  final double? marketValue;
  final double? roiPercent;

  PropertyFinancials({
    required this.propertyId,
    this.propertyName,
    required this.sumInstallments,
    required this.paidSoFar,
    required this.remainingInstallments,
    required this.remainingToPay,
    this.buyingPrice,
    this.contractedPrice,
    this.marketValue,
    this.roiPercent,
  });

  double get equity => (marketValue ?? 0) - remainingToPay;

  static PropertyFinancials fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return PropertyFinancials(
      propertyId: json['propertyId'] ?? json['PropertyId'] ?? 0,
      propertyName: json['propertyName'] ?? json['PropertyName'],
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
      contractedPrice: json['contractedPrice'] != null
          ? toDouble(json['contractedPrice'])
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

class PortfolioSummary {
  final double totalNetValue;
  final double totalAssets;
  final double totalOwed;
  final double totalEquity;
  final double averageROI;
  final double propertiesCount;

  PortfolioSummary({
    required this.totalNetValue,
    required this.totalAssets,
    required this.totalOwed,
    required this.totalEquity,
    required this.averageROI,
    required this.propertiesCount,
  });

  double get ownedPercent {
    if (totalAssets == 0) return 0;
    return (totalEquity / totalAssets) * 100;
  }

  double get owedPercent {
    if (totalAssets == 0) return 0;
    return (totalOwed / totalAssets) * 100;
  }
}
