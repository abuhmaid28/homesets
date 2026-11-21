import 'dart:math';
import '../models/domain_models.dart';

/// Pure-Dart domain analytics for Progress Tracking (WP03, WP04, WP05, WP06).
/// Strictly offline, deterministic, zero external dependencies.
class ProgressAnalytics {
  ProgressAnalytics._();

  // =========================================================================
  // WP03: WEIGHT TRACKING & WEEKLY AVERAGE MATH
  // =========================================================================

  /// Sensible physiological boundaries for adult body weight logging (30.0 kg – 300.0 kg).
  static const double minSensibleWeightKg = 30.0;
  static const double maxSensibleWeightKg = 300.0;

  /// Validates whether a body weight measurement is physiologically plausible.
  static bool isValidWeightKg(double kg) {
    return kg >= minSensibleWeightKg && kg <= maxSensibleWeightKg;
  }

  /// Calculates the rolling 7-day average of actual recorded entries ending at [referenceDate].
  /// Returns `null` if zero entries exist within the 7-day window.
  /// Strictly refrains from fabricating or interpolating missing days.
  static double? calculateRolling7DayAverage(List<WeightEntry> entries, DateTime referenceDate) {
    final windowStart = referenceDate.subtract(const Duration(days: 7));
    final windowEntries = entries.where((e) {
      return !e.loggedAt.isBefore(windowStart) && !e.loggedAt.isAfter(referenceDate);
    }).toList();

    if (windowEntries.isEmpty) return null;

    final sum = windowEntries.fold<double>(0.0, (acc, e) => acc + e.weightKg);
    final avg = sum / windowEntries.length;
    return (avg * 10).roundToDouble() / 10; // Round to 1 decimal place
  }

  /// Groups weight entries by ISO calendar week (Monday to Sunday) and computes
  /// the genuine arithmetic mean of actual logged entries for each week.
  /// Sparse weeks with no entries are excluded; zero fake interpolation.
  static List<WeeklyWeightAverage> computeWeeklyAverages(List<WeightEntry> entries) {
    if (entries.isEmpty) return [];

    // Group by year and ISO week
    final weekGroups = <String, List<WeightEntry>>{};
    for (final entry in entries) {
      final key = _isoWeekKey(entry.loggedAt);
      weekGroups.putIfAbsent(key, () => []).add(entry);
    }

    final result = <WeeklyWeightAverage>[];
    for (final group in weekGroups.values) {
      if (group.isEmpty) continue;
      // Sort entries in group to find date bounds
      group.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
      final weekStart = _startOfIsoWeek(group.first.loggedAt);
      final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      final sum = group.fold<double>(0.0, (acc, e) => acc + e.weightKg);
      final avg = (sum / group.length * 10).roundToDouble() / 10;

      result.add(WeeklyWeightAverage(
        weekStart: weekStart,
        weekEnd: weekEnd,
        averageKg: avg,
        entriesCount: group.length,
      ));
    }

    // Sort chronologically ascending
    result.sort((a, b) => a.weekStart.compareTo(b.weekStart));
    return result;
  }

  // =========================================================================
  // WP04: STRENGTH PROGRESS AGGREGATION
  // =========================================================================

  /// Summarizes strength progression over time for an exercise given its history.
  /// Enforces like-for-like comparability across band assistance/resistance (P5-R05).
  static StrengthSummary computeStrengthSummary(List<StrengthDataPoint> history) {
    if (history.isEmpty) {
      return const StrengthSummary(
        totalSessionsLogged: 0,
        baselineMaxReps: 0,
        allTimeBestMaxReps: 0,
        recentMaxReps: 0,
        repsDelta: 0,
        recentTotalVolume: 0,
        isComparable: true,
      );
    }

    final baseline = history.first.maxReps;
    final recent = history.last.maxReps;
    final allTimeBest = history.map((p) => p.maxReps).reduce(max);
    final recentVolume = history.last.totalReps;

    // Strict comparability: check if all data points share the exact same band configuration
    final firstBand = history.first.bandUsed?.trim();
    final isComparable = history.every((p) => (p.bandUsed?.trim()) == firstBand);

    return StrengthSummary(
      totalSessionsLogged: history.length,
      baselineMaxReps: baseline,
      allTimeBestMaxReps: allTimeBest,
      recentMaxReps: recent,
      repsDelta: isComparable ? (recent - baseline) : 0,
      recentTotalVolume: recentVolume,
      isComparable: isComparable,
      configurationLabel: isComparable
          ? (firstBand == null || firstBand.isEmpty ? 'bodyweight' : firstBand)
          : 'mixed',
    );
  }

  // =========================================================================
  // WP06: INEXPENSIVE EGYPTIAN CULTURAL PROTEIN IDEAS
  // =========================================================================

  static const List<ProteinSuggestion> proteinSuggestions = [
    ProteinSuggestion(
      nameAr: 'بيض بلدي / مسلوق',
      nameEn: 'Boiled Eggs',
      descriptionAr: 'مصدر بروتين كامل عالي القيمة الغذائية وسهل التحضير (٦ جرام بروتين للبيضة).',
      descriptionEn: 'Complete high-biological-value protein (~6g per egg).',
    ),
    ProteinSuggestion(
      nameAr: 'جبنة قريش',
      nameEn: 'Cottage Cheese (Areesh)',
      descriptionAr: 'بروتين كازين بطيء الامتصاص ممتاز لبناء العضلات وخفيف على المعدة.',
      descriptionEn: 'Slow-digesting casein protein, ideal for overnight recovery.',
    ),
    ProteinSuggestion(
      nameAr: 'فول مدمس بزيت زيتون',
      nameEn: 'Fava Beans (Foul)',
      descriptionAr: 'بروتين نباتي شعبي غني بالألياف والمعادن ومشبع لساعات طويلة.',
      descriptionEn: 'Traditional plant protein high in fiber and minerals.',
    ),
    ProteinSuggestion(
      nameAr: 'علبة تونة مصفاة',
      nameEn: 'Canned Tuna',
      descriptionAr: 'بروتين صافي سريع التحضير وغني بأوميجا ٣ بدون دهون زائدة.',
      descriptionEn: 'Lean protein rich in omega-3 fatty acids (~25g per can).',
    ),
    ProteinSuggestion(
      nameAr: 'عدس أصفر / بني',
      nameEn: 'Lentils',
      descriptionAr: 'خيار اقتصادي ممتاز غني بالبروتين والحديد، مثالي كوجبة دافئة.',
      descriptionEn: 'Economical nutrient-dense legume rich in protein and iron.',
    ),
  ];

  // =========================================================================
  // PRIVATE HELPER FUNCTIONS
  // =========================================================================

  static DateTime _startOfIsoWeek(DateTime dt) {
    // ISO-8601: Monday is 1, Sunday is 7
    final diff = dt.weekday - DateTime.monday;
    final monday = dt.subtract(Duration(days: diff));
    return DateTime(monday.year, monday.month, monday.day);
  }

  static String _isoWeekKey(DateTime dt) {
    final monday = _startOfIsoWeek(dt);
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }
}

/// Represents the average weight for an ISO calendar week (WP03).
class WeeklyWeightAverage {
  final DateTime weekStart;
  final DateTime weekEnd;
  final double averageKg;
  final int entriesCount;

  const WeeklyWeightAverage({
    required this.weekStart,
    required this.weekEnd,
    required this.averageKg,
    required this.entriesCount,
  });
}

/// Aggregated strength progression summary for an exercise (WP04, P5-R05).
class StrengthSummary {
  final int totalSessionsLogged;
  final int baselineMaxReps;
  final int allTimeBestMaxReps;
  final int recentMaxReps;
  final int repsDelta;
  final int recentTotalVolume;
  final bool isComparable;
  final String? configurationLabel;

  const StrengthSummary({
    required this.totalSessionsLogged,
    required this.baselineMaxReps,
    required this.allTimeBestMaxReps,
    required this.recentMaxReps,
    required this.repsDelta,
    required this.recentTotalVolume,
    this.isComparable = true,
    this.configurationLabel,
  });
}

/// Informational protein suggestion (WP06).
class ProteinSuggestion {
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;

  const ProteinSuggestion({
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
  });
}
