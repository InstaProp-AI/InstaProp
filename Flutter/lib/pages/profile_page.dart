import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';
import '../models/user.dart';
import 'kyc_verification_page.dart';
import 'email_verification_page.dart';
import 'phone_verification_page.dart';
import 'rewards_page.dart';
import 'saved_searches_page.dart';

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

  // Password change controllers
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isChangingPassword = false;
  bool _showChangePassword = false;
  String? _errorMessage;
  String? _successMessage;
  String? _passwordErrorMessage;

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
              color: AppColors.primary,
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
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondary!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pending Verification',
                      style: TextStyle(
                        color: AppColors.primary,
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
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final currentEmail = appState.user?.email ?? '';
    final currentPhone = appState.user?.phoneNumber ?? '';
    final newEmail = _emailController.text.trim();
    final newPhone = _phoneController.text.trim();

    final emailChanged = newEmail != currentEmail;
    final phoneChanged = newPhone != currentPhone;

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
        phoneNumber: newPhone,
        email: newEmail,
      );

      if (response.success) {
        // Reload user data from AppState to get updated verification status
        await appState.refreshUserProfile();
        _loadUserData();

        setState(() {
          _isEditing = false;
        });

        // Show different messages based on what changed
        if (emailChanged || phoneChanged) {
          // Show dialog prompting to verify
          _showVerificationRequiredDialog(
            emailChanged: emailChanged,
            phoneChanged: phoneChanged,
          );
        } else {
          setState(() {
            _successMessage = 'Profile updated successfully!';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully!'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
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

  void _showVerificationRequiredDialog({
    required bool emailChanged,
    required bool phoneChanged,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.security, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            const Text('Verification Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve updated your ${emailChanged && phoneChanged
                  ? 'email and phone number'
                  : emailChanged
                  ? 'email'
                  : 'phone number'}.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondary!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please verify your ${emailChanged && phoneChanged
                          ? 'email and phone'
                          : emailChanged
                          ? 'email'
                          : 'phone'} to continue.',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _successMessage =
                    'Profile updated. Please verify your contact information.';
              });
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to appropriate verification page
              if (emailChanged) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmailVerificationPage(
                      email: _emailController.text.trim(),
                      canSkip:
                          phoneChanged, // Can skip if phone also needs verification
                      onVerified: () {
                        Navigator.pop(context);
                        if (phoneChanged) {
                          // After email, verify phone
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhoneVerificationPage(
                                phoneNumber: _phoneController.text.trim(),
                                canSkip: true,
                                onVerified: () {
                                  Navigator.pop(context);
                                  _loadUserData();
                                },
                              ),
                            ),
                          );
                        } else {
                          _loadUserData();
                        }
                      },
                    ),
                  ),
                );
              } else if (phoneChanged) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhoneVerificationPage(
                      phoneNumber: _phoneController.text.trim(),
                      canSkip: true,
                      onVerified: () {
                        Navigator.pop(context);
                        _loadUserData();
                      },
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Verify Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isChangingPassword = true;
      _passwordErrorMessage = null;
    });

    try {
      final authService = AuthService();
      final response = await authService.changePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (response.success) {
        setState(() {
          _showChangePassword = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password changed successfully!'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _passwordErrorMessage = response.error ?? 'Failed to change password';
        });
      }
    } catch (e) {
      setState(() {
        _passwordErrorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isChangingPassword = false;
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
        // Redirect to auth page if not logged in
        if (!appState.isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/auth');
          });
          // Return empty scaffold while redirecting
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
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
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              (appState.user?.firstName ?? 'U')[0]
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.surface,
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
                                ?.copyWith(color: AppColors.primary),
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

                    const SizedBox(height: 24),

                    // Quick Access Features (only when not editing)
                    if (!_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildFeatureCard(
                              context,
                              icon: Icons.card_giftcard,
                              title: 'Rewards',
                              subtitle: 'Points & Badges',
                              color: Colors.orange,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RewardsPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFeatureCard(
                              context,
                              icon: Icons.bookmark,
                              title: 'Saved Searches',
                              subtitle: 'Your searches',
                              color: Colors.blue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SavedSearchesPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Email & Phone Verification Status
                    if (!_isEditing) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.verified_user,
                                  color: Colors.purple[700],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Account Verification',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple[900],
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Email Verification Status
                            _buildVerificationItem(
                              icon: Icons.email,
                              title: 'Email Verification',
                              subtitle: appState.user!.email,
                              isVerified: appState.user!.emailVerified,
                              onVerify: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EmailVerificationPage(
                                      email: appState.user!.email,
                                      canSkip: true,
                                      onVerified: () {
                                        Navigator.pop(context);
                                        _loadUserData();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),

                            const Divider(height: 24),

                            // Phone Verification Status
                            _buildVerificationItem(
                              icon: Icons.phone,
                              title: 'Phone Verification',
                              subtitle: appState.user!.phoneNumber,
                              isVerified: appState.user!.phoneVerified,
                              onVerify: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PhoneVerificationPage(
                                      phoneNumber: appState.user!.phoneNumber,
                                      canSkip: true,
                                      onVerified: () {
                                        Navigator.pop(context);
                                        _loadUserData();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

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

                    const SizedBox(height: 32),

                    // Change Password Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Security',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Changing your password does not affect your verification status',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (!_showChangePassword)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showChangePassword = true;
                                    _passwordErrorMessage = null;
                                  });
                                },
                                icon: const Icon(Icons.key),
                                label: const Text('Change Password'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.surface,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),

                          if (_showChangePassword)
                            Form(
                              key: _passwordFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Password error message
                                  if (_passwordErrorMessage != null)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.secondary!,
                                        ),
                                      ),
                                      child: Text(
                                        _passwordErrorMessage!,
                                        style: TextStyle(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),

                                  // Current password
                                  CustomTextField(
                                    controller: _currentPasswordController,
                                    labelText: 'Current Password',
                                    obscureText: true,
                                    validator: (value) => value?.isEmpty == true
                                        ? 'Current password is required'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // New password
                                  CustomTextField(
                                    controller: _newPasswordController,
                                    labelText: 'New Password',
                                    obscureText: true,
                                    validator: (value) {
                                      if (value?.isEmpty == true) {
                                        return 'New password is required';
                                      }
                                      if (value!.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Confirm password
                                  CustomTextField(
                                    controller: _confirmPasswordController,
                                    labelText: 'Confirm New Password',
                                    obscureText: true,
                                    validator: (value) {
                                      if (value?.isEmpty == true) {
                                        return 'Please confirm your password';
                                      }
                                      if (value !=
                                          _newPasswordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Action buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: LoadingButton(
                                          onPressed: _isChangingPassword
                                              ? null
                                              : _changePassword,
                                          isLoading: _isChangingPassword,
                                          child: const Text('Update Password'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _isChangingPassword
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _showChangePassword = false;
                                                    _passwordErrorMessage =
                                                        null;
                                                    _currentPasswordController
                                                        .clear();
                                                    _newPasswordController
                                                        .clear();
                                                    _confirmPasswordController
                                                        .clear();
                                                  });
                                                },
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
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
                                    AppColors.primary!,
                                    AppColors.primary!.withOpacity(0.3),
                                  ]
                                : [
                                    AppColors.background!,
                                    Colors.orange[100]!.withOpacity(0.3),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                appState.user!.status ==
                                    VerificationStatus.pending
                                ? AppColors.primary!
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
                                        ? AppColors.primary
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
                                        ? AppColors.primary
                                        : AppColors.primary,
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
                                              ? AppColors.primary
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
                                              ? AppColors.primary
                                              : AppColors.primary,
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
                                        builder: (context) =>
                                            KycVerificationPage(
                                              firstName:
                                                  appState.user!.firstName,
                                              lastName: appState.user!.lastName,
                                              email: appState.user!.email,
                                              isNewSignup:
                                                  false, // Existing user
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
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.surface,
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
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.secondary!),
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
                                'Saving changes will set your account to pending. An admin will review your updates.',
                                style: TextStyle(
                                  color: AppColors.primary,
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
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: Colors.red[300]!),
                        ),
                        child: const Text('Logout'),
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
        return AppColors.background!;
      case VerificationStatus.pending:
        return AppColors.primary!;
      case VerificationStatus.notVerified:
        return Colors.orange[100]!;
    }
  }

  Color _getStatusTextColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return AppColors.primary!;
      case VerificationStatus.pending:
        return AppColors.primary!;
      case VerificationStatus.notVerified:
        return AppColors.primary!;
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

  Widget _buildVerificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isVerified,
    required VoidCallback onVerify,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isVerified ? AppColors.background : Colors.orange[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isVerified ? AppColors.primary : AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (isVerified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          ElevatedButton(
            onPressed: onVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Verify',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
