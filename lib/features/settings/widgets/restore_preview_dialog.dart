import 'package:flutter/material.dart';
import '../../../core/theme/homesets_colors.dart';
import '../../../core/theme/homesets_typography.dart';
import '../../../data/services/backup_archive_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/kinetic_button.dart';
import '../../shared/tactile_card.dart';

/// Modal dialog displaying dry-run backup metadata, record counts, and destructive warning (WP12).
class RestorePreviewDialog extends StatelessWidget {
  final BackupValidationResult validationResult;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const RestorePreviewDialog({
    super.key,
    required this.validationResult,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final manifest = validationResult.manifest;
    final snapshot = validationResult.snapshot;

    final workoutsCount = snapshot?.workoutSessions.length ?? 0;
    final setsCount = snapshot?.setLogs.length ?? 0;
    final weightsCount = snapshot?.weightEntries.length ?? 0;
    final photosCount = validationResult.photoFiles.length;

    return Dialog(
      backgroundColor: HomesetsColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: HomesetsColors.borderSubtle, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: HomesetsColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings_backup_restore, color: HomesetsColors.lime, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.restorePreviewTitle,
                          style: HomesetsTypography.heading3.copyWith(fontSize: 18),
                        ),
                        if (manifest != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            l10n.restoreCreatedAt(manifest.createdAt.split('T').first),
                            style: HomesetsTypography.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Record Counts Card
              TactileCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.restoreRecordCountsTitle,
                      style: HomesetsTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildStatRow(Icons.fitness_center, l10n.restoreWorkoutsCount(workoutsCount)),
                    const SizedBox(height: 6),
                    _buildStatRow(Icons.repeat, l10n.restoreSetsCount(setsCount)),
                    const SizedBox(height: 6),
                    _buildStatRow(Icons.monitor_weight_outlined, l10n.restoreWeightsCount(weightsCount)),
                    const SizedBox(height: 6),
                    _buildStatRow(Icons.photo_library_outlined, l10n.restorePhotosCount(photosCount)),
                  ],
                ),
              ),

              // Warnings (if any)
              if (validationResult.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                TactileCard(
                  borderColor: HomesetsColors.borderActive,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: validationResult.warnings
                        .map(
                          (w) => Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: HomesetsColors.lime, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(w, style: HomesetsTypography.bodySmall),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Destructive Warning Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HomesetsColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HomesetsColors.orange.withValues(alpha: 0.5), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: HomesetsColors.orange, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.restoreDestructiveWarning,
                        style: HomesetsTypography.bodySmall.copyWith(color: HomesetsColors.orange),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        l10n.restoreCancelButton,
                        style: HomesetsTypography.buttonText.copyWith(color: HomesetsColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: KineticButton(
                      label: l10n.restoreConfirmButton,
                      style: KineticButtonStyle.danger,
                      onPressed: onConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: HomesetsColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: HomesetsTypography.bodySmall),
        ),
      ],
    );
  }
}
