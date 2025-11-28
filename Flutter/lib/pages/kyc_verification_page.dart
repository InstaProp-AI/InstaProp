import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state.dart';
import '../services/kyc_service.dart';
import '../theme/app_colors.dart';
import '../widgets/modern_button.dart';

/// Clean, simplified KYC Verification Page
///
/// Flow:
/// 1. User picks documents (ID both sides OR Passport)
/// 2. Each document uploads immediately when selected
/// 3. Status updates automatically in the backend
/// 4. User can skip or continue after uploading
class KycVerificationPage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final bool isNewSignup; // true for registration, false for existing users

  const KycVerificationPage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.isNewSignup = true,
  });

  @override
  State<KycVerificationPage> createState() => _KycVerificationPageState();
}

class _KycVerificationPageState extends State<KycVerificationPage> {
  final ImagePicker _imagePicker = ImagePicker();

  // Track uploaded documents
  final Map<String, String?> _uploadedDocs = {
    'ID_Front': null,
    'ID_Back': null,
    'Passport': null,
  };

  bool _isUploading = false;
  String? _errorMessage;
  String? _uploadingDocType;

  /// Pick and upload a document
  Future<void> _pickAndUploadDocument(String docType) async {
    try {
      // Pick image
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return; // User cancelled

      // Upload immediately
      setState(() {
        _isUploading = true;
        _uploadingDocType = docType;
        _errorMessage = null;
      });

      final response = await KycService.uploadDocument(
        file: image,
        docType: docType,
        email: widget.email, // Pass email for public upload during registration
      );

      if (response.success && response.data != null) {
        setState(() {
          _uploadedDocs[docType] = response.data;
          _errorMessage = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_getDocDisplayName(docType)} uploaded successfully!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to upload document';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload document: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
        _uploadingDocType = null;
      });
    }
  }

  /// Check if user has uploaded sufficient documents
  bool _hasSufficientDocuments() {
    final hasID =
        _uploadedDocs['ID_Front'] != null && _uploadedDocs['ID_Back'] != null;
    final hasPassport = _uploadedDocs['Passport'] != null;
    return hasID || hasPassport;
  }

  /// Handle completion
  void _handleComplete() {
    if (!_hasSufficientDocuments()) {
      setState(() {
        _errorMessage = 'Please upload either ID (both sides) or Passport';
      });
      return;
    }

    _showSuccessDialog();
  }

  /// Handle skip
  void _handleSkip() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Skip Verification?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You can verify your account later from your profile.'),
            const SizedBox(height: 12),
            _buildInfoItem('Account marked as "Not Verified"'),
            const SizedBox(height: 6),
            _buildInfoItem('Some features may be limited'),
          ],
        ),
        actions: [
          ModernButton(
            text: 'Cancel',
            type: ModernButtonType.text,
            onPressed: () => Navigator.pop(context),
          ),
          ModernButton(
            text: 'Skip for Now',
            type: ModernButtonType.primary,
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _showSuccessDialog(skipped: true);
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog({bool skipped = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  skipped ? Icons.person_add_rounded : Icons.check_rounded,
                  size: 60,
                  color: AppColors.surface,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome Aboard!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                skipped
                    ? 'Your account is ready to use!'
                    : 'Your documents have been submitted for review.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                skipped
                    ? 'You can upload documents anytime from your profile.'
                    : 'We\'ll notify you once your documents are verified.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 32),
              ModernButton(
                text: widget.isNewSignup ? 'Get Started' : 'Back to Profile',
                type: ModernButtonType.primary,
                onPressed: () async {
                  Navigator.of(context).pop(); // Close dialog

                  // Refresh user profile to get updated status
                  final appState = context.read<AppState>();
                  await appState.refreshUserProfile();

                  if (widget.isNewSignup) {
                    // For new signups, go to home page
                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  } else {
                    // For existing users, go back to profile
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDocDisplayName(String docType) {
    switch (docType) {
      case 'ID_Front':
        return 'ID Card (Front)';
      case 'ID_Back':
        return 'ID Card (Back)';
      case 'Passport':
        return 'Passport';
      default:
        return docType;
    }
  }

  Widget _buildInfoItem(String text) {
    return Row(
      children: [
        Icon(Icons.circle, size: 6, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.09),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isNewSignup
                                  ? 'Identity Verification'
                                  : 'Upload Documents',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            if (widget.isNewSignup)
                              const Text(
                                'Step 2 of 2',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress Bar (only for new signups)
                if (widget.isNewSignup) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: 1.0,
                        minHeight: 8,
                        backgroundColor: AppColors.background,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_user_rounded,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hi ${widget.firstName}! 👋',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.isNewSignup
                                          ? 'Upload documents to verify your account'
                                          : 'Submit documents to get verified',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Error Message
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red[700],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Instructions
                        Text(
                          widget.isNewSignup
                              ? 'Upload Your Documents (Optional)'
                              : 'Upload Your Documents',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose one option: ID card (both sides) OR Passport',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Government ID Section
                        _buildIDSection(),

                        const SizedBox(height: 20),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppColors.secondary,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'OR',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppColors.secondary,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Passport Section
                        _buildPassportSection(),

                        const SizedBox(height: 32),

                        // Complete Button
                        if (_hasSufficientDocuments())
                          ModernButton(
                            text: 'Complete Verification',
                            type: ModernButtonType.primary,
                            onPressed: _isUploading ? null : _handleComplete,
                            isLoading: _isUploading,
                          ),

                        const SizedBox(height: 16),

                        // Skip Button (only for new signups)
                        if (widget.isNewSignup)
                          Center(
                            child: ModernButton(
                              text: 'I\'ll do this later',
                              type: ModernButtonType.text,
                              onPressed: _isUploading ? null : _handleSkip,
                            ),
                          ),

                        // Back Button (for existing users)
                        if (!widget.isNewSignup)
                          Center(
                            child: TextButton.icon(
                              onPressed: _isUploading
                                  ? null
                                  : () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back to Profile'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIDSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.credit_card_rounded,
                  color: AppColors.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Government ID',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    Text(
                      'Upload both sides of your ID card',
                      style: TextStyle(fontSize: 13, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildDocumentUploadCard('ID_Front', 'Front'),
              const SizedBox(width: 16),
              _buildDocumentUploadCard('ID_Back', 'Back'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassportSection() {
    final hasPassport = _uploadedDocs['Passport'] != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flight_takeoff_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passport',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Upload your passport photo page',
                      style: TextStyle(fontSize: 13, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _isUploading
                ? null
                : () => _pickAndUploadDocument('Passport'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: hasPassport
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasPassport ? AppColors.primary : AppColors.secondary,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  if (_isUploading && _uploadingDocType == 'Passport')
                    const CircularProgressIndicator()
                  else
                    Icon(
                      hasPassport
                          ? Icons.check_circle_rounded
                          : Icons.add_photo_alternate_outlined,
                      color: hasPassport
                          ? AppColors.primary
                          : AppColors.secondary,
                      size: 48,
                    ),
                  const SizedBox(height: 12),
                  Text(
                    hasPassport
                        ? 'Passport Uploaded'
                        : 'Tap to Upload Passport',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: hasPassport
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasPassport
                        ? 'Ready to submit'
                        : 'Photo page with your details',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasPassport
                          ? AppColors.primary.withOpacity(0.7)
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadCard(String docType, String label) {
    final hasDocument = _uploadedDocs[docType] != null;

    return Expanded(
      child: InkWell(
        onTap: _isUploading ? null : () => _pickAndUploadDocument(docType),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: hasDocument
                ? AppColors.secondary.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.secondary, width: 2),
          ),
          child: Column(
            children: [
              if (_isUploading && _uploadingDocType == docType)
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(),
                )
              else
                Icon(
                  hasDocument
                      ? Icons.check_circle_rounded
                      : Icons.add_photo_alternate_outlined,
                  color: hasDocument
                      ? AppColors.secondary
                      : AppColors.secondary,
                  size: 44,
                ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: hasDocument
                      ? AppColors.secondary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasDocument ? 'Uploaded' : 'Tap to upload',
                style: TextStyle(
                  fontSize: 12,
                  color: hasDocument
                      ? AppColors.secondary.withOpacity(0.7)
                      : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
