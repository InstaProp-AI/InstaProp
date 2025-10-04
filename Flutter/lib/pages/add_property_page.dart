import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/property_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';

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
  final _priceController = TextEditingController();
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
    _priceController.dispose();
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
        startingPrice: double.parse(_priceController.text),
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

        // Clear form
        _nameController.clear();
        _descriptionController.clear();
        _locationController.clear();
        _priceController.clear();
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

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
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
        // Always show the full form, but add login prompt for unauthenticated users

        return Scaffold(
          appBar: AppBar(
            title: const Text('Add Property'),
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
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
                    'Add New Property',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Fill in the details below to add your property to the platform',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
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
                    validator: (value) =>
                        value?.isEmpty == true ? 'Location is required' : null,
                  ),

                  const SizedBox(height: 16),

                  // Starting price
                  CustomTextField(
                    controller: _priceController,
                    labelText: 'Starting Price',
                    hintText: 'e.g., 250000',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty == true)
                        return 'Starting price is required';
                      if (double.tryParse(value!) == null)
                        return 'Please enter a valid number';
                      if (double.parse(value) <= 0)
                        return 'Price must be greater than 0';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Property Details Section
                  Text(
                    'Property Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                    validator: (value) =>
                        value == null ? 'Please select a category' : null,
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

                  const SizedBox(height: 16),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your property will be reviewed by our team before being approved for auction.',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Login prompt for unauthenticated users
                  if (!appState.isLoggedIn) ...[
                    const SizedBox(height: 24),

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
                            'Login to Submit Property',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You need to be logged in to submit your property for auction',
                            style: TextStyle(color: Colors.orange[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/auth'),
                            icon: const Icon(Icons.login),
                            label: const Text('Login to Submit'),
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
