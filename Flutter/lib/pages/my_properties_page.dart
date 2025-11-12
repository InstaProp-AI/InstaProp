import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/property.dart';
import '../models/auction_request.dart';
import '../widgets/loading_button.dart';
import '../widgets/property_image_carousel.dart';
import '../services/auction_service.dart';
import 'add_property_page.dart';
import 'edit_property_page.dart';
import '../services/property_financials_service.dart';
import '../services/api_client.dart';
import '../widgets/property_installments_card.dart';

class MyPropertiesPage extends StatefulWidget {
  const MyPropertiesPage({super.key});

  @override
  State<MyPropertiesPage> createState() => _MyPropertiesPageState();
}

class _MyPropertiesPageState extends State<MyPropertiesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadProperties();
    });
  }

  Future<void> _requestAuction(Property property) async {
    if (!property.canRequestAuction) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Property must be approved before requesting an auction',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if property already has an active auction
    if (property.hasActiveAuction) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.gavel, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Already in Auction'),
            ],
          ),
          content: const Text(
            'This property already has an active auction. You cannot request another auction while one is in progress.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AuctionRequestDialog(property: property),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return CustomScrollView(
            slivers: [
              // Minimal Clean Header
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: Colors.white,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'My Properties',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your property portfolio',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[600],
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  title: const Text(
                    'My Properties',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Color(0xFF1A1A1A)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddPropertyPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    if (appState.loadingProperties)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (appState.userProperties.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.home_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'No Properties Yet',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Add your first property to get started',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  letterSpacing: -0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AddPropertyPage(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add, size: 22),
                                      SizedBox(width: 12),
                                      Text(
                                        'Add Property',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Properties List
                            ...appState.userProperties.map(
                              (property) => Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: PropertyCard(
                                  property: property,
                                  onRequestAuction: () =>
                                      _requestAuction(property),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 100,
                            ), // Space for bottom navigation
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onRequestAuction;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onRequestAuction,
  });

  void _handleEdit(BuildContext context, Property property) {
    if (property.isApproved) {
      // Show popup - property is verified
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lock, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Cannot Edit'),
            ],
          ),
          content: const Text(
            'Property is already verified and cannot be edited. Please contact the support team if you need to make changes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Navigate to edit page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditPropertyPage(property: property),
        ),
      );
    }
  }

  void _handleDelete(BuildContext context, Property property) {
    // Check if property is in auction
    if (property.hasActiveAuction) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.gavel, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Cannot Delete'),
            ],
          ),
          content: const Text(
            'This property is currently in auction and cannot be deleted. Please wait for the auction to complete or cancel it first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Delete Property'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${property.name}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _deleteProperty(context, property);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProperty(BuildContext context, Property property) async {
    try {
      final appState = context.read<AppState>();
      final response = await appState.deleteProperty(property.propertyId);

      if (context.mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Property deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload properties
          appState.loadProperties();
        } else {
          // Check if it's an auction error
          final errorMessage = response.error ?? 'Failed to delete property';
          final isAuctionError = errorMessage.toLowerCase().contains('auction');

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    isAuctionError ? Icons.gavel : Icons.error,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Cannot Delete'),
                ],
              ),
              content: Text(
                isAuctionError
                    ? 'This property is currently in auction and cannot be deleted. Please wait for the auction to complete or cancel it first.'
                    : errorMessage,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
          // Property Image Carousel
          PropertyImageCarousel(
            images: property.propertyImages,
            fallbackImageUrl: property.imageUrl,
            height: 240,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Name and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        property.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(),
                  ],
                ),

                const SizedBox(height: 12),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.location,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Property Details
                Row(
                  children: [
                    _buildDetailChip(
                      Icons.bed_outlined,
                      '${property.bedrooms} bed',
                    ),
                    const SizedBox(width: 8),
                    _buildDetailChip(
                      Icons.bathtub_outlined,
                      '${property.bathrooms} bath',
                    ),
                    const SizedBox(width: 8),
                    _buildDetailChip(
                      Icons.square_foot_outlined,
                      '${property.squareFeet} sqft',
                    ),
                  ],
                ),

              if (property.installmentSummary != null) ...[
                const SizedBox(height: 16),
                _buildInstallmentSnapshotSection(),
              ],

                const SizedBox(height: 20),

                // Financials Summary
                FutureBuilder<ApiResponse<PropertyFinancials>>(
                  future: PropertyFinancialsService.getFinancials(
                    property.propertyId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasData &&
                        snapshot.data!.success &&
                        snapshot.data!.data != null) {
                      final fin = snapshot.data!.data!;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Financial Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildFinancialStat(
                                  'Paid',
                                  '\$${_formatNumber(fin.paidSoFar)}',
                                  Colors.green,
                                ),
                                _buildFinancialStat(
                                  'Remaining',
                                  '\$${_formatNumber(fin.remainingToPay)}',
                                  Colors.orange,
                                ),
                                if (fin.roiPercent != null)
                                  _buildFinancialStat(
                                    'ROI',
                                    '${fin.roiPercent!.toStringAsFixed(1)}%',
                                    fin.roiPercent! >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleEdit(context, property),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A1A1A),
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleDelete(context, property),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                            color: AppColors.error.withOpacity(0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (property.isApproved) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
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
                    child: ElevatedButton(
                      onPressed: onRequestAuction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gavel, size: 20),
                          SizedBox(width: 8),
                          Text('Request Auction'),
                        ],
                      ),
                    ),
                  ),
                ],

                // Payment Installments Card
                const SizedBox(height: 16),
                PropertyInstallmentsCard(
                  propertyId: property.propertyId,
                  summary: property.installmentSummary,
                  onPaymentMade: () {
                    context.read<AppState>().loadProperties();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentSnapshotSection() {
    final summary = property.installmentSummary!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Installment Snapshot',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildFinancialStat(
                'Contract',
                '\$${_formatNumber(summary.contractedPrice)}',
                AppColors.primary ?? Colors.blueAccent,
              ),
              _buildFinancialStat(
                'Paid',
                '\$${_formatNumber(summary.totalPaid)}',
                Colors.green,
              ),
              _buildFinancialStat(
                'Remaining',
                '\$${_formatNumber(summary.remainingBalance)}',
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (summary.downPaymentPercent > 0)
                _buildDetailChip(
                  Icons.payments_outlined,
                  'Down ${summary.downPaymentPercent.toStringAsFixed(1)}%',
                ),
              if (summary.termYears != null)
                _buildDetailChip(
                  Icons.schedule,
                  '${summary.termYears} year plan',
                ),
              if (summary.installmentEndDate != null)
                _buildDetailChip(
                  Icons.event,
                  'Ends ${summary.installmentEndDate!.year}',
                ),
              _buildDetailChip(
                summary.isFullyPaid ? Icons.verified : Icons.timelapse,
                summary.isFullyPaid ? 'Fully paid' : 'Outstanding',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final isApproved = property.isApproved;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isApproved
            ? AppColors.success.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApproved ? Icons.verified : Icons.schedule,
            size: 14,
            color: isApproved ? AppColors.success : Colors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            isApproved ? 'Verified' : 'Pending',
            style: TextStyle(
              color: isApproved ? AppColors.success : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }
}

class AuctionRequestDialog extends StatefulWidget {
  final Property property;

  const AuctionRequestDialog({super.key, required this.property});

  @override
  State<AuctionRequestDialog> createState() => _AuctionRequestDialogState();
}

class _AuctionRequestDialogState extends State<AuctionRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _startPriceController = TextEditingController();
  final _durationController = TextEditingController();

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 24));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startPriceController.text = '';
    _durationController.text = '24'; // 24 hours default
    _updateEndDate();
  }

  @override
  void dispose() {
    _startPriceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _updateEndDate() {
    final duration = int.tryParse(_durationController.text) ?? 24;
    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    setState(() {
      _endDate = startDateTime.add(Duration(hours: duration));
    });
  }

  DateTime _getFullStartDateTime() {
    return DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
  }

  Future<void> _submitRequest() async {
    // Check if user is verified
    final appState = context.read<AppState>();
    if (appState.user == null || !appState.user!.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be verified to create auction requests'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = AuctionRequest(
        propertyId: widget.property.propertyId,
        startPrice: double.parse(_startPriceController.text),
        startAt: _getFullStartDateTime(),
        duration: int.parse(_durationController.text),
      );

      final response = await AuctionService.requestAuction(request);

      if (mounted) {
        if (response.success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auction request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload properties to update auction status
          appState.loadProperties();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.error ?? 'Failed to submit auction request',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Consumer<AppState>(
          builder: (context, appState, child) {
            // Check if user is verified - show warning if not
            if (appState.user == null || !appState.user!.isVerified) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.gavel, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Start Auction',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.secondary),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.verified_user,
                          color: AppColors.primary,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Account Not Verified',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You need to verify your account to create auction requests. Please upload your verification documents from your profile.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushNamed('/profile');
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Go to Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.surface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // User is verified - show the form
            return Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.gavel, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Start Auction',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    widget.property.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.property.location,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
                  ),

                  const SizedBox(height: 24),

                  // Start Price
                  TextFormField(
                    controller: _startPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Starting Price',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty == true)
                        return 'Starting price is required';
                      if (double.tryParse(value!) == null)
                        return 'Invalid price';
                      if (double.parse(value) <= 0)
                        return 'Price must be greater than 0';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Duration
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (Hours)',
                      suffixText: 'hours',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 24, 48, 72',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateEndDate(),
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Duration is required';
                      final duration = int.tryParse(value!);
                      if (duration == null || duration <= 0)
                        return 'Invalid duration';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Start Date and Time
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                                _updateEndDate();
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _startTime,
                            );
                            if (time != null) {
                              setState(() {
                                _startTime = time;
                                _updateEndDate();
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Time',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.access_time),
                            ),
                            child: Text(
                              '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // End Date (read-only, auto-calculated)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date & Time (calculated)',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.event),
                    ),
                    child: Text(
                      '${_endDate.day}/${_endDate.month}/${_endDate.year} at ${_endDate.hour.toString().padLeft(2, '0')}:${_endDate.minute.toString().padLeft(2, '0')}',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Buy Now Price (Optional)
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: LoadingButton(
                      onPressed: _isLoading ? null : _submitRequest,
                      isLoading: _isLoading,
                      child: const Text('Submit Request'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
