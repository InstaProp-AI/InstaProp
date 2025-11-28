import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../models/property.dart';
import '../models/auction.dart';
import '../services/property_service.dart';
import '../services/auction_service.dart';
import '../widgets/property_image_carousel.dart';
import 'property_comparison_page.dart';
import 'property_details_page.dart';
import 'auction_details_page.dart';
import 'projects_list_page.dart';
import 'developers_list_page.dart';

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
  Map<String, Auction> _propertyAuctionMap = {}; // Map propertyId to auction
  bool _isLoading = true;

  // Served/Suggested Searches
  final List<Map<String, dynamic>> _servedSearches = [
    {
      'title': 'Luxury Apartments in New Cairo',
      'subtitle': 'Handpicked apartments with premium amenities',
      'filters': {'type': 'Apartment', 'location': 'Waterfront'},
      'icon': Icons.apartment,
    },
    {
      'title': 'Budget Family Homes',
      'subtitle': 'Affordable townhouses with good schools nearby',
      'filters': {'type': 'Townhouse', 'priceMax': 300000},
      'icon': Icons.family_restroom,
    },
    {
      'title': 'Downtown Studios',
      'subtitle': 'Perfect for young professionals',
      'filters': {'type': 'Studio', 'location': 'Downtown'},
      'icon': Icons.business,
    },
    {
      'title': 'Commercial Spaces',
      'subtitle': 'Retail, clinic, and office spaces in key areas',
      'filters': {'type': 'Commercial'},
      'icon': Icons.store,
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
              property.location.toLowerCase().contains(searchLower) ||
              property.typeLabel.toLowerCase().contains(searchLower) ||
              (property.project ?? '').toLowerCase().contains(searchLower);
        }).toList();
      }
    });
  }

  void _applyServedSearch(Map<String, dynamic> filters) {
    setState(() {
      _filteredProperties = _allProperties.where((property) {
        bool matches = true;

        if (filters.containsKey('type')) {
          matches = matches && property.typeLabel == filters['type'];
        }

        if (filters.containsKey('location')) {
          matches =
              matches && property.location.contains(filters['location']);
        }

        if (filters.containsKey('status')) {
          matches = matches && property.status == filters['status'];
        }

        return matches;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Minimal Clean Header
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: const Text(
                'Properties',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name, location, type...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey[500],
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _performSearch('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.3,
                        ),
                        onChanged: _performSearch,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Reset Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                      icon: Icon(
                        Icons.refresh,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      tooltip: 'Reset Search',
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Served Searches Section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Popular Searches',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
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
          ),

          // Results Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Text(
                    'Results: ${_filteredProperties.length}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  if (_filteredProperties.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_filteredProperties.length} found',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Properties List
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _filteredProperties.isEmpty
                ? _buildEmptyState()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: _filteredProperties.map((property) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPropertyCard(property),
                        );
                      }).toList(),
                    ),
                  ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Projects Button
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProjectsListPage(),
                      ),
                    );
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  icon: Icon(
                    Icons.apartment,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  label: Text(
                    'Projects',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                  heroTag: 'projects_button',
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Compare Button (square)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
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
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(
                  Icons.compare_arrows,
                  color: Colors.white,
                  size: 20,
                ),
                heroTag: 'compare_button_properties',
              ),
            ),
            const SizedBox(width: 12),
            // Developers Button
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DevelopersListPage(),
                      ),
                    );
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  icon: Icon(Icons.people, color: AppColors.primary, size: 20),
                  label: Text(
                    'Developers',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                  heroTag: 'developers_button',
                ),
              ),
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
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(search['icon'], color: AppColors.primary, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                search['title'],
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _handlePropertyTap(property),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image with auction badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: PropertyImageCarousel(
                    images: property.propertyImages,
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
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: auction.isUpcoming
                            ? Colors.blue
                            : (auction.isActive
                                  ? AppColors.success
                                  : Colors.orange),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
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
                          const SizedBox(width: 6),
                          Text(
                            auction.isUpcoming
                                ? 'UPCOMING'
                                : (auction.isActive ? 'LIVE' : 'ENDED'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property name
                  Text(
                    property.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Tags row
                  Row(
                    children: [
                      // Property Type Tag (Primary/Resale)
                      _buildPropertyTypeTag(property.listingType),
                      const SizedBox(width: 8),

                      // Category Tag
                      if (property.typeLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            property.typeLabel,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (property.location.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
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
                    const SizedBox(height: 8),
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
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
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
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text(
              'No Properties Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your search criteria',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
                      builder: (context) => PropertyDetailsPage(
                        propertyId: property.propertyId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.insights),
                label: const Text('View Details'),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.primary, width: 2),
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
                    side: const BorderSide(color: AppColors.primary, width: 2),
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

  Widget _buildPropertyTypeTag(ListingType listingType) {
    final isPrimary = listingType == ListingType.primary;
    final backgroundColor = isPrimary
        ? AppColors.primary.withOpacity(0.1)
        : Colors.purple.withOpacity(0.1);
    final borderColor = isPrimary
        ? AppColors.primary.withOpacity(0.3)
        : Colors.purple.withOpacity(0.3);
    final textColor = isPrimary ? AppColors.primary : Colors.purple[700]!;
    final text = isPrimary ? 'Primary' : 'Resale';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPrimary ? Icons.new_releases : Icons.recycling,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
