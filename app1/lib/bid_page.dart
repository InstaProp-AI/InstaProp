import 'package:flutter/material.dart';
import 'main.dart'; // To get Auction class and color constants
import 'package:fl_chart/fl_chart.dart';
import 'i18n.dart';

// Use the same color constants as main.dart
// kBg, kCard, kPrimary, kAccent, kText, kGray, kWhite

class BidPage extends StatefulWidget {
  final Auction auction;
  const BidPage({super.key, required this.auction});

  @override
  State<BidPage> createState() => _BidPageState();
}

class _BidPageState extends State<BidPage> {
  int _currentImage = 0;

  List<Map<String, dynamic>> get leaderboard => [
    {"name": "Alice", "amount": widget.auction.currentPrice - 10000},
    {"name": "Bob", "amount": widget.auction.currentPrice - 8000},
    {"name": "Carol", "amount": widget.auction.currentPrice - 6000},
    {"name": "Dave", "amount": widget.auction.currentPrice - 4000},
    {"name": "Eve", "amount": widget.auction.currentPrice - 2000},
  ];

  List<FlSpot> get bidHistory => [
    FlSpot(0, widget.auction.startPrice),
    FlSpot(1, widget.auction.startPrice + 10000),
    FlSpot(2, widget.auction.startPrice + 20000),
    FlSpot(3, widget.auction.startPrice + 30000),
    FlSpot(4, widget.auction.currentPrice),
  ];

  List<String> get images => [
    widget.auction.imageUrl,
    'https://images.unsplash.com/photo-1464983953574-0892a716854b?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?auto=format&fit=crop&w=800&q=80',
  ];

  @override
  Widget build(BuildContext context) {
    final t = Strings.of(context);
    double minY =
        widget.auction.startPrice -
        0.1 *
            (widget.auction.currentPrice - widget.auction.startPrice <= 0
                ? widget.auction.startPrice
                : widget.auction.currentPrice - widget.auction.startPrice);
    double maxY =
        widget.auction.currentPrice +
        0.1 *
            (widget.auction.currentPrice - widget.auction.startPrice <= 0
                ? widget.auction.currentPrice
                : widget.auction.currentPrice - widget.auction.startPrice);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Text(
          t.auctionDetails,
          style: TextStyle(color: kText, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: kText),
      ),
      body: Directionality(
        textDirection: t.direction,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel Modern
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    controller: PageController(initialPage: _currentImage),
                    onPageChanged: (index) {
                      setState(() {
                        _currentImage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.network(
                          images[index],
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                  // Carousel indicators
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (idx) => Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImage == idx
                                ? kPrimary
                                : kGray.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Title and category modern
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.auction.propertyName,
                    style: TextStyle(
                      color: kText,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.auction.category,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Prices and bidders modern
            Row(
              children: [
                Icon(Icons.attach_money, color: kPrimary, size: 22),
                Text(
                  '${widget.auction.currentPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(width: 18),
                Text(
                  'Start: \$${widget.auction.startPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: kGray,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 18),
                Icon(Icons.people, color: kAccent, size: 20),
                Text(
                  '${widget.auction.bidders} Bidders',
                  style: TextStyle(
                    color: kText,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Chart modern
            Text(
              t.bidHistory,
              style: TextStyle(
                color: kPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  backgroundColor: kCard,
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Price',
                        style: TextStyle(color: kText),
                      ),
                      axisNameSize: 24,
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        'Bid #',
                        style: TextStyle(color: kText),
                      ),
                      axisNameSize: 24,
                    ),
                    rightTitles: AxisTitles(),
                    topTitles: AxisTitles(),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: kPrimary, width: 2),
                  ),
                  minX: 0,
                  maxX: 4,
                  minY: minY,
                  maxY: maxY > minY ? maxY : minY + 1000,
                  lineBarsData: [
                    LineChartBarData(
                      spots: bidHistory.map((spot) {
                        double y = spot.y.clamp(
                          minY,
                          maxY > minY ? maxY : minY + 1000,
                        );
                        return FlSpot(spot.x, y);
                      }).toList(),
                      isCurved: true,
                      color: kPrimary,
                      barWidth: 4,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Leaderboard modern
            Text(
              t.topBidders,
              style: TextStyle(
                color: kPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leaderboard.length,
              itemBuilder: (context, idx) {
                final entry = leaderboard[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: kGray.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: kPrimary,
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          entry["name"],
                          style: TextStyle(
                            color: kText,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '\$${entry["amount"].toStringAsFixed(0)}',
                        style: TextStyle(
                          color: kText,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Posted by modern
            Row(
              children: [
                Icon(Icons.person, color: kAccent, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Posted by ${widget.auction.postedBy}',
                  style: TextStyle(
                    color: kText,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Description modern
            Text(
              t.propertyDetails,
              style: TextStyle(
                color: kPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailPoint(t.beds, '${widget.auction.beds}'),
                  _detailPoint(t.bathrooms, '${widget.auction.baths}'),
                  _detailPoint(t.payment, t.cashOrInstallment),
                  _detailPoint(t.startPrice, 'EGP ${widget.auction.startPrice.toStringAsFixed(0)}'),
                  _detailPoint(t.currentPrice, 'EGP ${widget.auction.currentPrice.toStringAsFixed(0)}'),
                  _detailPoint(t.bidders, '${widget.auction.bidders}'),
                  _detailPoint(t.category, widget.auction.category),
                  _detailPoint(t.postedBy, widget.auction.postedBy),
                  _detailPoint(t.symbol, widget.auction.symbol),
                  _detailPoint(t.location, t.primeArea),
                  _detailPoint(t.description, t.spaciousModern),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Place Bid Button modern
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(t.bidPlaced)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  t.placeBid,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _detailPoint(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: kPrimary, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: kText,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: kText,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
