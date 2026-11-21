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
    tempDir = await Directory.systemTemp.createTemp('homesets_responsive_test_');
    repository = WorkoutRepository();
    mockBackupPlatform = MockBackupPlatformService();
    mockReminderPlatform = MockReminderPlatformService();
    archiveService = const BackupArchiveService(hashProvider: DefaultBackupHashProvider());
    stagingManager = BackupStagingManager(appDocsDir: tempDir);

    final db = await DatabaseHelper.instance.database;
    await db.delete('set_logs');
    await db.delete('workout_sessions');
    await db.delete('user_profile');
    await db.delete('reminder_settings');

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

  Widget createTestApp({
    required Size physicalSize,
    required double textScaleFactor,
    required Locale locale,
    Widget? customHome,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: physicalSize,
        textScaler: TextScaler.linear(textScaleFactor),
      ),
      child: MaterialApp(
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
        home: customHome ??
            SettingsScreen(
              repository: repository,
              backupPlatformService: mockBackupPlatform,
              backupArchiveService: archiveService,
              backupStagingManager: stagingManager,
              reminderPlatformService: mockReminderPlatform,
              onEditProfile: () {},
              onBack: () {},
              onDataRestored: () {},
            ),
      ),
    );
  }

  group('Responsive Layouts & Accessibility (WP19)', () {
    final viewports = [
      const Size(360, 780), // Small form factor
      const Size(390, 844), // iPhone / Standard Android
      const Size(412, 915), // Pixel / Honor Large
    ];

    for (final size in viewports) {
      testWidgets('Settings screen renders without overflow at ${size.width}x${size.height} (1.0x and 1.5x font)',
          (tester) async {
        for (final textScale in [1.0, 1.5]) {
          for (final locale in [const Locale('en'), const Locale('ar')]) {
            tester.view.physicalSize = Size(size.width * 2, size.height * 2);
            tester.view.devicePixelRatio = 2.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            await tester.pumpWidget(createTestApp(
              physicalSize: size,
              textScaleFactor: textScale,
              locale: locale,
            ));
            await pumpAsync(tester);

            // Assert no RenderFlex overflow errors
            expect(tester.takeException(), isNull);
          }
        }
      });
    }

    testWidgets('RestorePreviewDialog renders without overflow at 360dp with 1.5x font scale', (tester) async {
      tester.view.physicalSize = const Size(720, 1560);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final validation = BackupValidationResult(
        isValid: true,
        manifest: BackupManifest(
          formatVersion: 1,
          appVersion: '1.0.0+1',
          databaseSchemaVersion: 2,
          createdAt: DateTime.now().toUtc().toIso8601String(),
          devicePlatform: 'android',
          dataSnapshotChecksum: 'abc',
          recordCounts: const {},
          files: const [],
          totalFilesCount: 0,
          totalUncompressedBytes: 100,
        ),
        snapshot: const HomesetsDataSnapshot(
          workoutSessions: [{}],
          setLogs: [{}, {}],
          weightEntries: [{}],
          progressPhotos: [{}],
        ),
        warnings: const ['Sample non-fatal warning for test'],
      );

      for (final locale in [const Locale('en'), const Locale('ar')]) {
        await tester.pumpWidget(createTestApp(
          physicalSize: const Size(360, 780),
          textScaleFactor: 1.5,
          locale: locale,
          customHome: Scaffold(
            body: RestorePreviewDialog(
              validationResult: validation,
              onConfirm: () {},
              onCancel: () {},
            ),
          ),
        ));
        await pumpAsync(tester);

        expect(tester.takeException(), isNull);
        expect(find.byType(RestorePreviewDialog), findsOneWidget);
      }
    });
  });
}
