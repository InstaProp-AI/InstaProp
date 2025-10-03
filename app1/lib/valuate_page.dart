import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'add_property_page.dart' show AddPropertyPage;
import 'main.dart';
import 'i18n.dart';

class OwnedProperty {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final double purchasePrice;
  final String address;
  final DateTime createdAt;

  OwnedProperty({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.purchasePrice,
    required this.address,
    required this.createdAt,
  });
}

class ValuatePage extends StatefulWidget {
  const ValuatePage({super.key});

  @override
  State<ValuatePage> createState() => _ValuatePageState();
}

class _ValuatePageState extends State<ValuatePage> {
  final List<OwnedProperty> _owned = [];
  OwnedProperty? _selected;

  @override
  void initState() {
    super.initState();
    _seedDemoOwned();
  }

  void _seedDemoOwned() {
    _owned.addAll([
      OwnedProperty(
        id: 'op1',
        name: 'My Villa',
        category: 'Villa',
        imageUrl:
            'https://images.unsplash.com/photo-1507089947368-19c1da9775ae?auto=format&fit=crop&w=900&q=80',
        purchasePrice: 520000,
        address: 'Palm Hills, 6th October',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      OwnedProperty(
        id: 'op2',
        name: 'City Apartment',
        category: 'Apartment',
        imageUrl:
            'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?auto=format&fit=crop&w=900&q=80',
        purchasePrice: 210000,
        address: 'Downtown, Cairo',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ]);
    _selected = _owned.first;
  }

  Future<void> _addProperty() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPropertyPage()),
    );
    if (result is Map<String, dynamic>) {
      final op = OwnedProperty(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result['name'] ?? 'New Property',
        category: result['category'] ?? 'House',
        imageUrl:
            result['imageUrl'] ??
            'https://images.unsplash.com/photo-1464983953574-0892a716854b?auto=format&fit=crop&w=900&q=80',
        purchasePrice: (result['startPrice'] as num?)?.toDouble() ?? 0,
        address: result['address'] ?? '-',
        createdAt:
            DateTime.tryParse(result['createdAt'] ?? '') ?? DateTime.now(),
      );
      setState(() {
        _owned.insert(0, op);
        _selected = op;
      });
    }
  }

  double _estimateMarketPrice(OwnedProperty property) {
    // Simple mocked model: add 5-25% depending on category + trend factor
    final base = property.purchasePrice;
    double categoryBoost;
    switch (property.category) {
      case 'Villa':
        categoryBoost = 0.18;
        break;
      case 'Apartment':
        categoryBoost = 0.12;
        break;
      case 'Condo':
        categoryBoost = 0.1;
        break;
      default:
        categoryBoost = 0.08;
    }
    final monthsHeld =
        DateTime.now().difference(property.createdAt).inDays / 30.0;
    final trend = (monthsHeld.clamp(0, 24) as double) * 0.003; // up to ~7.2%
    return base * (1 + categoryBoost + trend);
  }

  List<FlSpot> _generateTrendSeries(OwnedProperty property) {
    final List<FlSpot> points = [];
    final months = 12;
    final base = property.purchasePrice;
    for (int i = 0; i <= months; i++) {
      final progression = (i / months);
      final categoryBump = property.category == 'Villa'
          ? 0.16
          : property.category == 'Apartment'
          ? 0.12
          : 0.09;
      final seasonality = (0.02 * (1 + (i % 6) / 6));
      final value = base * (1 + categoryBump * progression + seasonality);
      points.add(FlSpot(i.toDouble(), value));
    }
    return points;
  }

  // Helpers for richer breakdown (mocked logic for demo)
  double _assumedAreaSqm(OwnedProperty property) {
    switch (property.category) {
      case 'Villa':
        return 300;
      case 'Apartment':
        return 120;
      case 'Condo':
        return 100;
      default:
        return 160;
    }
  }

  List<double> _comparablePrices(OwnedProperty property, double estimated) {
    final base = estimated;
    return [base * 0.92, base * 0.97, base * 1.01, base * 1.06, base * 0.98];
  }

  String _rentalYieldLabel(OwnedProperty property) {
    switch (property.category) {
      case 'Villa':
        return '4.2% (mocked)';
      case 'Apartment':
        return '6.1% (mocked)';
      case 'Condo':
        return '5.3% (mocked)';
      default:
        return '5.0% (mocked)';
    }
  }

  Widget _ownedCard(OwnedProperty p, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _selected = p),
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: selected ? kPrimary.withOpacity(0.12) : kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kGray.withOpacity(0.6),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: selected ? Border.all(color: kPrimary, width: 2) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                p.imageUrl,
                height: 120,
                width: 240,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: TextStyle(color: kText, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: kAccent, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          p.address,
                          style: TextStyle(color: kText.withOpacity(0.7)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: kPrimary, size: 18),
                      Text(
                        p.purchasePrice.toStringAsFixed(0),
                        style: TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Strings.of(context);
    final OwnedProperty? property = _selected;
    final double? estimated = property != null
        ? _estimateMarketPrice(property)
        : null;
    final List<FlSpot> trend = property != null
        ? _generateTrendSeries(property)
        : [];

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Text(
          t.valuation,
          style: TextStyle(color: kText, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: kText),
        actions: [
          IconButton(
            onPressed: _addProperty,
            icon: const Icon(Icons.add_business),
            tooltip: 'Add Property',
            color: kPrimary,
          ),
        ],
      ),
      body: Directionality(
        textDirection: t.direction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.yourProperties,
                  style: TextStyle(
                    color: kText,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addProperty,
                  icon: const Icon(Icons.add),
                  label: Text(t.addNew),
                  style: TextButton.styleFrom(foregroundColor: kPrimary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _owned.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, idx) =>
                    _ownedCard(_owned[idx], _owned[idx].id == property?.id),
              ),
            ),
            const SizedBox(height: 20),
            if (property == null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kGray,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No property selected',
                      style: TextStyle(
                        color: kText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a property to start valuation.',
                      style: TextStyle(color: kText.withOpacity(0.7)),
                    ),
                  ],
                ),
              )
            else ...[
              // Valuation Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: kPrimary,
                    child: const Icon(Icons.home, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.name,
                          style: TextStyle(
                            color: kText,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          property.address,
                          style: TextStyle(color: kText.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      t.marketEstimate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // KPI Cards
              Row(
                children: [
                  Expanded(
                    child: _kpiCard(
                      title: t.purchasePrice,
                      value: 'EGP ${property.purchasePrice.toStringAsFixed(0)}',
                      icon: Icons.attach_money,
                      color: kAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _kpiCard(
                      title: t.estValue,
                      value: 'EGP ${estimated!.toStringAsFixed(0)}',
                      icon: Icons.trending_up,
                      color: kPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _kpiCard(
                      title: t.gain,
                      value:
                          '+${((estimated - property.purchasePrice) / property.purchasePrice * 100).toStringAsFixed(1)}%',
                      icon: Icons.percent,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Chart
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: LineChart(
                  LineChartData(
                    backgroundColor: kCard,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: kGray, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 52,
                          interval: (estimated / 4).roundToDouble(),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 2,
                          getTitlesWidget: (v, meta) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'M${v.toInt()}',
                              style: TextStyle(
                                color: kText.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                      rightTitles: AxisTitles(),
                      topTitles: AxisTitles(),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: kPrimary, width: 1.5),
                    ),
                    minX: 0,
                    maxX: 12,
                    minY: (property.purchasePrice * 0.8),
                    maxY: (estimated * 1.2),
                    lineBarsData: [
                      LineChartBarData(
                        spots: trend,
                        isCurved: true,
                        color: kPrimary,
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: kPrimary.withOpacity(0.15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Details
              Container(
                decoration: BoxDecoration(
                  color: kGray,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.valuationBreakdown,
                      style: TextStyle(
                        color: kText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _detailRow(t.categoryFactor, property.category),
                    _detailRow(
                      t.holdingPeriod,
                      '${DateTime.now().difference(property.createdAt).inDays ~/ 30} months',
                    ),
                    _detailRow(t.neighborhoodIndex, '0.92 (mocked)'),
                    _detailRow(t.demandScore, 'High (mocked)'),
                    _detailRow(t.comparablesUsed, '5 nearby listings (mocked)'),
                    _detailRow(
                      t.medianComparable,
                      'EGP ${(_comparablePrices(property, estimated).reduce((a, b) => a + b) / 5).toStringAsFixed(0)}',
                    ),
                    _detailRow(
                      t.pricePerSqm,
                      'EGP ${(estimated / _assumedAreaSqm(property)).toStringAsFixed(0)}',
                    ),
                    _detailRow(
                      t.assumedArea,
                      '${_assumedAreaSqm(property).toStringAsFixed(0)} sqm (mocked)',
                    ),
                    _detailRow(t.rentalYield, _rentalYieldLabel(property)),
                    _detailRow(t.confidence, '85% (mocked)'),
                    _detailRow(
                      t.suggestedRange,
                      'EGP ${(estimated * 0.95).toStringAsFixed(0)} - EGP ${(estimated * 1.05).toStringAsFixed(0)}',
                    ),
                    _detailRow(t.liquidityDom, '45 days on market (mocked)'),
                    _detailRow(t.riskScore, 'Low (mocked)'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // CTA
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.picture_as_pdf),
                        label: Text(t.exportReport),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.share),
                        label: Text(t.share),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kGray.withOpacity(0.6),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: kText.withOpacity(0.7), fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(color: kText, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: kText.withOpacity(0.75)),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: kText, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
