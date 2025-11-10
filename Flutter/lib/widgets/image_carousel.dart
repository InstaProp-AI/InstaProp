import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'progressive_network_image.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> images;
  final double height;
  final BoxFit fit;
  final VoidCallback? onTap;
  final bool showDots;

  const ImageCarousel({
    super.key,
    required this.images,
    this.height = 200,
    this.fit = BoxFit.cover,
    this.onTap,
    this.showDots = true,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: widget.height,
        color: AppColors.border,
        child: const Center(
          child: Icon(Icons.image, size: 48, color: AppColors.textSecondary),
        ),
      );
    }

    return Stack(
      children: [
        // PageView for images
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: widget.onTap,
                  child: ProgressiveNetworkImage(
                    imageUrl: widget.images[index],
                    fit: widget.fit,
                    height: widget.height,
                    placeholderColor: AppColors.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),
          ),
        ),

        // Dot indicators
        if (widget.showDots && widget.images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  widget.images.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
