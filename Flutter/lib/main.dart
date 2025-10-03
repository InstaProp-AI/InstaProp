import 'dart:convert';
import 'package:flutter/material.dart';
import 'add_property_page.dart';
import 'profile_page.dart';
import 'bid_page.dart';
import 'valuate_page.dart';
import 'calender_page.dart';
import 'notification_page.dart';
import 'auctions_page.dart'; // Add this import at the top with others
import 'i18n.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'login_signup.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await authState.init();
  runApp(const MyApp());
}

// Light mode colors
const Color kBg = Colors.white;
const Color kCard = Colors.white;
const Color kPrimary = Colors.green;
const Color kAccent = Color.fromARGB(255, 25, 71, 48);
const Color kText = Colors.black87;
const Color kGray = Color(0xFFF5F5F5);

class Auction {
  final int id;
  final String name;
  final String imageUrl;
  final String category;
  final int beds;
  final int baths;
  final double startPrice;
  final double currentPrice;
  final int bidders;
  final String postedBy;
  final String symbol;
  final String propertyName;

  Auction({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.beds,
    required this.baths,
    required this.startPrice,
    required this.currentPrice,
    required this.bidders,
    required this.postedBy,
    required this.symbol,
    required this.propertyName,
  });

  double get percentageChange =>
      ((currentPrice - startPrice) / startPrice) * 100;

  static Auction fromApi(Map<String, dynamic> a) {
    final property = a['property'] as Map<String, dynamic>? ?? {};
    return Auction(
      id: a['auctionId'] as int,
      name: (property['name'] as String?) ?? 'Property',
      imageUrl: '',
      category: 'N/A',
      beds: 0,
      baths: 0,
      startPrice: (property['startingPrice'] as num?)?.toDouble() ?? 0,
      currentPrice: _extractCurrentPrice(a),
      bidders: (a['bids'] as List?)?.length ?? 0,
      postedBy: (property['owner'] != null
          ? (property['owner']['firstName'] ?? '')
          : ''),
      symbol: 'LV', // Placeholder
      propertyName: (property['name'] as String?) ?? 'Property',
    );
  }

  static double _extractCurrentPrice(Map<String, dynamic> a) {
    final bids = (a['bids'] as List?) ?? [];
    if (bids.isEmpty) {
      return (a['property']?['startingPrice'] as num?)?.toDouble() ?? 0;
    }
    bids.sort(
      (x, y) => ((x['bidAmount'] as num).toDouble()).compareTo(
        (y['bidAmount'] as num).toDouble(),
      ),
    );
    return (bids.last['bidAmount'] as num).toDouble();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (_, lang, __) {
        final t = Strings(lang);
        return Directionality(
          textDirection: t.direction,
          child: MaterialApp(
            title: t.appTitle,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'Montserrat',
              scaffoldBackgroundColor: kBg,
              colorScheme: ColorScheme.fromSeed(
                seedColor: kPrimary,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            home: const HomePage(),
          ),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2;
  String sortBy = 'Symbol';
  bool sortDesc = false;
  int unreadNotifications = 0;
  List<Auction> auctions = [];

  @override
  void initState() {
    super.initState();
    _loadAuctions();
  }

  Future<void> _loadAuctions() async {
    try {
      final res = await api.get('/api/Auctions');
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body) as List? ?? [];
        setState(() {
          auctions = data
              .map((a) => Auction.fromApi(a as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading auctions: $e');
    }
  }

  List<Auction> get featuredAuctions {
    final sorted = List<Auction>.from(auctions)
      ..sort((a, b) => b.bidders.compareTo(a.bidders));
    return sorted.take(2).toList();
  }

  List<Auction> get filteredAuctions {
    List<Auction> list = List<Auction>.from(auctions);
    list.sort((a, b) {
      int result = 0;
      switch (sortBy) {
        case 'Symbol':
          result = a.name.compareTo(b.name);
          break;
        case 'Name':
          result = a.name.compareTo(b.name);
          break;
        case 'Percentage':
          result = a.percentageChange.compareTo(b.percentageChange);
          break;
        case 'Start Price':
          result = a.startPrice.compareTo(b.startPrice);
          break;
        case 'Current Price':
          result = a.currentPrice.compareTo(b.currentPrice);
          break;
        case 'Bidders':
          result = a.bidders.compareTo(b.bidders);
          break;
        case 'Beds':
          result = a.beds.compareTo(b.beds);
          break;
        case 'Baths':
          result = a.baths.compareTo(b.baths);
          break;
      }
      return sortDesc ? -result : result;
    });
    return list;
  }

  void _onHeaderTap(String column) {
    setState(() {
      if (sortBy == column) {
        sortDesc = !sortDesc;
      } else {
        sortBy = column;
        sortDesc = false;
      }
    });
  }

  Future<void> _onNavTap(int idx) async {
    setState(() {
      _selectedIndex = idx;
    });
    Widget page;
    switch (idx) {
      case 0:
        if (await requireLogin(context)) {
          page = const AddPropertyPage();
        } else {
          return;
        }
        break;
      case 1:
        if (await requireLogin(context)) {
          page = const ValuatePage();
        } else {
          return;
        }
        break;
      case 2:
        page = const HomePage();
        break;
      case 3:
        if (await requireLogin(context)) {
          page = const CalenderPage();
        } else {
          return;
        }
        break;
      case 4:
        if (await requireLogin(context)) {
          page = const ProfilePage();
        } else {
          return;
        }
        break;
      default:
        page = const HomePage();
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      selectedIndex: _selectedIndex,
      onNavTap: _onNavTap,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // AppBar Modern with Notification Button and Badge
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: ValueListenableBuilder<AppLanguage>(
                      valueListenable: appLanguage,
                      builder: (_, lang, __) {
                        final t = Strings(lang);
                        return Text(
                          t.appTitle,
                          style: TextStyle(
                            color: kPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            letterSpacing: 1.2,
                          ),
                        );
                      },
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_none,
                          color: kPrimary,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationPage(),
                            ),
                          );
                        },
                        tooltip: 'Notifications',
                      ),
                      if (unreadNotifications > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationPage(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unreadNotifications',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Featured Auctions Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ValueListenableBuilder<AppLanguage>(
                    valueListenable: appLanguage,
                    builder: (_, lang, __) {
                      final t = Strings(lang);
                      return Text(
                        t.featuredAuctions,
                        style: TextStyle(
                          color: kText,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      );
                    },
                  ),
                  Icon(Icons.arrow_forward_ios, color: kPrimary, size: 18),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: featuredAuctions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, idx) {
                    final auction = featuredAuctions[idx];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BidPage(auction: auction),
                          ),
                        );
                      },
                      child: Container(
                        width: 220,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 227, 227, 227),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: kGray.withOpacity(0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                bottomLeft: Radius.circular(18),
                              ),
                              child: Image.network(
                                auction.imageUrl,
                                height: 120,
                                width: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      auction.name,
                                      style: TextStyle(
                                        color: kText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.attach_money,
                                          color: kPrimary,
                                          size: 16,
                                        ),
                                        Text(
                                          auction.currentPrice.toStringAsFixed(0),
                                          style: TextStyle(
                                            color: kPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people,
                                          color: kAccent,
                                          size: 15,
                                        ),
                                        Text(
                                          '${auction.bidders} Bidders',
                                          style: TextStyle(
                                            color: kText,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
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
                  },
                ),
              ),
            ),
            // Banner Modern
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      kPrimary.withOpacity(0.85),
                      kAccent.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Opacity(
                        opacity: 0.18,
                        child: Image.network(
                          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
                          width: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ValueListenableBuilder<AppLanguage>(
                            valueListenable: appLanguage,
                            builder: (_, lang, __) {
                              final t = Strings(lang);
                              return Text(
                                t.discountOff,
                                style: TextStyle(
                                  color: kCard,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 2),
                          ValueListenableBuilder<AppLanguage>(
                            valueListenable: appLanguage,
                            builder: (_, lang, __) {
                              final t = Strings(lang);
                              return Text(
                                t.discountsOnAuctions,
                                style: TextStyle(
                                  color: kCard,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Last Auctions Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ValueListenableBuilder<AppLanguage>(
                    valueListenable: appLanguage,
                    builder: (_, lang, __) {
                      final t = Strings(lang);
                      return Text(
                        t.allAuctions,
                        style: TextStyle(
                          color: kText,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior
                        .translucent, // Ensures the area is clickable
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuctionsPage(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0), // Large tap area
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: kPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Matrix Table Headers and Rows (scrollable together)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: kGray,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 900,
                    child: Column(
                      children: [
                        // Matrix Table Headers
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          child: Row(
                            children: [
                              _matrixHeader('Symbol', flex: 1),
                              _matrixHeader('Name', flex: 2),
                              _matrixHeader('Percentage', flex: 1),
                              _matrixHeader('Start Price', flex: 1),
                              _matrixHeader('Current Price', flex: 1),
                              _matrixHeader('Bidders', flex: 1),
                              _matrixHeader('Beds', flex: 1),
                              _matrixHeader('Baths', flex: 1),
                            ],
                          ),
                        ),
                        // Matrix Table Rows
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredAuctions.length,
                            itemBuilder: (context, idx) {
                              final auction = filteredAuctions[idx];
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BidPage(auction: auction),
                                    ),
                                  );
                                },
                                child: Container(
                                  color: idx % 2 == 0
                                      ? kCard
                                      : kGray.withOpacity(0.6),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          auction.name,
                                          style: TextStyle(
                                            color: kText,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          auction.name,
                                          style: TextStyle(
                                            color: kText,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          '${auction.percentageChange.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            color: auction.percentageChange >= 0
                                                ? kPrimary
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          'EGP ${auction.startPrice.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            color: kText,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          'EGP ${auction.currentPrice.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            color: kText,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          '${auction.bidders}',
                                          style: TextStyle(
                                            color: kText,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          '${auction.beds}',
                                          style: TextStyle(
                                            color: kText,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          '${auction.baths}',
                                          style: TextStyle(
                                            color: kText,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _matrixHeader(String label, {int flex = 1}) {
    final isActive = sortBy == label;
    return Expanded(
      flex: flex,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _onHeaderTap(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: isActive
              ? BoxDecoration(
                  color: kPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? kPrimary : kText,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (isActive)
                Icon(
                  sortDesc ? Icons.arrow_downward : Icons.arrow_upward,
                  color: kPrimary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScaffold extends StatelessWidget {
  final int selectedIndex;
  final Widget child;
  final void Function(int) onNavTap;

  const MainScaffold({
    super.key,
    required this.selectedIndex,
    required this.child,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kCard,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navIcon(Icons.add_circle_outline, 0),
              _navIcon(Icons.analytics_outlined, 1),
              _navIcon(Icons.home_outlined, 2),
              _navIcon(Icons.calendar_month, 3),
              _navIcon(Icons.person_outline, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, int idx) {
    return GestureDetector(
      onTap: () => onNavTap(idx),
      child: Container(
        decoration: BoxDecoration(
          color: selectedIndex == idx
              ? kPrimary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: selectedIndex == idx ? kPrimary : kText.withOpacity(0.6),
          size: 28,
        ),
      ),
    );
  }
}
