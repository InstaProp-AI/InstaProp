import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/analytics_service.dart';
import '../models/gold_price.dart';

class MarketAnalysisPage extends StatefulWidget {
  const MarketAnalysisPage({super.key});

  @override
  State<MarketAnalysisPage> createState() => _MarketAnalysisPageState();
}

class _MarketAnalysisPageState extends State<MarketAnalysisPage> {
  MarketOverviewResponse? _marketOverview;
  List<PriceTrendResponse>? _priceTrends;
  GoldComparisonResponse? _goldComparison;
  List<DeveloperRankingResponse>? _developerRankings;
  List<BestInvestmentResponse>? _bestInvestments;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMarketData();
  }

  Future<void> _loadMarketData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        AnalyticsService.getMarketOverview(),
        AnalyticsService.getPriceTrends(months: 12),
        AnalyticsService.getGoldComparison(months: 12),
        AnalyticsService.getDeveloperRankings(),
        AnalyticsService.getBestInvestments(limit: 5),
      ]);

      setState(() {
        _marketOverview = results[0] as MarketOverviewResponse?;
        _priceTrends = results[1] as List<PriceTrendResponse>?;
        _goldComparison = results[2] as GoldComparisonResponse?;
        _developerRankings = results[3] as List<DeveloperRankingResponse>?;
        _bestInvestments = results[4] as List<BestInvestmentResponse>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Analysis'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMarketData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMarketData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Market Overview
                    _buildMarketOverview(),
                    const SizedBox(height: 24),

                    // Price Trends Chart
                    _buildPriceTrendsChart(),
                    const SizedBox(height: 24),

                    // Gold vs Property Comparison
                    _buildGoldComparison(),
                    const SizedBox(height: 24),

                    // Developer Rankings
                    _buildDeveloperRankings(),
                    const SizedBox(height: 24),

                    // Best Investment Opportunities
                    _buildBestInvestments(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMarketOverview() {
    if (_marketOverview == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Market Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Properties',
                    _marketOverview!.totalProperties.toString(),
                    Icons.home,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Active Auctions',
                    _marketOverview!.activeAuctions.toString(),
                    Icons.gavel,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Developers',
                    _marketOverview!.totalDevelopers.toString(),
                    Icons.business,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Avg Price',
                    '${(_marketOverview!.areaPrices.isNotEmpty ? _marketOverview!.areaPrices.first.averagePrice : 0).toStringAsFixed(0)} EGP',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTrendsChart() {
    if (_priceTrends == null || _priceTrends!.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No price trend data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Trends (12 Months)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${(value / 1000).toInt()}K');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _priceTrends!.length) {
                            return Text(
                              '${_priceTrends![value.toInt()].date.month}/${_priceTrends![value.toInt()].date.year}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _priceTrends!.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.price);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldComparison() {
    if (_goldComparison == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Property vs Gold Investment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildComparisonCard(
                    'Property ROI',
                    '${_goldComparison!.propertyReturnPercentage.toStringAsFixed(1)}%',
                    Icons.home,
                    _goldComparison!.propertyReturnPercentage > 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildComparisonCard(
                    'Gold ROI',
                    '${_goldComparison!.goldReturnPercentage.toStringAsFixed(1)}%',
                    Icons.monetization_on,
                    _goldComparison!.goldReturnPercentage > 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _goldComparison!.betterInvestment == 'Property'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _goldComparison!.betterInvestment == 'Property'
                      ? Colors.green
                      : Colors.blue,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _goldComparison!.betterInvestment == 'Property'
                        ? Icons.trending_up
                        : Icons.monetization_on,
                    color: _goldComparison!.betterInvestment == 'Property'
                        ? Colors.green
                        : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_goldComparison!.betterInvestment} is performing better',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _goldComparison!.betterInvestment == 'Property'
                          ? Colors.green
                          : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperRankings() {
    if (_developerRankings == null || _developerRankings!.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Developers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._developerRankings!
                .take(5)
                .map(
                  (developer) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.business, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                developer.developerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${developer.projectCount} projects • ${developer.totalProperties} properties',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${developer.averageRating.toStringAsFixed(1)}★',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            Text(
                              '${developer.averagePropertyPrice.toStringAsFixed(0)} EGP',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestInvestments() {
    if (_bestInvestments == null || _bestInvestments!.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Best Investment Opportunities',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._bestInvestments!.map(
              (investment) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        investment.propertyName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${investment.location} • ${investment.propertyType}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${investment.bedrooms} bed • ${investment.bathrooms} bath • ${investment.squareFeet} sqft',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            '${investment.currentPrice.toStringAsFixed(0)} EGP',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
