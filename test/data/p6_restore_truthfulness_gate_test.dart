import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesets/data/database/database_helper.dart';
import 'package:homesets/data/repositories/workout_repository.dart';
import 'package:homesets/data/services/backup_archive_service.dart';
import 'package:homesets/data/services/backup_hash_provider.dart';
import 'package:homesets/data/services/backup_platform_service.dart';
import 'package:homesets/data/services/backup_staging_manager.dart';
import 'package:homesets/data/services/photo_service.dart';
import 'package:homesets/data/services/reminder_platform_service.dart';
import 'package:homesets/domain/backup/backup_models.dart';
import 'package:homesets/features/settings/settings_screen.dart';
import 'package:homesets/features/settings/widgets/restore_preview_dialog.dart';
import 'package:homesets/l10n/app_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Minimal 150-byte valid JFIF JPEG fixture that decodes to a 1x1 image in Flutter's engine.
final Uint8List genuine1x1JpegBytes = Uint8List.fromList([
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00,
  0xFF, 0xDB, 0x00, 0x43, 0x00, 0x03, 0x02, 0x02, 0x03, 0x02, 0x02, 0x03, 0x03, 0x03, 0x03, 0x04, 0x03, 0x03, 0x04, 0x05,
  0x08, 0x05, 0x05, 0x04, 0x04, 0x05, 0x0A, 0x07, 0x07, 0x06, 0x08, 0x0C, 0x0A, 0x0C, 0x0C, 0x0B, 0x0A, 0x0B, 0x0B, 0x0D,
  0x0E, 0x12, 0x10, 0x0D, 0x0E, 0x11, 0x0E, 0x0B, 0x0B, 0x10, 0x16, 0x10, 0x11, 0x13, 0x14, 0x15, 0x15, 0x15, 0x0C, 0x0F,
  0x17, 0x18, 0x16, 0x14, 0x18, 0x12, 0x14, 0x15, 0x14, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01,
  0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00, 0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0xFF, 0xDA, 0x00, 0x08, 0x01,
  0x01, 0x00, 0x00, 0x3F, 0x00, 0xD2, 0xCF, 0x20, 0xFF, 0xD9,
]);

/// Corrupted JPEG: Valid header but truncated before EOI.
final Uint8List truncatedJpegBytes = Uint8List.fromList([
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x01, 0x00, 0x48,
  0x00, 0x48, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
]);

void main() {
  late Directory tempDir;
  late WorkoutRepository repository;
  late BackupStagingManager stagingManager;
  late BackupArchiveService archiveService;
  late MockBackupPlatformService mockBackupPlatform;
  late MockReminderPlatformService mockReminderPlatform;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setCustomFactory(databaseFactoryFfi);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('homesets_p6_gate_');
    repository = WorkoutRepository();
    stagingManager = BackupStagingManager(appDocsDir: tempDir);
    archiveService = const BackupArchiveService(hashProvider: DefaultBackupHashProvider());
    mockBackupPlatform = MockBackupPlatformService();
    mockReminderPlatform = MockReminderPlatformService();

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
    await db.delete('app_metadata');
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  Widget createSettingsTestApp({
    BackupStagingManager? customStagingManager,
    VoidCallback? onDataRestored,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
      ],
      home: SettingsScreen(
        repository: repository,
        backupPlatformService: mockBackupPlatform,
        backupArchiveService: archiveService,
        backupStagingManager: customStagingManager ?? stagingManager,
        reminderPlatformService: mockReminderPlatform,
        onEditProfile: () {},
        onBack: () {},
        onDataRestored: onDataRestored ?? () {},
      ),
    );
  }

  Future<void> pumpAsync(WidgetTester tester, [int count = 6]) async {
    for (var i = 0; i < count; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('P6 Restore Truthfulness & Image Integrity Final Gate', () {
    test('Scenario 1: Post-commit photo validation failure throws BackupRestoreException and preserves state', () async {
      // 1. Establish initial state with an existing photo
      final photosDir = stagingManager.photosDir;
      await photosDir.create(recursive: true);
      final originalPhoto = File('${photosDir.path}/original.jpg');
      await originalPhoto.writeAsBytes(genuine1x1JpegBytes);

      // 2. Prepare staged incoming photo (valid during staging)
      final stagedDir = await stagingManager.prepareImportStaging();
      final incomingPhoto = File('${stagedDir.path}/photo1.jpg');
      await incomingPhoto.writeAsBytes(genuine1x1JpegBytes);

      // 3. Construct snapshot declaring the photo record
      final snapshot = HomesetsDataSnapshot(
        progressPhotos: [
          {
            'id': 'photo1',
            'file_path': 'progress_photos/photo1.jpg',
            'angle': 'FRONT',
            'taken_at': '2026-11-22T10:00:00.000Z',
          }
        ],
      );

      // 4. Execute restore where onDbRestore successfully commits SQLite data,
      // but active photo is corrupted immediately post-commit.
      await expectLater(
        () => stagingManager.executeTwoPhaseRestore(
          snapshot: snapshot,
          stagedPhotos: [incomingPhoto],
          onDbRestore: (restoreToken) async {
            await repository.restoreDataSnapshot(snapshot, restoreToken: restoreToken);
            // Simulate corruption of active photo immediately after SQLite commit
            final activePhoto = File('${stagingManager.photosDir.path}/photo1.jpg');
            await activePhoto.writeAsBytes(truncatedJpegBytes);
          },
          repository: repository,
        ),
        throwsA(isA<BackupRestoreException>()),
      );

      // 5. Verify: SQLite data was committed (NOT rolled back independently)
      final photosInDb = await repository.getProgressPhotos();
      expect(photosInDb.length, equals(1));
      expect(photosInDb.first.id, equals('photo1'));

      // 6. Verify: Rollback photos directory is PRESERVED on disk
      expect(await stagingManager.photosBackupDir.exists(), isTrue);
      final rollbackOriginal = File('${stagingManager.photosBackupDir.path}/original.jpg');
      expect(await rollbackOriginal.exists(), isTrue);
      expect(await rollbackOriginal.readAsBytes(), equals(genuine1x1JpegBytes));

      // 7. Verify: Journal file is PRESERVED on disk with phase ACTIVE_PHOTOS_INVALID
      expect(await stagingManager.journalFile.exists(), isTrue);
      final journalContent = await stagingManager.journalFile.readAsString();
      final journalData = jsonDecode(journalContent) as Map<String, dynamic>;
      expect(journalData['phase'], equals('ACTIVE_PHOTOS_INVALID'));
    });

    testWidgets('Scenario 2: SettingsScreen displays error dialog and suppresses success on post-commit photo validation failure', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var onDataRestoredInvoked = false;

      // 1. Create a valid archive structure with a valid photo
      final failingStaging = _FailingPhotoValidationStagingManager(appDocsDir: tempDir);
      final archiveFile = File('${tempDir.path}/valid_photo_backup.homesets');
      final validPhoto = File('${tempDir.path}/p_valid.jpg');

      await tester.runAsync(() async {
        await validPhoto.writeAsBytes(genuine1x1JpegBytes);

        final snapshot = const HomesetsDataSnapshot(
          progressPhotos: [
            {
              'id': 'p_valid',
              'file_path': 'progress_photos/p_valid.jpg',
              'angle': 'FRONT',
              'taken_at': '2026-11-22T10:00:00.000Z',
            }
          ],
        );

        await archiveService.createBackupArchive(
          snapshot: snapshot,
          photoFiles: [validPhoto],
          outputFilePath: archiveFile.path,
        );
        expect(await archiveFile.exists(), isTrue);
      });

      mockBackupPlatform.importFilePath = archiveFile.path;

      // 2. Pump SettingsScreen with custom failing staging manager
      await tester.pumpWidget(createSettingsTestApp(
        customStagingManager: failingStaging,
        onDataRestored: () {
          onDataRestoredInvoked = true;
        },
      ));
      await pumpAsync(tester);

      // 3. Trigger restore flow
      final restoreBtn = find.text('Restore from Backup');
      await tester.ensureVisible(restoreBtn);
      await pumpAsync(tester, 2);
      await tester.tap(restoreBtn);

      // Wait for validation dialog
      for (var i = 0; i < 60; i++) {
        await pumpAsync(tester, 2);
        if (find.byType(RestorePreviewDialog).evaluate().isNotEmpty) break;
      }
      expect(find.byType(RestorePreviewDialog), findsOneWidget);

      // 4. Confirm Restore
      final confirmBtn = find.text('Replace Data & Restore');
      await tester.tap(confirmBtn);

      // Wait for restore attempt to complete
      for (var i = 0; i < 30; i++) {
        await pumpAsync(tester, 2);
        if (find.byType(AlertDialog).evaluate().isNotEmpty) break;
      }

      // 5. Verify Truthful Error Presentation:
      // Error dialog MUST be visible
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('active photo'), findsOneWidget);

      // Success snackbar MUST NOT be visible
      expect(find.text('Data and photos restored successfully.'), findsNothing);

      // onDataRestored MUST NOT have been called
      expect(onDataRestoredInvoked, isFalse);

      // Journal MUST be preserved on disk
      final journalExists = await tester.runAsync(() => failingStaging.journalFile.exists());
      expect(journalExists, isTrue);
    });

    test('Scenario 3: Post-commit cleanup failure throws BackupRestoreException instead of reporting success', () async {
      // 1. Prepare valid staged photo
      final stagedDir = await stagingManager.prepareImportStaging();
      final incomingPhoto = File('${stagedDir.path}/incoming_valid.jpg');
      await incomingPhoto.writeAsBytes(genuine1x1JpegBytes);

      final snapshot = HomesetsDataSnapshot(
        progressPhotos: [
          {
            'id': 'incoming_valid',
            'file_path': 'progress_photos/incoming_valid.jpg',
            'angle': 'FRONT',
            'taken_at': '2026-11-22T10:00:00.000Z',
          }
        ],
      );

      // 2. Create existing photo so hadOriginalPhotos is true and photosBackupDir is created
      final photosDir = stagingManager.photosDir;
      await photosDir.create(recursive: true);
      await File('${photosDir.path}/old.jpg').writeAsBytes(genuine1x1JpegBytes);

      // 3. Subclass or create staging manager where photosBackupDir deletion fails
      // We can make photosBackupDir a read-only or lock it, or use a custom StagingManager with throwing delete
      final failingStagingManager = _FailingCleanupStagingManager(appDocsDir: tempDir);

      await expectLater(
        () => failingStagingManager.executeTwoPhaseRestore(
          snapshot: snapshot,
          stagedPhotos: [incomingPhoto],
          onDbRestore: (restoreToken) async {
            await repository.restoreDataSnapshot(snapshot, restoreToken: restoreToken);
          },
          repository: repository,
        ),
        throwsA(isA<BackupRestoreException>()),
      );
    });

    test('Scenario 4: SQLite token check failure during error handling throws BackupRestoreException and preserves state', () async {
      final stagedDir = await stagingManager.prepareImportStaging();
      final incomingPhoto = File('${stagedDir.path}/photo.jpg');
      await incomingPhoto.writeAsBytes(genuine1x1JpegBytes);

      final photosDir = stagingManager.photosDir;
      await photosDir.create(recursive: true);
      await File('${photosDir.path}/old.jpg').writeAsBytes(genuine1x1JpegBytes);

      // Repository where getCurrentRestoreToken throws an unexpected disk/locking error
      final failingRepo = _FailingTokenRepository();

      await expectLater(
        () => stagingManager.executeTwoPhaseRestore(
          snapshot: const HomesetsDataSnapshot(),
          stagedPhotos: [incomingPhoto],
          onDbRestore: (restoreToken) async {
            throw const SocketException('Simulated network/disk crash during restore');
          },
          repository: failingRepo,
        ),
        throwsA(
          isA<BackupRestoreException>().having(
            (e) => e.message,
            'message',
            contains('SQLite token verification threw an error'),
          ),
        ),
      );

      // Both generations and journal must be preserved
      expect(await stagingManager.photosBackupDir.exists(), isTrue);
      expect(await stagingManager.journalFile.exists(), isTrue);
    });

    test('Scenario 5: Genuinely decodable 150-byte JPEG fixture decodes via instantiateImageCodec and preserves bit fidelity across archive roundtrip', () async {
      // 1. Verify that genuine1x1JpegBytes decodes cleanly into a real 1x1 bitmap
      final codec = await ui.instantiateImageCodec(genuine1x1JpegBytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, equals(1));
      expect(frame.image.height, equals(1));
      frame.image.dispose();

      // 2. Verify PhotoService.tryDecodeImage returns true
      final testPhoto = File('${tempDir.path}/photo_107.jpg');
      await testPhoto.writeAsBytes(genuine1x1JpegBytes);
      expect(await PhotoService.tryDecodeImage(testPhoto), isTrue);

      // 3. Verify that truncated JPEG fails full decode
      final badPhoto = File('${tempDir.path}/test_trunc.jpg');
      await badPhoto.writeAsBytes(truncatedJpegBytes);
      expect(await PhotoService.tryDecodeImage(badPhoto), isFalse);

      // 4. Archive round-trip: Export backup archive with genuine1x1JpegBytes
      final archiveFile = File('${tempDir.path}/export_1x1.homesets');
      final snapshot = HomesetsDataSnapshot(
        progressPhotos: [
          {
            'id': 'photo_107',
            'file_path': 'progress_photos/photo_107.jpg',
            'angle': 'FRONT',
            'taken_at': '2026-11-22T10:00:00.000Z',
          }
        ],
      );

      await archiveService.createBackupArchive(
        snapshot: snapshot,
        photoFiles: [testPhoto],
        outputFilePath: archiveFile.path,
      );

      // 5. Validate and extract archive
      final validation = await archiveService.validateAndExtractArchive(
        archiveFile: archiveFile,
        stagingDir: await stagingManager.prepareImportStaging(),
      );

      expect(validation.isValid, isTrue);
      expect(validation.photoFiles.length, equals(1));
      final extractedPhoto = validation.photoFiles.first;

      // Bit-for-bit equality check: restored file bytes must be EXACTLY identical to source bytes
      final restoredBytes = await extractedPhoto.readAsBytes();
      expect(restoredBytes, equals(genuine1x1JpegBytes));
      expect(restoredBytes.length, equals(genuine1x1JpegBytes.length));
      expect(restoredBytes.length, equals(150));

      // Restored photo must decode cleanly into a 1x1 image
      expect(await PhotoService.tryDecodeImage(extractedPhoto), isTrue);
    });

    test('Scenario 6: Fully valid restore succeeds, preserves bit fidelity, and cleans up journal', () async {
      // 1. Setup existing photo
      final photosDir = stagingManager.photosDir;
      await photosDir.create(recursive: true);
      await File('${photosDir.path}/old.jpg').writeAsBytes(genuine1x1JpegBytes);

      // 2. Prepare valid incoming photo
      final stagedDir = await stagingManager.prepareImportStaging();
      final incomingPhoto = File('${stagedDir.path}/photo_valid.jpg');
      await incomingPhoto.writeAsBytes(genuine1x1JpegBytes);

      final snapshot = HomesetsDataSnapshot(
        progressPhotos: [
          {
            'id': 'photo_valid',
            'file_path': 'progress_photos/photo_valid.jpg',
            'angle': 'FRONT',
            'taken_at': '2026-11-22T12:00:00.000Z',
          }
        ],
      );

      // 3. Execute two-phase restore
      await stagingManager.executeTwoPhaseRestore(
        snapshot: snapshot,
        stagedPhotos: [incomingPhoto],
        onDbRestore: (restoreToken) async {
          await repository.restoreDataSnapshot(snapshot, restoreToken: restoreToken);
        },
        repository: repository,
      );

      // 4. Verify SQLite data committed
      final photos = await repository.getProgressPhotos();
      expect(photos.length, equals(1));
      expect(photos.first.id, equals('photo_valid'));

      // 5. Verify active photo on disk exists, is bit-exact, and decodes cleanly
      final activePhoto = File('${photosDir.path}/photo_valid.jpg');
      expect(await activePhoto.exists(), isTrue);
      final activeBytes = await activePhoto.readAsBytes();
      expect(activeBytes, equals(genuine1x1JpegBytes));
      expect(await PhotoService.tryDecodeImage(activePhoto), isTrue);

      // 6. Verify journal and rollback directories are cleaned up
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });
  });
}

class _FailingPhotoValidationStagingManager extends BackupStagingManager {
  _FailingPhotoValidationStagingManager({required super.appDocsDir});

  @override
  Future<bool> validateActivePhotos(WorkoutRepository repository) async => false;
}

class _FailingCleanupStagingManager extends BackupStagingManager {
  _FailingCleanupStagingManager({required super.appDocsDir});

  @override
  Directory get photosBackupDir => _FailingDirectory(super.photosBackupDir.path);
}

class _FailingDirectory implements Directory {
  final Directory _inner;
  _FailingDirectory(String path) : _inner = Directory(path);

  @override
  Future<bool> exists() => _inner.exists();

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    throw const FileSystemException('Simulated permission denied deleting rollback directory');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => _inner.noSuchMethod(invocation);
}

class _FailingTokenRepository extends WorkoutRepository {
  @override
  Future<String?> getCurrentRestoreToken() async {
    throw const FileSystemException('Simulated SQLite disk read I/O error');
  }
}
