import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class ProgressiveNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Color placeholderColor;
  final double maxBlur;

  const ProgressiveNetworkImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.placeholderColor = const Color(0xFFE8ECF3),
    this.maxBlur = 12,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedBorderRadius = borderRadius ?? BorderRadius.zero;
    final placeholderWidget = placeholder ??
        Container(
          color: placeholderColor,
          height: height,
          width: width,
        );

    if (imageUrl.isEmpty) {
      return ClipRRect(
        borderRadius: resolvedBorderRadius,
        child: placeholderWidget,
      );
    }

    return ClipRRect(
      borderRadius: resolvedBorderRadius,
      child: Image.network(
        imageUrl,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => placeholderWidget,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          final totalBytes = loadingProgress.expectedTotalBytes;
          final progress = totalBytes != null && totalBytes > 0
              ? (loadingProgress.cumulativeBytesLoaded / totalBytes)
                  .clamp(0.0, 1.0)
              : 0.0;

          final blur = math.max((1 - progress) * maxBlur, 0.0);
          final overlayOpacity = 0.35 * (1 - progress);

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: placeholderWidget),
              ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: blur,
                  sigmaY: blur,
                ),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(overlayOpacity),
                    BlendMode.srcATop,
                  ),
                  child: child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

