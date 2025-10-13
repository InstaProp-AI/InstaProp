import 'package:flutter/material.dart';
import '../models/property_image.dart';
import '../../theme/app_colors.dart';

class PropertyImageCarousel extends StatefulWidget {
  final List<PropertyImage> images;
  final String? fallbackImageUrl;
  final double height;
  final bool showIndicators;
  final bool showNavigationButtons;
  final bool showImageCounter;
  final BorderRadius? borderRadius;

  const PropertyImageCarousel({
    super.key,
    required this.images,
    this.fallbackImageUrl,
    this.height = 200,
    this.showIndicators = true,
    this.showNavigationButtons = true,
    this.showImageCounter = true,
    this.borderRadius,
  });

  @override
  State<PropertyImageCarousel> createState() => _PropertyImageCarouselState();
}

class _PropertyImageCarouselState extends State<PropertyImageCarousel> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get imageUrls {
    if (widget.images.isEmpty) {
      return widget.fallbackImageUrl != null &&
              widget.fallbackImageUrl!.isNotEmpty
          ? [widget.fallbackImageUrl!]
          : [];
    }
    return widget.images
        .map((img) => img.imageUrl)
        .where((url) => url.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final urls = imageUrls;

    if (urls.isEmpty) {
      return _buildPlaceholder();
    }

    if (urls.length == 1) {
      return _buildSingleImage(urls[0]);
    }

    return Stack(
      children: [
        // Image PageView - Scrollable/Swipeable
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            physics: const AlwaysScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: urls.length,
            itemBuilder: (context, index) {
              return _buildImageItem(urls[index]);
            },
          ),
        ),

        // Previous button (if more than 1 image and enabled)
        if (urls.length > 1 &&
            widget.showNavigationButtons &&
            _currentIndex > 0)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildNavigationButton(Icons.chevron_left, () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }),
            ),
          ),

        // Next button (if more than 1 image and enabled)
        if (urls.length > 1 &&
            widget.showNavigationButtons &&
            _currentIndex < urls.length - 1)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildNavigationButton(Icons.chevron_right, () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }),
            ),
          ),

        // Indicators
        if (widget.showIndicators && urls.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                urls.length,
                (index) => _buildIndicator(index == _currentIndex),
              ),
            ),
          ),

        // Image counter badge (if enabled)
        if (urls.length > 1 && widget.showImageCounter)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentIndex + 1} / ${urls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleImage(String url) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Image.network(
        url,
        height: widget.height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      ),
    );
  }

  Widget _buildImageItem(String url) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: Icon(Icons.home, size: 50, color: AppColors.secondary),
      ),
    );
  }

  Widget _buildNavigationButton(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
