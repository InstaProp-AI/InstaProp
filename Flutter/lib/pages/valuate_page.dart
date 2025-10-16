import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/property.dart';
import '../services/valuation_service.dart';
import '../widgets/reward_popup.dart';

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
  EnhancedValuationResult? _valuationResult;
  bool _showManualForm = false;
  String? _errorMessage;

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

  Future<void> _performValuation() async {
    if (_addressController.text.isEmpty ||
        _bedroomsController.text.isEmpty ||
        _bathroomsController.text.isEmpty ||
        _squareFeetController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all required fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = ValuationRequest(
        location: _addressController.text,
        bedrooms: int.parse(_bedroomsController.text),
        bathrooms: int.parse(_bathroomsController.text),
        squareFeet: int.parse(_squareFeetController.text),
        yearBuilt:
            int.tryParse(_yearBuiltController.text) ?? DateTime.now().year,
        propertyType: 'Residential',
      );

      final response = await ValuationService.calculateAIValuation(request);

      if (response.success && response.data != null) {
        setState(() {
          _valuationResult = response.data;
          _hasValuation = true;
          _errorMessage = null;
        });
        // Show reward popup after valuation
        final appState = context.read<AppState>();
        await appState.refreshUserProfile();
        if (mounted && appState.user?.totalPoints != null) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => RewardPopup(
              pointsAwarded: 5,
              totalPoints: appState.user!.totalPoints!,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to calculate valuation';
          _hasValuation = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error calculating valuation: $e';
        _hasValuation = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildFeatureChip(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color[700],
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Property Valuation'),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
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
                colors: AppColors.accentGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary),
            ),
            child: Column(
              children: [
                Icon(Icons.analytics, size: 48, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  'AI Property Valuation',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose from your properties or enter new property details',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Debug logging
          Builder(
            builder: (context) {
              print('📊 Valuate Page Debug:');
              print('  Is Logged In: ${appState.isLoggedIn}');
              print('  Total Properties: ${appState.properties.length}');
              print('  User ID: ${appState.user?.accountId}');
              print('  User Properties: ${appState.userProperties.length}');
              return const SizedBox.shrink();
            },
          ),

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
                  (property) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.surface, AppColors.background],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green[200]!, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, Colors.green[400]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.home,
                          color: AppColors.surface,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        property.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  property.location,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildFeatureChip(
                                Icons.bed,
                                '${property.bedrooms} bed',
                                Colors.blue,
                              ),
                              _buildFeatureChip(
                                Icons.bathtub,
                                '${property.bathrooms} bath',
                                Colors.purple,
                              ),
                              _buildFeatureChip(
                                Icons.square_foot,
                                '${property.squareFeet} sqft',
                                Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: ElevatedButton.icon(
                        onPressed: () => _valuateProperty(property),
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('AI Value'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
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

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[50]!, Colors.purple[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple[300]!, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple[600]!, Colors.purple[400]!],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_home,
                    size: 32,
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Don\'t see your property?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter property details manually for instant valuation',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.purple[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple[600]!, Colors.purple[400]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showManualForm = true),
                    icon: const Icon(Icons.edit),
                    label: const Text('Enter Property Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
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
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary),
              ),
              child: Column(
                children: [
                  Icon(Icons.lock, color: AppColors.primary, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Login to Save Valuations',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You need to be logged in to save your property valuations and access advanced features',
                    style: TextStyle(color: AppColors.primary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/auth'),
                    icon: const Icon(Icons.login),
                    label: const Text('Login to Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
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
                colors: AppColors.accentGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary),
            ),
            child: Column(
              children: [
                Icon(Icons.edit, size: 48, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  'Property Details',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter property details for valuation',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Get AI Valuation',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'AI',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Error Message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Valuation Results
          if (_hasValuation && _valuationResult != null) ...[
            // Main Valuation Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.green[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          size: 32,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'AI Valuation',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AI Powered',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '\$${_valuationResult!.estimatedValue.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Range: \$${_valuationResult!.priceRangeLow.toStringAsFixed(0)} - \$${_valuationResult!.priceRangeHigh.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    // Confidence Indicator
                    Row(
                      children: [
                        const Text(
                          'Confidence: ',
                          style: TextStyle(fontSize: 14),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _valuationResult!.confidence,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _valuationResult!.confidence > 0.8
                                  ? Colors.green
                                  : _valuationResult!.confidence > 0.6
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(_valuationResult!.confidence * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Based on ${_valuationResult!.comparablesCount} comparable properties and ${_valuationResult!.auctionsCount} auctions',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // AI Reasoning Card
            if (_valuationResult!.aiReasoning != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'AI Insights',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _valuationResult!.aiReasoning!,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Market Trends Card
            if (_valuationResult!.marketTrends != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Market Trends',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _valuationResult!.marketTrends!,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Top Comparable Properties
            Text(
              'Top 5 Comparable Properties',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ..._valuationResult!.topComparables.map(
              (property) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.home, color: Colors.blue[700]),
                  ),
                  title: Text(
                    property.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        property.location,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${property.bedrooms} bed • ${property.bathrooms} bath • ${property.squareFeet} sqft',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${property.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: property.status.toLowerCase().contains('sold')
                              ? Colors.green[100]
                              : Colors.blue[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          property.status,
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                property.status.toLowerCase().contains('sold')
                                ? Colors.green[700]
                                : Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Login prompt for unauthenticated users
          if (!appState.isLoggedIn) ...[
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary),
              ),
              child: Column(
                children: [
                  Icon(Icons.lock, color: AppColors.primary, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Login to Save Valuation',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You need to be logged in to save your property valuations and access advanced features',
                    style: TextStyle(color: AppColors.primary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/auth'),
                    icon: const Icon(Icons.login),
                    label: const Text('Login to Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
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
