import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/homesets_colors.dart';
import '../../../core/theme/homesets_typography.dart';
import '../../../data/services/photo_service.dart';
import '../../../domain/models/domain_models.dart';
import '../../../l10n/app_localizations.dart';

/// Side-by-side comparison view for 2 physique photos (WP01, WP09).
class PhotoComparisonView extends StatelessWidget {
  final ProgressPhoto photoBefore;
  final ProgressPhoto photoAfter;
  final PhotoService photoService;
  final VoidCallback onClose;

  const PhotoComparisonView({
    super.key,
    required this.photoBefore,
    required this.photoAfter,
    required this.photoService,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final dateFormat = DateFormat('d MMM yyyy', isArabic ? 'ar' : 'en');

    return Container(
      color: HomesetsColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows, color: HomesetsColors.lime),
                  const SizedBox(width: 8),
                  Text(
                    l10n.comparePhotos,
                    style: HomesetsTypography.heading2,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: HomesetsColors.textPrimary),
                    onPressed: onClose,
                    tooltip: l10n.exitCompare,
                  ),
                ],
              ),
            ),
            const Divider(color: HomesetsColors.borderSubtle),

            // Side-by-side photo comparison
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Before photo
                    Expanded(
                      child: _PhotoPanel(
                        badgeText: l10n.photoBefore,
                        photo: photoBefore,
                        photoService: photoService,
                        dateLabel: dateFormat.format(photoBefore.takenAt),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // After photo
                    Expanded(
                      child: _PhotoPanel(
                        badgeText: l10n.photoAfter,
                        photo: photoAfter,
                        photoService: photoService,
                        dateLabel: dateFormat.format(photoAfter.takenAt),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPanel extends StatelessWidget {
  final String badgeText;
  final ProgressPhoto photo;
  final PhotoService photoService;
  final String dateLabel;

  const _PhotoPanel({
    required this.badgeText,
    required this.photo,
    required this.photoService,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HomesetsColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomesetsColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Badge & Date bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: HomesetsColors.surfaceElevated,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: HomesetsColors.lime.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: HomesetsColors.lime,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: HomesetsColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Image display
          Expanded(
            child: FutureBuilder<String>(
              future: photoService.getAbsolutePath(photo.filePath),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final path = snapshot.data;
                if (path == null) {
                  return const Center(
                    child: Icon(Icons.broken_image, color: HomesetsColors.textMuted),
                  );
                }
                final file = File(path);
                if (!file.existsSync()) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo, color: HomesetsColors.lime, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          photo.angle.name.toUpperCase(),
                          style: const TextStyle(
                            color: HomesetsColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.0,
                  child: Image.file(
                    file,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image, color: HomesetsColors.textMuted),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
