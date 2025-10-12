import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/loading_button.dart';
import 'home_page.dart';

class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key});

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      // Update phone number
      final response = await appState.authService.updateProfile(
        phoneNumber: _phoneController.text.trim(),
      );

      if (response.success) {
        // Refresh user data
        await appState.authService.getCurrentUser();

        if (mounted) {
          // Navigate to home page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to update profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.accentGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      size: 40,
                      color: AppColors.surface,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Complete Your Profile',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Hi ${user?.firstName ?? 'there'}! Please provide your phone number to complete your profile.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Email verified badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${user?.email ?? ''} (Verified)',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Phone Number Field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+1234567890',
                      prefixIcon: const Icon(Icons.phone_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                      if (digitsOnly.length < 10) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Complete Profile Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? AppColors.secondary
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LoadingButton(
                      onPressed: _isLoading ? null : _completeProfile,
                      isLoading: _isLoading,
                      child: const Text(
                        'Complete Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Skip for now (optional)
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const HomePage(),
                              ),
                            );
                          },
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
