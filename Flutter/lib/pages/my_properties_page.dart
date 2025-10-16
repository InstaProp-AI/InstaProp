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
import 'property_docs_upload_page.dart';
import 'payment_schedule_scanner_dialog.dart';
import '../services/event_service.dart';
import '../services/property_financials_service.dart';
import '../models/event.dart';
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
      appBar: AppBar(
        title: const Text('My Properties'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.loadingProperties) {
            return const Center(child: CircularProgressIndicator());
          }

          final userProperties = appState.userProperties;

          if (userProperties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_outlined,
                    size: 80,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Properties Yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first property to get started',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddPropertyPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Property'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await appState.loadProperties();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: userProperties.length,
              itemBuilder: (context, index) {
                final property = userProperties[index];
                return PropertyCard(
                  property: property,
                  onRequestAuction: () => _requestAuction(property),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPropertyPage()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.surface),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Image Carousel
          PropertyImageCarousel(
            images: property.propertyImages,
            fallbackImageUrl: property.imageUrl,
            height: 200,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusChip(),
                  ],
                ),

                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.location,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Property Details
                Row(
                  children: [
                    _buildDetailChip(Icons.bed, '${property.bedrooms}'),
                    const SizedBox(width: 8),
                    _buildDetailChip(Icons.bathtub, '${property.bathrooms}'),
                    const SizedBox(width: 8),
                    _buildDetailChip(
                      Icons.square_foot,
                      '${property.squareFeet}',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action Buttons - Row 1
                Row(
                  children: [
                    // Edit Button - Small button always visible
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleEdit(context, property),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Delete Button - Small button always visible
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleDelete(context, property),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text(
                          'Delete',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),

                    // Documents Button - Only visible for non-approved properties
                    if (!property.isApproved) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PropertyDocsUploadPage(
                                  propertyId: property.propertyId,
                                  propertyName: property.name,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: const Text(
                            'Docs',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Action Buttons - Row 2 (Auction button if approved)
                if (property.isApproved) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRequestAuction,
                      icon: const Icon(Icons.gavel, size: 18),
                      label: const Text(
                        'Request Auction',
                        style: TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (context) => PaymentScheduleScannerDialog(
                            initialProperty: property,
                          ),
                        );
                      },
                      icon: const Icon(Icons.event_available, size: 18),
                      label: const Text(
                        'Add Payment Schedule',
                        style: TextStyle(fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],

                // Payment Installments Card
                const SizedBox(height: 16),
                PropertyInstallmentsCard(
                  propertyId: property.propertyId,
                  onPaymentMade: () {
                    // Refresh property data when payment is made
                    context.read<AppState>().loadProperties();
                  },
                ),

                if (!property.isApproved)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.secondary),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Property pending admin verification',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (property.isApproved)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Property verified - documents and details are locked',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),
                // Payments & Financials quick view
                FutureBuilder(
                  future: Future.wait([
                    EventService.getEventsByProperty(property.propertyId),
                    PropertyFinancialsService.getFinancials(
                      property.propertyId,
                    ),
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final eventsResp =
                        snapshot.data![0] as ApiResponse<List<Event>>;
                    final finResp =
                        snapshot.data![1] as ApiResponse<PropertyFinancials>;
                    if (!eventsResp.success ||
                        !finResp.success ||
                        eventsResp.data == null ||
                        finResp.data == null) {
                      return const SizedBox.shrink();
                    }

                    final payments =
                        eventsResp.data!
                            .where((e) => e.type == EventType.installment)
                            .toList()
                          ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
                    final fin = finResp.data!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payments & Financials',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.secondary),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _miniStat(
                                    'Paid',
                                    '\$${fin.paidSoFar.toStringAsFixed(0)}',
                                  ),
                                  _miniStat(
                                    'Remaining',
                                    '\$${fin.remainingToPay.toStringAsFixed(0)}',
                                  ),
                                  _miniStat(
                                    'Total',
                                    '\$${fin.sumInstallments.toStringAsFixed(0)}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (fin.roiPercent != null)
                                Row(
                                  children: [
                                    _miniStat(
                                      'ROI',
                                      '${fin.roiPercent!.toStringAsFixed(1)}%',
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Upcoming Installments',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...payments
                                  .where(
                                    (e) =>
                                        !e.isCompleted &&
                                        e.eventDate.isAfter(
                                          DateTime.now().subtract(
                                            const Duration(days: 1),
                                          ),
                                        ),
                                  )
                                  .take(3)
                                  .map(
                                    (e) => Row(
                                      children: [
                                        const Icon(
                                          Icons.event,
                                          size: 14,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${e.eventDate.year}-${e.eventDate.month.toString().padLeft(2, '0')}-${e.eventDate.day.toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          e.amount != null
                                              ? '\$${e.amount!.toStringAsFixed(0)}'
                                              : '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      // Run valuation then refresh
                                      if (!context.mounted) return;
                                      Navigator.pushNamed(context, '/valuate');
                                    },
                                    icon: const Icon(
                                      Icons.assessment,
                                      size: 16,
                                    ),
                                    label: const Text('Run Valuation'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () async {
                                      await showDialog(
                                        context: context,
                                        builder: (context) =>
                                            PaymentScheduleScannerDialog(
                                              initialProperty: property,
                                            ),
                                      );
                                      if (context.mounted) {
                                        context
                                            .read<AppState>()
                                            .loadProperties();
                                      }
                                    },
                                    child: const Text('Add/Update Schedule'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String text;

    if (property.isApproved) {
      backgroundColor = AppColors.background;
      textColor = Colors.green[800]!;
      text = 'Verified';
    } else {
      backgroundColor = Colors.orange[100]!;
      textColor = Colors.orange[800]!;
      text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: AppColors.primary, fontSize: 12)),
        ],
      ),
    );
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
  final _buyNowPriceController = TextEditingController();
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
    _buyNowPriceController.dispose();
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
        buyNowPrice: _buyNowPriceController.text.isNotEmpty
            ? double.parse(_buyNowPriceController.text)
            : null,
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
                  TextFormField(
                    controller: _buyNowPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Buy Now Price (Optional)',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isNotEmpty == true) {
                        if (double.tryParse(value!) == null)
                          return 'Invalid price';
                        if (double.parse(value) <= 0)
                          return 'Price must be greater than 0';
                      }
                      return null;
                    },
                  ),

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
