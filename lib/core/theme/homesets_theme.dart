import 'package:flutter/material.dart';
import 'homesets_colors.dart';
import 'homesets_typography.dart';

/// HOMESETS Primary Hybrid Theme Definition (GOV12)
class HomesetsTheme {
  HomesetsTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: HomesetsColors.background,
      colorScheme: const ColorScheme.dark(
        surface: HomesetsColors.surface,
        primary: HomesetsColors.lime,
        onPrimary: HomesetsColors.textOnLime,
        secondary: HomesetsColors.limeDim,
        onSecondary: HomesetsColors.textOnLime,
        error: HomesetsColors.orange,
        onError: HomesetsColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: HomesetsColors.background,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: HomesetsTypography.heading2,
      ),
      cardTheme: CardThemeData(
        color: HomesetsColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: HomesetsColors.borderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HomesetsColors.lime,
          foregroundColor: HomesetsColors.textOnLime,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: HomesetsTypography.buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HomesetsColors.textPrimary,
          side: const BorderSide(color: HomesetsColors.borderSubtle, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: HomesetsTypography.buttonText,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: HomesetsColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
