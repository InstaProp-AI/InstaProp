import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/app_colors.dart';
import '../models/child_property.dart';
import '../models/property_image.dart';
import '../models/parent_property.dart';
import '../models/price_history.dart';
import '../models/installment_summary.dart';
import '../services/property_service.dart';
import '../services/api_client.dart';
import '../services/analytics_service.dart';
import '../widgets/property_image_carousel.dart';
import '../widgets/country_flag.dart';

class PropertyDetailsPage extends StatefulWidget {
  final String propertyId;

  const PropertyDetailsPage({
    super.key,
    required this.propertyId,
  });

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  PropertyMarketBundle? _bundle;
  Map<String, dynamic>? _financials;
  MarketOverviewResponse? _marketOverview;
  List<PriceTrendResponse>? _priceTrends;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPropertyBundle();
  }

  Future<void> _loadPropertyBundle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load property bundle, financials, and market data in parallel
      final property = await PropertyService.getPropertyMarketBundle(widget.propertyId);
      if (!property.success || property.data == null) {
        setState(() {
          _error = property.error ?? 'Failed to load property details.';
          _isLoading = false;
        });
        return;
      }

      final bundle = property.data!;
      
      // Load financials and market data in parallel
      final results = await Future.wait([
        PropertyService.getPropertyFinancials(widget.propertyId).catchError((e) {
          return ApiResponse<Map<String, dynamic>>.error('Not available');
        }),
        AnalyticsService.getMarketOverview().catchError((e) => null),
        AnalyticsService.getPriceTrends(
          parentPropertyId: bundle.property.parentPropertyId,
          propertyType: bundle.property.typeLabel,
          location: bundle.property.location,
          months: 12,
        ).catchError((e) => null),
      ]);

      if (!mounted) return;

      final financialsResponse = results[0] as ApiResponse<Map<String, dynamic>>;
      final marketOverview = results[1] as MarketOverviewResponse?;
      final priceTrends = results[2] as List<PriceTrendResponse>?;

      setState(() {
        _bundle = bundle;
        if (financialsResponse.success && financialsResponse.data != null) {
          _financials = financialsResponse.data;
        }
        _marketOverview = marketOverview;
        _priceTrends = priceTrends;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load property details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _bundle?.property.name ?? 'Property Details';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPropertyBundle,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bundle = _bundle!;
    final children = <Widget>[
      _buildHeroSection(bundle.property),
      const SizedBox(height: 16),
      _buildPropertyOverview(bundle.property),
      const SizedBox(height: 16),
      _buildHighlightStats(bundle.property, bundle.marketAnalytics),
      if (bundle.hasParent) ...[
        const SizedBox(height: 16),
        _buildParentOverview(bundle.parent!),
      ],
      if (bundle.hasSiblings) ...[
        const SizedBox(height: 16),
        _buildSiblingSection(bundle.siblings),
      ],
      if (bundle.hasAnalytics) ...[
        const SizedBox(height: 16),
        _buildMarketIndicators(bundle.marketAnalytics!),
      ],
      // Investment Analysis Section
      const SizedBox(height: 16),
      _buildInvestmentAnalysis(bundle.property, bundle.marketAnalytics),
      // Payment Plan Section
      if (bundle.property.installmentSummary != null) ...[
        const SizedBox(height: 16),
        _buildPaymentPlan(bundle.property.installmentSummary!),
      ],
      // Enhanced Market Analysis (even with limited data)
      const SizedBox(height: 16),
      _buildEnhancedMarketAnalysis(
        bundle.property, 
        bundle.marketAnalytics, 
        bundle.siblings,
        _marketOverview,
        _priceTrends,
      ),
      const SizedBox(height: 48),
    ];

    return RefreshIndicator(
      onRefresh: _loadPropertyBundle,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildHeroSection(ChildProperty property) {
    final images = property.propertyImages ?? <PropertyImage>[];

    return SizedBox(
      height: 260,
      child: PropertyImageCarousel(
        images: images,
        fallbackImageUrl: property.imageUrl,
        height: 260,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        showNavigationButtons: true,
        showIndicators: true,
        showImageCounter: true,
      ),
    );
  }

  Widget _buildPropertyOverview(ChildProperty property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            property.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              // Country Flag
              CountryFlag(
                countryCode: CountryFlag.extractCountryCodeFromLocation(
                  property.location,
                ),
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  property.location,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (property.project != null)
                _buildChip(Icons.business, property.project!),
              _buildChip(Icons.apartment, property.typeLabel),
              if (property.phase != null && property.phase!.isNotEmpty)
                _buildChip(Icons.timeline, property.phase!),
              if (property.status != null && property.status!.isNotEmpty)
                _buildChip(Icons.verified, property.status!),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            property.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF3A3A3A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightStats(
    ChildProperty property,
    PropertyMarketAnalytics? analytics,
  ) {
    final cards = <Widget>[
      _buildStatCard(
        icon: Icons.king_bed_outlined,
        label: 'Bedrooms',
        value: '${property.bedrooms}',
      ),
      _buildStatCard(
        icon: Icons.bathtub_outlined,
        label: 'Bathrooms',
        value: '${property.bathrooms}',
      ),
      _buildStatCard(
        icon: Icons.square_foot,
        label: 'Area (sqft)',
        value: property.squareFeet.toString(),
      ),
      if (property.deliveryDate != null)
        _buildStatCard(
          icon: Icons.calendar_today,
          label: 'Delivery',
          value:
              '${property.deliveryDate!.month}/${property.deliveryDate!.year}',
        ),
      if (property.parkingSlots != null)
        _buildStatCard(
          icon: Icons.local_parking_outlined,
          label: 'Parking',
          value: '${property.parkingSlots}',
        ),
    ];

    if (property.buyingPrice != null && property.buyingPrice! > 0) {
      cards.insert(
        0,
        _buildStatCard(
          icon: Icons.payments_outlined,
          label: 'Acquired At',
          value: _formatCurrency(property.buyingPrice!),
          highlight: true,
        ),
      );
    } else if (analytics?.priceStats != null) {
      cards.insert(
        0,
        _buildStatCard(
          icon: Icons.price_change_outlined,
          label: 'Avg Market',
          value:
              _formatCurrency(analytics!.priceStats!.statistics.averagePrice),
          highlight: true,
        ),
      );
    }

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) => cards[index],
        separatorBuilder: (context, _) => const SizedBox(width: 12),
        itemCount: cards.length,
      ),
    );
  }

  Widget _buildParentOverview(ParentProperty parent) {
    final amenities = <_Amenity>[
      _Amenity('Pool', parent.hasPool, Icons.pool),
      _Amenity('Gym', parent.hasGym, Icons.fitness_center),
      _Amenity('Security', parent.hasSecurity, Icons.security),
      _Amenity('Parking', parent.hasParking, Icons.local_parking),
      _Amenity('Garden', parent.hasGarden, Icons.park),
      _Amenity('Playground', parent.hasPlayground, Icons.attractions),
      _Amenity('Clubhouse', parent.hasClubhouse, Icons.houseboat),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.domain, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Parent Project',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          parent.displayProjectName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildInfoPill(
                    icon: Icons.bed,
                    text: '${parent.bedrooms} Bedrooms mix',
                  ),
                  _buildInfoPill(
                    icon: Icons.bathtub,
                    text: '${parent.bathrooms} Bathrooms mix',
                  ),
                  _buildInfoPill(
                    icon: Icons.straighten,
                    text: '${parent.areaSqm} sqm avg',
                  ),
                  _buildInfoPill(
                    icon: Icons.checkroom,
                    text: parent.finishingType,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Compound Amenities',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: amenities
                    .where((amenity) => amenity.isAvailable)
                    .map(
                      (amenity) => _buildAmenityChip(
                        amenity.icon,
                        amenity.label,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSiblingSection(List<ChildProperty> siblings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sibling Units',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '${siblings.length} available',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: siblings.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final sibling = siblings[index];
                return _buildSiblingCard(sibling);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketIndicators(PropertyMarketAnalytics analytics) {
    final stats = analytics.priceStats?.statistics;
    final history = analytics.priceHistory?.priceHistory ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Market Indicators',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          if (stats != null)
            Row(
              children: [
                Expanded(
                  child: _buildMarketStatTile(
                    label: 'Avg Price',
                    value: _formatCurrency(stats.averagePrice),
                    icon: Icons.show_chart,
                    accent: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMarketStatTile(
                    label: '12M Change',
                    value:
                        '${stats.priceChangePercent.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    accent: stats.priceChangePercent >= 0
                        ? Colors.green
                        : Colors.redAccent,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: history.isEmpty
                  ? _buildEmptyMarketState()
                  : SizedBox(
                      height: 220,
                      child: LineChart(
                        _buildPriceHistoryChartData(history),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildPriceHistoryChartData(List<PropertyPriceHistory> history) {
    final sortedHistory = [...history]
      ..sort((a, b) => a.priceDate.compareTo(b.priceDate));

    final spots = <FlSpot>[];
    final labels = <int, String>{};

    for (var i = 0; i < sortedHistory.length; i++) {
      final entry = sortedHistory[i];
      spots.add(FlSpot(i.toDouble(), entry.price));
      labels[i] = '${entry.priceDate.month}/${entry.priceDate.year % 100}';
    }

    final minPrice = sortedHistory.map((e) => e.price).reduce(
          (value, element) => value < element ? value : element,
        );
    final maxPrice = sortedHistory.map((e) => e.price).reduce(
          (value, element) => value > element ? value : element,
        );

    return LineChartData(
      gridData: FlGridData(show: true),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          left: BorderSide(color: Colors.black12),
          bottom: BorderSide(color: Colors.black12),
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (value, meta) {
              final label = labels[value.toInt()];
              if (label == null) return const SizedBox.shrink();
              return Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 48,
            getTitlesWidget: (value, meta) {
              return Text(
                _formatCompactCurrency(value),
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primary.withOpacity(0.12),
          ),
        ),
      ],
      minY: minPrice * 0.95,
      maxY: maxPrice * 1.05,
    );
  }

  Widget _buildEmptyMarketState() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.signal_cellular_connected_no_internet_4_bar,
                color: Colors.grey, size: 32),
            SizedBox(height: 8),
            Text(
              'No price history available yet.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight
              ? AppColors.primary.withOpacity(0.3)
              : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: highlight
                  ? Colors.white.withOpacity(0.12)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: highlight ? Colors.white : AppColors.primary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: highlight ? Colors.white : const Color(0xFF1A1A1A),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: highlight ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiblingCard(ChildProperty sibling) {
    final images = sibling.propertyImages ?? <PropertyImage>[];
    final price = sibling.buyingPrice ?? 0;

    return SizedBox(
      width: 220,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailsPage(
                  propertyId: sibling.propertyId,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: PropertyImageCarousel(
                  images: images,
                  fallbackImageUrl: sibling.imageUrl,
                  height: 110,
                  showIndicators: false,
                  showNavigationButtons: false,
                  showImageCounter: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sibling.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${sibling.bedrooms} BR • ${sibling.bathrooms} Bath',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${sibling.squareFeet} sqft',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price > 0 ? _formatCurrency(price) : 'Price on request',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M EGP';
    }
    if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(0)}K EGP';
    }
    return '${value.toStringAsFixed(0)} EGP';
  }

  String _formatCompactCurrency(double value) {
    if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M';
    }
    if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildInvestmentAnalysis(
    ChildProperty property,
    PropertyMarketAnalytics? analytics,
  ) {
    // Use real financials data from backend
    dynamic buyingPriceNum = _financials?['buyingPrice'];
    if (buyingPriceNum == null) buyingPriceNum = _financials?['contractedPrice'];
    if (buyingPriceNum == null) buyingPriceNum = property.buyingPrice;
    final buyingPrice = buyingPriceNum is num ? buyingPriceNum.toDouble() : 0.0;
    
    dynamic marketValueNum = _financials?['marketValue'];
    if (marketValueNum == null) {
      final avgPrice = analytics?.priceStats?.statistics.averagePrice ?? 0;
      marketValueNum = avgPrice;
    }
    final marketValue = marketValueNum is num ? marketValueNum.toDouble() : 0.0;
    
    dynamic roiPercentNum = _financials?['roiPercent'];
    final roiPercent = roiPercentNum is num ? roiPercentNum.toDouble() : null;
    
    String? paybackPeriod;
    
    // Calculate payback period if we have ROI
    if (roiPercent != null && roiPercent > 0) {
      // Estimate based on annual appreciation rate (6% average)
      final annualAppreciation = 0.06;
      final yearsToDouble = (72 / (roiPercent * annualAppreciation)).abs();
      paybackPeriod = yearsToDouble < 1 
          ? '${(yearsToDouble * 12).toStringAsFixed(0)} months'
          : '${yearsToDouble.toStringAsFixed(1)} years';
    } else if (buyingPrice > 0 && marketValue > 0) {
      // Calculate ROI if not provided
      final calculatedROI = ((marketValue - buyingPrice) / buyingPrice) * 100;
      if (calculatedROI > 0) {
        final annualAppreciation = 0.06;
        final yearsToDouble = (72 / (calculatedROI * annualAppreciation)).abs();
        paybackPeriod = yearsToDouble < 1 
            ? '${(yearsToDouble * 12).toStringAsFixed(0)} months'
            : '${yearsToDouble.toStringAsFixed(1)} years';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Investment Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (buyingPrice > 0 && marketValue > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalysisTile(
                        label: 'Market Value',
                        value: _formatCurrency(marketValue),
                        icon: Icons.price_check,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalysisTile(
                        label: 'ROI',
                        value: roiPercent != null 
                            ? '${roiPercent.toStringAsFixed(1)}%'
                            : buyingPrice > 0 && marketValue > 0
                                ? '${((marketValue - buyingPrice) / buyingPrice * 100).toStringAsFixed(1)}%'
                                : 'N/A',
                        icon: Icons.percent,
                        color: (roiPercent ?? ((marketValue - buyingPrice) / buyingPrice * 100)) >= 0 
                            ? Colors.green 
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (paybackPeriod != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estimated Payback Period',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                paybackPeriod,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Investment analysis will be available once purchase price is set.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentPlan(InstallmentSummary summary) {
    final monthlyPayment = summary.termYears != null && summary.termYears! > 0
        ? (summary.remainingBalance / (summary.termYears! * 12)).toDouble()
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payment,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Payment Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildAnalysisTile(
                      label: 'Down Payment',
                      value: _formatCurrency(summary.downPaymentAmount),
                      icon: Icons.account_balance_wallet,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAnalysisTile(
                      label: 'Remaining',
                      value: _formatCurrency(summary.remainingBalance),
                      icon: Icons.credit_card,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              if (monthlyPayment > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade50,
                        Colors.green.shade100,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Installment',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade900,
                              ),
                            ),
                            Text(
                              _formatCurrency(monthlyPayment),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.green.shade900,
                              ),
                            ),
                            if (summary.termYears != null)
                              Text(
                                'Over ${summary.termYears} years',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'Total Paid',
                      _formatCurrency(summary.totalPaid),
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      'Progress',
                      '${((summary.totalPaid / summary.contractedPrice) * 100).toStringAsFixed(0)}%',
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedMarketAnalysis(
    ChildProperty property,
    PropertyMarketAnalytics? analytics,
    List<ChildProperty> siblings,
    MarketOverviewResponse? marketOverview,
    List<PriceTrendResponse>? priceTrends,
  ) {
    // Use real data from multiple sources
    final hasAnalyticsData = analytics?.hasData ?? false;
    final hasMarketOverview = marketOverview?.hasData ?? false;
    final hasPriceTrends = priceTrends?.isNotEmpty ?? false;
    
    // Get average price from real data
    double avgPrice = 0;
    double priceChange = 0;
    
    if (hasAnalyticsData && analytics != null && analytics.priceStats != null) {
      avgPrice = analytics.priceStats!.statistics.averagePrice.toDouble();
      priceChange = analytics.priceStats!.statistics.priceChangePercent.toDouble();
    } else if (hasMarketOverview) {
      final overview = marketOverview!;
      if (overview.areaPrices.isNotEmpty) {
        // Find matching area price
        final areaPrice = overview.areaPrices.firstWhere(
          (ap) => ap.area.toLowerCase().contains(property.location.toLowerCase()) ||
                  property.location.toLowerCase().contains(ap.area.toLowerCase()),
          orElse: () => overview.areaPrices.first,
        );
        avgPrice = areaPrice.averagePrice;
      }
    } else if (hasPriceTrends) {
      final trends = priceTrends!;
      if (trends.isNotEmpty) {
        // Calculate from price trends
        final prices = trends.map((pt) => pt.price).toList();
        avgPrice = prices.reduce((a, b) => a + b) / prices.length;
        if (prices.length > 1) {
          final firstPrice = prices.first;
          final lastPrice = prices.last;
          priceChange = firstPrice > 0 ? ((lastPrice - firstPrice) / firstPrice * 100) : 0;
        }
      }
    }
    
    final hasData = hasAnalyticsData || hasMarketOverview || hasPriceTrends;
    final siblingCount = siblings.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: Colors.purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Market Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (hasData && avgPrice > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalysisTile(
                        label: 'Market Avg',
                        value: _formatCurrency(avgPrice),
                        icon: Icons.show_chart,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalysisTile(
                        label: '12M Trend',
                        value: '${priceChange.toStringAsFixed(1)}%',
                        icon: priceChange >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: priceChange >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Limited Market Data',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This is a sampling unit. Market analysis will be available as more data is collected.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade800,
                        ),
                      ),
                      if (siblingCount > 0) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.apartment, size: 16, color: Colors.amber.shade700),
                            const SizedBox(width: 6),
                            Text(
                              '$siblingCount similar units available',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Price per sqft analysis
              if (property.buyingPrice != null && property.buyingPrice! > 0 && property.squareFeet > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.square_foot, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Price per sqft',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              _formatCurrency(property.buyingPrice! / property.squareFeet),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildAnalysisTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getShadeColor(color, 700),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _getShadeColor(color, 900),
            ),
          ),
        ],
      ),
    );
  }

  Color _getShadeColor(Color color, int shade) {
    // For MaterialColor, use the shade index
    if (color is MaterialColor) {
      return color[shade] ?? color;
    }
    // For regular colors, return a darker/lighter variant
    if (shade == 700) {
      return Color.fromRGBO(
        (color.red * 0.7).round(),
        (color.green * 0.7).round(),
        (color.blue * 0.7).round(),
        1.0,
      );
    } else if (shade == 900) {
      return Color.fromRGBO(
        (color.red * 0.5).round(),
        (color.green * 0.5).round(),
        (color.blue * 0.5).round(),
        1.0,
      );
    }
    return color;
  }
}

class _Amenity {
  final String label;
  final bool isAvailable;
  final IconData icon;

  const _Amenity(this.label, this.isAvailable, this.icon);
}

