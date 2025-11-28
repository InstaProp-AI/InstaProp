import '../../theme/app_colors.dart';
import '../../theme/app_animations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../services/google_sign_in_service.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_card.dart';
import 'kyc_verification_page.dart';
import 'home_page.dart';
import 'email_verification_page.dart';
import 'phone_verification_page.dart';
import 'forgot_password_dialog.dart';
import 'force_change_password_page.dart';
import 'profile_completion_page.dart';
import 'sales_chats_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLogin = true;

  // Login form
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Signup form
  final _signupFormKey = GlobalKey<FormState>();
  final _signupFirstNameController = TextEditingController();
  final _signupLastNameController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  String _selectedGender = 'Male';
  String? _selectedTimeZone; // User's preferred timezone

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureLoginPassword = true;

  final GoogleSignInService _googleSignInService = GoogleSignInService();

  // Live validation states
  bool _passwordsMatch = true;
  bool _emailValid = true;
  bool _phoneValid = true;
  bool _emailExists = false;
  bool _phoneExists = false;
  bool _checkingEmail = false;
  bool _checkingPhone = false;

  // Password strength requirements
  bool _hasMinLength = false;
  bool _hasLetters = false;
  bool _hasNumbers = false;

  // Debounce timers
  Timer? _emailDebounce;
  Timer? _phoneDebounce;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.normal, // 300ms
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: AppAnimations.defaultCurve,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupFirstNameController.dispose();
    _signupLastNameController.dispose();
    _signupPhoneController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    _emailDebounce?.cancel();
    _phoneDebounce?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailAvailability(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _emailExists = false;
        _checkingEmail = false;
      });
      return;
    }

    setState(() => _checkingEmail = true);

    try {
      final authService = AuthService();
      final response = await authService.checkEmailExists(email);

      if (mounted) {
        setState(() {
          _emailExists = response.success && response.data == true;
          _checkingEmail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingEmail = false;
        });
      }
    }
  }

  Future<void> _checkPhoneAvailability(String phone) async {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) {
      setState(() {
        _phoneExists = false;
        _checkingPhone = false;
      });
      return;
    }

    setState(() => _checkingPhone = true);

    try {
      final authService = AuthService();
      final response = await authService.checkPhoneExists(phone);

      if (mounted) {
        setState(() {
          _phoneExists = response.success && response.data == true;
          _checkingPhone = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingPhone = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = context.read<AppState>();
      final response = await appState.login(
        _loginEmailController.text.trim(),
        _loginPasswordController.text,
      );

      // Note: We no longer block login for suspended users (403 status)
      // They can login but won't be able to place bids

      if (response.success && mounted) {
        // Check if user requires password change
        if (appState.user?.requiresPasswordChange == true) {
          // Navigate to force change password page
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const ForceChangePasswordPage(),
            ),
            (route) => false,
          );
        } else {
          // Check if user is sales - redirect to sales chats page
          if (appState.user?.isSales == true) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const SalesChatsPage()),
              (route) => false,
            );
          } else {
            // Navigate to home page and remove all previous routes
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          }

          // Show welcome message
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Welcome back, ${appState.user?.firstName}! 👋',
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          });
        }
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Invalid email or password';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;

    if (_signupPasswordController.text !=
        _signupConfirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (_emailExists) {
      setState(() {
        _errorMessage = 'This email is already registered';
      });
      return;
    }

    if (_phoneExists) {
      setState(() {
        _errorMessage = 'This phone number is already registered';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create account immediately
      final appState = context.read<AppState>();
      final success = await appState.signup(
        firstName: _signupFirstNameController.text.trim(),
        lastName: _signupLastNameController.text.trim(),
        phoneNumber: _signupPhoneController.text.trim(),
        email: _signupEmailController.text.trim(),
        password: _signupPasswordController.text,
        timeZone: _selectedTimeZone,
      );

      if (success && mounted) {
        // Account created! Now navigate to email verification first
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationPage(
              email: _signupEmailController.text.trim(),
              canSkip: false, // Cannot skip during signup
              onVerified: () {
                // After email verification, navigate to phone verification
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhoneVerificationPage(
                      phoneNumber: _signupPhoneController.text.trim(),
                      canSkip: false, // Cannot skip during signup
                      onVerified: () {
                        // After phone verification, navigate to KYC page
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => KycVerificationPage(
                              firstName: _signupFirstNameController.text.trim(),
                              lastName: _signupLastNameController.text.trim(),
                              email: _signupEmailController.text.trim(),
                              isNewSignup: true, // New user during signup
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Signup failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Signup failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _googleSignInService.signInWithGoogle();

      if (!result.success) {
        setState(() {
          _errorMessage = result.error ?? 'Google Sign-In failed';
          _isGoogleLoading = false;
        });
        return;
      }

      // Set user in app state - manually update authService since this is OAuth
      final appState = Provider.of<AppState>(context, listen: false);
      // Force refresh user data to update app state
      await appState.authService.getCurrentUser();

      setState(() {
        _isGoogleLoading = false;
      });

      // Navigate based on profile completion needs
      if (!mounted) return;

      final phoneNumber = result.account?.phoneNumber;
      if (result.requiresProfileCompletion ||
          phoneNumber == null ||
          phoneNumber.isEmpty) {
        // Navigate to profile completion
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ProfileCompletionPage(),
          ),
        );
      } else {
        // Navigate to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-In failed: $e';
        _isGoogleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // #F8F9FA
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Close Button
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconButton(
                    onPressed: () {
                      // Try to pop, if can't pop (no previous route), go to home
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowCard,
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowCard,
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.home_work_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Title
                        const Text(
                          'Instaprop',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _isLogin
                              ? 'Welcome back!'
                              : 'Create your account',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'SF Pro Text',
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Error Message
                        if (_errorMessage != null)
                          ModernCard(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: AppColors.error.withOpacity(0.1),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.normal,
                                      fontFamily: 'SF Pro Text',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Forms
                        Container(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: _isLogin
                              ? _buildLoginForm()
                              : _buildSignupForm(),
                        ),

                        const SizedBox(height: 24),

                        // Toggle Login/Signup
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? "Don't have an account? "
                                  : "Already have an account? ",
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                fontFamily: 'SF Pro Text',
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _errorMessage = null;
                                });
                              },
                              child: Text(
                                _isLogin ? 'Sign Up' : 'Login',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SF Pro Text',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ModernTextField(
            controller: _loginEmailController,
            labelText: 'Email',
            hintText: 'your.email@example.com',
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty == true) return 'Email is required';
              if (!value!.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          ModernTextField(
            controller: _loginPasswordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            obscureText: _obscureLoginPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () {
                setState(() => _obscureLoginPassword = !_obscureLoginPassword);
              },
            ),
            validator: (value) {
              if (value?.isEmpty == true) return 'Password is required';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ForgotPasswordDialog(),
                );
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ModernButton(
            text: 'Login',
            type: ModernButtonType.primary,
            onPressed: _isLoading ? null : _handleLogin,
            isLoading: _isLoading,
          ),

          const SizedBox(height: 24),

          // Divider with OR
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.normal,
                    fontSize: 13,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.divider)),
            ],
          ),

          const SizedBox(height: 24),

          // Google Sign-In Button (Login)
          ModernButton(
            text: 'Continue with Google',
            type: ModernButtonType.secondary,
            icon: Icons.email_outlined,
            onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
            isLoading: _isGoogleLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ModernTextField(
                  controller: _signupFirstNameController,
                  labelText: 'First Name',
                  hintText: 'John',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ModernTextField(
                  controller: _signupLastNameController,
                  labelText: 'Last Name',
                  hintText: 'Doe',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ModernTextField(
            controller: _signupEmailController,
            labelText: 'Email',
            hintText: 'your.email@example.com',
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              setState(() {
                _emailValid =
                    value.isEmpty ||
                    (value.contains('@') && value.contains('.'));
              });

              // Debounce email check
              _emailDebounce?.cancel();
              _emailDebounce = Timer(const Duration(milliseconds: 800), () {
                _checkEmailAvailability(value);
              });
            },
            suffixIcon: _checkingEmail
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            validator: (value) {
              if (value?.isEmpty == true) return 'Email is required';
              if (!value!.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          if (!_emailValid && _signupEmailController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Please enter a valid email address',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          if (_emailExists && _signupEmailController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'This email is already registered',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ModernTextField(
            controller: _signupPhoneController,
            labelText: 'Phone Number',
            hintText: '+1 234 567 8900',
            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              setState(() {
                // Basic phone validation - at least 10 digits
                final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                _phoneValid = value.isEmpty || digitsOnly.length >= 10;
              });

              // Debounce phone check
              _phoneDebounce?.cancel();
              _phoneDebounce = Timer(const Duration(milliseconds: 800), () {
                _checkPhoneAvailability(value);
              });
            },
            suffixIcon: _checkingPhone
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            validator: (value) =>
                value?.isEmpty == true ? 'Phone is required' : null,
          ),
          if (!_phoneValid && _signupPhoneController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Phone number must have at least 10 digits',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          if (_phoneExists && _signupPhoneController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'This phone number is already registered',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                prefixIcon: Icon(Icons.wc_outlined, color: AppColors.textSecondary, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              dropdownColor: AppColors.surface,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontFamily: 'SF Pro Text',
              ),
              items: ['Male', 'Female'].map((gender) {
                return DropdownMenuItem(value: gender, child: Text(gender));
              }).toList(),
              onChanged: (value) => setState(() => _selectedGender = value!),
            ),
          ),
          const SizedBox(height: 16),
          ModernTextField(
            controller: _signupPasswordController,
            labelText: 'Password',
            hintText: 'At least 8 characters',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            obscureText: _obscurePassword,
            onChanged: (value) {
              setState(() {
                // Check password requirements
                _hasMinLength = value.length >= 8;
                _hasLetters = RegExp(r'[a-zA-Z]').hasMatch(value);
                _hasNumbers = RegExp(r'[0-9]').hasMatch(value);

                // Check if passwords match
                _passwordsMatch =
                    _signupConfirmPasswordController.text.isEmpty ||
                    value == _signupConfirmPasswordController.text;
              });
            },
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value?.isEmpty == true) return 'Password is required';
              if (value!.length < 8) return 'Min 8 characters';
              if (!RegExp(r'[a-zA-Z]').hasMatch(value))
                return 'Must contain letters';
              if (!RegExp(r'[0-9]').hasMatch(value))
                return 'Must contain numbers';
              return null;
            },
          ),
          if (_signupPasswordController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPasswordRequirement(
                    'At least 8 characters',
                    _hasMinLength,
                  ),
                  const SizedBox(height: 6),
                  _buildPasswordRequirement('Contains letters', _hasLetters),
                  const SizedBox(height: 6),
                  _buildPasswordRequirement('Contains numbers', _hasNumbers),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ModernTextField(
            controller: _signupConfirmPasswordController,
            labelText: 'Confirm Password',
            hintText: 'Re-enter password',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            obscureText: _obscureConfirmPassword,
            onChanged: (value) {
              setState(() {
                _passwordsMatch =
                    _signupPasswordController.text.isEmpty ||
                    value == _signupPasswordController.text;
              });
            },
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
            validator: (value) =>
                value?.isEmpty == true ? 'Confirm password' : null,
          ),
          if (!_passwordsMatch &&
              _signupConfirmPasswordController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Passwords do not match',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          if (_passwordsMatch &&
              _signupConfirmPasswordController.text.isNotEmpty &&
              _signupPasswordController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Passwords match',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          ModernButton(
            text: 'Sign up',
            type: ModernButtonType.primary,
            onPressed: _isLoading ? null : _handleSignup,
            isLoading: _isLoading,
          ),

          const SizedBox(height: 24),

          // Divider with OR
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.normal,
                    fontSize: 13,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.divider)),
            ],
          ),

          const SizedBox(height: 24),

          // Google Sign-In Button (Signup)
          ModernButton(
            text: 'Continue with Google',
            type: ModernButtonType.secondary,
            icon: Icons.email_outlined,
            onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
            isLoading: _isGoogleLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: isMet ? AppColors.success : AppColors.textTertiary,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isMet ? AppColors.success : AppColors.textSecondary,
            fontWeight: FontWeight.normal,
            fontFamily: 'SF Pro Text',
          ),
        ),
      ],
    );
  }
}



