import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/property_financials_service.dart';

class PortfolioAnalyticsPage extends StatelessWidget {
  final PortfolioSummary summary;
  final List<PropertyFinancials> propertiesFinancials;

  const PortfolioAnalyticsPage({
    super.key,
    required this.summary,
    required this.propertiesFinancials,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Portfolio Analytics',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portfolio Overview
            _buildSectionTitle('Portfolio Overview'),
            const SizedBox(height: 20),
            _buildMetricsGrid(),

            const SizedBox(height: 48),

            // Own vs Owe Chart
            _buildSectionTitle('Asset Distribution'),
            const SizedBox(height: 20),
            _buildOwnVsOwePieChart(),

            const SizedBox(height: 48),

            // ROI Distribution
            if (propertiesFinancials.any((f) => f.roiPercent != null)) ...[
              _buildSectionTitle('ROI Distribution'),
              const SizedBox(height: 20),
              _buildROIChart(),
              const SizedBox(height: 48),
            ],

            // Property Breakdown
            _buildSectionTitle('Property Breakdown'),
            const SizedBox(height: 20),
            _buildPropertyBreakdown(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
        letterSpacing: -0.7,
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Net Value',
          '\$${_formatNumber(summary.totalNetValue)}',
          Colors.green,
          Icons.account_balance_wallet,
        ),
        _buildMetricCard(
          'Total Assets',
          '\$${_formatNumber(summary.totalAssets)}',
          Colors.blue,
          Icons.home_work,
        ),
        _buildMetricCard(
          'Total Owed',
          '\$${_formatNumber(summary.totalOwed)}',
          Colors.orange,
          Icons.credit_card,
        ),
        _buildMetricCard(
          'Avg ROI',
          '${summary.averageROI.toStringAsFixed(1)}%',
          summary.averageROI >= 0 ? Colors.green : Colors.red,
          Icons.trending_up,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnVsOwePieChart() {
    final owned = summary.totalEquity;
    final owed = summary.totalOwed;

    if (owned == 0 && owed == 0) {
      return _buildEmptyChart('No financial data available');
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: owned,
                    title: '${summary.ownedPercent.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: owed,
                    title: '${summary.owedPercent.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                'Owned',
                Colors.green,
                '\$${_formatNumber(owned)}',
              ),
              const SizedBox(width: 24),
              _buildLegendItem(
                'Owed',
                Colors.orange,
                '\$${_formatNumber(owed)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildROIChart() {
    final roiData = propertiesFinancials
        .where((f) => f.roiPercent != null)
        .toList();

    if (roiData.isEmpty) {
      return _buildEmptyChart('No ROI data available');
    }

    // Calculate chart dimensions based on number of properties
    final isScrollable = roiData.length > 5;
    final chartWidth = isScrollable ? roiData.length * 80.0 : 300.0;
    final chartHeight = 280.0;

    final maxROI = roiData
        .map((f) => f.roiPercent!)
        .reduce((a, b) => a > b ? a : b);
    final minROI = roiData
        .map((f) => f.roiPercent!)
        .reduce((a, b) => a < b ? a : b);
    final chartMaxY = maxROI + 5;
    final chartMinY = minROI - 5;

    Widget chartWidget = Container(
      height: chartHeight,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: chartMaxY,
          minY: chartMinY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final property = roiData[groupIndex];
                final name = property.propertyName?.isNotEmpty == true
                    ? property.propertyName!
                    : 'Property ${property.propertyId}';
                return BarTooltipItem(
                  '$name\nROI: ${rod.toY.toStringAsFixed(1)}%',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < roiData.length) {
                    final property = roiData[value.toInt()];
                    final name = property.propertyName?.isNotEmpty == true
                        ? property.propertyName!
                        : 'Property ${value.toInt() + 1}';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        name.length > 12 ? '${name.substring(0, 12)}...' : name,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey[300], strokeWidth: 1);
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: roiData
              .asMap()
              .entries
              .map(
                (entry) => BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.roiPercent!,
                      color: entry.value.roiPercent! >= 0
                          ? Colors.green
                          : Colors.red,
                      width: isScrollable ? 30 : 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );

    // Add ROI value labels on top of bars
    chartWidget = Stack(
      children: [
        chartWidget,
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Container(
            height: chartHeight - 40,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMaxY,
                minY: chartMinY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: roiData
                    .asMap()
                    .entries
                    .map(
                      (entry) => BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: 0,
                            color: Colors.transparent,
                            width: isScrollable ? 30 : 20,
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        // ROI value labels
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Container(
            height: chartHeight - 40,
            child: CustomPaint(
              painter: ROILabelPainter(
                roiData: roiData,
                isScrollable: isScrollable,
                chartMaxY: chartMaxY,
                chartMinY: chartMinY,
              ),
            ),
          ),
        ),
      ],
    );

    // Add min/max ROI labels
    final minMaxWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Min ROI: ${minROI.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Max ROI: ${maxROI.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (isScrollable) {
      return Column(
        children: [
          minMaxWidget,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: chartWidth, child: chartWidget),
          ),
        ],
      );
    } else {
      return Column(children: [minMaxWidget, chartWidget]);
    }
  }

  Widget _buildPropertyBreakdown() {
    if (propertiesFinancials.isEmpty) {
      return _buildEmptyChart('No properties to display');
    }

    return Column(
      children: propertiesFinancials.map((f) {
        final equity = f.equity;
        final roi = f.roiPercent ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                f.propertyName?.isNotEmpty == true
                    ? f.propertyName!
                    : 'Property #${f.propertyId}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPropertyStat(
                      'Contracted Price',
                      '\$${_formatNumber(f.contractedPrice ?? 0)}',
                    ),
                  ),
                  Expanded(
                    child: _buildPropertyStat(
                      'Market Value',
                      '\$${_formatNumber(f.marketValue ?? 0)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPropertyStat(
                      'Equity',
                      '\$${_formatNumber(equity)}',
                    ),
                  ),
                  Expanded(
                    child: _buildPropertyStat(
                      'Remaining',
                      '\$${_formatNumber(f.remainingToPay)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPropertyStat(
                      'ROI',
                      '${roi.toStringAsFixed(1)}%',
                      color: roi >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const Expanded(
                    child: SizedBox(),
                  ), // Empty space for alignment
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPropertyStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color ?? const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }
}

class ROILabelPainter extends CustomPainter {
  final List<PropertyFinancials> roiData;
  final bool isScrollable;
  final double chartMaxY;
  final double chartMinY;

  ROILabelPainter({
    required this.roiData,
    required this.isScrollable,
    required this.chartMaxY,
    required this.chartMinY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final barWidth = isScrollable ? 30.0 : 20.0;
    final spacing = size.width / roiData.length;

    for (int i = 0; i < roiData.length; i++) {
      final roi = roiData[i].roiPercent!;
      final x = (i * spacing) + (spacing / 2) - (barWidth / 2);

      // Calculate Y position based on ROI value
      final normalizedY = (roi - chartMinY) / (chartMaxY - chartMinY);
      final y = size.height - (normalizedY * size.height) - 20;

      // Create text
      final text = TextSpan(
        text: '${roi.toStringAsFixed(1)}%',
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );

      textPainter.text = text;
      textPainter.layout();

      // Draw text centered above the bar
      textPainter.paint(
        canvas,
        Offset(x + (barWidth / 2) - (textPainter.width / 2), y - 15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
