import 'dart:ui';
import 'package:flutter/material.dart';
import 'homesets_colors.dart';

/// HOMESETS Approved Typography Hierarchy (GOV12)
/// Employs clean modern sans-serif with Direction A precision tabular figures
/// for jitter-free timers, rep steppers, and set progress indicators.
class HomesetsTypography {
  HomesetsTypography._();

  static const TextStyle displayTimer = TextStyle(
    fontSize: 54,
    fontWeight: FontWeight.w800,
    color: HomesetsColors.lime,
    letterSpacing: -1.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle displayRepCount = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: HomesetsColors.textPrimary,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: HomesetsColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: HomesetsColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: HomesetsColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: HomesetsColors.textPrimary,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: HomesetsColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: HomesetsColors.textMuted,
    height: 1.4,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static const TextStyle tabularBadge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: HomesetsColors.lime,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle wordmark = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.5,
    color: HomesetsColors.textPrimary,
  );
}
