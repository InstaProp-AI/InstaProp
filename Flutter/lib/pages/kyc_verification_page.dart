import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state.dart';
import '../widgets/loading_button.dart';

class KycVerificationPage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String password;
  final String gender;
  final bool
  isNewSignup; // true for first-time signup, false for existing users

  const KycVerificationPage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.gender,
    this.isNewSignup = true, // Default to true for backward compatibility
  });

  @override
  State<KycVerificationPage> createState() => _KycVerificationPageState();
}

class _KycVerificationPageState extends State<KycVerificationPage> {
  final Map<String, XFile?> _kycDocuments = {
    'ID_Front': null,
    'ID_Back': null,
    'Passport': null,
  };
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickKycDocument(String docType) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _kycDocuments[docType] = image;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _handleSubmit() async {
    // Validate KYC documents
    bool hasIdDocs =
        _kycDocuments['ID_Front'] != null && _kycDocuments['ID_Back'] != null;
    bool hasPassport = _kycDocuments['Passport'] != null;

    if (!hasIdDocs && !hasPassport) {
      setState(() {
        _errorMessage = 'Please upload either ID (both sides) or Passport';
      });
      return;
    }

    await _uploadKycDocuments();
  }

  Future<void> _handleSkipKyc() async {
    // Account already created, just show success
    if (mounted) {
      _showSuccessDialog(withKyc: false);
    }
  }

  Future<void> _uploadKycDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AppState>();
      List<Map<String, String>> kycDocs = [];

      // Upload each file and get its URL
      for (var entry in _kycDocuments.entries) {
        if (entry.value != null) {
          final docType = entry.key;
          final file = entry.value!;

          // Upload file to server
          final fileUrl = await authService.uploadKycFile(
            filePath: file.path,
            docType: docType,
          );

          if (fileUrl != null) {
            kycDocs.add({'docType': docType, 'imageUrl': fileUrl});
          } else {
            throw Exception('Failed to upload $docType');
          }
        }
      }

      // Submit all uploaded document URLs
      final success = await authService.uploadKycDocuments(
        kycDocuments: kycDocs,
      );

      if (success && mounted) {
        _showSuccessDialog(withKyc: true);
      } else {
        setState(() {
          _errorMessage = 'Failed to submit KYC documents. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload documents: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog({required bool withKyc}) {
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
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  withKyc ? Icons.check_rounded : Icons.person_add_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome Aboard!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                withKyc
                    ? 'Your documents have been submitted for review.'
                    : 'Your account is ready to use!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                withKyc
                    ? 'We\'ll notify you once your documents are verified.'
                    : 'You can upload verification documents anytime from your profile.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back from KYC page
                    if (widget.isNewSignup) {
                      // For new signups, go to home page
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/', (route) => false);
                    }
                    // For existing users, just popping twice goes back to profile
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    widget.isNewSignup ? 'Get Started' : 'Back to Profile',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background circles
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF4CAF50).withOpacity(0.2),
                    Color(0xFF2E7D32).withOpacity(0.05),
                  ],
                ),
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
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1B5E20).withOpacity(0.15),
                    Color(0xFF2E7D32).withOpacity(0.03),
                  ],
                ),
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
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF2E7D32),
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
                                  : 'Upload Verification Documents',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            if (widget.isNewSignup)
                              Text(
                                'Step 2 of 2',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
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
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4CAF50),
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
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF4CAF50).withOpacity(0.1),
                                Color(0xFF2E7D32).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Color(0xFF4CAF50).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(0xFF4CAF50).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.verified_user_rounded,
                                  color: Color(0xFF2E7D32),
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
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.isNewSignup
                                          ? 'Upload documents to verify your account'
                                          : 'Submit documents to get verified',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
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
                              border: Border.all(color: Colors.red[200]!),
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
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isNewSignup
                              ? 'Choose one option to verify your account, or skip for now'
                              : 'Choose one option to verify your account',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Government ID Section
                        _buildDocumentSection(
                          title: 'Government ID',
                          subtitle: 'Upload front and back of your ID card',
                          icon: Icons.credit_card_rounded,
                          color: Color(0xFF9C27B0),
                          docTypes: ['ID_Front', 'ID_Back'],
                        ),

                        const SizedBox(height: 20),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
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
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Passport Section
                        _buildPassportSection(),

                        const SizedBox(height: 32),

                        // Submit Button
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isLoading
                                  ? [Colors.grey[300]!, Colors.grey[400]!]
                                  : [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: !_isLoading
                                ? [
                                    BoxShadow(
                                      color: Color(0xFF4CAF50).withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ]
                                : null,
                          ),
                          child: LoadingButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            isLoading: _isLoading,
                            child: Text(
                              widget.isNewSignup
                                  ? 'Complete Verification'
                                  : 'Submit Documents',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Skip Button (only for new signups)
                        if (widget.isNewSignup)
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.orange[700],
                                            ),
                                            const SizedBox(width: 12),
                                            const Text('Skip Verification?'),
                                          ],
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Some features will be limited:',
                                            ),
                                            const SizedBox(height: 12),
                                            _buildLimitationItem(
                                              'Account marked as "Unverified"',
                                            ),
                                            const SizedBox(height: 6),
                                            _buildLimitationItem(
                                              'Limited access to some features',
                                            ),
                                            const SizedBox(height: 6),
                                            _buildLimitationItem(
                                              'Can verify anytime from profile',
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _handleSkipKyc();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.orange[700],
                                            ),
                                            child: const Text('Skip for Now'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                            child: const Text(
                              'I\'ll do this later',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        // Back to Profile Button (for existing users)
                        if (!widget.isNewSignup)
                          TextButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back to Profile'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
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

  Widget _buildDocumentSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> docTypes,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: docTypes.map((docType) {
              final hasDocument = _kycDocuments[docType] != null;
              final isFront = docType.contains('Front');
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: isFront ? 8 : 0,
                    left: isFront ? 0 : 8,
                  ),
                  child: InkWell(
                    onTap: () => _pickKycDocument(docType),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: hasDocument
                            ? color.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasDocument ? color : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            hasDocument
                                ? Icons.check_circle_rounded
                                : Icons.add_photo_alternate_outlined,
                            color: hasDocument ? color : Colors.grey[400],
                            size: 44,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isFront ? 'Front' : 'Back',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: hasDocument ? color : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasDocument ? 'Uploaded' : 'Tap to upload',
                            style: TextStyle(
                              fontSize: 12,
                              color: hasDocument
                                  ? color.withOpacity(0.7)
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitationItem(String text) {
    return Row(
      children: [
        Icon(Icons.circle, size: 6, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildPassportSection() {
    final hasPassport = _kycDocuments['Passport'] != null;
    final color = Color(0xFF3F51B5);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.flight_takeoff_rounded,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passport',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      'Upload your passport photo page',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _pickKycDocument('Passport'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: hasPassport ? color.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasPassport ? color : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    hasPassport
                        ? Icons.check_circle_rounded
                        : Icons.add_photo_alternate_outlined,
                    color: hasPassport ? color : Colors.grey[400],
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
                      color: hasPassport ? color : Colors.grey[700],
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
                          ? color.withOpacity(0.7)
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
}
