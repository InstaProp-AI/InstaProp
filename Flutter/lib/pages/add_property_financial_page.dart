import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/installment_summary.dart';
import '../models/property.dart';
import '../models/property_type.dart';
import '../services/property_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';
import 'payment_schedule_scanner_dialog.dart';
import 'property_docs_upload_page.dart';

class AddPropertyFinancialPage extends StatefulWidget {
  final int? propertyId;
  final String? propertyName;

  const AddPropertyFinancialPage({
    super.key,
    this.propertyId,
    this.propertyName,
  });

  @override
  State<AddPropertyFinancialPage> createState() =>
      _AddPropertyFinancialPageState();
}

class _AddPropertyFinancialPageState extends State<AddPropertyFinancialPage> {
  final _formKey = GlobalKey<FormState>();

  final _contractedPriceController = TextEditingController();
  final _totalPaidController = TextEditingController();
  final _downPaymentPercentController = TextEditingController();
  final _termYearsController = TextEditingController();
  final _installmentEndYearController = TextEditingController();

  bool _isFullyPaid = false;
  bool _isLoading = true;
  bool _isSaving = false;
  Property? _property;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProperty();
  }

  @override
  void dispose() {
    _contractedPriceController.dispose();
    _totalPaidController.dispose();
    _downPaymentPercentController.dispose();
    _termYearsController.dispose();
    _installmentEndYearController.dispose();
    super.dispose();
  }

  Future<void> _loadProperty() async {
    final propertyId = widget.propertyId;
    if (propertyId == null) {
      setState(() {
        _error = 'Missing property identifier.';
        _isLoading = false;
      });
      return;
    }

    final response = await PropertyService.getProperty(propertyId);
    if (!mounted) return;

    if (response.success && response.data != null) {
      final property = response.data!;
      final summary = property.installmentSummary;

      setState(() {
        _property = property;
        if (summary != null) {
          _contractedPriceController.text =
              summary.contractedPrice.toStringAsFixed(0);
          _totalPaidController.text =
              summary.totalPaid.toStringAsFixed(0);
          _downPaymentPercentController.text =
              summary.downPaymentPercent.toStringAsFixed(1);
          _termYearsController.text =
              summary.termYears?.toString() ?? '';
          _installmentEndYearController.text =
              summary.installmentEndDate?.year.toString() ?? '';
          _isFullyPaid = summary.isFullyPaid;
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = response.error ?? 'Failed to load property data.';
        _isLoading = false;
      });
    }
  }

  double? _parseNumber(String value) {
    final normalized = value.trim().replaceAll(',', '');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  int? _parseInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  DateTime? _parseEndYear(String value) {
    final year = _parseInt(value);
    if (year == null || year < 1900) return null;
    return DateTime(year, 1, 1);
  }

  Future<void> _saveSummary() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.propertyId == null) return;

    final contractedPrice = _parseNumber(_contractedPriceController.text);
    if (contractedPrice == null || contractedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contract price is required.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final payload = InstallmentSummaryPayload(
      contractedPrice: contractedPrice,
      totalPaid: _parseNumber(_totalPaidController.text),
      downPaymentPercent: _parseNumber(_downPaymentPercentController.text),
      termYears: _parseInt(_termYearsController.text),
      installmentEndDate: _parseEndYear(_installmentEndYearController.text),
      isFullyPaid: _isFullyPaid,
    );

    final response = await PropertyService.upsertPropertyInstallmentSummary(
      widget.propertyId!,
      payload,
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      setState(() {
        _isFullyPaid = response.data!.isFullyPaid;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Financial summary saved.')),
      );
    } else {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.error ?? 'Failed to save financial summary.',
          ),
        ),
      );
    }
  }

  Future<void> _openScanner() async {
    if (_property == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property data is still loading.')),
      );
      return;
    }

    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          PaymentScheduleScannerDialog(initialProperty: _property),
    );

    if (result != null) {
      // Refresh summary to reflect new totals
      await _loadProperty();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment events added to your calendar. Financial summary refreshed.',
          ),
        ),
      );
    }
  }

  void _openDocsUpload() {
    if (_property == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDocsUploadPage(
          propertyId: _property!.propertyId,
          propertyName: _property!.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertyId = widget.propertyId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installments & Financial Summary'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip for now'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : propertyId == null
              ? _buildErrorState(
                  'Missing property identifier. Please return and try again.',
                )
              : _property == null
                  ? _buildErrorState(
                      _error ?? 'Unable to load property details.',
                    )
                  : _buildContent(context),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIntroCard(context),
            const SizedBox(height: 24),
            _buildFinancialForm(context),
            const SizedBox(height: 24),
            _buildScheduleScannerPrompt(context),
            const SizedBox(height: 24),
            LoadingButton(
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveSummary,
              child: const Text('Save Financial Summary'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _openDocsUpload,
              child: const Text('Upload Supporting Documents'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(BuildContext context) {
    final property = _property!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            property.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  property.location,
                  style: TextStyle(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.category_outlined,
                label: property.type.displayName,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.people_alt_outlined,
                label: '${property.bedrooms} BR · ${property.bathrooms} BA',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.square_foot,
                label: '${property.squareFeet} sqft',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
      ),
    );
  }

  Widget _buildFinancialForm(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Installment Summary', style: labelStyle),
        const SizedBox(height: 8),
        Text(
          'Capture the high-level financial details so the dashboard can track equity and outstanding balance.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _contractedPriceController,
          labelText: 'Contract Price (EGP)',
          hintText: 'e.g., 5,500,000',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            final parsed = _parseNumber(value ?? '');
            if (parsed == null || parsed <= 0) {
              return 'Enter a valid contract price';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _totalPaidController,
          labelText: 'Total Paid So Far (EGP)',
          hintText: 'e.g., 1,200,000',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _downPaymentPercentController,
          labelText: 'Down Payment (%)',
          hintText: 'e.g., 10',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            'Enable if the property is completely settled and no balance remains.',
          ),
          onChanged: (value) => setState(() => _isFullyPaid = value),
        ),
      ],
    );
  }

  Widget _buildScheduleScannerPrompt(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.document_scanner, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Scan Payment Schedule',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Use our AI scanner to extract installment timelines from a contract. '
            'All recognized payments will be added to your calendar automatically so you never miss a due date.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('Scan Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Imported events appear in Calendar > Installments.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


