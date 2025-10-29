import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_animations.dart';

/// Instagram-style heart animation that appears on double-tap
class LikeAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onLike;
  final bool isLiked;
  final double size;

  const LikeAnimation({
    super.key,
    required this.child,
    required this.onLike,
    this.isLiked = false,
    this.size = 200,
  });

  @override
  State<LikeAnimation> createState() => _LikeAnimationState();
}

class _LikeAnimationState extends State<LikeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.heartAnimation,
      vsync: this,
    );

    // Scale animation (0 -> 1.2 -> 0)
    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 1.2),
            weight: 40,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.2, end: 0.0),
            weight: 60,
          ),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: AppAnimations.likeCurve),
        );

    // Rotation animation (-20 -> 20 -> -10)
    _rotationAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: -0.35),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: -0.35, end: 0.0),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: AppAnimations.likeCurve),
        );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerLike() {
    setState(() {
      _showHeart = true;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Trigger like callback
    widget.onLike();

    // Play animation
    _controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _showHeart = false;
        });
        _controller.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _triggerLike,
      child: Stack(
        children: [
          widget.child,
          if (_showHeart)
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Icon(
                          Icons.favorite,
                          color: widget.isLiked ? Colors.red : Colors.white,
                          size: widget.size,
                          shadows: [
                            Shadow(
                              blurRadius: 20,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact like button with animation
class AnimatedLikeButton extends StatefulWidget {
  final bool isLiked;
  final int likes;
  final VoidCallback onTap;
  final double iconSize;
  final double fontSize;

  const AnimatedLikeButton({
    super.key,
    required this.isLiked,
    required this.likes,
    required this.onTap,
    this.iconSize = 24,
    this.fontSize = 14,
  });

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.quick,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != oldWidget.isLiked) {
      HapticFeedback.lightImpact();
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Icon(
                  widget.isLiked ? Icons.favorite : Icons.favorite_border,
                  size: widget.iconSize,
                  color: widget.isLiked ? Colors.red : null,
                ),
              );
            },
          ),
          if (widget.likes > 0) ...[
            const SizedBox(width: 4),
            Text(
              _formatLikes(widget.likes),
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w600,
                color: widget.isLiked ? Colors.red : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatLikes(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}

