import 'package:flutter/material.dart';
import '../../../core/theme/homesets_colors.dart';
import '../../../core/theme/homesets_typography.dart';
import '../../../domain/progress/progress_analytics.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/tactile_card.dart';

/// Interactive daily nutrition & protein checklist with Egyptian cultural suggestions (WP05).
class MealChecklistCard extends StatelessWidget {
  final Map<int, bool> mealChecks; // 0=breakfast, 1=lunch, 2=dinner, 3=snack1, 4=snack2
  final Function(int slot, bool isChecked) onToggle;

  const MealChecklistCard({
    super.key,
    required this.mealChecks,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final baseSlots = [
      (0, l10n.mealBreakfast, Icons.wb_sunny_outlined),
      (1, l10n.mealLunch, Icons.lunch_dining_outlined),
      (2, l10n.mealDinner, Icons.nightlife_outlined),
    ];

    final optionalSlots = [
      (3, l10n.mealSnack1, Icons.coffee_outlined),
      (4, l10n.mealSnack2, Icons.apple_outlined),
    ];

    int baseCompleted = 0;
    for (final slot in baseSlots) {
      if (mealChecks[slot.$1] == true) baseCompleted++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TactileCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.restaurant, color: HomesetsColors.lime),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.mealsTitle,
                            style: HomesetsTypography.heading3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: baseCompleted == 3
                          ? HomesetsColors.lime.withValues(alpha: 0.2)
                          : HomesetsColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: baseCompleted == 3
                            ? HomesetsColors.lime
                            : HomesetsColors.borderSubtle,
                      ),
                    ),
                    child: Text(
                      '$baseCompleted/3',
                      style: TextStyle(
                        color: baseCompleted == 3
                            ? HomesetsColors.lime
                            : HomesetsColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Base meals
              ...baseSlots.map((slot) => _buildMealRow(
                    context: context,
                    slotIndex: slot.$1,
                    title: slot.$2,
                    icon: slot.$3,
                    isChecked: mealChecks[slot.$1] ?? false,
                  )),

              const Divider(color: HomesetsColors.borderSubtle, height: 24),

              // Optional snacks
              ...optionalSlots.map((slot) => _buildMealRow(
                    context: context,
                    slotIndex: slot.$1,
                    title: slot.$2,
                    icon: slot.$3,
                    isChecked: mealChecks[slot.$1] ?? false,
                    isOptional: true,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Inexpensive Egyptian protein suggestions card
        TactileCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: HomesetsColors.limeDim),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.proteinTipsTitle,
                      style: HomesetsTypography.heading3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...ProgressAnalytics.proteinSuggestions.map((tip) {
                final name = isArabic ? tip.nameAr : tip.nameEn;
                final desc = isArabic ? tip.descriptionAr : tip.descriptionEn;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: HomesetsColors.limeGlow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Protein',
                          style: TextStyle(
                            color: HomesetsColors.lime,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: HomesetsColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              desc,
                              style: const TextStyle(
                                color: HomesetsColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealRow({
    required BuildContext context,
    required int slotIndex,
    required String title,
    required IconData icon,
    required bool isChecked,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onToggle(slotIndex, !isChecked),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                color: isChecked ? HomesetsColors.lime : HomesetsColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isChecked
                        ? HomesetsColors.textPrimary
                        : HomesetsColors.textSecondary,
                    fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isChecked ? HomesetsColors.lime : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isChecked ? HomesetsColors.lime : HomesetsColors.borderSubtle,
                    width: 1.5,
                  ),
                ),
                child: isChecked
                    ? const Icon(
                        Icons.check,
                        size: 18,
                        color: HomesetsColors.textOnLime,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
