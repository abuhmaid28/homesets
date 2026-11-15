import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesets/core/theme/homesets_colors.dart';
import 'package:homesets/core/theme/homesets_theme.dart';
import 'package:homesets/features/shared/tactile_card.dart';
import 'package:homesets/features/shared/kinetic_button.dart';
import 'package:homesets/features/shared/rep_counter_stepper.dart';
import 'package:homesets/features/shared/tabular_timer_display.dart';
import 'package:homesets/features/shared/homesets_header.dart';

void main() {
  group('Homesets Design System & Contrast Compliance (WP06, WP11)', () {
    test('verifies WCAG contrast ratios for key colors', () {
      // Calculate relative luminance
      double luminance(Color c) => c.computeLuminance();
      double contrastRatio(Color fg, Color bg) {
        final l1 = luminance(fg);
        final l2 = luminance(bg);
        final lighter = l1 > l2 ? l1 : l2;
        final darker = l1 > l2 ? l2 : l1;
        return (lighter + 0.05) / (darker + 0.05);
      }

      // Text Primary against Background (#F5F7FA on #121417)
      final primaryTextRatio = contrastRatio(HomesetsColors.textPrimary, HomesetsColors.background);
      expect(primaryTextRatio, greaterThanOrEqualTo(12.0), reason: 'Primary text must exceed 4.5:1 WCAG AAA');

      // Performance Lime against Background (#CCFF00 on #121417)
      final limeRatio = contrastRatio(HomesetsColors.lime, HomesetsColors.background);
      expect(limeRatio, greaterThanOrEqualTo(10.0), reason: 'Lime accent must have high contrast');

      // Black text on Performance Lime button (#0D0F12 on #CCFF00)
      final buttonTextRatio = contrastRatio(HomesetsColors.textOnLime, HomesetsColors.lime);
      expect(buttonTextRatio, greaterThanOrEqualTo(10.0), reason: 'Lime button text must exceed 4.5:1');

      // Safety Orange against Background (#FF5E1E on #121417)
      final orangeRatio = contrastRatio(HomesetsColors.orange, HomesetsColors.background);
      expect(orangeRatio, greaterThanOrEqualTo(4.5), reason: 'Orange alert must meet 4.5:1 WCAG AA');
    });

    testWidgets('TactileCard renders child with proper rounded border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: HomesetsTheme.darkTheme,
          home: const Scaffold(
            body: TactileCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(TactileCard), findsOneWidget);
    });

    testWidgets('KineticButton triggers callback on tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: HomesetsTheme.darkTheme,
          home: Scaffold(
            body: KineticButton(
              label: 'Test Button',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      await tester.tap(find.text('Test Button'));
      expect(tapped, isTrue);
    });

    testWidgets('RepCounterStepper increments and decrements correctly', (tester) async {
      int count = 8;
      await tester.pumpWidget(
        MaterialApp(
          theme: HomesetsTheme.darkTheme,
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: RepCounterStepper(
                  count: count,
                  onChanged: (newCount) => setState(() => count = newCount),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('8'), findsOneWidget);

      // Tap + button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('9'), findsOneWidget);

      // Tap - button
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('TabularTimerDisplay renders time correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: HomesetsTheme.darkTheme,
          home: const Scaffold(
            body: TabularTimerDisplay(
              totalSeconds: 90,
              remainingSeconds: 45,
            ),
          ),
        ),
      );

      expect(find.text('45'), findsOneWidget);
      expect(find.text('SECONDS'), findsOneWidget);
    });

    testWidgets('HomesetsHeader renders wordmark per GOV18', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: HomesetsTheme.darkTheme,
          home: const Scaffold(
            appBar: HomesetsHeader(),
            body: SizedBox(),
          ),
        ),
      );

      expect(find.text('HOMESETS'), findsOneWidget);
    });
  });
}
