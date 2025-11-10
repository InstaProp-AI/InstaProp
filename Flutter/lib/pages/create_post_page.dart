import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/community_service.dart';
import '../services/community_post_service.dart';
import '../models/community.dart';
import '../theme/app_colors.dart';

class CreatePostPage extends StatefulWidget {
  final int? preSelectedCommunityId;

  const CreatePostPage({
    super.key,
    this.preSelectedCommunityId,
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  File? _selectedImage;
  Community? _selectedCommunity;
  List<Community> _communities = [];
  bool _isLoading = false;
  bool _isLoadingCommunities = false;

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities() async {
    setState(() => _isLoadingCommunities = true);
    final response = await CommunityService.getMyCommunities();
    if (response.success && response.data != null) {
      setState(() {
        _communities = response.data!;
        if (widget.preSelectedCommunityId != null) {
          try {
            _selectedCommunity = _communities.firstWhere(
              (c) => c.communityId == widget.preSelectedCommunityId,
            );
          } catch (_) {
            if (_communities.isNotEmpty) {
              _selectedCommunity = _communities.first;
            }
          }
        } else if (_communities.isNotEmpty) {
          _selectedCommunity = _communities.first;
        }
        _isLoadingCommunities = false;
      });
    } else {
      setState(() => _isLoadingCommunities = false);
    }
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate() || _selectedCommunity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a community and enter content'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Upload image to backend first and get URL
      String? imageUrl;
      if (_selectedImage != null) {
        // For now, placeholder - implement image upload service
        imageUrl = _selectedImage!.path;
      }

      final response = await CommunityPostService.createPost(
        communityId: _selectedCommunity!.communityId,
        content: _contentController.text.trim(),
        imageUrl: imageUrl,
      );

      if (response.success && mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to create post'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitPost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Community selector
              if (_isLoadingCommunities)
                const Center(child: CircularProgressIndicator())
              else if (_communities.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(height: 8),
                      const Text(
                        'You need to join a community first',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Join communities to start posting',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<Community>(
                  value: _selectedCommunity,
                  decoration: const InputDecoration(
                    labelText: 'Community',
                    border: OutlineInputBorder(),
                  ),
                  items: _communities.map((community) {
                    return DropdownMenuItem(
                      value: community,
                      child: Text(community.name),
                    );
                  }).toList(),
                  onChanged: (community) {
                    setState(() {
                      _selectedCommunity = community;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Please select a community';
                    return null;
                  },
                ),

              const SizedBox(height: 24),

              // Content field
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'What\'s on your mind?',
                  hintText: 'Write your post content here...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter post content';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Image section
              if (_selectedImage != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                        onPressed: _removeImage,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      onPressed: _pickImage,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      onPressed: _takePhoto,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

