import 'package:flutter/material.dart';
import '../models/egyptian_filters.dart';
import '../../theme/app_colors.dart';
import '../data/egyptian_projects.dart';

/// Egyptian-specific property and auction filter dialog
/// Designed for the Egyptian real estate market
class EgyptianFilterDialog extends StatefulWidget {
  final EgyptianPropertyFilters? initialFilters;
  final Function(EgyptianPropertyFilters) onApply;
  final bool isAuctionFilter;

  const EgyptianFilterDialog({
    Key? key,
    this.initialFilters,
    required this.onApply,
    this.isAuctionFilter = false,
  }) : super(key: key);

  @override
  State<EgyptianFilterDialog> createState() => _EgyptianFilterDialogState();
}

class _EgyptianFilterDialogState extends State<EgyptianFilterDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late EgyptianPropertyFilters _filters;

  // Controllers for text inputs
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _minAreaController = TextEditingController();
  final _maxAreaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _filters = widget.initialFilters ?? EgyptianPropertyFilters();
    _initializeControllers();
  }

  void _initializeControllers() {
    _searchController.text = _filters.searchTerm ?? '';
    _minPriceController.text = _filters.minPrice?.toString() ?? '';
    _maxPriceController.text = _filters.maxPrice?.toString() ?? '';
    _minAreaController.text = _filters.minArea?.toString() ?? '';
    _maxAreaController.text = _filters.maxArea?.toString() ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minAreaController.dispose();
    _maxAreaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Egyptian Property Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              color: AppColors.background,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Location', icon: Icon(Icons.location_on)),
                  Tab(text: 'Property', icon: Icon(Icons.home)),
                  Tab(text: 'Price & Size', icon: Icon(Icons.attach_money)),
                  Tab(text: 'Features', icon: Icon(Icons.star)),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLocationTab(),
                  _buildPropertyTab(),
                  _buildPriceSizeTab(),
                  _buildFeaturesTab(),
                ],
              ),
            ),
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetFilters,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Reset',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(color: Colors.white),
                      ),
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

  Widget _buildLocationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Properties',
              hintText: 'Enter property name, location, or developer',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) =>
                _filters = _filters.copyWith(searchTerm: value),
          ),
          const SizedBox(height: 20),
          // Governorate
          _buildDropdown(
            'Governorate',
            _filters.governorate,
            EgyptianLocations.allGovernorates,
            (value) => _filters = _filters.copyWith(governorate: value),
          ),
          const SizedBox(height: 16),
          // District
          _buildDropdown(
            'District',
            _filters.district,
            EgyptianLocations.allDistricts,
            (value) => _filters = _filters.copyWith(district: value),
          ),
          const SizedBox(height: 16),
          // Area
          TextField(
            decoration: InputDecoration(
              labelText: 'Specific Area',
              hintText: 'e.g., New Cairo, Maadi, Zamalek',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => _filters = _filters.copyWith(area: value),
          ),
          const SizedBox(height: 16),
          // Project Selection
          _buildDropdown(
            'Project',
            _filters.projectName,
            EgyptianProjects.allProjectNames,
            (value) => _filters = _filters.copyWith(projectName: value),
          ),
          const SizedBox(height: 20),
          // Nearby Amenities
          Text(
            'Nearby Amenities',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildCheckboxList(
            [
              'Near Metro Station',
              'Near Shopping Mall',
              'Near International School',
              'Near Hospital',
            ],
            [
              _filters.nearMetro,
              _filters.nearMall,
              _filters.nearSchool,
              _filters.nearHospital,
            ],
            [
              (value) => _filters = _filters.copyWith(nearMetro: value),
              (value) => _filters = _filters.copyWith(nearMall: value),
              (value) => _filters = _filters.copyWith(nearSchool: value),
              (value) => _filters = _filters.copyWith(nearHospital: value),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Category
          _buildDropdown(
            'Property Type',
            _filters.propertyCategory,
            EgyptianPropertyCategories.all,
            (value) => _filters = _filters.copyWith(propertyCategory: value),
          ),
          const SizedBox(height: 16),
          // Property Sub Category
          _buildDropdown(
            'Property Sub Type',
            _filters.propertySubCategory,
            [
              'Duplex',
              'Triplex',
              'Garden Apartment',
              'Ground Floor',
              'Roof Apartment',
            ],
            (value) => _filters = _filters.copyWith(propertySubCategory: value),
          ),
          const SizedBox(height: 20),
          // Size Filters
          Text(
            'Size (Square Meters)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minAreaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Min Area',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    final area = int.tryParse(value);
                    _filters = _filters.copyWith(minArea: area);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxAreaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max Area',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    final area = int.tryParse(value);
                    _filters = _filters.copyWith(maxArea: area);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bedrooms & Bathrooms
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Min Bedrooms',
                  _filters.minBedrooms?.toString(),
                  List.generate(6, (index) => index.toString()),
                  (value) => _filters = _filters.copyWith(
                    minBedrooms: int.tryParse(value ?? ''),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  'Max Bedrooms',
                  _filters.maxBedrooms?.toString(),
                  List.generate(6, (index) => index.toString()),
                  (value) => _filters = _filters.copyWith(
                    maxBedrooms: int.tryParse(value ?? ''),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Min Bathrooms',
                  _filters.minBathrooms?.toString(),
                  List.generate(6, (index) => index.toString()),
                  (value) => _filters = _filters.copyWith(
                    minBathrooms: int.tryParse(value ?? ''),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  'Max Bathrooms',
                  _filters.maxBathrooms?.toString(),
                  List.generate(6, (index) => index.toString()),
                  (value) => _filters = _filters.copyWith(
                    maxBathrooms: int.tryParse(value ?? ''),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Property Age
          _buildDropdown(
            'Property Age',
            _filters.propertyAge,
            [
              'New (0-2 years)',
              'Recent (2-10 years)',
              'Old (10+ years)',
              'Heritage (50+ years)',
            ],
            (value) {
              String? age;
              switch (value) {
                case 'New (0-2 years)':
                  age = 'new';
                  break;
                case 'Recent (2-10 years)':
                  age = 'recent';
                  break;
                case 'Old (10+ years)':
                  age = 'old';
                  break;
                case 'Heritage (50+ years)':
                  age = 'heritage';
                  break;
              }
              _filters = _filters.copyWith(propertyAge: age);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSizeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price Range
          Text(
            'Price Range (EGP)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDropdown(
            'Price Range',
            _filters.priceRange,
            EgyptianPriceRanges.all,
            (value) => _filters = _filters.copyWith(priceRange: value),
          ),
          const SizedBox(height: 16),
          // Custom Price Range
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Min Price (EGP)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    final price = double.tryParse(value);
                    _filters = _filters.copyWith(minPrice: price);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max Price (EGP)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    final price = double.tryParse(value);
                    _filters = _filters.copyWith(maxPrice: price);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Developer
          TextField(
            decoration: InputDecoration(
              labelText: 'Developer Name',
              hintText: 'e.g., Talaat Moustafa, Emaar, SODIC',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) =>
                _filters = _filters.copyWith(developerName: value),
          ),
          const SizedBox(height: 16),
          // Project
          TextField(
            decoration: InputDecoration(
              labelText: 'Project Name',
              hintText: 'e.g., Madinaty, New Capital, Palm Hills',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) =>
                _filters = _filters.copyWith(projectName: value),
          ),
          const SizedBox(height: 16),
          // Project Type
          _buildDropdown(
            'Project Type',
            _filters.projectType,
            EgyptianProjects.allTypes,
            (value) => _filters = _filters.copyWith(projectType: value),
          ),
          const SizedBox(height: 20),
          // Sorting
          _buildDropdown(
            'Sort By',
            _filters.sortBy,
            EgyptianPropertySorting.sortOptions
                .map((e) => e['value']!)
                .toList(),
            (value) => _filters = _filters.copyWith(sortBy: value),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Furnishing
          Text(
            'Furnishing',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildCheckboxList(['Fully Furnished'], [_filters.furnished], [
            (value) => _filters = _filters.copyWith(furnished: value),
          ]),
          const SizedBox(height: 20),
          // Property Features
          Text(
            'Property Features',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildCheckboxList(
            [
              'Balcony',
              'Garden',
              'Swimming Pool',
              'Gym',
              'Security',
              'Parking',
            ],
            [
              _filters.hasBalcony,
              _filters.hasGarden,
              _filters.hasPool,
              _filters.hasGym,
              _filters.hasSecurity,
              _filters.hasParking,
            ],
            [
              (value) => _filters = _filters.copyWith(hasBalcony: value),
              (value) => _filters = _filters.copyWith(hasGarden: value),
              (value) => _filters = _filters.copyWith(hasPool: value),
              (value) => _filters = _filters.copyWith(hasGym: value),
              (value) => _filters = _filters.copyWith(hasSecurity: value),
              (value) => _filters = _filters.copyWith(hasParking: value),
            ],
          ),
          const SizedBox(height: 20),
          // Special Views
          Text(
            'Special Views',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildCheckboxList(
            ['Sea View', 'Nile View', 'Pyramid View'],
            [
              _filters.hasSeaView,
              _filters.hasNileView,
              _filters.hasPyramidView,
            ],
            [
              (value) => _filters = _filters.copyWith(hasSeaView: value),
              (value) => _filters = _filters.copyWith(hasNileView: value),
              (value) => _filters = _filters.copyWith(hasPyramidView: value),
            ],
          ),
          const SizedBox(height: 20),
          // Community Type
          Text(
            'Community Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildCheckboxList(
            [
              'Gated Community',
              'Residential Compound',
              'Investment Property',
              'Residential Property',
            ],
            [
              _filters.isGatedCommunity,
              _filters.isCompound,
              _filters.isInvestment,
              _filters.isResidential,
            ],
            [
              (value) => _filters = _filters.copyWith(isGatedCommunity: value),
              (value) => _filters = _filters.copyWith(isCompound: value),
              (value) => _filters = _filters.copyWith(isInvestment: value),
              (value) => _filters = _filters.copyWith(isResidential: value),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: [
        DropdownMenuItem<String>(value: null, child: Text('Any $label')),
        ...options.map(
          (option) =>
              DropdownMenuItem<String>(value: option, child: Text(option)),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildCheckboxList(
    List<String> labels,
    List<bool?> values,
    List<Function(bool?)> onChanged,
  ) {
    return Column(
      children: List.generate(labels.length, (index) {
        return CheckboxListTile(
          title: Text(labels[index]),
          value: values[index] ?? false,
          onChanged: (value) => onChanged[index](value),
          activeColor: AppColors.primary,
        );
      }),
    );
  }

  void _resetFilters() {
    setState(() {
      _filters = EgyptianPropertyFilters();
      _initializeControllers();
    });
  }

  void _applyFilters() {
    widget.onApply(_filters);
    Navigator.of(context).pop();
  }
}
