import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesets/core/theme/homesets_theme.dart';
import 'package:homesets/data/database/database_helper.dart';
import 'package:homesets/data/repositories/workout_repository.dart';
import 'package:homesets/data/services/backup_archive_service.dart';
import 'package:homesets/data/services/backup_hash_provider.dart';
import 'package:homesets/data/services/backup_platform_service.dart';
import 'package:homesets/data/services/backup_staging_manager.dart';
import 'package:homesets/data/services/reminder_platform_service.dart';
import 'package:homesets/domain/backup/backup_models.dart';
import 'package:homesets/domain/models/domain_models.dart';
import 'package:homesets/features/settings/settings_screen.dart';
import 'package:homesets/features/settings/widgets/restore_preview_dialog.dart';
import 'package:homesets/l10n/app_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late WorkoutRepository repository;
  late MockBackupPlatformService mockBackupPlatform;
  late MockReminderPlatformService mockReminderPlatform;
  late BackupArchiveService archiveService;
  late BackupStagingManager stagingManager;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setCustomFactory(databaseFactoryFfi);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('homesets_settings_test_');
    repository = WorkoutRepository();
    mockBackupPlatform = MockBackupPlatformService();
    mockReminderPlatform = MockReminderPlatformService();
    archiveService = const BackupArchiveService(hashProvider: DefaultBackupHashProvider());
    stagingManager = BackupStagingManager(appDocsDir: tempDir);

    // Clean tables between tests
    final db = await DatabaseHelper.instance.database;
    await db.delete('set_logs');
    await db.delete('workout_sessions');
    await db.delete('user_profile');
    await db.delete('equipment_inventory');
    await db.delete('active_session_state');
    await db.delete('session_salvage_archive');
    await db.delete('weight_entries');
    await db.delete('progress_photos');
    await db.delete('daily_meal_checks');
    await db.delete('reminder_settings');

    // Seed basic profile
    await repository.saveUserProfile(const UserProfile(
      id: 'default',
      goal: 'MUSCLE_BUILDING',
      wakeTimeMinutes: 480,
      shiftStartMinutes: 1140,
    ));
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  Future<void> pumpAsync(WidgetTester tester, [int count = 6]) async {
    for (var i = 0; i < count; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  void setupPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget createTestWidget({
    Locale locale = const Locale('en'),
    VoidCallback? onEditProfile,
    VoidCallback? onBack,
    VoidCallback? onDataRestored,
  }) {
    return MaterialApp(
      locale: locale,
      theme: HomesetsTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
      ],
      home: SettingsScreen(
        repository: repository,
        backupPlatformService: mockBackupPlatform,
        backupArchiveService: archiveService,
        backupStagingManager: stagingManager,
        reminderPlatformService: mockReminderPlatform,
        onEditProfile: onEditProfile ?? () {},
        onBack: onBack ?? () {},
        onDataRestored: onDataRestored ?? () {},
      ),
    );
  }

  group('SettingsScreen & Backup/Reminder Flow (WP10, WP12, WP15, WP16, WP18)', () {
    testWidgets('Renders all 3 sections in English and Arabic', (tester) async {
      setupPhoneViewport(tester);
      await tester.pumpWidget(createTestWidget(locale: const Locale('en')));
      await pumpAsync(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Equipment & Joint Profile'), findsOneWidget);
      expect(find.text('Daily Local Reminder'), findsOneWidget);
      expect(find.text('Backup & Local Data'), findsOneWidget);
      expect(find.text('Create Offline Backup'), findsOneWidget);
      expect(find.text('Restore from Backup'), findsOneWidget);

      // Switch to Arabic
      await tester.pumpWidget(createTestWidget(locale: const Locale('ar')));
      await pumpAsync(tester);

      expect(find.text('الإعدادات'), findsOneWidget);
      expect(find.text('الأدوات وسلامة المفاصل'), findsOneWidget);
      expect(find.text('التذكير اليومي المحلي'), findsOneWidget);
      expect(find.text('النسخ الاحتياطي والبيانات'), findsOneWidget);
      expect(find.text('إنشاء نسخة احتياطية محلية'), findsOneWidget);
      expect(find.text('استعادة من نسخة احتياطية'), findsOneWidget);
    });

    testWidgets('Toggling reminder schedules alarm and persists in repository', (tester) async {
      setupPhoneViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await pumpAsync(tester);

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Initially disabled
      final initialSettings = await tester.runAsync(() => repository.getReminderSettings());
      expect(initialSettings?.isEnabled, isFalse);

      // Toggle ON
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      expect(mockReminderPlatform.isScheduled, isTrue);
      expect(mockReminderPlatform.scheduledHour, equals(15));
      expect(mockReminderPlatform.scheduledMinute, equals(30));

      final updatedSettings = await tester.runAsync(() => repository.getReminderSettings());
      expect(updatedSettings?.isEnabled, isTrue);

      // Toggle OFF
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      expect(mockReminderPlatform.isScheduled, isFalse);
      final turnedOffSettings = await tester.runAsync(() => repository.getReminderSettings());
      expect(turnedOffSettings?.isEnabled, isFalse);
    });

    testWidgets('Shows warning banner when notifications are disabled at system level', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = false;

      await tester.pumpWidget(createTestWidget());
      await pumpAsync(tester);

      expect(find.textContaining('Notifications are disabled in system settings'), findsOneWidget);
    });

    testWidgets('Create Backup exports valid archive and shows success snackbar', (tester) async {
      setupPhoneViewport(tester);
      await tester.pumpWidget(createTestWidget());
      await pumpAsync(tester);

      final backupBtn = find.text('Create Offline Backup');
      expect(backupBtn, findsOneWidget);

      await tester.tap(backupBtn);
      for (var i = 0; i < 30; i++) {
        await pumpAsync(tester, 2);
        if (find.text('Backup exported successfully.').evaluate().isNotEmpty) break;
      }

      expect(find.text('Backup exported successfully.'), findsOneWidget);
    });

    testWidgets('Restore Backup displays dry-run preview and commits on confirmation', (tester) async {
      setupPhoneViewport(tester);
      var dataRestoredCalled = false;

      // Create a valid backup archive to import
      final validArchiveFile = File('${tempDir.path}/test_import.homesets');
      const snapshot = HomesetsDataSnapshot(
        userProfile: {
          'id': 'restored_user',
          'goal': 'STRENGTH',
          'wake_time_minutes': 360,
          'shift_start_minutes': 900,
          'target_workouts_per_week': 3,
          'avoided_joints': '[]',
          'created_at': '2026-11-21T00:00:00.000Z',
        },
        workoutSessions: [
          {
            'id': 'sess_1',
            'scheduled_session_id': 'sch_1',
            'routine_name': 'Routine A',
            'is_lite_mode': 0,
            'started_at': '2026-11-21T01:00:00.000Z',
            'ended_at': '2026-11-21T01:45:00.000Z',
            'total_duration_seconds': 2700,
            'is_emergency_stopped': 0,
          }
        ],
        setLogs: [],
        salvageArchives: [],
        weightEntries: [],
        progressPhotos: [],
        dailyMealChecks: [],
      );

      await tester.runAsync(() async {
        await archiveService.createBackupArchive(
          snapshot: snapshot,
          photoFiles: [],
          outputFilePath: validArchiveFile.path,
        );
      });

      mockBackupPlatform.importFilePath = validArchiveFile.path;

      await tester.pumpWidget(createTestWidget(
        onDataRestored: () {
          dataRestoredCalled = true;
        },
      ));
      await pumpAsync(tester);

      // Tap Restore button
      final restoreBtn = find.text('Restore from Backup');
      await tester.ensureVisible(restoreBtn);
      await pumpAsync(tester, 2);
      await tester.tap(restoreBtn);

      // Wait for validation to finish and dialog to open
      for (var i = 0; i < 30; i++) {
        await pumpAsync(tester, 2);
        if (find.byType(RestorePreviewDialog).evaluate().isNotEmpty) {
          break;
        }
      }

      // Verify Restore Preview Dialog opened
      expect(find.byType(RestorePreviewDialog), findsOneWidget);
      expect(find.text('Restore Backup Preview'), findsOneWidget);
      expect(find.text('Workout Sessions: 1'), findsOneWidget);
      expect(find.textContaining('WARNING: Restoring will completely replace'), findsOneWidget);

      // Tap "Replace Data & Restore"
      final confirmBtn = find.text('Replace Data & Restore');
      await tester.tap(confirmBtn);
      for (var i = 0; i < 40; i++) {
        await pumpAsync(tester, 2);
        if (dataRestoredCalled) break;
      }

      expect(dataRestoredCalled, isTrue);
      expect(find.text('Data and photos restored successfully.'), findsOneWidget);

      // Verify profile was updated in SQLite
      final restoredProfile = await tester.runAsync(() => repository.getUserProfile());
      expect(restoredProfile?.id, equals('restored_user'));
      expect(restoredProfile?.wakeTimeMinutes, equals(360));
    });

    testWidgets('Restore Cancel preserves current database contents untouched', (tester) async {
      setupPhoneViewport(tester);
      final validArchiveFile = File('${tempDir.path}/test_cancel.homesets');
      const snapshot = HomesetsDataSnapshot(
        userProfile: {
          'id': 'cancelled_user',
          'goal': 'STRENGTH',
          'wake_time_minutes': 100,
          'shift_start_minutes': 200,
          'target_workouts_per_week': 3,
          'avoided_joints': '[]',
          'created_at': '2026-11-21T00:00:00.000Z',
        },
        workoutSessions: [],
        setLogs: [],
        salvageArchives: [],
        weightEntries: [],
        progressPhotos: [],
        dailyMealChecks: [],
      );

      await tester.runAsync(() async {
        await archiveService.createBackupArchive(
          snapshot: snapshot,
          photoFiles: [],
          outputFilePath: validArchiveFile.path,
        );
      });

      mockBackupPlatform.importFilePath = validArchiveFile.path;

      await tester.pumpWidget(createTestWidget());
      await pumpAsync(tester);

      final restoreBtn = find.text('Restore from Backup');
      await tester.ensureVisible(restoreBtn);
      await pumpAsync(tester, 2);
      await tester.tap(restoreBtn);

      for (var i = 0; i < 30; i++) {
        await pumpAsync(tester, 2);
        if (find.byType(RestorePreviewDialog).evaluate().isNotEmpty) {
          break;
        }
      }

      // Tap Cancel on preview dialog
      await tester.tap(find.text('Cancel'));
      await pumpAsync(tester);

      expect(find.byType(RestorePreviewDialog), findsNothing);

      // Verify original profile remains untouched
      final currentProfile = await tester.runAsync(() => repository.getUserProfile());
      expect(currentProfile?.id, equals('default'));
      expect(currentProfile?.wakeTimeMinutes, equals(480));
    });

    testWidgets('THREAT-01 / THREAT-03: Corrupt or tampered restore shows error dialog and touches nothing',
        (tester) async {
      setupPhoneViewport(tester);
      // Write invalid/corrupt archive
      final corruptArchiveFile = File('${tempDir.path}/corrupt.homesets');
      await tester.runAsync(() async {
        await corruptArchiveFile.writeAsBytes(Uint8List.fromList([1, 2, 3, 4, 5]));
      });

      mockBackupPlatform.importFilePath = corruptArchiveFile.path;

      await tester.pumpWidget(createTestWidget());
      await pumpAsync(tester);

      final restoreBtn = find.text('Restore from Backup');
      await tester.ensureVisible(restoreBtn);
      await pumpAsync(tester, 2);
      await tester.tap(restoreBtn);

      for (var i = 0; i < 30; i++) {
        await pumpAsync(tester, 2);
        if (find.byType(AlertDialog).evaluate().isNotEmpty) {
          break;
        }
      }

      // Verify error dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Corrupt or invalid backup container format'), findsOneWidget);

      // Tap OK
      await tester.tap(find.text('OK'));
      await pumpAsync(tester);

      // Verify original profile untouched
      final currentProfile = await tester.runAsync(() => repository.getUserProfile());
      expect(currentProfile?.id, equals('default'));
    });
  });
}
