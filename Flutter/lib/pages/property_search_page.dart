import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../models/property.dart';
import '../models/auction.dart';
import '../services/property_service.dart';
import '../services/auction_service.dart';
import '../widgets/property_image_carousel.dart';
import 'property_comparison_page.dart';
import 'auction_details_page.dart';
import 'auctions_page.dart';

class PropertySearchPage extends StatefulWidget {
  const PropertySearchPage({super.key});

  @override
  State<PropertySearchPage> createState() => _PropertySearchPageState();
}

class _PropertySearchPageState extends State<PropertySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Property> _allProperties = [];
  List<Property> _filteredProperties = [];
  List<Auction> _allAuctions = [];
  Map<int, Auction> _propertyAuctionMap = {}; // Map propertyId to auction
  bool _isLoading = true;

  // Served/Suggested Searches
  final List<Map<String, dynamic>> _servedSearches = [
    {
      'title': 'Luxury Waterfront',
      'icon': Icons.water,
      'filters': {'category': 'Condo', 'location': 'Waterfront'},
    },
    {
      'title': 'Affordable Family Homes',
      'icon': Icons.home,
      'filters': {'category': 'Single Family', 'priceMax': 300000},
    },
    {
      'title': 'Downtown Condos',
      'icon': Icons.apartment,
      'filters': {'category': 'Condo', 'location': 'Downtown'},
    },
    {
      'title': 'Historic Properties',
      'icon': Icons.history_edu,
      'filters': {'location': 'Historic'},
    },
    {
      'title': 'New Construction',
      'icon': Icons.construction,
      'filters': {'status': 'New'},
    },
    {
      'title': 'Investment Opportunities',
      'icon': Icons.trending_up,
      'filters': {'category': 'Commercial'},
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      // Use public endpoint that doesn't require authentication
      final propertiesResponse = await PropertyService.getProperties();
      final auctionsResponse = await AuctionService.getAuctions();

      if (propertiesResponse.success && propertiesResponse.data != null) {
        _allProperties = propertiesResponse.data!;
        _filteredProperties = _allProperties;

        // Load auctions and create property-to-auction mapping
        if (auctionsResponse.success && auctionsResponse.data != null) {
          _allAuctions = auctionsResponse.data!;
          _propertyAuctionMap.clear();

          for (var auction in _allAuctions) {
            if (auction.property != null) {
              _propertyAuctionMap[auction.property!.propertyId] = auction;
            }
          }
        }

        setState(() => _isLoading = false);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading properties: $e');
      setState(() => _isLoading = false);
    }
  }

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProperties = _allProperties;
      } else {
        _filteredProperties = _allProperties.where((property) {
          final searchLower = query.toLowerCase();
          return property.name.toLowerCase().contains(searchLower) ||
              (property.location ?? '').toLowerCase().contains(searchLower) ||
              (property.category ?? '').toLowerCase().contains(searchLower) ||
              (property.project ?? '').toLowerCase().contains(searchLower);
        }).toList();
      }
    });
  }

  void _applyServedSearch(Map<String, dynamic> filters) {
    setState(() {
      _filteredProperties = _allProperties.where((property) {
        bool matches = true;

        if (filters.containsKey('category')) {
          matches = matches && property.category == filters['category'];
        }

        if (filters.containsKey('location')) {
          matches =
              matches &&
              (property.location ?? '').contains(filters['location']);
        }

        if (filters.containsKey('status')) {
          matches = matches && property.status == filters['status'];
        }

        if (filters.containsKey('priceMax')) {
          // For auction properties, we'd need to check auction price
          // For now, we'll just include them in results
          matches = matches;
        }

        return matches;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, location, category...',
                      prefixIcon: Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: AppColors.primary),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.secondary!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primary!,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: _performSearch,
                  ),
                ),
                const SizedBox(width: 8),
                // Reset Button
                IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                  icon: Icon(Icons.refresh, color: AppColors.primary),
                  tooltip: 'Reset Search',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),

          // Served Searches Section
          Container(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                bottom: BorderSide(color: AppColors.secondary!, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.stars, color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Popular Searches',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _servedSearches.length,
                    itemBuilder: (context, index) {
                      final search = _servedSearches[index];
                      return _buildServedSearchCard(search);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Results Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.surface,
            child: Text(
              'Results: ${_filteredProperties.length}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),

          // Properties List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProperties.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredProperties.length,
                    itemBuilder: (context, index) {
                      final property = _filteredProperties[index];
                      return _buildPropertyCard(property);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Auctions View Switch Button (Back Button)
            FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context);
              },
              backgroundColor: AppColors.surface,
              icon: Icon(Icons.gavel, color: AppColors.primary),
              label: Text(
                'Auctions',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              heroTag: 'auctions_button',
            ),
            // Compare Button (smaller)
            FloatingActionButton(
              onPressed: () {
                if (_filteredProperties.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyComparisonPage(
                        preSelectedProperties: _filteredProperties
                            .take(5)
                            .toList(),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No properties available to compare'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.compare_arrows, color: AppColors.surface),
              heroTag: 'compare_button_properties',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServedSearchCard(Map<String, dynamic> search) {
    return GestureDetector(
      onTap: () {
        _applyServedSearch(search['filters']);
        // Show a snackbar to indicate the search was applied
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied: ${search['title']}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
      },
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary!, AppColors.primary!.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary!.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(search['icon'], color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                search['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    final auction = _propertyAuctionMap[property.propertyId];
    final hasAuction = auction != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _handlePropertyTap(property),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image with auction badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: PropertyImageCarousel(
                    images: property.propertyImages ?? [],
                    fallbackImageUrl: property.imageUrl,
                    height: 160,
                    showIndicators: true,
                    showNavigationButtons: false,
                    showImageCounter: true,
                  ),
                ),
                // Auction Status Badge
                if (hasAuction)
                  Positioned(
                    top: 38,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: auction.isUpcoming
                            ? Colors.blue
                            : (auction.isActive ? Colors.green : Colors.orange),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            auction.isUpcoming
                                ? Icons.schedule
                                : (auction.isActive
                                      ? Icons.gavel
                                      : Icons.history),
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            auction.isUpcoming
                                ? 'UPCOMING'
                                : (auction.isActive ? 'LIVE' : 'ENDED'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Property Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property name
                  Text(
                    property.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Tags row
                  Row(
                    children: [
                      // Property Type Tag (Primary/Resale)
                      _buildPropertyTypeTag(property.type),
                      const SizedBox(width: 8),

                      // Category Tag
                      if (property.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.secondary!),
                          ),
                          child: Text(
                            property.category!,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (property.location != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildPropertySpec(
                        Icons.bed,
                        '${property.bedrooms} Beds',
                      ),
                      const SizedBox(width: 12),
                      _buildPropertySpec(
                        Icons.bathtub,
                        '${property.bathrooms} Baths',
                      ),
                      const SizedBox(width: 12),
                      _buildPropertySpec(
                        Icons.square_foot,
                        '${property.squareFeet} sqft',
                      ),
                    ],
                  ),
                  if (property.project != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.apartment,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Project: ${property.project}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertySpec(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: AppColors.secondary),
          const SizedBox(height: 16),
          Text(
            'No Properties Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _handlePropertyTap(Property property) {
    final auction = _propertyAuctionMap[property.propertyId];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.home_work, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                property.name,
                style: const TextStyle(fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What would you like to do?',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),

            // Add to Compare Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyComparisonPage(
                        preSelectedProperties: [property],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_chart),
                label: const Text('Add to Compare'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            if (auction != null) const SizedBox(height: 12),

            // View Auction Button
            if (auction != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AuctionDetailsPage(auction: auction),
                      ),
                    );
                  },
                  icon: const Icon(Icons.gavel),
                  label: Text(
                    auction.isActive
                        ? 'View Live Auction'
                        : auction.isUpcoming
                        ? 'View Upcoming Auction'
                        : 'View Ended Auction',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppColors.primary!, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

            // No auction message
            if (auction == null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No auction available for this property',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeTag(PropertyType type) {
    final isPrimary = type == PropertyType.primary;
    final backgroundColor = isPrimary ? Colors.blue[100]! : Colors.purple[100]!;
    final borderColor = isPrimary ? Colors.blue[400]! : Colors.purple[400]!;
    final textColor = isPrimary ? Colors.blue[900]! : Colors.purple[900]!;
    final text = isPrimary ? 'Primary' : 'Resale';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPrimary ? Icons.new_releases : Icons.recycling,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
