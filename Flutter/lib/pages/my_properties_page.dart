import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/property.dart';
import '../models/auction_request.dart';
import '../widgets/loading_button.dart';
import '../services/auction_service.dart';
import 'add_property_page.dart';
import 'edit_property_page.dart';

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
          // Property Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                property.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.background,
                    child: const Icon(Icons.home, size: 50, color: Colors.grey),
                  );
                },
              ),
            ),
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

                // Action Buttons
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
                          side: BorderSide(color: AppColors.primary!),
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
                          side: BorderSide(color: AppColors.primary!),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),

                    if (property.isApproved) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: onRequestAuction,
                          icon: const Icon(Icons.gavel, size: 16),
                          label: const Text(
                            'Auction',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.surface,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                if (!property.isApproved)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.secondary!),
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

                if (property.isApproved && !property.isEditable)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Property verified and locked',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
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
      backgroundColor = AppColors.background!;
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

  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startPriceController.text = '';
    _durationController.text = '168'; // 7 days in hours
  }

  @override
  void dispose() {
    _startPriceController.dispose();
    _buyNowPriceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final request = AuctionRequest(
        propertyId: widget.property.propertyId,
        startPrice: double.parse(_startPriceController.text),
        startAt: _endDate,
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
        child: Form(
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                  if (double.tryParse(value!) == null) return 'Invalid price';
                  return null;
                },
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
                  if (value?.isNotEmpty == true &&
                      double.tryParse(value!) == null) {
                    return 'Invalid price';
                  }
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
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Duration is required';
                  if (int.tryParse(value!) == null) return 'Invalid duration';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // End Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _endDate = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_endDate.toString().split(' ')[0]),
                ),
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
        ),
      ),
    );
  }
}
