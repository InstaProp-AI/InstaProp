import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../services/event_service.dart';
import '../models/property.dart';
import '../providers/app_state.dart';
import 'package:provider/provider.dart';
import '../widgets/reward_popup.dart';

class PaymentScheduleScannerDialog extends StatefulWidget {
  final Property? initialProperty;

  const PaymentScheduleScannerDialog({super.key, this.initialProperty});

  @override
  State<PaymentScheduleScannerDialog> createState() =>
      _PaymentScheduleScannerDialogState();
}

class _PaymentScheduleScannerDialogState
    extends State<PaymentScheduleScannerDialog> {
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _selectedImage;
  bool _isUploading = false;
  String? _errorMessage;
  int? _selectedReminderMinutes;
  bool _useCustomReminder = false;
  int _customDays = 1;
  Property? _selectedProperty;
  final _buyingPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedProperty = widget.initialProperty;
  }

  // Predefined reminder options
  final Map<String, int> _reminderOptions = {
    '1 day before': 1440,
    '3 days before': 4320,
    '1 week before': 10080,
  };

  /// Pick and upload payment schedule image
  Future<void> _pickAndScanSchedule() async {
    try {
      // Pick image (accepts JPEG, PNG, etc.)
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
        // Image picker accepts all common formats: JPEG, JPG, PNG, GIF, BMP, WEBP
      );

      if (image == null) return; // User cancelled

      setState(() {
        _selectedImage = image;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select image: $e';
      });
    }
  }

  /// Scan and create events
  Future<void> _scanAndCreateEvents() async {
    if (_selectedProperty == null) {
      setState(() {
        _errorMessage = 'Please select a property to assign this schedule';
      });
      return;
    }
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final reminderMinutes = _useCustomReminder
          ? _customDays * 1440
          : _selectedReminderMinutes;

      // Read image bytes
      final imageBytes = await _selectedImage!.readAsBytes();

      final buyingPrice = _buyingPriceController.text.isNotEmpty
          ? double.tryParse(_buyingPriceController.text)
          : null;

      final response = await EventService.scanPaymentSchedule(
        imageBytes,
        _selectedImage!.name,
        _selectedProperty!.propertyId,
        reminderMinutes: reminderMinutes,
        buyingPrice: buyingPrice,
      );

      if (response.success && response.data != null) {
        if (mounted) {
          // Show reward popup
          final appState = context.read<AppState>();
          await appState.refreshUserProfile();
          if (mounted && appState.user?.totalEarnedPoints != null) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => RewardPopup(
                pointsAwarded: response.data!.eventsCreated.clamp(1, 20),
                totalPoints: appState.user!.totalEarnedPoints!,
              ),
            );
          }
          if (mounted) {
            Navigator.of(context).pop(response.data);
          }
        }
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to scan payment schedule';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error scanning image: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(20),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  const Icon(
                    Icons.document_scanner,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Scan Payment Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Select property, enter buying price (optional), then upload an image. AI will extract all payment dates and link them to the property.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              // Property selector
              const SizedBox(height: 12),
              const Text(
                'Assign to Property',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<Property>(
                isExpanded: true,
                value: _selectedProperty,
                items: appState.userProperties
                    .map(
                      (p) => DropdownMenuItem<Property>(
                        value: p,
                        child: Text(p.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: _isUploading
                    ? null
                    : (p) => setState(() => _selectedProperty = p),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Select property',
                ),
              ),

              const SizedBox(height: 12),
              // Buying price field (optional)
              const Text(
                'Buying Price (optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _buyingPriceController,
                enabled: !_isUploading,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: '\$ ',
                  hintText: 'e.g., 250000',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),

              const SizedBox(height: 20),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Image Upload Card
              InkWell(
                onTap: (_isUploading || _selectedProperty == null)
                    ? null
                    : _pickAndScanSchedule,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _selectedImage != null
                        ? Colors.green.withOpacity(0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedImage != null
                          ? Colors.green
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedImage != null
                            ? Icons.check_circle
                            : Icons.add_photo_alternate_outlined,
                        color: _selectedImage != null
                            ? Colors.green
                            : Colors.blue,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedImage != null
                            ? 'Image Selected'
                            : 'Tap to Upload Image',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedImage != null
                            ? _selectedImage!.name
                            : 'JPEG, JPG, PNG supported',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Reminder Settings
              const Text(
                'Bulk Reminder (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set a reminder for all payment events',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),

              // Predefined options
              ..._reminderOptions.entries.map(
                (entry) => RadioListTile<int>(
                  title: Text(entry.key),
                  value: entry.value,
                  groupValue: _useCustomReminder
                      ? null
                      : _selectedReminderMinutes,
                  onChanged: _isUploading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedReminderMinutes = value;
                            _useCustomReminder = false;
                          });
                        },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),

              // Custom option
              RadioListTile<bool>(
                title: const Text('Custom'),
                value: true,
                groupValue: _useCustomReminder,
                onChanged: _isUploading
                    ? null
                    : (value) {
                        setState(() {
                          _useCustomReminder = value ?? false;
                          if (_useCustomReminder)
                            _selectedReminderMinutes = null;
                        });
                      },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),

              if (_useCustomReminder)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Days before',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          enabled: !_isUploading,
                          onChanged: (value) => setState(
                            () => _customDays = int.tryParse(value) ?? 1,
                          ),
                          controller: TextEditingController(
                            text: _customDays.toString(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('days'),
                    ],
                  ),
                ),

              // No reminder
              RadioListTile<int>(
                title: const Text('No reminder'),
                value: -1,
                groupValue: _useCustomReminder
                    ? -1
                    : (_selectedReminderMinutes ?? -1),
                onChanged: _isUploading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedReminderMinutes = null;
                          _useCustomReminder = false;
                        });
                      },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _isUploading || _selectedImage == null
                          ? null
                          : _scanAndCreateEvents,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Scan & Create Events',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isUploading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
