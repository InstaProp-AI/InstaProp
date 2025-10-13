import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../providers/app_state.dart';
import '../services/api_client.dart';
import '../widgets/loading_button.dart';
import 'properties_management_page.dart';

class PropertyDocsUploadPage extends StatefulWidget {
  final int propertyId;
  final String propertyName;

  const PropertyDocsUploadPage({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  State<PropertyDocsUploadPage> createState() => _PropertyDocsUploadPageState();
}

class _PropertyDocsUploadPageState extends State<PropertyDocsUploadPage> {
  List<PlatformFile> _selectedFiles = [];
  Map<String, String> _docTypes = {};
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  final List<String> _availableDocTypes = [
    'Ownership',
    'Legal',
    'FloorPlan',
    'Inspection',
    'Appraisal',
    'Survey',
    'Title',
    'Insurance',
    'Permits',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Property Documents'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Property Documents',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.propertyName,
                    style: TextStyle(
                      color: AppColors.surface.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload supporting documents for your property listing',
                    style: TextStyle(
                      color: AppColors.surface.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // File Upload Section
            Text(
              'Select Documents',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Maximum file size: 50MB per file. Supported formats: PDF, DOC, DOCX, JPG, PNG',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 16),

            // Upload Button
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.secondary!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: _pickFiles,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to select files',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'or drag and drop files here',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Selected Files List
            if (_selectedFiles.isNotEmpty) ...[
              Text(
                'Selected Files (${_selectedFiles.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._selectedFiles.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return _buildFileCard(index, file);
              }).toList(),
            ],

            const SizedBox(height: 24),

            // Error/Success Messages
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.secondary!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_successMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Upload Button
            SizedBox(
              width: double.infinity,
              child: LoadingButton(
                onPressed: _selectedFiles.isEmpty || _isLoading
                    ? null
                    : _uploadFiles,
                isLoading: _isLoading,
                child: Text(
                  _selectedFiles.isEmpty
                      ? 'No files selected'
                      : 'Upload Documents',
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Skip Button - Always visible
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _skipUpload,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Skip for Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(int index, PlatformFile file) {
    final docType = _docTypes[file.name] ?? 'Other';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getFileIcon(file.extension ?? ''),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _removeFile(index),
                  icon: const Icon(Icons.close),
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: docType,
              decoration: const InputDecoration(
                labelText: 'Document Type',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _availableDocTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _docTypes[file.name] = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          // Filter files by size (50MB limit)
          final validFiles = result.files.where((file) {
            return file.size <= 50 * 1024 * 1024; // 50MB in bytes
          }).toList();

          final invalidFiles = result.files.where((file) {
            return file.size > 50 * 1024 * 1024;
          }).toList();

          if (invalidFiles.isNotEmpty) {
            _errorMessage = 'Some files exceed 50MB limit and were not added.';
          }

          _selectedFiles.addAll(validFiles);

          // Set default document types
          for (final file in validFiles) {
            _docTypes[file.name] ??= 'Other';
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting files: $e';
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      final file = _selectedFiles[index];
      _docTypes.remove(file.name);
      _selectedFiles.removeAt(index);
      _errorMessage = null;
    });
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Get auth token
      final appState = Provider.of<AppState>(context, listen: false);
      if (!appState.isLoggedIn) {
        setState(() {
          _errorMessage = 'You must be logged in to upload documents.';
        });
        return;
      }

      final token = appState.token;
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token not found.';
        });
        return;
      }

      // Upload each file
      int successCount = 0;
      int failCount = 0;

      for (final file in _selectedFiles) {
        try {
          // Create multipart request
          var request = http.MultipartRequest(
            'POST',
            Uri.parse(
              '${ApiClient.baseUrl}/api/Property/${widget.propertyId}/documents',
            ),
          );

          // Add headers
          request.headers.addAll({'Authorization': 'Bearer $token'});

          // Add file
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              file.bytes!,
              filename: file.name,
            ),
          );

          // Add document type
          request.fields['docType'] = _docTypes[file.name] ?? 'Other';

          // Send request
          var response = await request.send();

          if (response.statusCode == 200) {
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          failCount++;
          print('Error uploading ${file.name}: $e');
        }
      }

      if (successCount > 0) {
        setState(() {
          _successMessage = 'Successfully uploaded $successCount document(s).';
          if (failCount > 0) {
            _errorMessage = 'Failed to upload $failCount document(s).';
          }
        });

        // If all files uploaded successfully, navigate to properties page
        if (failCount == 0) {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const PropertiesManagementPage(),
              ),
              (route) => false,
            );

            // Show success message on properties page
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Documents uploaded successfully! Property status: Pending Review 📋',
                    ),
                    backgroundColor: Colors.blue,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            });
          }
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to upload documents. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Upload error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _skipUpload() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Skip Document Upload'),
          content: const Text(
            'You can upload documents later from the property details page. Documents are required for property verification and auction listing.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog

                // Check if this is the first screen in the navigation stack
                // If not, just go back. If yes, navigate to properties page
                if (Navigator.of(context).canPop()) {
                  // Just go back to the previous screen
                  Navigator.of(context).pop();

                  // Show info message
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'You can upload documents anytime from the property details 📄',
                          ),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  });
                } else {
                  // Navigate to properties page (for newly created properties)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const PropertiesManagementPage(),
                    ),
                    (route) => false,
                  );

                  // Show success message
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Property saved! Upload documents later to submit for review 📄',
                          ),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
              ),
              child: const Text('Skip for Now'),
            ),
          ],
        );
      },
    );
  }
}
