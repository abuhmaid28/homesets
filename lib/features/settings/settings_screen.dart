import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/homesets_colors.dart';
import '../../core/theme/homesets_typography.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/backup_archive_service.dart';
import '../../data/services/backup_platform_service.dart';
import '../../data/services/backup_staging_manager.dart';
import '../../data/services/reminder_platform_service.dart';
import '../../domain/backup/backup_models.dart';
import '../../domain/models/reminder_settings.dart';
import '../../l10n/app_localizations.dart';
import '../shared/homesets_header.dart';
import '../shared/kinetic_button.dart';
import '../shared/tactile_card.dart';
import 'widgets/restore_preview_dialog.dart';

/// Full Settings screen managing profile editing, local reminders, and offline backups (WP10, WP16, WP18).
class SettingsScreen extends StatefulWidget {
  final WorkoutRepository repository;
  final BackupPlatformService backupPlatformService;
  final BackupArchiveService backupArchiveService;
  final BackupStagingManager backupStagingManager;
  final ReminderPlatformService reminderPlatformService;
  final VoidCallback onEditProfile;
  final VoidCallback onBack;
  final VoidCallback onDataRestored;

  const SettingsScreen({
    super.key,
    required this.repository,
    required this.backupPlatformService,
    required this.backupArchiveService,
    required this.backupStagingManager,
    required this.reminderPlatformService,
    required this.onEditProfile,
    required this.onBack,
    required this.onDataRestored,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  late ReminderSettings _reminderSettings;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndReconcilePermissions();
    }
  }

  Future<void> _checkAndReconcilePermissions() async {
    try {
      final notificationsEnabled = await widget.reminderPlatformService.areNotificationsEnabled();
      if (!notificationsEnabled && _reminderSettings.isEnabled) {
        // Notification permission was revoked in system settings while app was backgrounded.
        // Explicitly cancel the active native alarm first so no stale alarm remains (P6-NOTIFY-01, P6-NOTIFY-02).
        bool cancelSuccess = false;
        try {
          cancelSuccess = await widget.reminderPlatformService.cancelDailyReminder();
        } catch (_) {
          cancelSuccess = false;
        }

        if (cancelSuccess) {
          final updated = _reminderSettings.copyWith(
            isEnabled: false,
            updatedAt: DateTime.now(),
          );
          await widget.repository.saveReminderSettings(updated);
          if (mounted) {
            setState(() {
              _reminderSettings = updated;
              _notificationsEnabled = false;
            });
          }
        } else {
          // Native cancellation failed; do NOT falsely mark disabled in SQLite/UI (P6-NOTIFY-02)
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            setState(() {
              _notificationsEnabled = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.reminderReconcileFailed),
                backgroundColor: HomesetsColors.orange,
              ),
            );
          }
        }
      } else if (mounted && _notificationsEnabled != notificationsEnabled) {
        setState(() {
          _notificationsEnabled = notificationsEnabled;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await widget.repository.getReminderSettings();
      final notificationsEnabled = await widget.reminderPlatformService.areNotificationsEnabled();
      if (!mounted) return;
      setState(() {
        _reminderSettings = settings;
        _notificationsEnabled = notificationsEnabled;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleReminders(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    if (value) {
      bool hasPerm = await widget.reminderPlatformService.areNotificationsEnabled();
      if (!mounted) return;
      if (!hasPerm) {
        // Show in-app pre-permission explanation dialog before invoking native prompt
        final bool? proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: HomesetsColors.surfaceElevated,
            title: Text(l10n.reminderPermissionDialogTitle, style: HomesetsTypography.heading3),
            content: Text(
              l10n.reminderPermissionDialogBody,
              style: HomesetsTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  l10n.reminderPermissionDialogCancel,
                  style: HomesetsTypography.buttonText.copyWith(color: HomesetsColors.textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: HomesetsColors.lime,
                  foregroundColor: HomesetsColors.textOnLime,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  l10n.reminderPermissionDialogConfirm,
                  style: HomesetsTypography.buttonText.copyWith(color: HomesetsColors.textOnLime),
                ),
              ),
            ],
          ),
        );

        if (proceed != true) {
          // User chose "Not Now"
          return;
        }

        // Request native runtime permission
        hasPerm = await widget.reminderPlatformService.requestNotificationPermission();
        if (!mounted) return;
        if (!hasPerm) {
          setState(() => _notificationsEnabled = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.reminderPermissionDenied),
              backgroundColor: HomesetsColors.orange,
            ),
          );
          return;
        }
      }

      bool scheduleSuccess = false;
      try {
        scheduleSuccess = await widget.reminderPlatformService.scheduleDailyReminder(
          hour: _reminderSettings.hour,
          minute: _reminderSettings.minute,
          title: l10n.reminderNotificationTitle,
          body: l10n.reminderNotificationBody,
        );
      } catch (_) {
        scheduleSuccess = false;
      }

      if (!scheduleSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.reminderScheduleFailed),
              backgroundColor: HomesetsColors.orange,
            ),
          );
        }
        return;
      }

      final updated = _reminderSettings.copyWith(
        isEnabled: true,
        updatedAt: DateTime.now(),
      );

      try {
        await widget.repository.saveReminderSettings(updated);
      } catch (e) {
        // DB save failed after successful scheduling (P6-NOTIFY-03, P6-NOTIFY-06).
        // Compensating action: Cancel scheduled alarm to prevent orphan schedule.
        bool compensated = false;
        try {
          compensated = await widget.reminderPlatformService.cancelDailyReminder();
        } catch (_) {
          compensated = false;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                compensated
                    ? l10n.reminderSaveFailed
                    : l10n.reminderCompensationFailed,
              ),
              backgroundColor: HomesetsColors.orange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _reminderSettings = updated;
          _notificationsEnabled = true;
        });
      }
    } else {
      bool cancelSuccess = false;
      try {
        cancelSuccess = await widget.reminderPlatformService.cancelDailyReminder();
      } catch (_) {
        cancelSuccess = false;
      }

      if (!cancelSuccess) {
        // Native cancellation failed (P6-NOTIFY-02).
        // Do NOT update state or save to SQLite; keep toggle ON and inform user.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.reminderCancelFailed),
              backgroundColor: HomesetsColors.orange,
            ),
          );
        }
        return;
      }

      final updated = _reminderSettings.copyWith(
        isEnabled: false,
        updatedAt: DateTime.now(),
      );

      try {
        await widget.repository.saveReminderSettings(updated);
      } catch (e) {
        // DB save failed after cancellation (P6-NOTIFY-03, P6-NOTIFY-06).
        // Compensating action: Reschedule the alarm to restore consistency with DB state.
        bool compensated = false;
        try {
          compensated = await widget.reminderPlatformService.scheduleDailyReminder(
            hour: _reminderSettings.hour,
            minute: _reminderSettings.minute,
            title: l10n.reminderNotificationTitle,
            body: l10n.reminderNotificationBody,
          );
        } catch (_) {
          compensated = false;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                compensated
                    ? l10n.reminderSaveFailed
                    : l10n.reminderCompensationFailed,
              ),
              backgroundColor: HomesetsColors.orange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() => _reminderSettings = updated);
      }
    }
  }

  Future<void> _pickReminderTime() async {
    final l10n = AppLocalizations.of(context)!;
    final initial = TimeOfDay(hour: _reminderSettings.hour, minute: _reminderSettings.minute);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: HomesetsColors.lime,
              onPrimary: HomesetsColors.textOnLime,
              surface: HomesetsColors.surface,
              onSurface: HomesetsColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final previousHour = _reminderSettings.hour;
      final previousMinute = _reminderSettings.minute;

      if (_reminderSettings.isEnabled) {
        final hasPerm = await widget.reminderPlatformService.areNotificationsEnabled();
        if (!mounted) return;
        if (!hasPerm) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.notificationsDisabledWarning),
              backgroundColor: HomesetsColors.orange,
            ),
          );
          return;
        }

        bool scheduleSuccess = false;
        try {
          scheduleSuccess = await widget.reminderPlatformService.scheduleDailyReminder(
            hour: picked.hour,
            minute: picked.minute,
            title: l10n.reminderNotificationTitle,
            body: l10n.reminderNotificationBody,
          );
        } catch (_) {
          scheduleSuccess = false;
        }

        if (!scheduleSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.reminderScheduleFailed),
                backgroundColor: HomesetsColors.orange,
              ),
            );
          }
          return;
        }
      }

      final updated = _reminderSettings.copyWith(
        hour: picked.hour,
        minute: picked.minute,
        updatedAt: DateTime.now(),
      );

      try {
        await widget.repository.saveReminderSettings(updated);
      } catch (e) {
        // Compensating action: If reminder was enabled, reschedule back to original time (P6-NOTIFY-03, P6-NOTIFY-06)
        bool compensated = true;
        if (_reminderSettings.isEnabled) {
          try {
            compensated = await widget.reminderPlatformService.scheduleDailyReminder(
              hour: previousHour,
              minute: previousMinute,
              title: l10n.reminderNotificationTitle,
              body: l10n.reminderNotificationBody,
            );
          } catch (_) {
            compensated = false;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                compensated
                    ? l10n.reminderSaveFailed
                    : l10n.reminderCompensationFailed,
              ),
              backgroundColor: HomesetsColors.orange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() => _reminderSettings = updated);
      }
    }
  }

  Future<void> _handleCreateBackup() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isBackingUp = true);

    try {
      final stagingDir = await widget.backupStagingManager.prepareExportStaging();
      final snapshot = await widget.repository.createDataSnapshot();
      final photos = await widget.repository.getProgressPhotos();
      final photoFiles = photos.map((p) {
        final path = p.filePath;
        if (path.startsWith('/') || path.contains(':')) {
          return File(path);
        }
        return File('${widget.backupStagingManager.appDocsDir.path}/$path');
      }).toList();

      for (final pf in photoFiles) {
        if (!await pf.exists()) {
          throw BackupValidationException(
            'Tracked photo file does not exist on disk: ${pf.path}',
          );
        }
      }

      final archiveFile = await widget.backupArchiveService.createBackupArchive(
        snapshot: snapshot,
        photoFiles: photoFiles,
        outputFilePath: '${stagingDir.path}/homesets_backup.homesets',
      );

      final dateStr = DateTime.now().toIso8601String().split('T').first.replaceAll('-', '');
      final suggestedName = 'homesets_backup_$dateStr.homesets';

      final success = await widget.backupPlatformService.exportBackupFile(
        stagedFilePath: archiveFile.path,
        suggestedFileName: suggestedName,
      );

      await widget.backupStagingManager.cleanStaging();

      if (!mounted) return;
      setState(() => _isBackingUp = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupSuccess),
            backgroundColor: HomesetsColors.surfaceElevated,
          ),
        );
      }
    } catch (e) {
      await widget.backupStagingManager.cleanStaging();
      if (!mounted) return;
      setState(() => _isBackingUp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.backupFailed(e.toString())),
          backgroundColor: HomesetsColors.orange,
        ),
      );
    }
  }

  Future<void> _handleRestoreBackup() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isRestoring = true);

    try {
      final stagingDir = await widget.backupStagingManager.prepareImportStaging();
      final stagedIncoming = '${stagingDir.path}/incoming.homesets';

      final selectedPath = await widget.backupPlatformService.pickBackupFile(
        targetStagingPath: stagedIncoming,
      );

      if (selectedPath == null) {
        await widget.backupStagingManager.cleanStaging();
        if (mounted) setState(() => _isRestoring = false);
        return;
      }

      final validation = await widget.backupArchiveService.validateAndExtractArchive(
        archiveFile: File(selectedPath),
        stagingDir: stagingDir,
      );

      if (!mounted) return;
      setState(() => _isRestoring = false);

      if (!validation.isValid) {
        await widget.backupStagingManager.cleanStaging();
        _showErrorDialog(l10n.restoreFailed(validation.error ?? 'Unknown validation error'));
        return;
      }

      // Show dry-run preview modal
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => RestorePreviewDialog(
          validationResult: validation,
          onConfirm: () async {
            Navigator.pop(dialogCtx);
            await _executeRestoreCommit(validation);
          },
          onCancel: () async {
            Navigator.pop(dialogCtx);
            await widget.backupStagingManager.cleanStaging();
          },
        ),
      );
    } catch (e) {
      await widget.backupStagingManager.cleanStaging();
      if (mounted) {
        setState(() => _isRestoring = false);
        _showErrorDialog(l10n.restoreFailed(e.toString()));
      }
    }
  }

  Future<void> _executeRestoreCommit(BackupValidationResult validation) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isRestoring = true);

    try {
      await widget.backupStagingManager.executeTwoPhaseRestore(
        snapshot: validation.snapshot!,
        stagedPhotos: validation.photoFiles,
        onDbRestore: (restoreToken) async {
          await widget.repository.restoreDataSnapshot(
            validation.snapshot!,
            restoreToken: restoreToken,
          );
        },
        repository: widget.repository,
      );

      if (!mounted) return;
      setState(() => _isRestoring = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.restoreSuccess),
          backgroundColor: HomesetsColors.surfaceElevated,
        ),
      );

      widget.onDataRestored();
    } catch (e) {
      if (mounted) {
        setState(() => _isRestoring = false);
        _showErrorDialog(l10n.restoreFailed(e.toString()));
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HomesetsColors.surface,
        title: Text('Error', style: HomesetsTypography.heading3),
        content: Text(message, style: HomesetsTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: HomesetsTypography.buttonText.copyWith(color: HomesetsColors.lime)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        appBar: HomesetsHeader(),
        body: Center(child: CircularProgressIndicator(color: HomesetsColors.lime)),
      );
    }

    final formattedTime =
        '${_reminderSettings.hour.toString().padLeft(2, '0')}:${_reminderSettings.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: HomesetsHeader(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: HomesetsColors.textPrimary),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Text(l10n.settingsTitle, style: HomesetsTypography.heading2),
            const SizedBox(height: 20),

            // 1. Equipment & Joint Profile Section
            TactileCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune, color: HomesetsColors.lime, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.profileEquipmentSettings,
                          style: HomesetsTypography.heading3.copyWith(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.profileEquipmentSubtitle, style: HomesetsTypography.bodySmall),
                  const SizedBox(height: 14),
                  KineticButton(
                    label: l10n.editProfile,
                    style: KineticButtonStyle.secondary,
                    onPressed: widget.onEditProfile,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Daily Local Reminders Section (WP16, WP17, WP18)
            TactileCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined, color: HomesetsColors.lime, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.remindersSectionTitle,
                          style: HomesetsTypography.heading3.copyWith(fontSize: 16),
                        ),
                      ),
                      Switch(
                        value: _reminderSettings.isEnabled,
                        activeThumbColor: HomesetsColors.lime,
                        activeTrackColor: HomesetsColors.lime.withValues(alpha: 0.3),
                        inactiveThumbColor: HomesetsColors.textSecondary,
                        inactiveTrackColor: HomesetsColors.surfaceElevated,
                        onChanged: _toggleReminders,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.reminderShameFreeDesc, style: HomesetsTypography.bodySmall),
                  if (!_notificationsEnabled) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: HomesetsColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: HomesetsColors.orange.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_off_outlined, color: HomesetsColors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.notificationsDisabledWarning,
                              style: HomesetsTypography.bodySmall.copyWith(color: HomesetsColors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_reminderSettings.isEnabled) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${l10n.reminderTimeLabel}: $formattedTime',
                            style: HomesetsTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.access_time, size: 18, color: HomesetsColors.lime),
                          label: Text(
                            l10n.changeTime,
                            style: HomesetsTypography.buttonText.copyWith(color: HomesetsColors.lime),
                          ),
                          onPressed: _pickReminderTime,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: HomesetsColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: HomesetsColors.borderSubtle),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: HomesetsColors.textMuted, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.reminderRebootNotice,
                              style: HomesetsTypography.bodySmall.copyWith(color: HomesetsColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Backup & Local Data Management Section (WP10, WP11, WP12)
            TactileCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: HomesetsColors.lime, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.backupSectionTitle,
                          style: HomesetsTypography.heading3.copyWith(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Privacy Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: HomesetsColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: HomesetsColors.borderSubtle),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock_outline, color: HomesetsColors.lime, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.backupPrivacyNotice,
                            style: HomesetsTypography.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isBackingUp) ...[
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: HomesetsColors.lime),
                          const SizedBox(height: 8),
                          Text(l10n.creatingBackup, style: HomesetsTypography.bodySmall),
                        ],
                      ),
                    ),
                  ] else ...[
                    KineticButton(
                      label: l10n.createBackup,
                      onPressed: _handleCreateBackup,
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (_isRestoring) ...[
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: HomesetsColors.lime),
                          const SizedBox(height: 8),
                          Text(l10n.restoringBackup, style: HomesetsTypography.bodySmall),
                        ],
                      ),
                    ),
                  ] else ...[
                    KineticButton(
                      label: l10n.restoreBackup,
                      style: KineticButtonStyle.secondary,
                      onPressed: _handleRestoreBackup,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
