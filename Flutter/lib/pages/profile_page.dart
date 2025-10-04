import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';

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

  void _loadUserData() {
    final appState = context.read<AppState>();
    if (appState.user != null) {
      _firstNameController.text = appState.user!.firstName;
      _lastNameController.text = appState.user!.lastName;
      _phoneController.text = appState.user!.phoneNumber;
      _emailController.text = appState.user!.email;
    }
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
        setState(() {
          _successMessage = 'Profile updated successfully!';
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
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
              if (!_isEditing)
                IconButton(
                  onPressed: () => setState(() => _isEditing = true),
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
                              color: appState.user!.isVerified
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              (appState.user?.isVerified ?? false)
                                  ? 'Verified'
                                  : 'Pending Verification',
                              style: TextStyle(
                                color: (appState.user?.isVerified ?? false)
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
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

                    // Gender (read-only)
                    TextFormField(
                      initialValue: appState.user?.gender ?? 'Not specified',
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
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

                    // Action buttons
                    if (_isEditing) ...[
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
}
