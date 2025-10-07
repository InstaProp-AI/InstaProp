import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';
import '../models/user.dart';
import 'kyc_verification_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload user data whenever dependencies change (e.g., when user logs in)
    _loadUserData();
  }

  void _loadUserData() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.user != null) {
      setState(() {
        _firstNameController.text = appState.user!.firstName;
        _lastNameController.text = appState.user!.lastName;
        _phoneController.text = appState.user!.phoneNumber;
        _emailController.text = appState.user!.email;
      });
    }
  }

  void _showEditWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Important Notice'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Editing your profile will change your account status to:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pending Verification',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your account will need to be re-verified by an admin after you save changes.',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isEditing = true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
            ),
            child: const Text('Continue Editing'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authService = AuthService();
      final response = await authService.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (response.success) {
        // Reload user data from AppState to get updated verification status
        _loadUserData();

        setState(() {
          _successMessage =
              'Profile updated successfully! Your account is now pending admin review.';
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Profile updated! An admin will review your changes shortly.',
            ),
            backgroundColor: Colors.orange[700],
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to update profile';
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

  Future<void> _logout() async {
    final appState = context.read<AppState>();
    await appState.logout();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Always show profile content, but add login prompt for unauthenticated users

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            actions: [
              if (!_isEditing && appState.isLoggedIn)
                IconButton(
                  onPressed: _showEditWarning,
                  icon: const Icon(Icons.edit),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (appState.isLoggedIn) ...[
                    // Profile header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.green[700],
                            child: Text(
                              (appState.user?.firstName ?? 'U')[0]
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            appState.user?.fullName ?? 'Guest User',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appState.user?.email ?? 'No email',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(appState.user!.status),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(appState.user!.status),
                                  size: 14,
                                  color: _getStatusTextColor(
                                    appState.user!.status,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getStatusText(appState.user!.status),
                                  style: TextStyle(
                                    color: _getStatusTextColor(
                                      appState.user!.status,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),

                    // Success message
                    if (_successMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ),

                    // Profile form
                    Text(
                      'Personal Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // First name
                    CustomTextField(
                      controller: _firstNameController,
                      labelText: 'First Name',
                      enabled: _isEditing,
                      validator: (value) => value?.isEmpty == true
                          ? 'First name is required'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Last name
                    CustomTextField(
                      controller: _lastNameController,
                      labelText: 'Last Name',
                      enabled: _isEditing,
                      validator: (value) => value?.isEmpty == true
                          ? 'Last name is required'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Phone number
                    CustomTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      enabled: _isEditing,
                      validator: (value) => value?.isEmpty == true
                          ? 'Phone number is required'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Email
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      enabled: _isEditing,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Email is required';
                        if (!value!.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Member since (read-only)
                    TextFormField(
                      initialValue:
                          'Member since ${appState.user?.createdAt.day ?? 0}/${appState.user?.createdAt.month ?? 0}/${appState.user?.createdAt.year ?? 0}',
                      decoration: const InputDecoration(
                        labelText: 'Member Since',
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),

                    const SizedBox(height: 24),

                    // Verification Status Warning (if not verified or pending)
                    if (appState.user!.status != VerificationStatus.verified &&
                        !_isEditing)
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                appState.user!.status ==
                                    VerificationStatus.pending
                                ? [
                                    Colors.blue[50]!,
                                    Colors.blue[100]!.withOpacity(0.3),
                                  ]
                                : [
                                    Colors.orange[50]!,
                                    Colors.orange[100]!.withOpacity(0.3),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                appState.user!.status ==
                                    VerificationStatus.pending
                                ? Colors.blue[300]!
                                : Colors.orange[300]!,
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
                                    color:
                                        appState.user!.status ==
                                            VerificationStatus.pending
                                        ? Colors.blue[100]
                                        : Colors.orange[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    appState.user!.status ==
                                            VerificationStatus.pending
                                        ? Icons.hourglass_empty
                                        : Icons.verified_user,
                                    color:
                                        appState.user!.status ==
                                            VerificationStatus.pending
                                        ? Colors.blue[700]
                                        : Colors.orange[700],
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appState.user!.status ==
                                                VerificationStatus.pending
                                            ? 'Documents Under Review'
                                            : 'Complete Your Verification',
                                        style: TextStyle(
                                          color:
                                              appState.user!.status ==
                                                  VerificationStatus.pending
                                              ? Colors.blue[900]
                                              : Colors.orange[900],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        appState.user!.status ==
                                                VerificationStatus.pending
                                            ? 'Your documents are being reviewed by our team. We\'ll notify you once verified.'
                                            : 'Upload your ID or Passport to unlock all features',
                                        style: TextStyle(
                                          color:
                                              appState.user!.status ==
                                                  VerificationStatus.pending
                                              ? Colors.blue[700]
                                              : Colors.orange[700],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Only show upload button if NotVerified
                            if (appState.user!.status ==
                                VerificationStatus.notVerified) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => KycVerificationPage(
                                          firstName: appState.user!.firstName,
                                          lastName: appState.user!.lastName,
                                          phoneNumber:
                                              appState.user!.phoneNumber,
                                          email: appState.user!.email,
                                          password:
                                              '', // Not needed for KYC upload only
                                          gender:
                                              'Male', // Not needed for KYC upload only
                                          isNewSignup: false, // Existing user
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text(
                                    'Upload Verification Documents',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Action buttons
                    if (_isEditing) ...[
                      // Warning about unverification
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Saving changes will set your account to pending. An admin will review your updates.',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: LoadingButton(
                              onPressed: _isLoading ? null : _updateProfile,
                              isLoading: _isLoading,
                              child: const Text('Save Changes'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isEditing = false;
                                        _errorMessage = null;
                                        _successMessage = null;
                                        _loadUserData(); // Reset to original values
                                      });
                                    },
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[700],
                          side: BorderSide(color: Colors.red[300]!),
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ],

                  // Login prompt for unauthenticated users
                  if (!appState.isLoggedIn) ...[
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.lock, color: Colors.orange[700], size: 32),
                          const SizedBox(height: 12),
                          Text(
                            'Login to Access Profile',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You need to be logged in to manage your profile and account settings',
                            style: TextStyle(
                              color: Colors.orange[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/auth'),
                            icon: const Icon(Icons.login),
                            label: const Text('Login to Continue'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper methods for verification status display
  Color _getStatusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return Colors.green[100]!;
      case VerificationStatus.pending:
        return Colors.blue[100]!;
      case VerificationStatus.notVerified:
        return Colors.orange[100]!;
    }
  }

  Color _getStatusTextColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return Colors.green[700]!;
      case VerificationStatus.pending:
        return Colors.blue[700]!;
      case VerificationStatus.notVerified:
        return Colors.orange[700]!;
    }
  }

  IconData _getStatusIcon(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return Icons.verified;
      case VerificationStatus.pending:
        return Icons.hourglass_empty;
      case VerificationStatus.notVerified:
        return Icons.warning_amber_rounded;
    }
  }

  String _getStatusText(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.notVerified:
        return 'Not Verified';
    }
  }
}
