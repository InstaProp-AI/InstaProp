import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/property.dart';
import '../services/property_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';
import 'property_docs_upload_page.dart';
import '../models/installment_summary.dart';

class EditPropertyPage extends StatefulWidget {
  final Property property;

  const EditPropertyPage({super.key, required this.property});

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _bedroomsController;
  late final TextEditingController _bathroomsController;
  late final TextEditingController _squareFeetController;
  late final TextEditingController _yearBuiltController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _contractedPriceController;
  late final TextEditingController _totalPaidController;
  late final TextEditingController _downPaymentPercentController;
  late final TextEditingController _termYearsController;
  late final TextEditingController _installmentEndYearController;

  bool _isFullyPaid = false;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing property data
    _nameController = TextEditingController(text: widget.property.name);
    _descriptionController = TextEditingController(
      text: widget.property.description,
    );
    _locationController = TextEditingController(text: widget.property.location);
    _bedroomsController = TextEditingController(
      text: widget.property.bedrooms.toString(),
    );
    _bathroomsController = TextEditingController(
      text: widget.property.bathrooms.toString(),
    );
    _squareFeetController = TextEditingController(
      text: widget.property.squareFeet.toString(),
    );
    _yearBuiltController = TextEditingController(
      text: widget.property.yearBuilt.toString(),
    );
    _imageUrlController = TextEditingController(text: widget.property.imageUrl);

    final summary = widget.property.installmentSummary;
    _contractedPriceController = TextEditingController(
      text: summary != null
          ? summary.contractedPrice.toStringAsFixed(0)
          : '',
    );
    _totalPaidController = TextEditingController(
      text: summary != null ? summary.totalPaid.toStringAsFixed(0) : '',
    );
    _downPaymentPercentController = TextEditingController(
      text: summary != null
          ? summary.downPaymentPercent.toStringAsFixed(2)
          : '',
    );
    _termYearsController = TextEditingController(
      text: summary?.termYears?.toString() ?? '',
    );
    _installmentEndYearController = TextEditingController(
      text: summary?.installmentEndDate?.year.toString() ?? '',
    );
    _isFullyPaid = summary?.isFullyPaid ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _squareFeetController.dispose();
    _yearBuiltController.dispose();
    _imageUrlController.dispose();
    _contractedPriceController.dispose();
    _totalPaidController.dispose();
    _downPaymentPercentController.dispose();
    _termYearsController.dispose();
    _installmentEndYearController.dispose();
    super.dispose();
  }

  double? _parseNumber(String value) {
    final normalized = value.trim().replaceAll(',', '');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  int? _parseIntValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  DateTime? _parseInstallmentEndDate(String value) {
    final year = _parseIntValue(value);
    if (year == null) return null;
    if (year < 1900) return null;
    return DateTime(year, 1, 1);
  }

  Future<void> _updateProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final summaryPayload = InstallmentSummaryPayload(
        contractedPrice: _parseNumber(_contractedPriceController.text),
        totalPaid: _parseNumber(_totalPaidController.text),
        downPaymentPercent:
            _parseNumber(_downPaymentPercentController.text),
        termYears: _parseIntValue(_termYearsController.text),
        installmentEndDate:
            _parseInstallmentEndDate(_installmentEndYearController.text),
        isFullyPaid: _isFullyPaid ? true : null,
      );

      final response = await PropertyService.updateProperty(
        propertyId: widget.property.propertyId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        installmentSummary: summaryPayload,
      );

      if (response.success) {
        setState(() {
          _successMessage = 'Property updated successfully!';
        });

        // Refresh properties in app state
        if (mounted) {
          context.read<AppState>().loadProperties();

          // Show success message and go back
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Property "${_nameController.text.trim()}" updated successfully! 🎉',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Navigate back after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to update property';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Property'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Edit Property Details',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Update your property information below',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.primary),
              ),

              const SizedBox(height: 24),

              // Status chip
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.property.isApproved
                      ? AppColors.background
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.property.isApproved
                        ? Colors.green[200]!
                        : AppColors.secondary!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.property.isApproved
                          ? Icons.check_circle
                          : Icons.pending,
                      color: widget.property.isApproved
                          ? AppColors.primary
                          : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.property.isApproved
                          ? 'Property Status: Verified'
                          : 'Property Status: Pending Verification',
                      style: TextStyle(
                        color: widget.property.isApproved
                            ? AppColors.primary
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.secondary!),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),

              // Success message
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Text(
                    _successMessage!,
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),

              // Property name
              CustomTextField(
                controller: _nameController,
                labelText: 'Property Name',
                hintText: 'e.g., Beautiful 3-bedroom house',
                validator: (value) =>
                    value?.isEmpty == true ? 'Property name is required' : null,
              ),

              const SizedBox(height: 16),

              // Description
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description',
                hintText: 'Describe your property...',
                maxLines: 4,
                validator: (value) =>
                    value?.isEmpty == true ? 'Description is required' : null,
              ),

              const SizedBox(height: 16),

              // Location
              CustomTextField(
                controller: _locationController,
                labelText: 'Location',
                hintText: 'e.g., 123 Main St, City, State',
                validator: (value) =>
                    value?.isEmpty == true ? 'Location is required' : null,
              ),

              const SizedBox(height: 16),

              // Property Details Section
              Text(
                'Property Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              // Bedrooms and Bathrooms Row
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _bedroomsController,
                      labelText: 'Bedrooms',
                      hintText: 'e.g., 3',
                      keyboardType: TextInputType.number,
                      enabled:
                          false, // Can't edit bedrooms for existing property
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Bedrooms required';
                        if (int.tryParse(value!) == null)
                          return 'Enter valid number';
                        if (int.parse(value) < 0) return 'Must be 0 or more';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _bathroomsController,
                      labelText: 'Bathrooms',
                      hintText: 'e.g., 2',
                      keyboardType: TextInputType.number,
                      enabled:
                          false, // Can't edit bathrooms for existing property
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Bathrooms required';
                        if (int.tryParse(value!) == null)
                          return 'Enter valid number';
                        if (int.parse(value) < 0) return 'Must be 0 or more';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Square Feet and Year Built Row
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _squareFeetController,
                      labelText: 'Square Feet',
                      hintText: 'e.g., 2000',
                      keyboardType: TextInputType.number,
                      enabled:
                          false, // Can't edit square feet for existing property
                      validator: (value) {
                        if (value?.isEmpty == true)
                          return 'Square feet required';
                        if (int.tryParse(value!) == null)
                          return 'Enter valid number';
                        if (int.parse(value) <= 0)
                          return 'Must be greater than 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _yearBuiltController,
                      labelText: 'Year Built',
                      hintText: 'e.g., 2020',
                      keyboardType: TextInputType.number,
                      enabled:
                          false, // Can't edit year built for existing property
                      validator: (value) {
                        if (value?.isEmpty == true)
                          return 'Year built required';
                        if (int.tryParse(value!) == null)
                          return 'Enter valid number';
                        final year = int.parse(value);
                        final currentYear = DateTime.now().year;
                        if (year < 1800 || year > currentYear + 1)
                          return 'Enter valid year';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Image URL (disabled)
              CustomTextField(
                controller: _imageUrlController,
                labelText: 'Image URL',
                hintText: 'https://example.com/image.jpg',
                keyboardType: TextInputType.url,
                enabled: false, // Can't edit image URL for existing property
              ),

              const SizedBox(height: 24),

              _buildInstallmentSummarySection(context),

              const SizedBox(height: 24),

              // Info message about limited editing
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Only name, description, and location can be edited. Other fields are locked to maintain property integrity.',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Manage Documents button - Only for non-approved properties
              if (!widget.property.isApproved) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PropertyDocsUploadPage(
                            propertyId: widget.property.propertyId,
                            propertyName: widget.property.name,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text(
                      'Manage Property Documents',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Info message for verified properties
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Documents are locked for verified properties. Contact support if changes are needed.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Update button
              LoadingButton(
                onPressed: _isLoading ? null : _updateProperty,
                isLoading: _isLoading,
                child: const Text('Update Property'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstallmentSummarySection(BuildContext context) {
    final summaryStyle = Theme.of(context)
        .textTheme
        .titleLarge
        ?.copyWith(fontWeight: FontWeight.bold);

    final noteStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: AppColors.primary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Financing Snapshot', style: summaryStyle),
        const SizedBox(height: 8),
        Text(
          'Keep your installment plan up to date so dashboards can show remaining balance and equity.',
          style: noteStyle,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _contractedPriceController,
          labelText: 'Contract Price (EGP)',
          hintText: 'e.g., 5,500,000',
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _totalPaidController,
          labelText: 'Total Paid So Far (EGP)',
          hintText: 'e.g., 1,200,000',
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _downPaymentPercentController,
          labelText: 'Down Payment (%)',
          hintText: 'e.g., 10',
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _termYearsController,
                labelText: 'Installment Term (years)',
                hintText: 'e.g., 10',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _installmentEndYearController,
                labelText: 'Installment End Year',
                hintText: 'e.g., 2033',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: _isFullyPaid,
          contentPadding: EdgeInsets.zero,
          title: const Text('Mark as fully paid'),
          subtitle: const Text(
            'Enable if the contract is fully settled and no further payments are due.',
          ),
          onChanged: (value) => setState(() => _isFullyPaid = value),
        ),
      ],
    );
  }
}
