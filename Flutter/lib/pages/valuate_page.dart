import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/app_state.dart';
import '../models/property.dart';

class ValuatePage extends StatefulWidget {
  const ValuatePage({super.key});

  @override
  State<ValuatePage> createState() => _ValuatePageState();
}

class _ValuatePageState extends State<ValuatePage> {
  final _addressController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _squareFeetController = TextEditingController();
  final _yearBuiltController = TextEditingController();

  bool _isLoading = false;
  bool _hasValuation = false;
  double _estimatedValue = 0;
  String _valuationRange = '';
  List<Map<String, dynamic>> _comparableProperties = [];
  bool _showManualForm = false;

  @override
  void dispose() {
    _addressController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _squareFeetController.dispose();
    _yearBuiltController.dispose();
    super.dispose();
  }

  void _valuateProperty(Property property) {
    // Pre-fill form with property data
    _addressController.text = property.location;
    _bedroomsController.text = property.bedrooms.toString();
    _bathroomsController.text = property.bathrooms.toString();
    _squareFeetController.text = property.squareFeet.toString();
    _yearBuiltController.text = property.yearBuilt.toString();

    setState(() {
      _showManualForm = true;
      _hasValuation = false;
    });

    // Auto-perform valuation
    _performValuation();
  }

  void _performValuation() {
    if (_addressController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate AI valuation process
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isLoading = false;
        _hasValuation = true;
        _estimatedValue = 450000.0 + (Random().nextInt(200000)).toDouble();
        _valuationRange =
            '${(_estimatedValue * 0.9).toStringAsFixed(0)} - ${(_estimatedValue * 1.1).toStringAsFixed(0)}';

        // Generate comparable properties
        _comparableProperties = [
          {
            'address': '123 Oak Street',
            'price': 425000,
            'bedrooms': 3,
            'bathrooms': 2,
            'sqft': 1800,
            'soldDate': '2 months ago',
          },
          {
            'address': '456 Pine Avenue',
            'price': 480000,
            'bedrooms': 4,
            'bathrooms': 3,
            'sqft': 2200,
            'soldDate': '1 month ago',
          },
          {
            'address': '789 Maple Drive',
            'price': 520000,
            'bedrooms': 3,
            'bathrooms': 2,
            'sqft': 2000,
            'soldDate': '3 months ago',
          },
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Property Valuation'),
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
          body: _showManualForm
              ? _buildManualForm(context, appState)
              : _buildPropertySelection(context, appState),
        );
      },
    );
  }

  Widget _buildPropertySelection(BuildContext context, AppState appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE3F2FD), Color(0xFFE8F5E8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.analytics, size: 48, color: Colors.blue[700]),
                const SizedBox(height: 12),
                Text(
                  'AI Property Valuation',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose from your properties or enter new property details',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // User Properties Section
          if (appState.isLoggedIn && appState.userProperties.isNotEmpty) ...[
            Text(
              'Your Properties',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ...appState.userProperties
                .map(
                  (property) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(
                          0xFF2E7D32,
                        ).withOpacity(0.1),
                        child: const Icon(Icons.home, color: Color(0xFF2E7D32)),
                      ),
                      title: Text(
                        property.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(property.location),
                          const SizedBox(height: 4),
                          Text(
                            '${property.bedrooms} bed • ${property.bathrooms} bath • ${property.squareFeet} sqft',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _valuateProperty(property),
                        child: const Text('Valuate'),
                      ),
                    ),
                  ),
                )
                .toList(),

            const SizedBox(height: 32),
          ],

          // Manual Entry Section
          Text(
            'Enter New Property Details',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.add_home, size: 48, color: Colors.green[700]),
                  const SizedBox(height: 12),
                  Text(
                    'Don\'t see your property?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter property details manually for instant valuation',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _showManualForm = true),
                    icon: const Icon(Icons.edit),
                    label: const Text('Enter Property Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
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
                    'Login to Save Valuations',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You need to be logged in to save your property valuations and access advanced features',
                    style: TextStyle(color: Colors.orange[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/auth'),
                    icon: const Icon(Icons.login),
                    label: const Text('Login to Save'),
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
    );
  }

  Widget _buildManualForm(BuildContext context, AppState appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE3F2FD), Color(0xFFE8F5E8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.edit, size: 48, color: Colors.blue[700]),
                const SizedBox(height: 12),
                Text(
                  'Property Details',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter property details for valuation',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Property Details Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Property Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Property Address',
                      hintText: 'Enter full address',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Address is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bedroomsController,
                          decoration: const InputDecoration(
                            labelText: 'Bedrooms',
                            hintText: '3',
                            prefixIcon: Icon(Icons.bed),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Required';
                            if (int.tryParse(value!) == null)
                              return 'Invalid number';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _bathroomsController,
                          decoration: const InputDecoration(
                            labelText: 'Bathrooms',
                            hintText: '2',
                            prefixIcon: Icon(Icons.bathtub),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Required';
                            if (int.tryParse(value!) == null)
                              return 'Invalid number';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _squareFeetController,
                          decoration: const InputDecoration(
                            labelText: 'Square Feet',
                            hintText: '2000',
                            prefixIcon: Icon(Icons.square_foot),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Required';
                            if (int.tryParse(value!) == null)
                              return 'Invalid number';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _yearBuiltController,
                          decoration: const InputDecoration(
                            labelText: 'Year Built',
                            hintText: '2010',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Required';
                            if (int.tryParse(value!) == null)
                              return 'Invalid year';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _showManualForm = false;
                              _hasValuation = false;
                            });
                          },
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (_addressController.text.isNotEmpty) {
                                    _performValuation();
                                  }
                                },
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Get Valuation'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Valuation Results
          if (_hasValuation) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valuation Results',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[50]!, Colors.blue[50]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.analytics,
                            size: 48,
                            color: Colors.green[700],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Estimated Value',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${_estimatedValue.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Range: \$${_valuationRange}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Comparable Properties
            Text(
              'Comparable Properties',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ..._comparableProperties
                .map(
                  (property) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Icon(Icons.home, color: Colors.blue[700]),
                      ),
                      title: Text(property['address']),
                      subtitle: Text(
                        '${property['bedrooms']} bed • ${property['bathrooms']} bath • ${property['sqft']} sqft',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${property['price'].toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            property['soldDate'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ],

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
                    'Login to Save Valuation',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You need to be logged in to save your property valuations and access advanced features',
                    style: TextStyle(color: Colors.orange[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/auth'),
                    icon: const Icon(Icons.login),
                    label: const Text('Login to Save'),
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
    );
  }
}
