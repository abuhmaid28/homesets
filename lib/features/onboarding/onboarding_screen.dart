import 'package:flutter/material.dart';
import '../../core/theme/homesets_colors.dart';
import '../../core/theme/homesets_typography.dart';
import '../../domain/models/domain_models.dart';
import '../../data/repositories/workout_repository.dart';
import '../shared/tactile_card.dart';
import '../shared/kinetic_button.dart';
import '../shared/homesets_header.dart';
import '../../l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  final WorkoutRepository repository;
  final UserProfile? initialProfile;
  final EquipmentInventory? initialInventory;
  final bool isEditing;
  final VoidCallback? onCancel;

  const OnboardingScreen({
    super.key,
    required this.onCompleted,
    required this.repository,
    this.initialProfile,
    this.initialInventory,
    this.isEditing = false,
    this.onCancel,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Equipment flags (D09, GOV13: unverified accessories default to false)
  bool _hasPullUpBar = true;
  bool _hasBands = true;
  bool _hasDoorAnchor = false;
  bool _hasSturdyTable = false;
  bool _hasParallelGrip = false;

  // Avoided joints list
  final Set<JointImpactTag> _avoidedJoints = {};

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialInventory != null) {
      _hasPullUpBar = widget.initialInventory!.hasPullUpBar;
      _hasBands = widget.initialInventory!.hasBands;
      _hasDoorAnchor = widget.initialInventory!.hasDoorAnchor;
      _hasSturdyTable = widget.initialInventory!.hasSturdyTable;
      _hasParallelGrip = widget.initialInventory!.hasParallelGrip;
    }
    if (widget.initialProfile != null) {
      _avoidedJoints.addAll(widget.initialProfile!.avoidedJoints);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    final baseProfile = widget.initialProfile ?? const UserProfile(
      id: 'primary_user',
      goal: 'MUSCLE_BUILDING',
      wakeTimeMinutes: 900, // 3:00 PM
      shiftStartMinutes: 1140, // 7:00 PM
      targetWorkoutsPerWeek: 4,
    );

    final updatedProfile = baseProfile.copyWith(
      avoidedJoints: _avoidedJoints.toList(),
    );

    final inventory = EquipmentInventory(
      hasPullUpBar: _hasPullUpBar,
      hasBands: _hasBands,
      hasDoorAnchor: _hasDoorAnchor,
      hasSturdyTable: _hasSturdyTable,
      hasParallelGrip: _hasParallelGrip,
    );

    await widget.repository.saveUserProfile(updatedProfile);
    await widget.repository.saveEquipmentInventory(inventory);

    setState(() => _isSaving = false);
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: HomesetsHeader(
        showTagline: !widget.isEditing,
        actions: [
          if (widget.onCancel != null)
            IconButton(
              icon: const Icon(Icons.close, color: HomesetsColors.textSecondary),
              onPressed: widget.onCancel,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Text(
              widget.isEditing
                  ? (isArabic ? 'تعديل الأدوات والمفاصل' : 'Edit Equipment & Joints')
                  : l10n.onboardingTitle,
              style: HomesetsTypography.heading1,
            ),
            const SizedBox(height: 6),
            Text(
              widget.isEditing
                  ? (isArabic
                      ? 'حدّث الأدوات المتاحة أو المفاصل التي تتجنب إجهادها.'
                      : 'Update available hardware or areas to avoid in your program.')
                  : l10n.onboardingSubtitle,
              style: HomesetsTypography.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Goal Card (Fixed to Muscle Building per D04)
            TactileCard(
              isHighlighted: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fitness_center, color: HomesetsColors.lime, size: 22),
                      const SizedBox(width: 10),
                      Text(l10n.goalTitle, style: HomesetsTypography.heading3),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.goalMuscleBuilding,
                    style: HomesetsTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Equipment Section (D09, GOV13)
            Text(l10n.equipmentTitle, style: HomesetsTypography.heading2),
            const SizedBox(height: 12),
            _CheckboxTile(
              title: l10n.pullUpBar,
              value: _hasPullUpBar,
              onChanged: (v) => setState(() => _hasPullUpBar = v),
            ),
            _CheckboxTile(
              title: l10n.resistanceBands,
              value: _hasBands,
              onChanged: (v) => setState(() => _hasBands = v),
            ),
            _CheckboxTile(
              title: l10n.doorAnchor,
              subtitle: l10n.doorAnchorNote,
              value: _hasDoorAnchor,
              onChanged: (v) => setState(() => _hasDoorAnchor = v),
            ),
            _CheckboxTile(
              title: l10n.sturdyTable,
              subtitle: l10n.sturdyTableNote,
              value: _hasSturdyTable,
              onChanged: (v) => setState(() => _hasSturdyTable = v),
            ),
            _CheckboxTile(
              title: l10n.neutralGripAvailable,
              value: _hasParallelGrip,
              onChanged: (v) => setState(() => _hasParallelGrip = v),
            ),
            const SizedBox(height: 24),

            // Avoided Joint Areas (SAFE-01)
            Text('مناطق تتجنب إجهادها (اختياري) / Avoided Joints', style: HomesetsTypography.heading2),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _JointFilterChip(
                  label: 'الكتف (Shoulder)',
                  tag: JointImpactTag.shoulderSubacromial,
                  selected: _avoidedJoints.contains(JointImpactTag.shoulderSubacromial),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _avoidedJoints.add(JointImpactTag.shoulderSubacromial);
                        _avoidedJoints.add(JointImpactTag.shoulderAnterior);
                      } else {
                        _avoidedJoints.remove(JointImpactTag.shoulderSubacromial);
                        _avoidedJoints.remove(JointImpactTag.shoulderAnterior);
                      }
                    });
                  },
                ),
                _JointFilterChip(
                  label: 'الكوع (Elbow)',
                  tag: JointImpactTag.elbowMedial,
                  selected: _avoidedJoints.contains(JointImpactTag.elbowMedial),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _avoidedJoints.add(JointImpactTag.elbowMedial);
                      } else {
                        _avoidedJoints.remove(JointImpactTag.elbowMedial);
                      }
                    });
                  },
                ),
                _JointFilterChip(
                  label: 'المعصم (Wrist)',
                  tag: JointImpactTag.wristCompression,
                  selected: _avoidedJoints.contains(JointImpactTag.wristCompression),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _avoidedJoints.add(JointImpactTag.wristCompression);
                      } else {
                        _avoidedJoints.remove(JointImpactTag.wristCompression);
                      }
                    });
                  },
                ),
                _JointFilterChip(
                  label: 'أسفل الظهر (Lower Back)',
                  tag: JointImpactTag.lumbarShear,
                  selected: _avoidedJoints.contains(JointImpactTag.lumbarShear),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _avoidedJoints.add(JointImpactTag.lumbarShear);
                      } else {
                        _avoidedJoints.remove(JointImpactTag.lumbarShear);
                      }
                    });
                  },
                ),
                _JointFilterChip(
                  label: 'الركبة (Knee)',
                  tag: JointImpactTag.kneePatellar,
                  selected: _avoidedJoints.contains(JointImpactTag.kneePatellar),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _avoidedJoints.add(JointImpactTag.kneePatellar);
                      } else {
                        _avoidedJoints.remove(JointImpactTag.kneePatellar);
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit Button
            KineticButton(
              label: l10n.saveAndContinue,
              isLoading: _isSaving,
              onPressed: _handleSave,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CheckboxTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckboxTile({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: value ? HomesetsColors.surfaceElevated : HomesetsColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: value ? HomesetsColors.limeDim : HomesetsColors.borderSubtle,
            width: value ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  value ? Icons.check_box : Icons.check_box_outline_blank,
                  color: value ? HomesetsColors.lime : HomesetsColors.textMuted,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: HomesetsTypography.bodyLarge.copyWith(
                          fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: HomesetsTypography.bodySmall),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JointFilterChip extends StatelessWidget {
  final String label;
  final JointImpactTag tag;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _JointFilterChip({
    required this.label,
    required this.tag,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: HomesetsColors.surfaceElevated,
      selectedColor: HomesetsColors.orange.withValues(alpha: 0.2),
      checkmarkColor: HomesetsColors.orange,
      labelStyle: HomesetsTypography.bodySmall.copyWith(
        color: selected ? HomesetsColors.orange : HomesetsColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? HomesetsColors.orange : HomesetsColors.borderSubtle,
          width: 1.5,
        ),
      ),
    );
  }
}
