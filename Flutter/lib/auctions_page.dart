import 'dart:convert';
import 'package:flutter/material.dart';
import 'main.dart'; // For Auction class and color constants
import 'bid_page.dart';
import 'i18n.dart';
import 'api_client.dart';

class AuctionsPage extends StatefulWidget {
  const AuctionsPage({super.key});

  @override
  State<AuctionsPage> createState() => _AuctionsPageState();
}

class _AuctionsPageState extends State<AuctionsPage> {
  String sortBy = 'Symbol';
  bool sortDesc = false;
  String searchText = '';
  String selectedCategory = 'All';
  int? minBeds;
  int? minBaths;
  int? minBidders;
  List<Auction> auctions = [];
  bool loading = true;

  final List<String> categories = [
    'All',
    'Villa',
    'Apartment',
    'Cottage',
    'Condo',
    'Penthouse',
    'House',
    'Studio',
    'Cabin',
  ];

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
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      print('Error loading auctions: $e');
      setState(() => loading = false);
    }
  }

  List<Auction> get filteredAuctions {
    List<Auction> list = List<Auction>.from(auctions);
    if (selectedCategory != 'All') {
      list = list.where((a) => a.category == selectedCategory).toList();
    }
    if (minBeds != null) {
      list = list.where((a) => a.beds >= minBeds!).toList();
    }
    if (minBaths != null) {
      list = list.where((a) => a.baths >= minBaths!).toList();
    }
    if (minBidders != null) {
      list = list.where((a) => a.bidders >= minBidders!).toList();
    }
    if (searchText.isNotEmpty) {
      list = list
          .where(
            (a) =>
                a.name.toLowerCase().contains(searchText.toLowerCase()) ||
                a.category.toLowerCase().contains(searchText.toLowerCase()),
          )
          .toList();
    }
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

  void _showFiltersDialog() {
    final t = Strings.of(context);
    int? tempBeds = minBeds;
    int? tempBaths = minBaths;
    int? tempBidders = minBidders;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          t.filters,
          style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: InputDecoration(
                labelText: t.category,
                labelStyle: TextStyle(color: kPrimary),
                filled: true,
                fillColor: kGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: categories
                  .map(
                    (cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat, style: TextStyle(color: kText)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => selectedCategory = val);
                Navigator.of(context).pop();
                _showFiltersDialog();
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: tempBeds?.toString() ?? '',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t.minBeds,
                labelStyle: TextStyle(color: kPrimary),
                filled: true,
                fillColor: kGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => tempBeds = int.tryParse(val),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: tempBaths?.toString() ?? '',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t.minBaths,
                labelStyle: TextStyle(color: kPrimary),
                filled: true,
                fillColor: kGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => tempBaths = int.tryParse(val),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: tempBidders?.toString() ?? '',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t.minBidders,
                labelStyle: TextStyle(color: kPrimary),
                filled: true,
                fillColor: kGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => tempBidders = int.tryParse(val),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                minBeds = tempBeds;
                minBaths = tempBaths;
                minBidders = tempBidders;
              });
              Navigator.of(context).pop();
            },
            child: Text(
              t.apply,
              style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                minBeds = null;
                minBaths = null;
                minBidders = null;
                selectedCategory = 'All';
              });
              Navigator.of(context).pop();
            },
            child: Text(
              t.clear,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Strings.of(context);
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Text(
          t.auctions,
          style: TextStyle(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        iconTheme: IconThemeData(color: kPrimary),
      ),
      body: Directionality(
        textDirection: t.direction,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                children: [
                  // Search Bar & Filters
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: t.searchProperties,
                              prefixIcon: Icon(Icons.search, color: kPrimary),
                              filled: true,
                              fillColor: kGray,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchText = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(Icons.filter_alt, color: kPrimary),
                          tooltip: t.filters,
                          onPressed: _showFiltersDialog,
                        ),
                      ],
                    ),
                  ),
                  // Auctions Table Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                    child: Text(
                      t.allAuctions,
                      style: TextStyle(
                        color: kText,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  // Matrix Table Headers and Rows (scrollable together)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: kGray,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 1100,
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
                                    _matrixHeader(t.name, flex: 2),
                                    _matrixHeader(t.category, flex: 1),
                                    _matrixHeader(t.beds, flex: 1),
                                    _matrixHeader(t.bathrooms, flex: 1),
                                    _matrixHeader(t.startPrice, flex: 1),
                                    _matrixHeader(t.currentPrice, flex: 1),
                                    _matrixHeader(t.bidders, flex: 1),
                                    _matrixHeader(t.postedBy, flex: 1),
                                    _matrixHeader(t.changePercent, flex: 1),
                                  ],
                                ),
                              ),
                              // Matrix Table Rows
                              SizedBox(
                                height: 500,
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
                                                auction.category,
                                                style: TextStyle(
                                                  color: kAccent,
                                                  fontWeight: FontWeight.w600,
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
                                                  color: kPrimary,
                                                  fontWeight: FontWeight.bold,
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
                                                auction.postedBy,
                                                style: TextStyle(
                                                  color: kAccent,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                '${auction.percentageChange.toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  color:
                                                      auction.percentageChange >=
                                                          0
                                                      ? kPrimary
                                                      : Colors.red,
                                                  fontWeight: FontWeight.bold,
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
