import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/homesets_colors.dart';
import '../../../domain/models/domain_models.dart';

/// Custom painter for body weight trend line chart (WP09).
/// Zero dependencies, uses Flutter Canvas with tabular figures and Performance Lime styling.
class WeightTrendChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final double? rollingAverage;
  final double height;

  const WeightTrendChart({
    super.key,
    required this.entries,
    this.rollingAverage,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            '--',
            style: TextStyle(color: HomesetsColors.textMuted),
          ),
        ),
      );
    }

    final sorted = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WeightChartPainter(
          entries: sorted,
          rollingAverage: rollingAverage,
        ),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<WeightEntry> entries;
  final double? rollingAverage;

  _WeightChartPainter({
    required this.entries,
    this.rollingAverage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 40.0;
    const double paddingRight = 16.0;
    const double paddingTop = 20.0;
    const double paddingBottom = 24.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    double minWeight = entries.first.weightKg;
    double maxWeight = entries.first.weightKg;

    for (final e in entries) {
      if (e.weightKg < minWeight) minWeight = e.weightKg;
      if (e.weightKg > maxWeight) maxWeight = e.weightKg;
    }

    if (rollingAverage != null) {
      if (rollingAverage! < minWeight) minWeight = rollingAverage!;
      if (rollingAverage! > maxWeight) maxWeight = rollingAverage!;
    }

    // Add padding to weight bounds so points don't clip top/bottom
    if ((maxWeight - minWeight).abs() < 0.5) {
      minWeight -= 1.0;
      maxWeight += 1.0;
    } else {
      final range = maxWeight - minWeight;
      minWeight -= range * 0.15;
      maxWeight += range * 0.15;
    }

    final weightRange = maxWeight - minWeight;

    // Draw background grid lines and Y-axis labels
    final gridPaint = Paint()
      ..color = HomesetsColors.borderSubtle.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    const int gridSteps = 3;
    for (int i = 0; i <= gridSteps; i++) {
      final double normalizedY = i / gridSteps;
      final double y = paddingTop + chartHeight * (1.0 - normalizedY);
      final double weightVal = minWeight + weightRange * normalizedY;

      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      final textSpan = TextSpan(
        text: weightVal.toStringAsFixed(1),
        style: const TextStyle(
          color: HomesetsColors.textMuted,
          fontSize: 10,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    // Rolling average horizontal dashed line
    if (rollingAverage != null && weightRange > 0) {
      final double avgY = paddingTop +
          chartHeight * (1.0 - ((rollingAverage! - minWeight) / weightRange));
      final avgPaint = Paint()
        ..color = HomesetsColors.limeDim.withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Draw dashed line
      const double dashWidth = 5.0;
      const double dashSpace = 4.0;
      double startX = paddingLeft;
      while (startX < size.width - paddingRight) {
        canvas.drawLine(
          Offset(startX, avgY),
          Offset(math.min(startX + dashWidth, size.width - paddingRight), avgY),
          avgPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    // Compute coordinate points
    final List<Offset> points = [];
    if (entries.length == 1) {
      final double y = paddingTop +
          chartHeight * (1.0 - ((entries.first.weightKg - minWeight) / weightRange));
      points.add(Offset(paddingLeft + chartWidth / 2, y));
    } else {
      final firstTime = entries.first.loggedAt.millisecondsSinceEpoch;
      final lastTime = entries.last.loggedAt.millisecondsSinceEpoch;
      final timeSpan = math.max(1, lastTime - firstTime);

      for (int i = 0; i < entries.length; i++) {
        final e = entries[i];
        final double xRatio = entries.length == 2
            ? (i / 1.0)
            : ((e.loggedAt.millisecondsSinceEpoch - firstTime) / timeSpan);
        final double x = paddingLeft + chartWidth * xRatio;
        final double y = paddingTop +
            chartHeight * (1.0 - ((e.weightKg - minWeight) / weightRange));
        points.add(Offset(x, y));
      }
    }

    // Draw gradient fill under curve
    if (points.length > 1) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, size.height - paddingBottom);
      fillPath.lineTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath.lineTo(points.last.dx, size.height - paddingBottom);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HomesetsColors.lime.withValues(alpha: 0.25),
            HomesetsColors.lime.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(
          paddingLeft,
          paddingTop,
          chartWidth,
          chartHeight,
        ));

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw connecting line
    if (points.length > 1) {
      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }

      final linePaint = Paint()
        ..color = HomesetsColors.lime
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(linePath, linePaint);
    }

    // Draw data points
    final pointFillPaint = Paint()
      ..color = HomesetsColors.lime
      ..style = PaintingStyle.fill;
    final pointRingPaint = Paint()
      ..color = HomesetsColors.background
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final pt in points) {
      canvas.drawCircle(pt, 4.5, pointFillPaint);
      canvas.drawCircle(pt, 4.5, pointRingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.rollingAverage != rollingAverage;
  }
}

/// Custom painter for exercise strength progression chart (WP09).
/// Plots reps per date with baseline, best, and recent highlights.
class StrengthProgressionChart extends StatelessWidget {
  final List<StrengthDataPoint> points;
  final double height;

  const StrengthProgressionChart({
    super.key,
    required this.points,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            '--',
            style: TextStyle(color: HomesetsColors.textMuted),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _StrengthChartPainter(points: points),
      ),
    );
  }
}

class _StrengthChartPainter extends CustomPainter {
  final List<StrengthDataPoint> points;

  _StrengthChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 32.0;
    const double paddingRight = 16.0;
    const double paddingTop = 26.0;
    const double paddingBottom = 24.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    int maxReps = 0;
    for (final p in points) {
      if (p.maxReps > maxReps) maxReps = p.maxReps;
    }
    if (maxReps < 5) maxReps = 5;
    final double topBound = (maxReps + 2).toDouble();

    // Horizontal gridlines
    final gridPaint = Paint()
      ..color = HomesetsColors.borderSubtle.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    const int gridSteps = 3;
    for (int i = 0; i <= gridSteps; i++) {
      final double normalized = i / gridSteps;
      final double y = paddingTop + chartHeight * (1.0 - normalized);
      final int repVal = (topBound * normalized).round();

      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      final textSpan = TextSpan(
        text: '$repVal',
        style: const TextStyle(
          color: HomesetsColors.textMuted,
          fontSize: 10,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(paddingLeft - tp.width - 6, y - tp.height / 2));
    }

    // Coordinates for each point
    final List<Offset> coords = [];
    final double step = points.length == 1
        ? 0
        : chartWidth / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final double x = points.length == 1
          ? paddingLeft + chartWidth / 2
          : paddingLeft + i * step;
      final double y = paddingTop + chartHeight * (1.0 - (p.maxReps / topBound));
      coords.add(Offset(x, y));
    }

    // Connecting line
    if (coords.length > 1) {
      final linePath = Path();
      linePath.moveTo(coords.first.dx, coords.first.dy);
      for (int i = 1; i < coords.length; i++) {
        linePath.lineTo(coords[i].dx, coords[i].dy);
      }

      final linePaint = Paint()
        ..color = HomesetsColors.lime
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(linePath, linePaint);
    }

    // Points and rep labels
    final pointPaint = Paint()
      ..color = HomesetsColors.lime
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = HomesetsColors.background
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < coords.length; i++) {
      final pt = coords[i];
      final p = points[i];

      canvas.drawCircle(pt, 5.0, pointPaint);
      canvas.drawCircle(pt, 5.0, ringPaint);

      // Rep number label on top of point
      final labelSpan = TextSpan(
        text: '${p.maxReps}',
        style: const TextStyle(
          color: HomesetsColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      );
      final labelTp = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      labelTp.paint(canvas, Offset(pt.dx - labelTp.width / 2, pt.dy - 16));
    }
  }

  @override
  bool shouldRepaint(covariant _StrengthChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
