import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../models/property.dart';
import '../models/property_type.dart';
import '../models/auction.dart';
import '../services/property_service.dart';
import '../services/auction_service.dart';
import '../widgets/property_image_carousel.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_search_bar.dart';

class PropertyComparisonPage extends StatefulWidget {
  final List<Property>? preSelectedProperties;

  const PropertyComparisonPage({super.key, this.preSelectedProperties});

  @override
  State<PropertyComparisonPage> createState() => _PropertyComparisonPageState();
}

class _PropertyComparisonPageState extends State<PropertyComparisonPage> {
  List<Property> selectedProperties = [];
  List<Property> allProperties = [];
  List<Property> filteredProperties = [];
  Map<String, Auction?> propertyAuctions =
      {}; // Store active auctions by propertyId
  bool isLoading = true;

  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _selectedTypeFilter = 'All';
  int _selectedBedrooms = 0; // 0 means all

  final List<String> _typeFilters = [
    'All',
    ...PropertyTypeX.orderedValues.map((type) => type.displayName),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedProperties != null) {
      selectedProperties = widget.preSelectedProperties!.take(5).toList();
    }
    _loadProperties();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    try {
      // Use public endpoint that doesn't require authentication
      final response = await PropertyService.getProperties();
      if (response.success && response.data != null) {
        setState(() {
          allProperties = response.data!;
          filteredProperties = allProperties;
          isLoading = false;
        });
        // Load auctions for selected properties
        await _loadAuctionsForSelectedProperties();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      filteredProperties = allProperties.where((property) {
        // Search filter
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch =
            searchQuery.isEmpty ||
            property.name.toLowerCase().contains(searchQuery) ||
            property.location.toLowerCase().contains(searchQuery) ||
            property.typeLabel.toLowerCase().contains(searchQuery);

        // Type filter
        final matchesType =
            _selectedTypeFilter == 'All' ||
            property.typeLabel == _selectedTypeFilter;

        // Bedrooms filter
        final matchesBedrooms =
            _selectedBedrooms == 0 || property.bedrooms == _selectedBedrooms;

        return matchesSearch && matchesType && matchesBedrooms;
      }).toList();
    });
  }

  Future<void> _loadAuctionsForSelectedProperties() async {
    for (var property in selectedProperties) {
      if (property.hasActiveAuction) {
        try {
          final response = await AuctionService.getAuctions();
          if (response.success && response.data != null) {
            final auction = response.data!.firstWhere(
              (a) =>
                  a.property?.propertyId == property.propertyId && a.isActive,
              orElse: () => response.data!.first, // fallback
            );
            setState(() {
              propertyAuctions[property.propertyId] = auction;
            });
          }
        } catch (e) {
          print(
            'Error loading auction for property ${property.propertyId}: $e',
          );
        }
      }
    }
  }

  void _addProperty(Property property) {
    if (selectedProperties.length < 5 &&
        !selectedProperties.contains(property)) {
      setState(() {
        selectedProperties.add(property);
      });
      // Load auction data for the newly added property
      _loadAuctionsForSelectedProperties();
    }
  }

  void _removeProperty(int index) {
    setState(() {
      selectedProperties.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Compare Properties',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'SF Pro Display',
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Selected Properties Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Selected: ${selectedProperties.length}/5 (Min: 2)',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ),
                if (selectedProperties.length >= 2)
                  ModernButton(
                    text: 'Compare',
                    type: ModernButtonType.primary,
                    onPressed: () => _showComparisonTable(),
                    icon: Icons.compare_arrows,
                  ),
              ],
            ),
          ),

          // Selected Properties Row
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                if (index < selectedProperties.length) {
                  final property = selectedProperties[index];
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _removeProperty(index),
                          child: ModernCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: property.imageUrl.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                property.imageUrl,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      color: AppColors.textTertiary,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    property.name,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize: 10,
                                          color: AppColors.textPrimary,
                                          fontFamily: 'SF Pro Text',
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                              onPressed: () => _removeProperty(index),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: ModernCard(
                      child: Center(
                        child: Icon(
                          Icons.add,
                          color: AppColors.textTertiary,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          const Divider(),

          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                ModernSearchBar(
                  controller: _searchController,
                  hintText: 'Search properties...',
                ),
                const SizedBox(height: 12),

                // Filters Row
                Row(
                  children: [
                    // Category Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTypeFilter,
                        decoration: InputDecoration(
                          labelText: 'Property Type',
                          labelStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontFamily: 'SF Pro Text',
                              ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontFamily: 'SF Pro Text',
                        ),
                        items: _typeFilters.map((typeLabel) {
                          return DropdownMenuItem<String>(
                            value: typeLabel,
                            child: Text(typeLabel),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedTypeFilter = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Bedrooms Filter
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedBedrooms,
                        decoration: InputDecoration(
                          labelText: 'Bedrooms',
                          labelStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontFamily: 'SF Pro Text',
                              ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontFamily: 'SF Pro Text',
                        ),
                        items: [
                          const DropdownMenuItem(value: 0, child: Text('All')),
                          const DropdownMenuItem(value: 1, child: Text('1')),
                          const DropdownMenuItem(value: 2, child: Text('2')),
                          const DropdownMenuItem(value: 3, child: Text('3')),
                          const DropdownMenuItem(value: 4, child: Text('4')),
                          const DropdownMenuItem(value: 5, child: Text('5+')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedBedrooms = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Available Properties List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProperties.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No properties found',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'SF Pro Display',
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textTertiary,
                                fontFamily: 'SF Pro Text',
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredProperties.length,
                    itemBuilder: (context, index) {
                      final property = filteredProperties[index];
                      final isSelected = selectedProperties.contains(property);
                      final canAdd = selectedProperties.length < 5;

                      return ModernCard(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              image: property.imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(property.imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: AppColors.textTertiary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          title: Text(
                            property.name,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'SF Pro Text',
                                ),
                          ),
                          subtitle: Text(
                            '${property.bedrooms} bed • ${property.bathrooms} bath • ${property.typeLabel}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontFamily: 'SF Pro Text',
                                ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                )
                              : canAdd
                              ? IconButton(
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () => _addProperty(property),
                                )
                              : null,
                          enabled: !isSelected && canAdd,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showComparisonTable() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Property Comparison',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: _buildComparisonTable(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildComparisonTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Images Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const SizedBox(width: 120), // Space for labels column
                ...selectedProperties.map((property) {
                  return Container(
                    width:
                        170, // 150 + 20 for spacing to match DataTable columnSpacing
                    height: 120,
                    alignment: Alignment.center,
                    child: Container(
                      width: 150,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: PropertyImageCarousel(
                          images: property.propertyImages,
                          fallbackImageUrl: property.imageUrl,
                          height: 120,
                          showIndicators: false,
                          showNavigationButtons: false,
                          showImageCounter: false,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Data Table
          DataTable(
            columnSpacing: 20,
            headingRowColor: MaterialStateProperty.all(AppColors.background),
            dataRowColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return AppColors.primary.withOpacity(0.1);
              }
              return null;
            }),
            columns: [
              DataColumn(
                label: SizedBox(
                  width: 120,
                  child: Text(
                    'Feature',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ),
              ),
              ...selectedProperties.map(
                (p) => DataColumn(
                  label: SizedBox(
                    width: 150,
                    child: Text(
                      'Property ${selectedProperties.indexOf(p) + 1}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'SF Pro Text',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
            rows: _buildComparisonRows(),
          ),
        ],
      ),
    );
  }

  List<DataRow> _buildComparisonRows() {
    final rows = [
      {
        'label': 'Bedrooms',
        'values': selectedProperties.map((p) => '${p.bedrooms}').toList(),
      },
      {
        'label': 'Bathrooms',
        'values': selectedProperties.map((p) => '${p.bathrooms}').toList(),
      },
      {
        'label': 'Square Feet',
        'values': selectedProperties
            .map((p) => '${p.squareFeet} sqft')
            .toList(),
      },
      {
        'label': 'Year Built',
        'values': selectedProperties.map((p) => '${p.yearBuilt}').toList(),
      },
      {
        'label': 'Type',
        'values': selectedProperties.map((p) => p.typeLabel).toList(),
      },
    ];

    return rows.map((row) {
      final values = (row['values'] as List).cast<String>();
      return DataRow(
        cells: [
          DataCell(
            SizedBox(
              width: 120,
              child: Text(
                row['label'] as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ),
          ),
          ...values.map(
            (value) => DataCell(
              SizedBox(
                width: 150,
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }).toList();
  }
}
