import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/property_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';
import 'property_docs_upload_page.dart';

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _squareFeetController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _selectedCategory = 'Single Family';
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  final List<String> _categories = [
    'Single Family',
    'Condo',
    'Townhouse',
    'Commercial',
    'Multi-Family',
    'Land',
    'Other',
  ];

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
    super.dispose();
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await PropertyService.createProperty(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        bedrooms: int.parse(_bedroomsController.text),
        bathrooms: int.parse(_bathroomsController.text),
        squareFeet: int.parse(_squareFeetController.text),
        yearBuilt: int.parse(_yearBuiltController.text),
        category: _selectedCategory,
        imageUrl: _imageUrlController.text.trim(),
      );

      if (response.success) {
        setState(() {
          _successMessage = 'Property added successfully!';
        });

        // Save property name before clearing
        final propertyName = _nameController.text.trim();

        // Clear form
        _nameController.clear();
        _descriptionController.clear();
        _locationController.clear();
        _bedroomsController.clear();
        _bathroomsController.clear();
        _squareFeetController.clear();
        _yearBuiltController.clear();
        _imageUrlController.clear();
        setState(() {
          _selectedCategory = 'Single Family';
        });

        // Refresh properties in app state
        context.read<AppState>().loadProperties();

        // Navigate to document upload page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyDocsUploadPage(
                propertyId: response.data!.propertyId,
                propertyName: propertyName,
              ),
            ),
          ).then((_) {
            // After documents are uploaded or skipped, show success and go to properties page
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Property "$propertyName" added successfully! 🎉',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          });
        }
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to add property';
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
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final isLoggedIn = appState.isLoggedIn;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Add Property'),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
          ),
          body: Stack(
            children: [
              // Form content (blurred when not logged in)
              Opacity(
                opacity: isLoggedIn ? 1.0 : 0.3,
                child: AbsorbPointer(
                  absorbing: !isLoggedIn,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          Text(
                            'Add New Property',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Fill in the details below to add your property to the platform',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.primary),
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
                            validator: (value) => value?.isEmpty == true
                                ? 'Property name is required'
                                : null,
                          ),

                          const SizedBox(height: 16),

                          // Description
                          CustomTextField(
                            controller: _descriptionController,
                            labelText: 'Description',
                            hintText: 'Describe your property...',
                            maxLines: 4,
                            validator: (value) => value?.isEmpty == true
                                ? 'Description is required'
                                : null,
                          ),

                          const SizedBox(height: 16),

                          // Location
                          CustomTextField(
                            controller: _locationController,
                            labelText: 'Location',
                            hintText: 'e.g., 123 Main St, City, State',
                            validator: (value) => value?.isEmpty == true
                                ? 'Location is required'
                                : null,
                          ),

                          const SizedBox(height: 16),

                          // Property Details Section
                          Text(
                            'Property Details',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
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
                                  validator: (value) {
                                    if (value?.isEmpty == true)
                                      return 'Bedrooms required';
                                    if (int.tryParse(value!) == null)
                                      return 'Enter valid number';
                                    if (int.parse(value) < 0)
                                      return 'Must be 0 or more';
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
                                  validator: (value) {
                                    if (value?.isEmpty == true)
                                      return 'Bathrooms required';
                                    if (int.tryParse(value!) == null)
                                      return 'Enter valid number';
                                    if (int.parse(value) < 0)
                                      return 'Must be 0 or more';
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

                          // Property Category
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Property Category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            items: _categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                            },
                            validator: (value) => value == null
                                ? 'Please select a category'
                                : null,
                          ),

                          const SizedBox(height: 16),

                          // Image URL
                          CustomTextField(
                            controller: _imageUrlController,
                            labelText: 'Image URL (Optional)',
                            hintText: 'https://example.com/image.jpg',
                            keyboardType: TextInputType.url,
                            validator: (value) {
                              if (value?.isNotEmpty == true) {
                                final uri = Uri.tryParse(value!);
                                if (uri == null ||
                                    !uri.hasScheme ||
                                    !uri.hasAuthority) {
                                  return 'Please enter a valid URL';
                                }
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 32),

                          // Submit button
                          LoadingButton(
                            onPressed: _isLoading ? null : _submitProperty,
                            isLoading: _isLoading,
                            child: const Text('Add Property'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Login overlay (shown when not logged in)
              if (!isLoggedIn)
                Container(
                  color: AppColors.primary.withOpacity(0.6),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Lock icon with gradient background
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green[400]!,
                                      AppColors.primary!,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_outline,
                                  color: AppColors.surface,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Title
                              Text(
                                'Authentication Required',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),

                              // Description
                              Text(
                                'Please sign in to add your property to our auction platform',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      height: 1.5,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              // Login button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      Navigator.of(context).pushNamed('/auth'),
                                  icon: const Icon(Icons.login),
                                  label: const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.surface,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Features list
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'What you can do after signing in:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFeatureItem(
                                      Icons.home_work,
                                      'List your properties',
                                    ),
                                    const SizedBox(height: 8),
                                    _buildFeatureItem(
                                      Icons.gavel,
                                      'Start auctions',
                                    ),
                                    const SizedBox(height: 8),
                                    _buildFeatureItem(
                                      Icons.trending_up,
                                      'Track bids in real-time',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
      ],
    );
  }
}
