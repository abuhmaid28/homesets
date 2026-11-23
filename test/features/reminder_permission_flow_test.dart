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
  int failSaveReminderSettingsCount = 0;

  @override
  Future<void> saveReminderSettings(ReminderSettings settings) async {
    if (failSaveReminderSettings || failSaveReminderSettingsCount > 0) {
      if (failSaveReminderSettingsCount > 0) {
        failSaveReminderSettingsCount--;
      }
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
      mockReminderPlatform.consentEnabled = true; // Native consent in SharedPreferences survives reboot

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

    testWidgets('15. P6-NOTIFY-02 & P6-NOTIFY-10: App resume reconciliation when cancellation fails records durable blocked state and revokes native consent', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.isScheduled = true;
      mockReminderPlatform.consentEnabled = true;
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

      // Native consent revoked fail-closed
      expect(mockReminderPlatform.consentEnabled, isFalse);

      // SQLite records durable blocked state with isEnabled: false (unified with startup reconciliation)
      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isFalse);
      expect(saved?.isPendingReconciliation, isTrue);

      // Delivery invariant: fail-closed delivery suppression
      expect(mockReminderPlatform.simulateAlarmDelivery(), isFalse);
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

    testWidgets('17. P6-NOTIFY-13: Toggle OFF SQLite save failure never silently re-enables alarm or restores native consent', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.isScheduled = true;
      mockReminderPlatform.consentEnabled = true;
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

      // Invariant (P6-NOTIFY-13): Alarm remains cancelled and consent remains revoked!
      expect(mockReminderPlatform.isScheduled, isFalse);
      expect(mockReminderPlatform.consentEnabled, isFalse);
      expect(mockReminderPlatform.simulateAlarmDelivery(), isFalse);

      // Switch is OFF
      final Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isFalse);
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

    testWidgets('19. P6-NOTIFY-04 & P6-NOTIFY-08: Startup cancellation returning false revokes native consent and records durable blocked reconciliation state', (tester) async {
      setupPhoneViewport(tester);

      // Initial state: alarm was active, consent was true, permission revoked in OS
      mockReminderPlatform.isScheduled = true;
      mockReminderPlatform.consentEnabled = true;
      mockReminderPlatform.scheduledHour = 17;
      mockReminderPlatform.scheduledMinute = 45;
      mockReminderPlatform.notificationsEnabled = false;
      mockReminderPlatform.cancelDailyReminderResult = false; // Native cancellation fails

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

      // Cancellation was attempted
      expect(mockReminderPlatform.cancelDailyReminderCallCount, greaterThanOrEqualTo(1));

      // Native consent revoked fail-closed
      expect(mockReminderPlatform.consentEnabled, isFalse);

      // SQLite records durable blocked state with isEnabled: false (fail-closed consent)
      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isFalse);
      expect(saved?.isPendingReconciliation, isTrue);

      // Subsequent OS permission regrant without in-app opt-in CANNOT dispatch notification!
      mockReminderPlatform.notificationsEnabled = true;
      expect(mockReminderPlatform.simulateAlarmDelivery(), isFalse);
    });

    testWidgets('20. P6-NOTIFY-04 & P6-NOTIFY-08: Startup cancellation throwing revokes native consent and records durable blocked state', (tester) async {
      setupPhoneViewport(tester);

      mockReminderPlatform.isScheduled = true;
      mockReminderPlatform.consentEnabled = true;
      mockReminderPlatform.scheduledHour = 17;
      mockReminderPlatform.scheduledMinute = 45;
      mockReminderPlatform.notificationsEnabled = false;
      mockReminderPlatform.cancelDailyReminderException = PlatformException(
        code: 'IPC_ERROR',
        message: 'Binder transaction failed',
      );

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

      expect(mockReminderPlatform.cancelDailyReminderCallCount, greaterThanOrEqualTo(1));

      // Native consent revoked fail-closed
      expect(mockReminderPlatform.consentEnabled, isFalse);

      // SQLite records durable blocked state
      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isFalse);
      expect(saved?.isPendingReconciliation, isTrue);
    });

    testWidgets('21. P6-NOTIFY-05: Platform service truthful failure reporting when AlarmManager unavailable', (tester) async {
      const MethodChannel channel = MethodChannel('com.abuhmaid.homesets/reminders');
      final log = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        log.add(call);
        if (call.method == 'scheduleDailyReminder') {
          return false; // Native AlarmManager returned false
        }
        if (call.method == 'cancelDailyReminder') {
          return false; // Native AlarmManager returned false
        }
        return null;
      });

      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      });

      const service = AndroidReminderPlatformService();
      final scheduleResult = await service.scheduleDailyReminder(
        hour: 15,
        minute: 30,
        title: 'HOMESETS',
        body: 'Ready?',
      );
      expect(scheduleResult, isFalse);

      final cancelResult = await service.cancelDailyReminder();
      expect(cancelResult, isFalse);
    });

    testWidgets('22. P6-NOTIFY-06: Toggle ON displays critical compensation failed snackbar when both DB save and compensating cancellation fail', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      repository.failSaveReminderSettings = true; // DB save fails
      mockReminderPlatform.cancelDailyReminderResult = false; // Compensating cancel ALSO fails

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      // Critical compensation failed snackbar shown
      expect(find.textContaining('Critical Error: Database update and reminder compensation failed'), findsOneWidget);
    });

    testWidgets('23. P6-NOTIFY-13: Toggle OFF when both consent revocation and cancellation fail retains ON state truthfully', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.isScheduled = true;
      mockReminderPlatform.consentEnabled = true;
      mockReminderPlatform.scheduledHour = 15;
      mockReminderPlatform.scheduledMinute = 30;

      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 15,
        minute: 30,
        updatedAt: DateTime.now(),
      )));

      // Neither consent can be revoked nor alarm cancelled (total platform failure)
      mockReminderPlatform.setReminderConsentResult = false;
      mockReminderPlatform.cancelDailyReminderResult = false;

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      // Warning snackbar shown
      expect(find.textContaining('Failed to cancel scheduled reminder'), findsOneWidget);

      // Switch remains ON because reminders are still live
      final Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);

      // SQLite remains enabled
      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isTrue);
    });

    testWidgets('24. P6-NOTIFY-06: Time change displays critical compensation failed snackbar when both DB save and compensating reschedule fail', (tester) async {
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

      repository.failSaveReminderSettings = true; // DB save fails
      int scheduleCount = 0;
      mockReminderPlatform.onScheduleDailyReminder = (hour, minute) {
        scheduleCount++;
        if (scheduleCount == 1) {
          // First schedule call (new time) succeeds
          return true;
        } else {
          // Second schedule call (compensating restore of original time) fails
          return false;
        }
      };

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

      // Critical compensation failed snackbar shown
      expect(find.textContaining('Critical Error: Database update and reminder compensation failed'), findsOneWidget);
    });

    testWidgets('25. P6-NOTIFY-07: Orphan alarm after failed ON save and failed cancel cannot dispatch and offers recovery on restart', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      repository.failSaveReminderSettingsCount = 1; // Initial ON save fails, but persisting blocked state succeeds
      mockReminderPlatform.cancelDailyReminderResult = false; // Compensating cancel also fails

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      // 1. Consent must remain FALSE in platform service fail-closed
      expect(mockReminderPlatform.consentEnabled, isFalse);

      // 2. Even if AlarmManager fires, native receiver suppresses delivery fail-closed!
      expect(mockReminderPlatform.simulateAlarmDelivery(), isFalse);

      // 3. Process restart / cold start
      repository.failSaveReminderSettings = false; // DB available again
      mockReminderPlatform.cancelDailyReminderResult = true; // Native cancel now succeeds on retry
      final cancelCallsBeforeRestart = mockReminderPlatform.cancelDailyReminderCallCount;

      await tester.pumpWidget(HomesetsApp(
        repository: repository,
        photoService: mockPhotoService,
        backupStagingManager: stagingManager,
        reminderPlatformService: mockReminderPlatform,
      ));
      await pumpAsync(tester, 10);

      // Startup attempted fresh cleanup of orphan/blocked state
      expect(mockReminderPlatform.cancelDailyReminderCallCount, greaterThan(cancelCallsBeforeRestart));
      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isFalse);
      expect(saved?.isPendingReconciliation, isFalse);
    });

    testWidgets('26. P6-NOTIFY-08: Revocation and cancel failure renders durable retry guidance in Settings and resolves on retry', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = false;
      mockReminderPlatform.cancelDailyReminderResult = true;

      // Seed durable blocked reconciliation state
      await tester.runAsync(() async {
        await repository.saveReminderSettings(ReminderSettings(
          isEnabled: false,
          hour: 15,
          minute: 30,
          updatedAt: DateTime.now(),
          isPendingReconciliation: true,
        ));
      });

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      // Warning card with retry button is visible
      expect(find.textContaining('Notice: Notification permission revoked'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap Retry button
      await tester.tap(find.text('Retry'));
      await pumpAsync(tester);

      // Cancellation succeeded, blocked state cleared
      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isPendingReconciliation, isFalse);
      expect(find.textContaining('Notice: Notification permission revoked'), findsNothing);
    });

    testWidgets('27. P6-NOTIFY-09: Disabled notification channel blocks reminder scheduling and displays truthful warning', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.channelEnabled = false; // Channel disabled by user in OS settings

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      // Displays channel-level disabled warning and does not schedule alarm
      expect(find.textContaining('notification channel for reminders is disabled'), findsOneWidget);
      expect(mockReminderPlatform.isScheduled, isFalse);

      final Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isFalse);
    });

    testWidgets('28. MethodChannel contract: setReminderConsent and getReminderConsent round-trip', (tester) async {
      const MethodChannel channel = MethodChannel('com.abuhmaid.homesets/reminders');
      final log = <MethodCall>[];
      bool nativeConsent = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        log.add(call);
        if (call.method == 'setReminderConsent') {
          nativeConsent = (call.arguments as Map)['enabled'] as bool;
          return true;
        }
        if (call.method == 'getReminderConsent') {
          return nativeConsent;
        }
        return null;
      });

      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      });

      const service = AndroidReminderPlatformService();
      final initialConsent = await service.getReminderConsent();
      expect(initialConsent, isFalse);

      final setResult = await service.setReminderConsent(true);
      expect(setResult, isTrue);

      final updatedConsent = await service.getReminderConsent();
      expect(updatedConsent, isTrue);
    });

    testWidgets('29. P6-NOTIFY-10: Resume revocation with cancel failure sets blocked state; regrant + restart never auto-renews consent', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.isScheduled = true;
      mockReminderPlatform.consentEnabled = true;
      mockReminderPlatform.cancelDailyReminderResult = false; // Native cancel fails on resume

      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 17,
        minute: 0,
        updatedAt: DateTime.now(),
      )));

      // 1. App is open in SettingsScreen
      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      // 2. Permission revoked in OS settings & resume
      mockReminderPlatform.notificationsEnabled = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpAsync(tester);

      // Verify blocked state was persisted symmetrically with startup
      final stateAfterResume = await tester.runAsync(() => repository.getReminderSettings());
      expect(stateAfterResume?.isEnabled, isFalse);
      expect(stateAfterResume?.isPendingReconciliation, isTrue);
      expect(mockReminderPlatform.consentEnabled, isFalse);

      // 3. User regrants OS permission in system settings while app is closed
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.cancelDailyReminderResult = true; // Native cancel succeeds now

      // 4. Cold app restart
      await tester.pumpWidget(HomesetsApp(
        repository: repository,
        photoService: mockPhotoService,
        backupStagingManager: stagingManager,
        reminderPlatformService: mockReminderPlatform,
      ));
      await pumpAsync(tester, 10);

      // Invariant: Consent MUST NOT be auto-granted and schedule MUST NOT be enabled
      expect(mockReminderPlatform.consentEnabled, isFalse);
      final stateAfterRestart = await tester.runAsync(() => repository.getReminderSettings());
      expect(stateAfterRestart?.isEnabled, isFalse);
      expect(stateAfterRestart?.isPendingReconciliation, isFalse); // Successfully cleaned up
      expect(mockReminderPlatform.simulateAlarmDelivery(), isFalse);
    });

    testWidgets('30. P6-NOTIFY-11: Toggle ON fails closed when native setReminderConsent commit returns false', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.setReminderConsentResult = false; // Native SharedPreferences.commit() returns false

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      // Save failed snackbar shown
      expect(find.textContaining('Failed to save reminder settings'), findsOneWidget);

      // Scheduled alarm was cancelled as compensation
      expect(mockReminderPlatform.isScheduled, isFalse);

      // Switch remains OFF
      final Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isFalse);

      // SQLite records disabled state with pending reconciliation
      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isFalse);
      expect(saved?.isPendingReconciliation, isTrue);

      // Delivery invariant: cannot dispatch
      expect(mockReminderPlatform.simulateAlarmDelivery(), isFalse);
    });

    testWidgets('31. P6-NOTIFY-11: Toggle OFF fails closed and warns user when native setReminderConsent commit returns false', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.isScheduled = true;
      mockReminderPlatform.consentEnabled = true;

      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 12,
        minute: 0,
        updatedAt: DateTime.now(),
      )));

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      // Verify switch is currently ON
      final switchFinder = find.byType(Switch);
      Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);

      // Inject setReminderConsent failure
      mockReminderPlatform.setReminderConsentResult = false;

      // User taps switch to turn OFF
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      // Alert snackbar shown explaining reminder could not be cancelled
      expect(find.textContaining('Failed to cancel scheduled reminder'), findsOneWidget);

      // Switch remains ON because cancellation/revocation was not verified
      switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);

      // Stored state preserves enabled setting
      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isTrue);
    });

    testWidgets('32. P6-NOTIFY-13: Toggle OFF SQLite save failure never silently re-enables alarm or restores native consent', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.isScheduled = true;
      mockReminderPlatform.consentEnabled = true;

      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 14,
        minute: 15,
        updatedAt: DateTime.now(),
      )));

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      // Inject SQLite failure on save
      repository.failSaveReminderSettings = true;

      // User attempts to turn OFF
      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      // Invariant (P6-NOTIFY-13): Alarm remains cancelled and native consent remains revoked!
      expect(mockReminderPlatform.isScheduled, isFalse);
      expect(mockReminderPlatform.consentEnabled, isFalse);
      expect(mockReminderPlatform.simulateAlarmDelivery(), isFalse);

      // Switch is OFF in UI
      final Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isFalse);

      // Warning snackbar shown explaining save failure
      expect(find.textContaining('Failed to save reminder settings'), findsOneWidget);
    });

    testWidgets('33. P6-NOTIFY-12: Cold startup reconciliation does not grant consent when scheduleDailyReminder fails', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.consentEnabled = true; // Reminders were enabled with consent before crash/restart
      mockReminderPlatform.scheduleDailyReminderResult = false; // Native scheduling fails on cold start

      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 9,
        minute: 0,
        isPendingReconciliation: false,
        updatedAt: DateTime.now(),
      )));

      await tester.pumpWidget(HomesetsApp(
        repository: repository,
        photoService: mockPhotoService,
        backupStagingManager: stagingManager,
        reminderPlatformService: mockReminderPlatform,
      ));
      await pumpAsync(tester, 10);

      // Consent must NOT be granted fail-closed
      expect(mockReminderPlatform.consentEnabled, isFalse);

      // Saved state records disabled with pending reconciliation
      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isFalse);
      expect(saved?.isPendingReconciliation, isTrue);

      // Delivery invariant: cannot dispatch
      expect(mockReminderPlatform.simulateAlarmDelivery(), isFalse);
    });

    testWidgets('34. P6-NOTIFY-13 Fault-Injection: OFF + cancellation failure + restart cleans up orphan without auto-renewing consent', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.isScheduled = true;
      mockReminderPlatform.consentEnabled = true;

      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 8,
        minute: 0,
        updatedAt: DateTime.now(),
      )));

      // Native cancellation fails during Toggle OFF (Repro A)
      mockReminderPlatform.cancelDailyReminderResult = false;

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      // 1. Native consent was revoked fail-closed
      expect(mockReminderPlatform.consentEnabled, isFalse);
      expect(mockReminderPlatform.simulateAlarmDelivery(), isFalse);

      // 2. Switch truthfully remains ON because native cancellation was unconfirmed
      final Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);

      // 3. Warning snackbar shown and pending reconciliation persisted
      expect(find.textContaining('Failed to cancel scheduled reminder'), findsOneWidget);
      final savedAfterToggle = await tester.runAsync(() => repository.getReminderSettings());
      expect(savedAfterToggle?.isEnabled, isTrue);
      expect(savedAfterToggle?.isPendingReconciliation, isTrue);

      // 4. Cold app restart: cancel succeeds now on restart
      mockReminderPlatform.cancelDailyReminderResult = true;
      final cancelCallsBeforeRestart = mockReminderPlatform.cancelDailyReminderCallCount;

      await tester.pumpWidget(HomesetsApp(
        repository: repository,
        photoService: mockPhotoService,
        backupStagingManager: stagingManager,
        reminderPlatformService: mockReminderPlatform,
      ));
      await pumpAsync(tester, 10);

      // Startup fresh cancellation occurred
      expect(mockReminderPlatform.cancelDailyReminderCallCount, greaterThan(cancelCallsBeforeRestart));

      // INVARIANT: Native consent NEVER auto-renewed, alarm NOT scheduled
      expect(mockReminderPlatform.consentEnabled, isFalse);
      expect(mockReminderPlatform.simulateAlarmDelivery(), isFalse);
      final savedAfterRestart = await tester.runAsync(() => repository.getReminderSettings());
      expect(savedAfterRestart?.isEnabled, isFalse);
      expect(savedAfterRestart?.isPendingReconciliation, isFalse);
    });

    testWidgets('35. P6-NOTIFY-13 Fault-Injection: OFF + SQLite failure + restart guards against auto-grant and preserves explicit opt-out', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.isScheduled = true;
      mockReminderPlatform.consentEnabled = true;

      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: true,
        hour: 18,
        minute: 30,
        updatedAt: DateTime.now(),
      )));

      // All SQLite saves fail during Toggle OFF (Repro B)
      repository.failSaveReminderSettings = true;

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      // Native consent was revoked and alarm was cancelled!
      expect(mockReminderPlatform.consentEnabled, isFalse);
      expect(mockReminderPlatform.isScheduled, isFalse);
      expect(mockReminderPlatform.simulateAlarmDelivery(), isFalse);

      // Switch is OFF
      final Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isFalse);

      // In SQLite, the write failed, so on-disk SQLite still has isEnabled: true
      repository.failSaveReminderSettings = false; // DB available again
      final onDiskBeforeRestart = await tester.runAsync(() => repository.getReminderSettings());
      expect(onDiskBeforeRestart?.isEnabled, isTrue);

      // Now cold start / restart
      await tester.pumpWidget(HomesetsApp(
        repository: repository,
        photoService: mockPhotoService,
        backupStagingManager: stagingManager,
        reminderPlatformService: mockReminderPlatform,
      ));
      await pumpAsync(tester, 10);

      // INVARIANT: Cold start inspects native consent (false), NEVER auto-grants consent or reschedules!
      expect(mockReminderPlatform.consentEnabled, isFalse);
      expect(mockReminderPlatform.isScheduled, isFalse);
      expect(mockReminderPlatform.simulateAlarmDelivery(), isFalse);

      // Startup reconciled on-disk SQLite to isEnabled: false to match the explicit opt-out
      final onDiskAfterRestart = await tester.runAsync(() => repository.getReminderSettings());
      expect(onDiskAfterRestart?.isEnabled, isFalse);
    });

    testWidgets('36. P6-NOTIFY-13 Fault-Injection: OS permission regrant without fresh in-app opt-in never activates reminders', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = false;
      mockReminderPlatform.isScheduled = false;
      mockReminderPlatform.consentEnabled = false;

      // Seed disabled settings
      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: false,
        hour: 10,
        minute: 0,
        isPendingReconciliation: false,
        updatedAt: DateTime.now(),
      )));

      // User regrants notification permission in Android OS Settings while app is closed
      mockReminderPlatform.notificationsEnabled = true;

      // Cold start
      await tester.pumpWidget(HomesetsApp(
        repository: repository,
        photoService: mockPhotoService,
        backupStagingManager: stagingManager,
        reminderPlatformService: mockReminderPlatform,
      ));
      await pumpAsync(tester, 10);

      // INVARIANT: Reminders remain OFF, consent remains false, delivery suppressed
      expect(mockReminderPlatform.isScheduled, isFalse);
      expect(mockReminderPlatform.consentEnabled, isFalse);
      expect(mockReminderPlatform.simulateAlarmDelivery(), isFalse);
      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isFalse);
    });

    testWidgets('37. P6-NOTIFY-13 Fault-Injection: Fresh explicit ON after recovery schedules alarm and grants consent with valid user action', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = true;
      mockReminderPlatform.isScheduled = false;
      mockReminderPlatform.consentEnabled = false;

      // App recovered from previous failure into clean OFF state
      await tester.runAsync(() => repository.saveReminderSettings(ReminderSettings(
        isEnabled: false,
        hour: 7,
        minute: 30,
        isPendingReconciliation: false,
        updatedAt: DateTime.now(),
      )));

      await tester.pumpWidget(createSettingsScreenWidget());
      await pumpAsync(tester);

      final switchFinder = find.byType(Switch);
      Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isFalse);

      // User explicitly taps Switch to turn reminders ON
      await tester.tap(switchFinder);
      await pumpAsync(tester);

      // INVARIANT: Explicit user action successfully schedules alarm, persists to SQLite, and grants native consent
      expect(mockReminderPlatform.isScheduled, isTrue);
      expect(mockReminderPlatform.consentEnabled, isTrue);
      expect(mockReminderPlatform.simulateAlarmDelivery(), isTrue);

      switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);

      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isTrue);
      expect(saved?.isPendingReconciliation, isFalse);
    });
  });
}
