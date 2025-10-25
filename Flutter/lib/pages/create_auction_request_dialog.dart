import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auction_request.dart';
import '../models/property.dart';
import '../services/auction_request_service.dart';
import '../providers/app_state.dart';

class CreateAuctionRequestDialog extends StatefulWidget {
  const CreateAuctionRequestDialog({super.key});

  @override
  State<CreateAuctionRequestDialog> createState() =>
      _CreateAuctionRequestDialogState();
}

class _CreateAuctionRequestDialogState
    extends State<CreateAuctionRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _auctionRequestService = AuctionRequestService();

  Property? _selectedProperty;
  final _startingPriceController = TextEditingController();
  final _durationController = TextEditingController(text: '24');
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 24));
  bool _isLoading = false;

  @override
  void dispose() {
    _startingPriceController.dispose();
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

    if (!_formKey.currentState!.validate() || _selectedProperty == null) {
      print('❌ Form validation failed or no property selected');
      return;
    }

    print('✅ Form validation passed, submitting request...');

    setState(() {
      _isLoading = true;
    });

    try {
      final request = AuctionRequest(
        propertyId: _selectedProperty!.propertyId,
        startPrice: double.parse(_startingPriceController.text),
        startAt: _getFullStartDateTime(),
        duration: int.parse(_durationController.text),
      );

      print('📋 Created request object: ${request.toJson()}');

      final response = await _auctionRequestService.createAuctionRequest(
        request,
      );

      print(
        '📨 Response received: success=${response.success}, message=${response.message}, auctionId=${response.auctionId}',
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
          // Refresh auctions
          context.read<AppState>().loadAuctions();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('💥 Error occurred: $e');
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
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel, color: AppColors.surface, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create Auction Request',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.surface),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Consumer<AppState>(
                builder: (context, appState, child) {
                  // Check if user is verified
                  if (appState.user == null || !appState.user!.isVerified) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.secondary!),
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
                    );
                  }

                  // User is verified, show the form
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property Selection
                        Text(
                          'Select Property',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final approvedProperties = appState.userProperties
                                .where((p) => p.canRequestAuction)
                                .toList();

                            if (approvedProperties.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.secondary!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'No verified properties available. Please verify your properties first.',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return DropdownButtonFormField<Property>(
                              value: _selectedProperty,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.home),
                              ),
                              hint: const Text('Choose a property'),
                              items: approvedProperties.map((property) {
                                return DropdownMenuItem(
                                  value: property,
                                  child: Text(property.name),
                                );
                              }).toList(),
                              onChanged: (property) {
                                setState(() {
                                  _selectedProperty = property;
                                });
                              },
                              validator: (value) {
                                if (value == null)
                                  return 'Please select a property';
                                return null;
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Starting Price
                        TextFormField(
                          controller: _startingPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Starting Price',
                            prefixIcon: Icon(Icons.attach_money),
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
                            labelText: 'Duration (hours)',
                            prefixIcon: Icon(Icons.schedule),
                            border: OutlineInputBorder(),
                            hintText: 'e.g., 24, 48, 72',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _updateEndDate(),
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Required';
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
                                    prefixIcon: Icon(Icons.calendar_today),
                                    border: OutlineInputBorder(),
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
                                    prefixIcon: Icon(Icons.access_time),
                                    border: OutlineInputBorder(),
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
                            prefixIcon: Icon(Icons.event),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            '${_endDate.day}/${_endDate.month}/${_endDate.year} at ${_endDate.hour.toString().padLeft(2, '0')}:${_endDate.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Buy Now Price (optional)
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.surface,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.surface,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Submit Auction Request',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
