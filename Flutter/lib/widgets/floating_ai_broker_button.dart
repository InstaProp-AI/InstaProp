import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'floating_chat_window.dart';
import '../pages/auth_page.dart';

/// A floating circular button that appears on all pages, similar to Facebook Messenger
/// Shows the AI Broker icon with unread message count badge
/// Sticks to screen edges and opens a floating chat window when tapped
/// Can be dragged to bottom center to dismiss
class FloatingAIBrokerButton extends StatefulWidget {
  const FloatingAIBrokerButton({super.key});

  @override
  State<FloatingAIBrokerButton> createState() => _FloatingAIBrokerButtonState();
}

class _FloatingAIBrokerButtonState extends State<FloatingAIBrokerButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _dismissZoneController;
  late Animation<double> _dismissZoneAnimation;

  // Track position - now using left/right based on which side we're closest to
  double? leftOffset;
  double? rightOffset = 16;
  double topOffset = 100;

  bool _isChatOpen = false;
  bool _isDragging = false;
  bool _showDismissZone = false;
  bool _isOverDismissZone = false;

  // Dismiss zone configuration
  static const double dismissZoneSize = 80.0;
  static const double dismissZoneTriggerDistance = 100.0;

  @override
  void initState() {
    super.initState();

    // Animation for pulsing effect when there are unread messages
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Animation for dismiss zone appearance
    _dismissZoneController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _dismissZoneAnimation = CurvedAnimation(
      parent: _dismissZoneController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dismissZoneController.dispose();
    super.dispose();
  }

  bool _isInDismissZone(double x, double y) {
    final size = MediaQuery.of(context).size;
    final dismissZoneX = size.width / 2;
    final dismissZoneY = size.height - 100;

    // Button center position
    final buttonCenterX = x + 30; // 30 is half of 60px button width
    final buttonCenterY = y + 30;

    // Calculate distance from button center to dismiss zone center
    final distance =
        ((buttonCenterX - dismissZoneX) * (buttonCenterX - dismissZoneX) +
                (buttonCenterY - dismissZoneY) * (buttonCenterY - dismissZoneY))
            .abs()
            .toDouble();

    return distance < (dismissZoneTriggerDistance * dismissZoneTriggerDistance);
  }

  void _snapToEdge() {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;

    // Calculate current center position of the button
    double currentX;
    if (leftOffset != null) {
      currentX = leftOffset! + 30; // Center of 60px button
    } else {
      currentX = screenWidth - (rightOffset ?? 0) - 30; // Center from right
    }

    // Snap to nearest edge (left or right) with animation
    setState(() {
      if (currentX < screenWidth / 2) {
        // Snap to left edge
        leftOffset = 16;
        rightOffset = null;
      } else {
        // Snap to right edge
        leftOffset = null;
        rightOffset = 16;
      }
    });
  }

  Future<void> _openAIBroker() async {
    debugPrint('🔵 FloatingAIBroker: _openAIBroker called');
    debugPrint('🔵 _isChatOpen: $_isChatOpen');

    if (_isChatOpen) {
      debugPrint('🔵 Chat already open, returning');
      return;
    }

    // Check if user is authenticated
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.token == null || appState.token!.isEmpty) {
      debugPrint('🔵 User not authenticated, showing login dialog');
      _showLoginRequiredDialog();
      return;
    }

    debugPrint('🔵 Opening chat window...');
    setState(() => _isChatOpen = true);

    // Load active chat in background
    try {
      await appState.notificationService.markAllAsRead();
    } catch (e) {
      debugPrint('🔵 Error in background tasks: $e');
    }
  }

  /// Show login required dialog with login button
  void _showLoginRequiredDialog() {
    // Ensure we have a valid context
    if (!mounted) {
      debugPrint('❌ Cannot show dialog - widget not mounted');
      return;
    }
    
    // Use post-frame callback to ensure Navigator is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Try to get Navigator - use rootNavigator
      final navigator = Navigator.maybeOf(context, rootNavigator: true);
      
      if (navigator == null) {
        debugPrint('❌ No Navigator found - navigating directly to auth page');
        // Fallback: Navigate directly to auth page
        try {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AuthPage()),
          );
        } catch (e) {
          debugPrint('❌ Failed to navigate: $e');
          // Last resort: show snackbar if ScaffoldMessenger is available
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please sign in to use the AI Broker. Go to Profile to login.'),
                duration: Duration(seconds: 4),
                backgroundColor: Colors.blue,
              ),
            );
          } catch (e2) {
            debugPrint('❌ Could not show snackbar either: $e2');
          }
        }
        return;
      }
      
      // We have a Navigator, show the dialog
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with gradient background
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  ),
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sign Up to Use Our AI Broker',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'SF Pro Display',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Get instant property insights, investment advice, and personalized recommendations from our AI-powered broker.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textSecondary,
                  fontFamily: 'SF Pro Text',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign up now to unlock the full potential of AI-driven real estate assistance.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textTertiary,
                  fontFamily: 'SF Pro Text',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        'Maybe Later',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        // Navigate to auth page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AuthPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.login, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Sign Up / Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SF Pro Text',
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
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Don't show button if hidden
        if (appState.isFloatingButtonHidden) {
          return const SizedBox.shrink();
        }
        
        // Don't show button for sales persons
        if (appState.isSales) {
          return const SizedBox.shrink();
        }

        final unreadCount = appState.notificationService.unreadCount;
        final hasUnread = unreadCount > 0;

        return Stack(
          children: [
            // Floating chat window (when open)
            if (_isChatOpen)
              FloatingChatWindow(
                aichatId: null,
                onClose: () {
                  debugPrint('🔵 Closing chat window');
                  setState(() => _isChatOpen = false);
                },
              ),

            // Don't show button when chat is open
            if (!_isChatOpen) ...[
              // Dismiss Zone (appears at bottom center when dragging)
              if (_showDismissZone)
                Positioned(
                  left:
                      MediaQuery.of(context).size.width / 2 -
                      dismissZoneSize / 2,
                  bottom: 50,
                  child: AnimatedBuilder(
                    animation: _dismissZoneAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _dismissZoneAnimation.value,
                        child: Opacity(
                          opacity: _dismissZoneAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: dismissZoneSize,
                      height: dismissZoneSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isOverDismissZone
                            ? Colors.red.withValues(alpha: 0.8)
                            : Colors.grey.withValues(alpha: 0.6),
                        boxShadow: [
                          BoxShadow(
                            color: _isOverDismissZone
                                ? Colors.red.withValues(alpha: 0.4)
                                : Colors.black26,
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: _isOverDismissZone ? 36 : 32,
                      ),
                    ),
                  ),
                ),

              // Floating AI Broker Button
              Positioned(
                left: leftOffset,
                right: rightOffset,
                top: topOffset,
                child: GestureDetector(
                  onTap: () {
                    debugPrint('🔵 Button tapped! _isDragging: $_isDragging');
                    if (!_isDragging) {
                      debugPrint('🔵 Calling _openAIBroker()');
                      _openAIBroker();
                    } else {
                      debugPrint('🔵 Tap ignored (was dragging)');
                    }
                  },
                  onPanStart: (details) {
                    debugPrint('🔵 Pan start');
                    setState(() {
                      _isDragging = true;
                      _showDismissZone = true;
                    });
                    _dismissZoneController.forward();
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      final size = MediaQuery.of(context).size;

                      // Convert to leftOffset for easier calculation during drag
                      if (rightOffset != null) {
                        leftOffset = size.width - rightOffset! - 60;
                        rightOffset = null;
                      }

                      // Update position based on drag
                      if (leftOffset != null) {
                        leftOffset = (leftOffset! + details.delta.dx).clamp(
                          0.0,
                          size.width - 60.0,
                        );
                      }

                      topOffset = (topOffset + details.delta.dy).clamp(
                        0.0,
                        size.height - 60.0,
                      );

                      // Check if over dismiss zone (only if leftOffset is set)
                      if (leftOffset != null) {
                        _isOverDismissZone = _isInDismissZone(
                          leftOffset!,
                          topOffset,
                        );
                      }
                    });
                  },
                  onPanEnd: (details) {
                    debugPrint('🔵 Pan end');

                    // Check if released over dismiss zone
                    if (_isOverDismissZone) {
                      debugPrint(
                        '🔵 Released over dismiss zone - hiding button',
                      );

                      // Hide button using AppState
                      final appState = Provider.of<AppState>(
                        context,
                        listen: false,
                      );
                      appState.hideFloatingButton();

                      setState(() {
                        _showDismissZone = false;
                      });
                      _dismissZoneController.reverse();

                      // Show a snackbar to inform user how to bring it back
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'AI Broker hidden. Open My Broker to restore.',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.grey[800],
                          duration: const Duration(seconds: 4),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    } else {
                      debugPrint(
                        '🔵 Released outside dismiss zone - snapping to edge',
                      );
                      _snapToEdge();
                      setState(() {
                        _showDismissZone = false;
                        _isOverDismissZone = false;
                      });
                      _dismissZoneController.reverse();
                    }

                    // Reset dragging flag after a short delay to prevent tap trigger
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (mounted) {
                        debugPrint('🔵 Resetting _isDragging to false');
                        setState(() => _isDragging = false);
                      }
                    });
                  },
                  child: AnimatedBuilder(
                    animation: hasUnread
                        ? _scaleAnimation
                        : const AlwaysStoppedAnimation(1.0),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: hasUnread ? _scaleAnimation.value : 1.0,
                        child: Opacity(
                          opacity: _isOverDismissZone ? 0.5 : 1.0,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // AI Icon
                          const Center(
                            child: Icon(
                              Icons.smart_toy,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          // Badge with unread count
                          if (hasUnread)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
