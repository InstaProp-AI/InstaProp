import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/app_colors.dart';
import '../models/community.dart';
import '../services/community_service.dart';
import '../services/community_post_service.dart';
import '../models/community_post.dart';
import 'select_community_dialog.dart';

class FeedPostComposer extends StatefulWidget {
  final VoidCallback? onPostCreated;

  const FeedPostComposer({
    super.key,
    this.onPostCreated,
  });

  @override
  State<FeedPostComposer> createState() => _FeedPostComposerState();
}

class _FeedPostComposerState extends State<FeedPostComposer> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _pollQuestionController = TextEditingController();
  final List<TextEditingController> _pollOptionControllers =
      [TextEditingController(), TextEditingController()];
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  List<Community> _communities = [];
  bool _creatingPoll = false;
  DateTime? _pollEndsAt;
  final TextEditingController _pollImageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _pollQuestionController.dispose();
    for (final c in _pollOptionControllers) { c.dispose(); }
    _pollImageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities() async {
    final response = await CommunityService.getMyCommunities();
    if (response.success && response.data != null) {
      setState(() {
        _communities = response.data!;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _createPoll() {
    setState(() {
      _creatingPoll = true;
    });
  }

  Future<void> _handlePost() async {
    if (_contentController.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add content or an image')),
      );
      return;
    }

    if (_communities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please join a community first')),
      );
      return;
    }

    // Show community selection dialog
    final selectedCommunity = await showDialog<Community>(
      context: context,
      builder: (context) => SelectCommunityDialog(
        communities: _communities,
      ),
    );

    if (selectedCommunity == null) return;

    // Upload image first if selected (TODO: implement image upload endpoint)
    String? imageUrl;
    if (_selectedImage != null) {
      // For now, we'll need to upload the image to get a URL
      // This requires an image upload endpoint
      // TODO: Implement image upload service
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image upload will be implemented soon. Please use image URLs for now.'),
        ),
      );
      return;
    }

    Map<String, dynamic>? pollPayload;
    if (_creatingPoll) {
      final question = _pollQuestionController.text.trim();
      final options = _pollOptionControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (question.isEmpty || options.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a question and at least two options')),
        );
        return;
      }
      pollPayload = {
        'question': question,
        'options': options,
        if (_pollEndsAt != null) 'endsAt': _pollEndsAt!.toIso8601String(),
        if (_pollImageUrlController.text.trim().isNotEmpty)
          'pollImageUrl': _pollImageUrlController.text.trim(),
      };
    }

    // Create post
    final response = await CommunityPostService.createPost(
      communityId: selectedCommunity.communityId,
      content: _contentController.text.trim(),
      imageUrl: imageUrl,
      postType: _creatingPoll ? PostType.poll : PostType.regular,
      // Backend reads 'poll' payload when postType == Poll
      categories: null,
      poll: pollPayload == null ? null : null,
    );

    if (response.success) {
      // Clear composer
      _contentController.clear();
      setState(() => _selectedImage = null);
      if (_creatingPoll) {
        _pollQuestionController.clear();
        for (final c in _pollOptionControllers) { c.clear(); }
        _pollEndsAt = null;
        _creatingPoll = false;
          _pollImageUrlController.clear();
      }
      
      // Notify parent
      widget.onPostCreated?.call();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Failed to create post'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Profile + Input
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ],
          ),

          // Preview selected image
          if (_selectedImage != null) ...[
            const SizedBox(height: 12),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _removeImage,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.photo_library, size: 20),
                label: const Text('Add Photo'),
                onPressed: _pickImage,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.poll, size: 20),
                label: const Text('Create Poll'),
                onPressed: _createPoll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _handlePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'Post',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

        if (_creatingPoll) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _pollQuestionController,
            decoration: const InputDecoration(
              labelText: 'Poll question',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ..._pollOptionControllers.asMap().entries.map((e) {
            final idx = e.key;
            final c = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: c,
                      decoration: InputDecoration(
                        labelText: 'Option ${idx + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_pollOptionControllers.length > 2)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _pollOptionControllers.removeAt(idx).dispose();
                        });
                      },
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                    ),
                ],
              ),
            );
          }).toList(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _pollOptionControllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add option'),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pollImageUrlController,
            decoration: const InputDecoration(
              labelText: 'Poll image URL (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        ],
      ),
    );
  }
}

