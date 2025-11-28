import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/property.dart';
import '../services/valuation_service.dart';
import '../services/property_service.dart';
import '../widgets/reward_popup.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_card.dart';

class ValuatePage extends StatefulWidget {
  final String? propertyId;
  
  const ValuatePage({super.key, this.propertyId});

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
  bool _loadingProperty = false;

  @override
  void initState() {
    super.initState();
    if (widget.propertyId != null && widget.propertyId!.isNotEmpty) {
      _loadProperty();
    }
  }

  Future<void> _loadProperty() async {
    if (widget.propertyId == null || widget.propertyId!.isEmpty) return;
    
    setState(() {
      _loadingProperty = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Try to get property from user's properties first
      final userProperties = appState.properties;
      try {
        final property = userProperties.firstWhere(
          (p) => p.propertyId == widget.propertyId,
        );
        _valuateProperty(property);
        setState(() {
          _loadingProperty = false;
        });
        return;
      } catch (e) {
        print('Property not found in user properties, trying to fetch from API: $e');
      }

      // If not found in user properties, try to fetch from API
      final response = await PropertyService.getProperty(widget.propertyId!);
      if (response.success && response.data != null) {
        _valuateProperty(response.data!);
      } else {
        setState(() {
          _errorMessage = 'Could not load property details. Please enter manually.';
        });
      }
    } catch (e) {
      print('Error loading property: $e');
      setState(() {
        _errorMessage = 'Could not load property details. Please enter manually.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingProperty = false;
        });
      }
    }
  }

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
        if (mounted && appState.user?.totalEarnedPoints != null) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => RewardPopup(
              pointsAwarded: 5,
              totalPoints: appState.user!.totalEarnedPoints!,
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

  Widget _buildFeatureChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'SF Pro Text',
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
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              'Property Valuation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
              ),
            ),
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ModernCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.analytics, size: 48, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  'AI Property Valuation',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose from your properties or enter new property details',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'SF Pro Text',
                  ),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'SF Pro Display',
              ),
            ),
            const SizedBox(height: 16),

            ...appState.userProperties
                .map(
                  (property) => ModernCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.home,
                          color: AppColors.surface,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        property.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'SF Pro Text',
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
                                AppColors.primary,
                              ),
                              _buildFeatureChip(
                                Icons.bathtub,
                                '${property.bathrooms} bath',
                                AppColors.accent,
                              ),
                              _buildFeatureChip(
                                Icons.square_foot,
                                '${property.squareFeet} sqft',
                                AppColors.warning,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: ModernButton(
                        text: 'AI Value',
                        icon: Icons.auto_awesome,
                        type: ModernButtonType.primary,
                        onPressed: () => _valuateProperty(property),
                        width: null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 16),

          ModernCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
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
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter property details manually for instant valuation',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'SF Pro Text',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ModernButton(
                  text: 'Enter Property Details',
                  icon: Icons.edit,
                  type: ModernButtonType.primary,
                  onPressed: () => setState(() => _showManualForm = true),
                ),
              ],
            ),
          ),

          // Login prompt for unauthenticated users
          if (!appState.isLoggedIn) ...[
            const SizedBox(height: 24),

            ModernCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.lock, color: AppColors.primary, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Login to Save Valuations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You need to be logged in to save your property valuations and access advanced features',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontFamily: 'SF Pro Text',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ModernButton(
                    text: 'Login to Save',
                    icon: Icons.login,
                    type: ModernButtonType.primary,
                    onPressed: () => Navigator.of(context).pushNamed('/auth'),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ModernCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.edit, size: 48, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  'Property Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter property details for valuation',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'SF Pro Text',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Property Details Form
          ModernCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Property Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                const SizedBox(height: 20),

                ModernTextField(
                  controller: _addressController,
                  labelText: 'Property Address',
                  hintText: 'Enter full address',
                  prefixIcon: const Icon(Icons.location_on),
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Address is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ModernTextField(
                        controller: _bedroomsController,
                        labelText: 'Bedrooms',
                        hintText: '3',
                        prefixIcon: const Icon(Icons.bed),
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
                      child: ModernTextField(
                        controller: _bathroomsController,
                        labelText: 'Bathrooms',
                        hintText: '2',
                        prefixIcon: const Icon(Icons.bathtub),
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
                      child: ModernTextField(
                        controller: _squareFeetController,
                        labelText: 'Square Feet',
                        hintText: '2000',
                        prefixIcon: const Icon(Icons.square_foot),
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
                      child: ModernTextField(
                        controller: _yearBuiltController,
                        labelText: 'Year Built',
                        hintText: '2010',
                        prefixIcon: const Icon(Icons.calendar_today),
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
                      child: ModernButton(
                        text: 'Back',
                        type: ModernButtonType.secondary,
                        onPressed: () {
                          setState(() {
                            _showManualForm = false;
                            _hasValuation = false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ModernButton(
                        text: 'Get AI Valuation',
                        icon: Icons.auto_awesome,
                        type: ModernButtonType.primary,
                        isLoading: _isLoading,
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_addressController.text.isNotEmpty) {
                                  _performValuation();
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Error Message
          if (_errorMessage != null) ...[
            ModernCard(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Valuation Results
          if (_hasValuation && _valuationResult != null) ...[
            // Main Valuation Card
            ModernCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, size: 32, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI Valuation',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontFamily: 'SF Pro Display',
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'AI Powered',
                          style: TextStyle(
                            color: AppColors.surface,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SF Pro Text',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '\$${_valuationResult!.estimatedValue.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Range: \$${_valuationResult!.priceRangeLow.toStringAsFixed(0)} - \$${_valuationResult!.priceRangeHigh.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontFamily: 'SF Pro Text',
                    ),
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
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _valuationResult!.confidence > 0.8
                                ? AppColors.success
                                : _valuationResult!.confidence > 0.6
                                ? AppColors.warning
                                : AppColors.error,
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(_valuationResult!.confidence * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Based on ${_valuationResult!.comparablesCount} comparable properties and ${_valuationResult!.auctionsCount} auctions',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontFamily: 'SF Pro Text',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // AI Reasoning Card
            if (_valuationResult!.aiReasoning != null)
              ModernCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text(
                          'AI Insights',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontFamily: 'SF Pro Display',
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _valuationResult!.aiReasoning!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Market Trends Card
            if (_valuationResult!.marketTrends != null)
              ModernCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text(
                          'Market Trends',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontFamily: 'SF Pro Display',
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _valuationResult!.marketTrends!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Top Comparable Properties
            Text(
              'Top 5 Comparable Properties',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'SF Pro Display',
              ),
            ),
            const SizedBox(height: 16),

            ..._valuationResult!.topComparables.map(
              (property) => ModernCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(Icons.home, color: AppColors.primary),
                  ),
                  title: Text(
                    property.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        property.location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${property.bedrooms} bed • ${property.bathrooms} bath • ${property.squareFeet} sqft',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${property.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                          fontFamily: 'SF Pro Text',
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
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          property.status,
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                property.status.toLowerCase().contains('sold')
                                ? AppColors.success
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SF Pro Text',
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

            ModernCard(
              padding: const EdgeInsets.all(20),
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
