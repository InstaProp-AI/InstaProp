import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Programmatically generated visual illustrations for onboarding screens
class OnboardingVisual extends StatefulWidget {
  final int screenIndex;

  const OnboardingVisual({
    super.key,
    required this.screenIndex,
  });

  @override
  State<OnboardingVisual> createState() => _OnboardingVisualState();
}

class _OnboardingVisualState extends State<OnboardingVisual>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.screenIndex) {
      case 0:
        return _buildWelcomeVisual();
      case 1:
        return _buildSmartSearchVisual();
      case 2:
        return _buildAuctionsVisual();
      case 3:
        return _buildPortfolioVisual();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Screen 1: Welcome - House/building shapes with animated icons
  Widget _buildWelcomeVisual() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final offset = _floatController.value * 10 - 5;
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.35,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background gradient circles
              Positioned(
                top: 40 + offset,
                left: 40,
                child: _buildFloatingCircle(
                  size: 60,
                  color: AppColors.primary.withOpacity(0.1),
                ),
              ),
              Positioned(
                bottom: 60 - offset * 0.7,
                right: 50,
                child: _buildFloatingCircle(
                  size: 80,
                  color: AppColors.accent.withOpacity(0.1),
                ),
              ),
              // Main house building visual
              Transform.translate(
                offset: Offset(0, offset),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Building base
                    Container(
                      width: 180,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withOpacity(0.8),
                            AppColors.primary.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                    // House roof
                    Positioned(
                      top: -40,
                      child: Container(
                        width: 200,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: CustomPaint(
                          painter: _TrianglePainter(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    // Animated icons
                    Positioned(
                      top: 20,
                      child: Transform.scale(
                        scale: 1.0 + (_mainController.value * 0.1),
                        child: Icon(
                          Icons.home_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      right: -30,
                      child: Transform.scale(
                        scale: 1.0 + (_mainController.value * 0.15),
                        child: Icon(
                          Icons.location_city_rounded,
                          size: 50,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Decorative floating circles
              Positioned(
                top: 80 + offset * 1.5,
                right: 30,
                child: _buildFloatingCircle(
                  size: 40,
                  color: AppColors.success.withOpacity(0.2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Screen 2: Smart Search - Map-like visual with location pins
  Widget _buildSmartSearchVisual() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _floatController]),
      builder: (context, child) {
        final offset = _floatController.value * 8 - 4;
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.35,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Map background with gradient
              Container(
                width: 280,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.accent.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              // Search radius rings
              ...List.generate(3, (index) {
                return Positioned(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 800 + (index * 200)),
                    width: 120 + (index * 40) + (_mainController.value * 20),
                    height: 120 + (index * 40) + (_mainController.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3 - (index * 0.1)),
                        width: 2,
                      ),
                    ),
                  ),
                );
              }),
              // Location pins with bounce animation
              Positioned(
                top: 50 + offset,
                left: 80,
                child: _buildLocationPin(
                  delay: 0,
                  color: AppColors.primary,
                ),
              ),
              Positioned(
                top: 100 - offset * 0.8,
                right: 70,
                child: _buildLocationPin(
                  delay: 200,
                  color: AppColors.accent,
                ),
              ),
              Positioned(
                bottom: 80 + offset * 1.2,
                left: 100,
                child: _buildLocationPin(
                  delay: 400,
                  color: AppColors.success,
                ),
              ),
              Positioned(
                bottom: 50 - offset * 0.5,
                right: 90,
                child: _buildLocationPin(
                  delay: 600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Screen 3: Live Auctions - Gavel with rotating animation and bid indicators
  Widget _buildAuctionsVisual() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _floatController]),
      builder: (context, child) {
        final offset = _floatController.value * 6 - 3;
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.35,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background pulsing circles
              ...List.generate(3, (index) {
                return Positioned(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 1000 + (index * 300)),
                    width: 100 + (index * 60) + (_mainController.value * 30),
                    height: 100 + (index * 60) + (_mainController.value * 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withOpacity(0.1 - (index * 0.03)),
                    ),
                  ),
                );
              }),
              // Main gavel icon with rotation
              Transform.translate(
                offset: Offset(0, offset),
                child: Transform.rotate(
                  angle: (_mainController.value * 0.1) - 0.05,
                  child: Icon(
                    Icons.gavel_rounded,
                    size: 100,
                    color: AppColors.primary,
                  ),
                ),
              ),
              // Bid indicators (circular badges)
              Positioned(
                top: 60,
                right: 80,
                child: _buildBidIndicator('127', delay: 0),
              ),
              Positioned(
                top: 100,
                left: 70,
                child: _buildBidIndicator('89', delay: 200),
              ),
              Positioned(
                bottom: 70,
                right: 60,
                child: _buildBidIndicator('156', delay: 400),
              ),
              // "Live" activity indicators
              Positioned(
                top: 50,
                left: 100,
                child: _buildLiveIndicator(),
              ),
              Positioned(
                bottom: 60,
                left: 90,
                child: _buildLiveIndicator(delay: 300),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Screen 4: Portfolio Management - Charts and analytics visual
  Widget _buildPortfolioVisual() {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _floatController]),
      builder: (context, child) {
        final offset = _floatController.value * 5 - 2.5;
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.35,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top section: Trending icon and progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Trending up icon
                  Transform.scale(
                    scale: 1.0 + (_mainController.value * 0.1),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.success,
                            AppColors.success.withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Circular progress indicator
                  Transform.translate(
                    offset: Offset(0, offset * 0.3),
                    child: _buildProgressIndicator(85, AppColors.primary, 0),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Middle section: Line chart
              Expanded(
                child: Transform.translate(
                  offset: Offset(0, offset * 0.5),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: CustomPaint(
                      painter: _LineChartPainter(
                        color: AppColors.primary,
                        animationValue: _mainController.value,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Bottom section: Bar chart
              SizedBox(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(5, (index) {
                      final height =
                          25.0 + (index * 10) + (_mainController.value * 12);
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 500 + (index * 100)),
                        width: 28,
                        height: height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.primary,
                              AppColors.accent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Bottom progress indicator
              Transform.translate(
                offset: Offset(0, -offset * 0.3),
                child: _buildProgressIndicator(65, AppColors.success, 300),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Helper: Floating circle decoration
  Widget _buildFloatingCircle({
    required double size,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Container(
          width: size + (_mainController.value * 10),
          height: size + (_mainController.value * 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        );
      },
    );
  }

  /// Helper: Location pin with bounce animation
  Widget _buildLocationPin({required int delay, required Color color}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Transform.translate(
            offset: Offset(0, -(_mainController.value * 8)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: color,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Helper: Bid indicator badge
  Widget _buildBidIndicator(String bid, {required int delay}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '\$$bid',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Helper: Live activity indicator
  Widget _buildLiveIndicator({int delay = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1000 + delay),
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 16 + (_mainController.value * 4),
          height: 16 + (_mainController.value * 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withOpacity(0.8 + (_mainController.value * 0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withOpacity(0.5),
                blurRadius: 8 + (_mainController.value * 4),
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Helper: Circular progress indicator
  Widget _buildProgressIndicator(
    double percentage,
    Color color,
    int delay,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: percentage / 100),
      duration: Duration(milliseconds: 1000 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 4,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for triangle (roof)
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => false;
}

/// Custom painter for line chart
class _LineChartPainter extends CustomPainter {
  final Color color;
  final double animationValue;

  _LineChartPainter({
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Generate points for upward trend
    final points = List.generate(
      8,
      (index) => Offset(
        (size.width / 7) * index,
        size.height - 20 - (index * 8) - (animationValue * 10),
      ),
    );

    // Draw gradient fill
    final fillPath = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);
    for (var point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (var point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(linePath, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (var point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
