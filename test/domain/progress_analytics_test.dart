import 'package:flutter_test/flutter_test.dart';
import 'package:homesets/domain/models/domain_models.dart';
import 'package:homesets/domain/progress/progress_analytics.dart';

void main() {
  group('ProgressAnalytics Tests (WP03, WP04, WP06)', () {
    test('Weight validation rejects implausible and accepts sensible kg values (WP03)', () {
      expect(ProgressAnalytics.isValidWeightKg(60.0), isTrue);
      expect(ProgressAnalytics.isValidWeightKg(80.5), isTrue);
      expect(ProgressAnalytics.isValidWeightKg(30.0), isTrue);
      expect(ProgressAnalytics.isValidWeightKg(300.0), isTrue);

      expect(ProgressAnalytics.isValidWeightKg(29.9), isFalse);
      expect(ProgressAnalytics.isValidWeightKg(300.1), isFalse);
      expect(ProgressAnalytics.isValidWeightKg(0.0), isFalse);
      expect(ProgressAnalytics.isValidWeightKg(-75.0), isFalse);
      expect(ProgressAnalytics.isValidWeightKg(999.0), isFalse);
    });

    test('Rolling 7-day average calculates genuine mean and handles empty/sparse cases (WP03)', () {
      final now = DateTime(2026, 11, 15, 12, 0);

      // Empty list returns null
      expect(ProgressAnalytics.calculateRolling7DayAverage([], now), isNull);

      // Entries completely outside 7-day window return null
      final oldEntries = [
        WeightEntry(
          id: 'w_old_1',
          weightKg: 65.0,
          loggedAt: now.subtract(const Duration(days: 10)),
        ),
      ];
      expect(ProgressAnalytics.calculateRolling7DayAverage(oldEntries, now), isNull);

      // Multiple entries inside window are averaged correctly
      final mixedEntries = [
        WeightEntry(
          id: 'w_1',
          weightKg: 60.0,
          loggedAt: now.subtract(const Duration(days: 5)),
        ),
        WeightEntry(
          id: 'w_2',
          weightKg: 61.0,
          loggedAt: now.subtract(const Duration(days: 3)),
        ),
        WeightEntry(
          id: 'w_3',
          weightKg: 60.5,
          loggedAt: now.subtract(const Duration(days: 1)),
        ),
        // One old entry that should be excluded
        WeightEntry(
          id: 'w_old_2',
          weightKg: 80.0,
          loggedAt: now.subtract(const Duration(days: 9)),
        ),
      ];

      // Mean of 60.0, 61.0, 60.5 = 181.5 / 3 = 60.5
      final avg = ProgressAnalytics.calculateRolling7DayAverage(mixedEntries, now);
      expect(avg, isNotNull);
      expect(avg, equals(60.5));
    });

    test('Weekly averages groups entries by calendar week without fake interpolation (WP03)', () {
      final week1Monday = DateTime(2026, 11, 2, 8, 0); // Week 45
      final week1Wednesday = DateTime(2026, 11, 4, 8, 0);
      final week3Tuesday = DateTime(2026, 11, 17, 8, 0); // Week 47 (Week 46 skipped)

      final entries = [
        WeightEntry(id: '1', weightKg: 60.0, loggedAt: week1Monday),
        WeightEntry(id: '2', weightKg: 61.0, loggedAt: week1Wednesday),
        WeightEntry(id: '3', weightKg: 62.0, loggedAt: week3Tuesday),
      ];

      final averages = ProgressAnalytics.computeWeeklyAverages(entries);
      expect(averages.length, equals(2), reason: 'Week 46 has 0 entries and must NOT be fabricated');
      expect(averages[0].averageKg, equals(60.5));
      expect(averages[0].entriesCount, equals(2));
      expect(averages[1].averageKg, equals(62.0));
      expect(averages[1].entriesCount, equals(1));
    });

    test('Strength summary correctly calculates baseline, best, and delta (WP04)', () {
      // Empty history
      final emptySummary = ProgressAnalytics.computeStrengthSummary([]);
      expect(emptySummary.totalSessionsLogged, equals(0));
      expect(emptySummary.baselineMaxReps, equals(0));
      expect(emptySummary.repsDelta, equals(0));

      final now = DateTime.now();
      final history = [
        StrengthDataPoint(
          date: now.subtract(const Duration(days: 14)),
          maxReps: 6,
          totalReps: 16,
          setsCount: 3,
          isLiteMode: false,
          sessionId: 's1',
        ),
        StrengthDataPoint(
          date: now.subtract(const Duration(days: 7)),
          maxReps: 9, // All-time best
          totalReps: 24,
          setsCount: 3,
          isLiteMode: false,
          sessionId: 's2',
        ),
        StrengthDataPoint(
          date: now.subtract(const Duration(days: 2)),
          maxReps: 8, // Recent
          totalReps: 22,
          setsCount: 3,
          isLiteMode: false,
          sessionId: 's3',
        ),
      ];

      final summary = ProgressAnalytics.computeStrengthSummary(history);
      expect(summary.totalSessionsLogged, equals(3));
      expect(summary.baselineMaxReps, equals(6));
      expect(summary.allTimeBestMaxReps, equals(9));
      expect(summary.recentMaxReps, equals(8));
      expect(summary.repsDelta, equals(2)); // 8 - 6 = +2
      expect(summary.recentTotalVolume, equals(22));
    });

    test('Protein suggestions provide Egyptian cultural options with bilingual descriptions (WP06)', () {
      expect(ProgressAnalytics.proteinSuggestions.length, greaterThanOrEqualTo(5));
      for (final p in ProgressAnalytics.proteinSuggestions) {
        expect(p.nameAr, isNotEmpty);
        expect(p.nameEn, isNotEmpty);
        expect(p.descriptionAr, isNotEmpty);
        expect(p.descriptionEn, isNotEmpty);
      }
    });
  });
}
