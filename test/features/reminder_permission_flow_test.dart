import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesets/core/theme/homesets_theme.dart';
import 'package:homesets/data/database/database_helper.dart';
import 'package:homesets/data/repositories/workout_repository.dart';
import 'package:homesets/data/services/backup_archive_service.dart';
import 'package:homesets/data/services/backup_hash_provider.dart';
import 'package:homesets/data/services/backup_platform_service.dart';
import 'package:homesets/data/services/backup_staging_manager.dart';
import 'package:homesets/data/services/photo_service.dart';
import 'package:homesets/data/services/reminder_platform_service.dart';
import 'package:homesets/domain/models/domain_models.dart';
import 'package:homesets/domain/models/reminder_settings.dart';
import 'package:homesets/features/settings/settings_screen.dart';
import 'package:homesets/l10n/app_localizations.dart';
import 'package:homesets/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FailingSettingsWorkoutRepository extends WorkoutRepository {
  bool failSaveReminderSettings = false;

  @override
  Future<void> saveReminderSettings(ReminderSettings settings) async {
    if (failSaveReminderSettings) {
      throw Exception('Simulated SQLite disk/write failure during saveReminderSettings');
    }
    return super.saveReminderSettings(settings);
  }
}

void main() {
  late Directory tempDir;
  late FailingSettingsWorkoutRepository repository;
  late MockBackupPlatformService mockBackupPlatform;
  late MockReminderPlatformService mockReminderPlatform;
  late MockPhotoService mockPhotoService;
  late BackupArchiveService archiveService;
  late BackupStagingManager stagingManager;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setCustomFactory(databaseFactoryFfi);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('homesets_reminder_test_');
    repository = FailingSettingsWorkoutRepository();
    mockBackupPlatform = MockBackupPlatformService();
    mockReminderPlatform = MockReminderPlatformService();
    mockPhotoService = MockPhotoService();
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

    // Seed profile
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

  Widget createSettingsScreenWidget({
    Locale locale = const Locale('en'),
    WorkoutRepository? customRepository,
    ReminderPlatformService? customReminderPlatform,
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
        repository: customRepository ?? repository,
        backupPlatformService: mockBackupPlatform,
        backupArchiveService: archiveService,
        backupStagingManager: stagingManager,
        reminderPlatformService: customReminderPlatform ?? mockReminderPlatform,
        onEditProfile: () {},
        onBack: () {},
        onDataRestored: () {},
      ),
    );
  }

  group('P6 Daily Reminders & Permission Flow Tests (GOV25A, WP01-WP12)', () {
    testWidgets('1. Toggle ON when notifications already enabled schedules alarm and saves isEnabled: true', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await pumpAsync(tester);

      expect(mockReminderPlatform.isScheduled, isTrue);
      expect(mockReminderPlatform.scheduledHour, equals(15));
      expect(mockReminderPlatform.scheduledMinute, equals(30));
      expect(mockReminderPlatform.requestPermissionCallCount, equals(0));

      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isTrue);
      expect(saved?.hour, equals(15));
      expect(saved?.minute, equals(30));
    });

    testWidgets('2. Toggle ON when notifications disabled displays pre-permission explanation dialog', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = false;

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      // Pre-permission explanation dialog appears
      expect(find.text('Enable Daily Reminders'), findsOneWidget);
      expect(find.textContaining('100% offline'), findsOneWidget);
      expect(find.text('Allow & Set Reminder'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);

      // Native permission not yet requested
      expect(mockReminderPlatform.requestPermissionCallCount, equals(0));
      expect(mockReminderPlatform.isScheduled, isFalse);

      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isFalse);
    });

    testWidgets('3. Pre-permission dialog "Not Now" cancels without prompting OS or saving', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = false;

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      await tester.tap(find.byType(Switch));
      await pumpAsync(tester);

      expect(find.text('Not Now'), findsOneWidget);
      await tester.tap(find.text('Not Now'));
      await pumpAsync(tester);

      // Dialog dismissed
      expect(find.text('Enable Daily Reminders'), findsNothing);

      // Native permission was NOT invoked
      expect(mockReminderPlatform.requestPermissionCallCount, equals(0));
      expect(mockReminderPlatform.isScheduled, isFalse);

      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isFalse);
    });

    testWidgets('4. Pre-permission dialog "Allow & Set Reminder" grants permission, schedules alarm, and persists', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = false;
      mockReminderPlatform.requestPermissionResult = true;

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      await tester.tap(find.byType(Switch));
      await pumpAsync(tester);

      await tester.tap(find.text('Allow & Set Reminder'));
      await pumpAsync(tester);

      // Native permission requested and granted
      expect(mockReminderPlatform.requestPermissionCallCount, equals(1));
      expect(mockReminderPlatform.isScheduled, isTrue);

      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isTrue);
    });

    testWidgets('5. Pre-permission dialog "Allow & Set Reminder" denied keeps toggle OFF, shows snackbar, and does not save', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = false;
      mockReminderPlatform.requestPermissionResult = false; // User denies OS prompt

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      await tester.tap(find.byType(Switch));
      await pumpAsync(tester);

      await tester.tap(find.text('Allow & Set Reminder'));
      await pumpAsync(tester);

      expect(mockReminderPlatform.requestPermissionCallCount, equals(1));
      expect(mockReminderPlatform.isScheduled, isFalse);

      // Denied snackbar shown
      expect(find.textContaining('Notification permission was not granted'), findsOneWidget);

      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isFalse);
    });

    testWidgets('6. Scheduling failure on native layer keeps toggle OFF and does not persist', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.scheduleDailyReminderResult = false; // Native scheduling returns false

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      await tester.tap(find.byType(Switch));
      await pumpAsync(tester);

      expect(find.textContaining('Failed to schedule reminder'), findsOneWidget);

      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isFalse);
    });

    testWidgets('7. Toggle OFF cancels scheduled alarm and persists isEnabled: false', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;

      // Seed as enabled
      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 15,
        minute: 30,
        updatedAt: DateTime.now(),
      )));

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      // Toggle OFF
      await tester.tap(find.byType(Switch));
      await pumpAsync(tester);

      expect(mockReminderPlatform.isScheduled, isFalse);

      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isFalse);
    });

    testWidgets('8. Rescheduling reminder time while enabled updates alarm and persists', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;

      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 15,
        minute: 30,
        updatedAt: DateTime.now(),
      )));

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      expect(find.text('Change Time'), findsOneWidget);
      await tester.tap(find.text('Change Time'));
      await pumpAsync(tester);

      // TimePicker dialog is open; tap OK to select current time
      final okBtn = find.text('OK');
      expect(okBtn, findsOneWidget);
      await tester.tap(okBtn);
      await pumpAsync(tester);

      expect(mockReminderPlatform.isScheduled, isTrue);
      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isTrue);
    });

    testWidgets('9. App startup safely reschedules alarm if enabled and notifications permitted', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;

      // Seed enabled reminder (as if device had rebooted)
      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 17,
        minute: 45,
        updatedAt: DateTime.now(),
      )));

      await tester.pumpWidget(HomesetsApp(
        repository: repository,
        photoService: mockPhotoService,
        backupStagingManager: stagingManager,
        reminderPlatformService: mockReminderPlatform,
      ));
      await pumpAsync(tester, 10);

      // Verify that startup rescheduled the alarm
      expect(mockReminderPlatform.isScheduled, isTrue);
      expect(mockReminderPlatform.scheduledHour, equals(17));
      expect(mockReminderPlatform.scheduledMinute, equals(45));

      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isTrue);
    });

    testWidgets('10. P6-NOTIFY-01: App startup cancels previously scheduled alarm when permission revoked, preventing stale alarm on regrant', (tester) async {
      setupPhoneViewport(tester);

      // Initial state: alarm was previously active
      mockReminderPlatform.isScheduled = true;
      mockReminderPlatform.scheduledHour = 17;
      mockReminderPlatform.scheduledMinute = 45;
      mockReminderPlatform.notificationsEnabled = false; // Permission was revoked in OS settings while app closed

      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 17,
        minute: 45,
        updatedAt: DateTime.now(),
      )));

      await tester.pumpWidget(HomesetsApp(
        repository: repository,
        photoService: mockPhotoService,
        backupStagingManager: stagingManager,
        reminderPlatformService: mockReminderPlatform,
      ));
      await pumpAsync(tester, 10);

      // P6-NOTIFY-01: Verify startup explicitly cancelled the alarm in AlarmManager!
      expect(mockReminderPlatform.isScheduled, isFalse);
      expect(mockReminderPlatform.cancelDailyReminderCallCount, greaterThanOrEqualTo(1));

      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isFalse);

      // Subsequent scenario: user regrants notifications in Android OS settings
      // WITHOUT opening HOMESETS or turning the reminder ON.
      mockReminderPlatform.notificationsEnabled = true;

      // Alarm must remain CANCELLED. No unexpected reminder remains scheduled.
      expect(mockReminderPlatform.isScheduled, isFalse);
    });

    testWidgets('11. App resume reconciles revoked notification permission, cancels alarm, and updates UI', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;

      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 15,
        minute: 30,
        updatedAt: DateTime.now(),
      )));

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      // Verify switch is ON
      Switch switchWidget = tester.widget(find.byType(Switch));
      expect(switchWidget.value, isTrue);

      // Simulate user revoking notification permission in OS settings while app is in background
      mockReminderPlatform.notificationsEnabled = false;

      // Dispatch lifecycle resumed state
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpAsync(tester);

      // Switch should now be OFF
      switchWidget = tester.widget(find.byType(Switch));
      expect(switchWidget.value, isFalse);

      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isFalse);
    });

    testWidgets('12. Localized dialog copy and reboot notice in Arabic and English', (tester) async {
      setupPhoneViewport(tester);

      // English
      await tester.pumpWidget(createSettingsScreenWidget(locale: const Locale('en')));
      await pumpAsync(tester);

      expect(find.text('Daily Local Reminder'), findsOneWidget);
      expect(find.textContaining('guilt-free'), findsOneWidget);

      // Arabic
      await tester.pumpWidget(createSettingsScreenWidget(locale: const Locale('ar')));
      await pumpAsync(tester);

      expect(find.text('التذكير اليومي المحلي'), findsOneWidget);
      expect(find.textContaining('تذكير يومي لطيف في الوقت اللي يناسب شيفتك'), findsOneWidget);
    });

    testWidgets('13. P6-NOTIFY-02: Toggle OFF when native cancellation returns false keeps toggle ON and does not save false', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.isScheduled = true;
      mockReminderPlatform.cancelDailyReminderResult = false; // Native cancellation fails

      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 15,
        minute: 30,
        updatedAt: DateTime.now(),
      )));

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      final switchFinder = find.byType(Switch);
      Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);

      // Attempt toggle OFF
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      // Error snackbar shown
      expect(find.textContaining('Failed to cancel scheduled reminder'), findsOneWidget);

      // Toggle remains ON (no misleading disabled state!)
      switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);

      // SQLite retains isEnabled: true
      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isTrue);
    });

    testWidgets('14. P6-NOTIFY-02: Toggle OFF when native cancellation throws PlatformException keeps toggle ON and does not save false', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.isScheduled = true;
      mockReminderPlatform.cancelDailyReminderException = PlatformException(
        code: 'CANCEL_FAILED',
        message: 'AlarmManager service unavailable',
      );

      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 15,
        minute: 30,
        updatedAt: DateTime.now(),
      )));

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      final switchFinder = find.byType(Switch);
      Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);

      // Attempt toggle OFF
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      // Error snackbar shown
      expect(find.textContaining('Failed to cancel scheduled reminder'), findsOneWidget);

      // Toggle remains ON
      switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);

      // SQLite retains isEnabled: true
      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isTrue);
    });

    testWidgets('15. P6-NOTIFY-02: App resume reconciliation when cancellation fails alerts user without falsely marking disabled in SQLite', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.isScheduled = true;
      mockReminderPlatform.cancelDailyReminderResult = false; // Native cancellation fails

      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 15,
        minute: 30,
        updatedAt: DateTime.now(),
      )));

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      // Simulate permission revoked in OS settings
      mockReminderPlatform.notificationsEnabled = false;

      // Resume app
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpAsync(tester);

      // Alert snackbar shown explaining cancellation could not be completed
      expect(find.textContaining('could not be cancelled'), findsOneWidget);

      // SQLite has NOT been falsely marked disabled
      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isTrue);
    });

    testWidgets('16. P6-NOTIFY-03: Toggle ON compensates by cancelling scheduled alarm if SQLite save fails', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      repository.failSaveReminderSettings = true; // Simulate DB write failure

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      // Save failed snackbar shown
      expect(find.textContaining('Failed to save reminder settings'), findsOneWidget);

      // Compensating action cancelled the scheduled alarm!
      expect(mockReminderPlatform.isScheduled, isFalse);
      expect(mockReminderPlatform.cancelDailyReminderCallCount, greaterThanOrEqualTo(1));

      // Switch remains OFF
      final Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isFalse);
    });

    testWidgets('17. P6-NOTIFY-03: Toggle OFF compensates by restoring schedule if SQLite save fails', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.isScheduled = true;
      mockReminderPlatform.scheduledHour = 15;
      mockReminderPlatform.scheduledMinute = 30;

      // Persist enabled
      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 15,
        minute: 30,
        updatedAt: DateTime.now(),
      )));

      // Now inject failure on next save
      repository.failSaveReminderSettings = true;

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      // Save failed snackbar shown
      expect(find.textContaining('Failed to save reminder settings'), findsOneWidget);

      // Compensating action restored the schedule to maintain consistency with SQLite!
      expect(mockReminderPlatform.isScheduled, isTrue);
      expect(mockReminderPlatform.scheduledHour, equals(15));
      expect(mockReminderPlatform.scheduledMinute, equals(30));

      // Switch remains ON
      final Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);
    });

    testWidgets('18. P6-NOTIFY-03: Time change compensates by restoring original schedule if SQLite save fails', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.isScheduled = true;
      mockReminderPlatform.scheduledHour = 15;
      mockReminderPlatform.scheduledMinute = 30;

      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 15,
        minute: 30,
        updatedAt: DateTime.now(),
      )));

      // Inject save failure
      repository.failSaveReminderSettings = true;

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      expect(find.text('Change Time'), findsOneWidget);
      await tester.tap(find.text('Change Time'));
      await pumpAsync(tester);

      // Tap OK in TimePicker
      final okBtn = find.text('OK');
      expect(okBtn, findsOneWidget);
      await tester.tap(okBtn);
      await pumpAsync(tester);

      // Save failed snackbar shown
      expect(find.textContaining('Failed to save reminder settings'), findsOneWidget);

      // Compensating action restored original scheduled alarm (15:30)
      expect(mockReminderPlatform.isScheduled, isTrue);
      expect(mockReminderPlatform.scheduledHour, equals(15));
      expect(mockReminderPlatform.scheduledMinute, equals(30));
    });
  });
}
