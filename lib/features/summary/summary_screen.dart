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
                    color: session.isEmergencyStopped
                        ? HomesetsColors.orange.withValues(alpha: 0.2)
                        : HomesetsColors.lime.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    session.isEmergencyStopped ? Icons.shield : Icons.check_circle,
                    color: session.isEmergencyStopped ? HomesetsColors.orange : HomesetsColors.lime,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                session.isEmergencyStopped
                    ? (isArabic ? 'سلامة مفاصلك أولاً ✓' : 'Joint Safety Respected ✓')
                    : l10n.summaryTitle,
                style: HomesetsTypography.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                session.isEmergencyStopped
                    ? (isArabic
                        ? 'تم حفظ المجموعات التي أكملتها. الراحة هي الأساس لتفادي تفاقم الألم.'
                        : 'Completed sets preserved. Early cessation prevents acute tissue injury.')
                    : l10n.summarySubtitle,
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

              // Weekly Consistency Credit Badge
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
