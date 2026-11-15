import 'package:flutter/material.dart';
import '../../core/theme/homesets_colors.dart';
import '../../core/theme/homesets_typography.dart';
import '../../domain/models/domain_models.dart';
import '../shared/tactile_card.dart';
import '../shared/kinetic_button.dart';
import '../../l10n/app_localizations.dart';

class SummaryScreen extends StatelessWidget {
  final CompletedWorkoutSession session;
  final VoidCallback onBackToToday;

  const SummaryScreen({
    super.key,
    required this.session,
    required this.onBackToToday,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final mins = session.totalDurationSeconds ~/ 60;
    final secs = session.totalDurationSeconds % 60;
    final formattedDuration = mins > 0 ? '$mins min $secs sec' : '$secs sec';
    final formattedDurationAr = mins > 0 ? '$mins دقيقة و $secs ثانية' : '$secs ثانية';

    final isWarning = !session.isPersisted || session.isEmergencyStopped;
    final validSetsCount = session.completedSets.where((s) => !s.isPainStopped && s.performedReps > 0).length;
    final minSetsForCredit = session.isLiteMode ? 2 : 3;
    final earnsConsistencyCredit = session.isPersisted &&
        !session.isEmergencyStopped &&
        validSetsCount >= minSetsForCredit;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isWarning
                        ? HomesetsColors.orange.withValues(alpha: 0.2)
                        : HomesetsColors.lime.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    !session.isPersisted
                        ? Icons.warning_amber_rounded
                        : (session.isEmergencyStopped ? Icons.shield : Icons.check_circle),
                    color: isWarning ? HomesetsColors.orange : HomesetsColors.lime,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                !session.isPersisted
                    ? (isArabic ? 'تم الخروج بدون حفظ' : 'Session Ended (Unsaved)')
                    : (session.isEmergencyStopped
                        ? (isArabic ? 'سلامة مفاصلك أولاً ✓' : 'Joint Safety Respected ✓')
                        : l10n.summaryTitle),
                style: HomesetsTypography.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                !session.isPersisted
                    ? (isArabic
                        ? 'تنبيه: تعذر حفظ بيانات التمرين على القرص. لم يتم تسجيل أي مجموعات في السجل المحلي.'
                        : 'Notice: Workout data could not be saved to local storage. No sets were written to local history.')
                    : (session.isEmergencyStopped
                        ? (isArabic
                            ? 'تم حفظ المجموعات التي أكملتها. الراحة هي الأساس لتفادي تفاقم الألم.'
                            : 'Completed sets preserved. Early cessation prevents acute tissue injury.')
                        : l10n.summarySubtitle),
                style: HomesetsTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Metrics Card
              TactileCard(
                isHighlighted: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricColumn(
                      label: l10n.durationLabel,
                      value: isArabic ? formattedDurationAr : formattedDuration,
                    ),
                    Container(width: 1, height: 40, color: HomesetsColors.borderSubtle),
                    _MetricColumn(
                      label: l10n.setsLoggedLabel,
                      value: '${session.completedSets.length}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Weekly Consistency Credit Badge or Status Note (GATE-B)
              if (earnsConsistencyCredit) ...[
                TactileCard(
                  backgroundColor: HomesetsColors.lime.withValues(alpha: 0.1),
                  borderColor: HomesetsColors.limeDim,
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: HomesetsColors.lime, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.consistencyAdded,
                          style: HomesetsTypography.heading3.copyWith(fontSize: 15, color: HomesetsColors.lime),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (!session.isPersisted) ...[
                TactileCard(
                  backgroundColor: HomesetsColors.orange.withValues(alpha: 0.1),
                  borderColor: HomesetsColors.orange.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: HomesetsColors.orange, size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'لم يتم احتساب إنجاز أسبوعي لهذه الجلسة غير المحفوظة.'
                              : 'No weekly consistency credit awarded for unsaved session.',
                          style: HomesetsTypography.bodySmall.copyWith(color: HomesetsColors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (session.isEmergencyStopped) ...[
                TactileCard(
                  backgroundColor: HomesetsColors.orange.withValues(alpha: 0.1),
                  borderColor: HomesetsColors.orange.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      const Icon(Icons.health_and_safety_outlined, color: HomesetsColors.orange, size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'تم تفعيل حماية المفاصل. لا يتم احتساب إنجاز أسبوعي عند التوقف الوقائي.'
                              : 'Joint protection active. Consistency credit is reserved for completed workouts.',
                          style: HomesetsTypography.bodySmall.copyWith(color: HomesetsColors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),

              KineticButton(
                label: l10n.finishWorkout,
                onPressed: onBackToToday,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;

  const _MetricColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: HomesetsTypography.heading2.copyWith(color: HomesetsColors.lime)),
        const SizedBox(height: 4),
        Text(label, style: HomesetsTypography.bodySmall),
      ],
    );
  }
}
