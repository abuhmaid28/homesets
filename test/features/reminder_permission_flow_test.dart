import 'dart:io';
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
import 'package:homesets/data/services/photo_service.dart';
import 'package:homesets/data/services/reminder_platform_service.dart';
import 'package:homesets/domain/models/domain_models.dart';
import 'package:homesets/domain/models/reminder_settings.dart';
import 'package:homesets/features/settings/settings_screen.dart';
import 'package:homesets/l10n/app_localizations.dart';
import 'package:homesets/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late WorkoutRepository repository;
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
    repository = WorkoutRepository();
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

    testWidgets('10. App startup reconciles isEnabled to false if permission was revoked while closed', (tester) async {
      setupPhoneViewport(tester);
      mockReminderPlatform.notificationsEnabled = false; // Revoked while closed

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

      expect(mockReminderPlatform.isScheduled, isFalse);

      final saved = await tester.runAsync(() => repository.getReminderSettings());
      expect(saved?.isEnabled, isFalse);
    });

    testWidgets('11. App resume reconciles revoked notification permission and updates UI', (tester) async {
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
  });
}
