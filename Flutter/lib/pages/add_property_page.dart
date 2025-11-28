import '../../theme/app_colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_state.dart';
import '../services/property_service.dart';
import '../services/api_client.dart';
import '../models/project_model.dart';
import '../models/property_type.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_button.dart';
import '../widgets/reward_popup.dart';
import '../core/router/app_router.dart';

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final _unitNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _areaController = TextEditingController();

  PropertyType _selectedType = PropertyType.apartment;
  int _selectedBedrooms = 1;
  int _selectedBathrooms = 1;
  bool _isBuilt = true;
  String? _selectedBuiltYear;
  String? _selectedDeliveryYear;
  String? _selectedProjectId;
  String? _selectedProjectName;

  bool _hasGarden = false;
  bool _hasClubhouse = false;
  bool _hasInfrastructure = false;
  bool _hasUndergroundParking = false;
  bool _hasMedicalCenter = false;
  bool _hasCommercialStrip = false;
  bool _hasBusinessHub = false;
  bool _hasOutdoorPools = false;
  bool _hasBicycleLanes = false;
  bool _hasJoggingTrail = false;

  bool _isLoading = false;
  bool _loadingProjects = false;
  String? _projectsError;
  String? _errorMessage;
  String? _successMessage;

  final List<PlatformFile> _selectedImages = [];
  List<ProjectModel> _projects = [];

  final List<int> _bedroomOptions = List<int>.generate(
    11,
    (index) => index,
  ); // 0-10
  final List<int> _bathroomOptions = List<int>.generate(
    11,
    (index) => index,
  ); // 0-10

  List<String> get _builtYearOptions => List<String>.generate(
    2025 - 1980 + 1,
    (index) => (2025 - index).toString(),
  );

  List<String> get _deliveryYearOptions => List<String>.generate(
    2040 - 2025 + 1,
    (index) => (2025 + index).toString(),
  );

  @override
  void initState() {
    super.initState();
    final builtYears = _builtYearOptions;
    if (builtYears.isNotEmpty) {
      _selectedBuiltYear = builtYears.first;
    }
    final deliveryYears = _deliveryYearOptions;
    if (deliveryYears.isNotEmpty) {
      _selectedDeliveryYear = deliveryYears.first;
    }
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _loadingProjects = true;
      _projectsError = null;
    });

    final response = await ApiClient.getList<ProjectModel>(
      '/api/project/public',
      ProjectModel.fromJson,
    );

    if (!mounted) return;

    if (response.success) {
      setState(() {
        _projects = response.data ?? [];
        _loadingProjects = false;
      });
    } else {
      setState(() {
        _projectsError = response.error ?? 'Failed to load projects';
        _loadingProjects = false;
      });
    }
  }

  @override
  void dispose() {
    _unitNumberController.dispose();
    _locationController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          // Filter valid image files
          final validFiles = result.files.where((file) {
            return file.size <= 50 * 1024 * 1024; // 50MB limit
          }).toList();

          final invalidFiles = result.files.where((file) {
            return file.size > 50 * 1024 * 1024;
          }).toList();

          if (invalidFiles.isNotEmpty) {
            _errorMessage = 'Some files exceed 50MB and were not added.';
          }

          _selectedImages.addAll(validFiles);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one property image';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final normalizedArea = _areaController.text.trim().replaceAll(',', '');
      final areaValue = double.tryParse(normalizedArea);

      if (areaValue == null || areaValue <= 0) {
        setState(() {
          _errorMessage = 'Enter a valid area in square meters';
        });
        return;
      }

      final int areaSqm = areaValue.round();

      final int year = int.parse(
        _isBuilt ? _selectedBuiltYear! : _selectedDeliveryYear!,
      );

      final DateTime? deliveryDate = _isBuilt ? null : DateTime(year, 1, 1);

      ProjectModel? selectedProject;
      if (_selectedProjectId != null) {
        try {
          selectedProject = _projects.firstWhere(
            (project) => project.projectId == _selectedProjectId,
          );
        } catch (_) {
          selectedProject = null;
        }
      }

      final response = await PropertyService.createProperty(
        description: '',
        location: _locationController.text.trim(),
        bedrooms: _selectedBedrooms,
        bathrooms: _selectedBathrooms,
        squareFeet: areaSqm,
        yearBuilt: year,
        type: _selectedType,
        projectId: selectedProject?.projectId,
        projectName: selectedProject?.name ?? _selectedProjectName,
        unitNumber: _unitNumberController.text.trim(),
        hasGardenUnit: _hasGarden,
        hasClubhouseUnit: _hasClubhouse,
        hasInfrastructure: _hasInfrastructure,
        hasUndergroundParking: _hasUndergroundParking,
        hasMedicalCenter: _hasMedicalCenter,
        hasCommercialStrip: _hasCommercialStrip,
        hasBusinessHub: _hasBusinessHub,
        hasOutdoorPools: _hasOutdoorPools,
        hasBicycleLanes: _hasBicycleLanes,
        hasJoggingTrail: _hasJoggingTrail,
        deliveryDate: deliveryDate,
        installmentSummary: null,
      );

      if (response.success && response.data != null) {
        final propertyId = response.data!.propertyId;
        final propertyName = response.data!.name;

        if (_selectedImages.isNotEmpty) {
          final uploadResponse =
              await PropertyService.uploadPropertyImagesPlatform(
                propertyId,
                _selectedImages,
                imageType: 'Gallery',
              );

          if (!uploadResponse.success) {
            setState(() {
              _errorMessage =
                  'Property created but failed to upload images: ${uploadResponse.error}';
            });
            return;
          }
        }

        final appState = context.read<AppState>();
        await appState.refreshUserProfile();
        if (mounted && appState.user?.totalEarnedPoints != null) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => RewardPopup(
              pointsAwarded: 50,
              totalPoints: appState.user!.totalEarnedPoints!,
            ),
          );
        }

        _unitNumberController.clear();
        _locationController.clear();
        _areaController.clear();
        _selectedImages.clear();
        setState(() {
          _selectedType = PropertyType.apartment;
          _selectedBedrooms = 1;
          _selectedBathrooms = 1;
          _isBuilt = true;
          _selectedBuiltYear = _builtYearOptions.isNotEmpty
              ? _builtYearOptions.first
              : null;
          _selectedDeliveryYear = _deliveryYearOptions.isNotEmpty
              ? _deliveryYearOptions.first
              : null;
          _selectedProjectId = null;
          _selectedProjectName = null;
          _hasGarden = false;
          _hasClubhouse = false;
          _hasInfrastructure = false;
          _hasUndergroundParking = false;
          _hasMedicalCenter = false;
          _hasCommercialStrip = false;
          _hasBusinessHub = false;
          _hasOutdoorPools = false;
          _hasBicycleLanes = false;
          _hasJoggingTrail = false;
        });

        context.read<AppState>().loadProperties();

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRouter.addPropertyFinancial,
            arguments: {'propertyId': propertyId, 'propertyName': propertyName},
          );
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
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              'Add Property',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
              ),
            ),
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
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
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'SF Pro Display',
                                ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Fill in the details below to add your property to the platform',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontFamily: 'SF Pro Text',
                                ),
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
                                border: Border.all(color: AppColors.secondary),
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

                          // Unit number
                          ModernTextField(
                            controller: _unitNumberController,
                            labelText: 'Unit Number',
                            hintText: 'e.g., Unit 5B',
                            validator: (value) => value?.trim().isEmpty == true
                                ? 'Unit number is required'
                                : null,
                          ),

                          const SizedBox(height: 16),

                          // Location
                          ModernTextField(
                            controller: _locationController,
                            labelText: 'Location',
                            hintText: 'e.g., 123 Main St, City, State',
                            validator: (value) => value?.trim().isEmpty == true
                                ? 'Location is required'
                                : null,
                          ),

                          const SizedBox(height: 16),

                          _buildProjectDropdown(context),

                          const SizedBox(height: 24),

                          // Property Details Section
                          Text(
                            'Property Details',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'SF Pro Display',
                                ),
                          ),

                          const SizedBox(height: 16),

                          _buildCategoryDropdown(context),

                          const SizedBox(height: 16),

                          _buildBedroomsBathroomsRow(),

                          const SizedBox(height: 16),

                          ModernTextField(
                            controller: _areaController,
                            labelText: 'Area (sqm)',
                            hintText: 'e.g., 185',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Area is required';
                              }
                              final normalized = value.replaceAll(',', '');
                              final number = double.tryParse(normalized);
                              if (number == null || number <= 0) {
                                return 'Enter a valid area';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          _buildConstructionStatusSection(context),

                          const SizedBox(height: 24),

                          _buildAmenitiesSection(context),
                          const SizedBox(height: 24),

                          // Property Images Section
                          Text(
                            'Property Images',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'SF Pro Display',
                                ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Add photos of your property (required)',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontFamily: 'SF Pro Text',
                                ),
                          ),

                          const SizedBox(height: 16),

                          // Image picker button
                          ModernButton(
                            text: 'Select Images',
                            type: ModernButtonType.secondary,
                            onPressed: _pickImages,
                            icon: Icons.add_photo_alternate,
                          ),

                          const SizedBox(height: 16),

                          // Selected images preview
                          if (_selectedImages.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.secondary),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_selectedImages.length} image(s) selected',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _selectedImages.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child:
                                                    _selectedImages[index]
                                                            .bytes !=
                                                        null
                                                    ? Image.memory(
                                                        _selectedImages[index]
                                                            .bytes!,
                                                        width: 100,
                                                        height: 100,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Image.file(
                                                        File(
                                                          _selectedImages[index]
                                                              .path!,
                                                        ),
                                                        width: 100,
                                                        height: 100,
                                                        fit: BoxFit.cover,
                                                      ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      _removeImage(index),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.red,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (index == 0)
                                                Positioned(
                                                  bottom: 4,
                                                  left: 4,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'Main',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 32),

                          // Submit button
                          ModernButton(
                            text: 'Add Property',
                            type: ModernButtonType.primary,
                            onPressed: _isLoading ? null : _submitProperty,
                            isLoading: _isLoading,
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
                              // Lock icon
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
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
                              ModernButton(
                                text: 'Sign In',
                                type: ModernButtonType.primary,
                                onPressed: () =>
                                    Navigator.of(context).pushNamed('/auth'),
                                icon: Icons.login,
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

  Widget _buildProjectDropdown(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );

    Widget content;
    if (_loadingProjects) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_projectsError != null) {
      content = Row(
        children: [
          Expanded(
            child: Text(
              _projectsError!,
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
          IconButton(
            onPressed: _loadProjects,
            icon: const Icon(Icons.refresh),
            tooltip: 'Retry',
          ),
        ],
      );
    } else {
      final items = <DropdownMenuItem<String?>>[
        ..._projects.map(
          (project) => DropdownMenuItem<String?>(
            value: project.projectId,
            child: Text(project.name),
          ),
        ),
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Other / Not Listed'),
        ),
      ];

      content = DropdownButtonFormField<String?>(
        value: _selectedProjectId,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintText: 'Select a project',
        ),
        items: items,
        onChanged: (value) {
          setState(() {
            _selectedProjectId = value;
            if (value != null) {
              try {
                final project = _projects.firstWhere(
                  (p) => p.projectId == value,
                );
                _selectedProjectName = project.name;
              } catch (_) {
                _selectedProjectName = null;
              }
            } else {
              _selectedProjectName = null;
            }
          });
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Project', style: labelStyle),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return DropdownButtonFormField<PropertyType>(
      value: _selectedType,
      decoration: InputDecoration(
        labelText: 'Property Type',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items: PropertyTypeX.orderedValues.map((propertyType) {
        return DropdownMenuItem<PropertyType>(
          value: propertyType,
          child: Text(propertyType.displayName),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedType = value;
        });
      },
    );
  }

  Widget _buildBedroomsBathroomsRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _selectedBedrooms,
            decoration: InputDecoration(
              labelText: 'Bedrooms',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            items: _bedroomOptions.map((value) {
              final label = value >= 10 ? '10+' : value.toString();
              return DropdownMenuItem<int>(value: value, child: Text(label));
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedBedrooms = value;
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _selectedBathrooms,
            decoration: InputDecoration(
              labelText: 'Bathrooms',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            items: _bathroomOptions.map((value) {
              final label = value >= 10 ? '10+' : value.toString();
              return DropdownMenuItem<int>(value: value, child: Text(label));
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedBathrooms = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConstructionStatusSection(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );

    final yearItems = (_isBuilt ? _builtYearOptions : _deliveryYearOptions)
        .map((year) => DropdownMenuItem<String>(value: year, child: Text(year)))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Construction Status', style: textStyle),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Built'),
                selected: _isBuilt,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    _isBuilt = true;
                    _selectedBuiltYear ??= _builtYearOptions.isNotEmpty
                        ? _builtYearOptions.first
                        : null;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Text('Delivering Soon'),
                selected: !_isBuilt,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    _isBuilt = false;
                    _selectedDeliveryYear ??= _deliveryYearOptions.isNotEmpty
                        ? _deliveryYearOptions.first
                        : null;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _isBuilt ? _selectedBuiltYear : _selectedDeliveryYear,
          decoration: InputDecoration(
            labelText: _isBuilt ? 'Year Built' : 'Delivery Year',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: yearItems,
          onChanged: (value) {
            setState(() {
              if (_isBuilt) {
                _selectedBuiltYear = value;
              } else {
                _selectedDeliveryYear = value;
              }
            });
          },
          validator: (value) => value == null ? 'Please select a year' : null,
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Key Amenities', style: titleStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildAmenityChip(
              'Garden',
              _hasGarden,
              (value) => _hasGarden = value,
            ),
            _buildAmenityChip(
              'Clubhouse',
              _hasClubhouse,
              (value) => _hasClubhouse = value,
            ),
            _buildAmenityChip(
              'Infrastructure',
              _hasInfrastructure,
              (value) => _hasInfrastructure = value,
            ),
            _buildAmenityChip(
              'Underground parking',
              _hasUndergroundParking,
              (value) => _hasUndergroundParking = value,
            ),
            _buildAmenityChip(
              'Medical center',
              _hasMedicalCenter,
              (value) => _hasMedicalCenter = value,
            ),
            _buildAmenityChip(
              'Commercial strip',
              _hasCommercialStrip,
              (value) => _hasCommercialStrip = value,
            ),
            _buildAmenityChip(
              'Business hub',
              _hasBusinessHub,
              (value) => _hasBusinessHub = value,
            ),
            _buildAmenityChip(
              'Outdoor pools',
              _hasOutdoorPools,
              (value) => _hasOutdoorPools = value,
            ),
            _buildAmenityChip(
              'Bicycles lanes',
              _hasBicycleLanes,
              (value) => _hasBicycleLanes = value,
            ),
            _buildAmenityChip(
              'Jogging trail',
              _hasJoggingTrail,
              (value) => _hasJoggingTrail = value,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmenityChip(
    String label,
    bool value,
    ValueChanged<bool> update,
  ) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: (selected) {
        setState(() {
          update(selected);
        });
      },
    );
  }
}
