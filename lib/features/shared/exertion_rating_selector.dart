import 'package:flutter/material.dart';
import '../../core/theme/homesets_colors.dart';
import '../../core/theme/homesets_typography.dart';
import '../../domain/models/domain_models.dart';
import '../../l10n/app_localizations.dart';

/// 3-Tier exertion rating selector aligned with Egyptian calisthenics RPE (D14).
class ExertionRatingSelector extends StatelessWidget {
  final ExertionRating? selectedRating;
  final ValueChanged<ExertionRating> onSelected;

  const ExertionRatingSelector({
    super.key,
    required this.selectedRating,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final options = [
      (
        rating: ExertionRating.easyReserve,
        title: l10n.effortEasy,
        desc: l10n.effortEasyDesc,
        color: HomesetsColors.success,
      ),
      (
        rating: ExertionRating.targetSweetspot,
        title: l10n.effortSweetspot,
        desc: l10n.effortSweetspotDesc,
        color: HomesetsColors.lime,
      ),
      (
        rating: ExertionRating.maxEffort,
        title: l10n.effortMax,
        desc: l10n.effortMaxDesc,
        color: HomesetsColors.orange,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options.map((opt) {
        final isSelected = selectedRating == opt.rating;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: isSelected
                ? opt.color.withValues(alpha: 0.15)
                : HomesetsColors.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected ? opt.color : HomesetsColors.borderSubtle,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: () => onSelected(opt.rating),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? opt.color : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? opt.color : HomesetsColors.textMuted,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: HomesetsColors.background)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt.title,
                            style: HomesetsTypography.heading3.copyWith(
                              fontSize: 15,
                              color: isSelected ? opt.color : HomesetsColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opt.desc,
                            style: HomesetsTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
