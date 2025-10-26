import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MiniGraph extends StatelessWidget {
  final List<num> dataPoints;
  final double height;
  final double width;
  final Color lineColor;
  final Color areaColor;
  final bool showLabels;

  MiniGraph({
    super.key,
    required this.dataPoints,
    this.height = 40,
    this.width = 100,
    Color? lineColor,
    Color? areaColor,
    this.showLabels = false,
  }) : lineColor = lineColor ?? AppColors.primary,
       areaColor = areaColor ?? _defaultAreaColor;

  static final Color _defaultAreaColor = AppColors.primary.withOpacity(0.1);

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty || dataPoints.length < 2) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: areaColor,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final maxValue = dataPoints.reduce((a, b) => a > b ? a : b).toDouble();
    final minValue = dataPoints.reduce((a, b) => a < b ? a : b).toDouble();
    final range = maxValue - minValue;

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _MiniGraphPainter(
          dataPoints: dataPoints,
          maxValue: maxValue,
          minValue: minValue,
          range: range,
          lineColor: lineColor,
          areaColor: areaColor,
          showLabels: showLabels,
        ),
      ),
    );
  }
}

class _MiniGraphPainter extends CustomPainter {
  final List<num> dataPoints;
  final double maxValue;
  final double minValue;
  final double range;
  final Color lineColor;
  final Color areaColor;
  final bool showLabels;

  _MiniGraphPainter({
    required this.dataPoints,
    required this.maxValue,
    required this.minValue,
    required this.range,
    required this.lineColor,
    required this.areaColor,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final areaPaint = Paint()
      ..color = areaColor
      ..style = PaintingStyle.fill;

    // Calculate points
    final points = <Offset>[];
    final double stepX = size.width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      // Flip Y axis (point 0 is at bottom)
      final y =
          size.height -
          ((dataPoints[i].toDouble() - minValue) /
              (range > 0 ? range : 1) *
              size.height);
      points.add(Offset(x, y));
    }

    // Draw area under curve
    final path = Path();
    path.moveTo(points[0].dx, size.height);
    for (final point in points) {
      path.lineTo(point.dx, point.dy);
    }
    path.lineTo(points.last.dx, size.height);
    path.close();
    canvas.drawPath(path, areaPaint);

    // Draw line
    final linePath = Path();
    linePath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    for (final point in points) {
      canvas.drawCircle(point, 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
