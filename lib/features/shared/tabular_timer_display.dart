import 'package:flutter/material.dart';
import '../../core/theme/homesets_colors.dart';
import '../../core/theme/homesets_typography.dart';

/// Tabular timer display showing seconds or mm:ss with an animated progress ring.
class TabularTimerDisplay extends StatelessWidget {
  final int totalSeconds;
  final int remainingSeconds;

  const TabularTimerDisplay({
    super.key,
    required this.totalSeconds,
    required this.remainingSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0 ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;
    final mins = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;
    final formattedTime = mins > 0
        ? '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'
        : '$secs';

    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background track
            SizedBox(
              width: 210,
              height: 210,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 8,
                valueColor: AlwaysStoppedAnimation<Color>(HomesetsColors.surfaceElevated),
              ),
            ),
            // Active progress ring
            SizedBox(
              width: 210,
              height: 210,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                valueColor: const AlwaysStoppedAnimation<Color>(HomesetsColors.lime),
              ),
            ),
            // Centered tabular readout
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTime,
                  style: HomesetsTypography.displayTimer,
                ),
                Text(
                  mins > 0 ? 'MIN:SEC' : 'SECONDS',
                  style: HomesetsTypography.bodySmall.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
