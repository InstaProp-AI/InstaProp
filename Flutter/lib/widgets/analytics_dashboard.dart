import 'package:flutter/material.dart';
import 'analytics_charts.dart';
import '../services/analytics_service.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  MarketIndicators? _marketIndicators;
  GoldComparison? _goldComparison;
  TopProjects? _topProjects;
  InvestmentOpportunities? _investmentOpportunities;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        AnalyticsService.getMarketIndicators(),
        AnalyticsService.getGoldComparison(),
        AnalyticsService.getTopProjects(limit: 5),
        AnalyticsService.getInvestmentOpportunities(limit: 10),
      ]);

      if (mounted) {
        setState(() {
          _marketIndicators = results[0] as MarketIndicators?;
          _goldComparison = results[1] as GoldComparison?;
          _topProjects = results[2] as TopProjects?;
          _investmentOpportunities = results[3] as InvestmentOpportunities?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AnalyticsCharts.buildLoadingIndicator();
    }

    if (_error != null) {
      return AnalyticsCharts.buildErrorWidget(_error!);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildMarketStats(),
          _buildChartsSection(),
          _buildTopProjectsSection(),
          _buildInvestmentOpportunitiesSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Market Analytics Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Real-time market insights and investment opportunities',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketStats() {
    if (_marketIndicators == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Market Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              AnalyticsCharts.buildStatCard(
                title: 'Total Properties',
                value: _marketIndicators!.totalProperties.toString(),
                subtitle: 'Listed properties',
                icon: Icons.home,
                color: Colors.blue,
              ),
              AnalyticsCharts.buildStatCard(
                title: 'Average Price',
                value:
                    '${(_marketIndicators!.averagePrice / 1000).toStringAsFixed(0)}K EGP',
                subtitle: 'Market average',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
              AnalyticsCharts.buildStatCard(
                title: 'Price Range',
                value:
                    '${(_marketIndicators!.priceRange.min / 1000).toStringAsFixed(0)}K - ${(_marketIndicators!.priceRange.max / 1000).toStringAsFixed(0)}K',
                subtitle: 'EGP',
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
              AnalyticsCharts.buildStatCard(
                title: 'Active Auctions',
                value: _marketIndicators!.marketActivity.activeAuctions
                    .toString(),
                subtitle: 'Live auctions',
                icon: Icons.gavel,
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    if (_marketIndicators == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Market Analysis',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Property Type Distribution
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Property Type Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                AnalyticsCharts.buildPropertyTypePieChart(
                  _marketIndicators!.byType,
                ),
              ],
            ),
          ),
          // Location Distribution
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Location Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                AnalyticsCharts.buildLocationBarChart(
                  _marketIndicators!.byLocation,
                ),
              ],
            ),
          ),
          // Bedroom Distribution
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Bedroom Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                AnalyticsCharts.buildBedroomBarChart(
                  _marketIndicators!.byBedrooms,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProjectsSection() {
    if (_topProjects == null || _topProjects!.projects.isEmpty) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Performing Projects',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topProjects!.projects.length,
            itemBuilder: (context, index) {
              final project = _topProjects!.projects[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.location,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildProjectStat(
                          'Properties',
                          project.propertyCount.toString(),
                        ),
                        const SizedBox(width: 16),
                        _buildProjectStat(
                          'Avg Price',
                          '${(project.averagePrice / 1000).toStringAsFixed(0)}K EGP',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInvestmentOpportunitiesSection() {
    if (_investmentOpportunities == null ||
        _investmentOpportunities!.opportunities.isEmpty) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Investment Opportunities',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _investmentOpportunities!.opportunities.length,
            itemBuilder: (context, index) {
              final opportunity =
                  _investmentOpportunities!.opportunities[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            opportunity.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: opportunity.estimatedROI > 0
                                ? Colors.green
                                : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${opportunity.estimatedROI.toStringAsFixed(1)}% ROI',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opportunity.location,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildOpportunityStat(
                          'Price',
                          '${(opportunity.buyingPrice / 1000).toStringAsFixed(0)}K EGP',
                        ),
                        const SizedBox(width: 16),
                        _buildOpportunityStat(
                          'Type',
                          opportunity.propertyType ?? 'N/A',
                        ),
                        const SizedBox(width: 16),
                        _buildOpportunityStat(
                          'Project',
                          opportunity.project ?? 'N/A',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
