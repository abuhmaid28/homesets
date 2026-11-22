import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:homesets/data/database/database_helper.dart';
import 'package:homesets/data/repositories/workout_repository.dart';
import 'package:homesets/data/services/backup_archive_service.dart';
import 'package:homesets/data/services/backup_hash_provider.dart';
import 'package:homesets/data/services/backup_staging_manager.dart';
import 'package:homesets/data/services/zip_codec.dart';
import 'package:homesets/domain/backup/backup_models.dart';
import 'package:homesets/domain/models/domain_models.dart';

Uint8List createValidJpegBytes([int size = 128]) {
  final bytes = Uint8List(size < 16 ? 16 : size);
  bytes[0] = 0xFF;
  bytes[1] = 0xD8;
  bytes[2] = 0xFF;
  bytes[3] = 0xE0;
  for (var i = 4; i < bytes.length - 2; i++) {
    bytes[i] = (i % 250) + 1;
  }
  bytes[bytes.length - 2] = 0xFF;
  bytes[bytes.length - 1] = 0xD9;
  return bytes;
}

Uint8List createTruncatedJpegBytes([int size = 128]) {
  final bytes = Uint8List(size < 16 ? 16 : size);
  bytes[0] = 0xFF;
  bytes[1] = 0xD8;
  bytes[2] = 0xFF;
  bytes[3] = 0xE0;
  for (var i = 4; i < bytes.length; i++) {
    bytes[i] = 0xAA;
  }
  // Deliberately omit JPEG EOI 0xFF, 0xD9
  bytes[bytes.length - 2] = 0x00;
  bytes[bytes.length - 1] = 0x00;
  return bytes;
}

void main() {
  late Directory tempDir;
  late WorkoutRepository repository;
  late BackupStagingManager stagingManager;
  late BackupArchiveService archiveService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setCustomFactory(databaseFactoryFfi);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('homesets_p6_exit03_');
    repository = WorkoutRepository();
    stagingManager = BackupStagingManager(appDocsDir: tempDir);
    archiveService = const BackupArchiveService();

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

  group('P6-EXIT-03: Canonical Relative Path & Image Completeness Hardening', () {
    test('Scenario A: Traversal path in DB pointing to rollback dir MUST NOT pass active photo validation', () async {
      final db = await DatabaseHelper.instance.database;
      const restoreToken = 'token_test_a';
      await db.insert('app_metadata', {'key': 'restore_token', 'value': restoreToken});

      // Rollback directory exists with old photo
      await stagingManager.photosBackupDir.create(recursive: true);
      final rollbackPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await rollbackPhoto.writeAsBytes(createValidJpegBytes());

      // SQLite progress_photos entry has traversal path pointing into rollback dir
      await db.insert('progress_photos', {
        'id': 'photo_traversal_a',
        'file_path': 'progress_photos/../progress_photos_rollback/old.jpg',
        'angle': 'FRONT',
        'taken_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Journal claims DB_COMMITTED
      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': restoreToken,
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // Active photosDir is empty
      await stagingManager.photosDir.create(recursive: true);
      expect(stagingManager.photosDir.listSync().isEmpty, isTrue);

      // Startup recovery
      // Active photosDir exists on disk (but does NOT contain outsideFile)
      await stagingManager.photosDir.create(recursive: true);

      final result = await stagingManager.recoverPendingJournal(repository: repository);

      // Must fail closed because traversal path into rollback cannot validate active photos!
      expect(result.isFailure, isTrue,
          reason: 'Active validation must fail when DB path traverses into rollback directory');
      // Rollback photos and journal MUST NOT be deleted!
      expect(await stagingManager.photosBackupDir.exists(), isTrue,
          reason: 'Rollback photos must be preserved');
      expect(await rollbackPhoto.exists(), isTrue);
      expect(await stagingManager.journalFile.exists(), isTrue,
          reason: 'Journal file must be preserved');
    });

    test('Scenario B: DB record with absolute outside path MUST NOT satisfy active validation', () async {
      final db = await DatabaseHelper.instance.database;
      const restoreToken = 'token_test_b';
      await db.insert('app_metadata', {'key': 'restore_token', 'value': restoreToken});

      // External file outside sandbox exists with valid JPEG bytes
      final outsideFile = File('${tempDir.path}/outside_external.jpg');
      await outsideFile.writeAsBytes(createValidJpegBytes());

      // Rollback directory exists with old photo
      await stagingManager.photosBackupDir.create(recursive: true);
      final rollbackPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await rollbackPhoto.writeAsBytes(createValidJpegBytes());

      // SQLite progress_photos entry has absolute path
      await db.insert('progress_photos', {
        'id': 'photo_abs_b',
        'file_path': outsideFile.path,
        'angle': 'FRONT',
        'taken_at': DateTime.now().toUtc().toIso8601String(),
      });

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': restoreToken,
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // Active photosDir exists on disk (but does NOT contain outsideFile)
      await stagingManager.photosDir.create(recursive: true);

      final result = await stagingManager.recoverPendingJournal(repository: repository);

      expect(result.isFailure, isTrue,
          reason: 'Absolute external path must be rejected by active photo validator');
      expect(await stagingManager.photosBackupDir.exists(), isTrue);
      expect(await rollbackPhoto.exists(), isTrue);
      expect(await stagingManager.journalFile.exists(), isTrue);
    });

    test('Scenario C: Malformed backup snapshot with relative traversal rejected before restore', () async {
      final archiveDir = Directory('${tempDir.path}/archive_fixtures');
      await archiveDir.create(recursive: true);
      final badArchive = File('${archiveDir.path}/bad_traversal.homesets');

      // Create snapshot with traversal path in progressPhotos
      const badSnapshot = HomesetsDataSnapshot(
        progressPhotos: [
          {
            'id': 'photo_evil',
            'file_path': 'progress_photos/../progress_photos_rollback/evil.jpg',
            'angle': 'FRONT',
            'taken_at': '2026-11-22T12:00:00.000Z',
          }
        ],
      );

      final photoFile = File('${stagingManager.photosDir.path}/evil.jpg');
      await stagingManager.photosDir.create(recursive: true);
      await photoFile.writeAsBytes(createValidJpegBytes());

      // Create archive manually or via service
      // Let's create an archive that packages this badSnapshot
      final manifest = BackupManifest(
        formatVersion: 1,
        appVersion: '1.0.0+1',
        databaseSchemaVersion: 2,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        devicePlatform: 'android',
        dataSnapshotChecksum: const DefaultBackupHashProvider().computeChecksum(utf8.encode(jsonEncode(badSnapshot.toJson()))),
        checksumAlgorithm: BackupManifest.supportedChecksumAlgorithm,
        recordCounts: badSnapshot.computeRecordCounts(),
        files: [
          BackupFileEntry(
            relativePath: 'progress_photos/evil.jpg',
            byteLength: await photoFile.length(),
            checksum: await const DefaultBackupHashProvider().computeFileChecksum(photoFile),
          )
        ],
        totalFilesCount: 1,
        totalUncompressedBytes: (await photoFile.length()) + 200,
      );

      final tempPkg = Directory('${tempDir.path}/temp_bad_pkg');
      await tempPkg.create(recursive: true);
      final mfFile = File('${tempPkg.path}/manifest.json');
      await mfFile.writeAsString(manifest.serialize());
      final dataFile = File('${tempPkg.path}/data.json');
      await dataFile.writeAsString(jsonEncode(badSnapshot.toJson()));

      await ZipCodec.createArchiveFileStream(
        outputFile: badArchive,
        files: [
          ZipFileInput(path: 'manifest.json', file: mfFile),
          ZipFileInput(path: 'data.json', file: dataFile),
          ZipFileInput(path: 'progress_photos/evil.jpg', file: photoFile),
        ],
        maxArchiveBytes: 250 * 1024 * 1024,
      );

      final importStaging = await stagingManager.prepareImportStaging();
      final validation = await archiveService.validateAndExtractArchive(
        archiveFile: badArchive,
        stagingDir: importStaging,
      );

      expect(validation.isValid, isFalse,
          reason: 'Snapshot with traversal photo path must be rejected before restore');
      expect(validation.error, contains('Non-canonical or unsafe photo path'));
    });

    test('Scenario D1: Nonempty plain text bytes cannot be labeled as verified image', () async {
      final db = await DatabaseHelper.instance.database;
      const restoreToken = 'token_test_d1';
      await db.insert('app_metadata', {'key': 'restore_token', 'value': restoreToken});

      await stagingManager.photosBackupDir.create(recursive: true);
      final rollbackPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await rollbackPhoto.writeAsBytes(createValidJpegBytes());

      // SQLite has valid canonical path
      await db.insert('progress_photos', {
        'id': 'photo_d1',
        'file_path': 'progress_photos/photo_d1.jpg',
        'angle': 'FRONT',
        'taken_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Active file exists but contains PLAIN TEXT, not a valid image
      await stagingManager.photosDir.create(recursive: true);
      final activeFile = File('${stagingManager.photosDir.path}/photo_d1.jpg');
      await activeFile.writeAsString('VALID_NON_EMPTY_PHOTO_BYTES_BUT_PLAIN_TEXT');

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': restoreToken,
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // Active photosDir exists on disk (but does NOT contain outsideFile)
      await stagingManager.photosDir.create(recursive: true);

      final result = await stagingManager.recoverPendingJournal(repository: repository);

      expect(result.isFailure, isTrue,
          reason: 'Arbitrary plain text bytes must not pass active image completeness verification');
      expect(await stagingManager.photosBackupDir.exists(), isTrue);
      expect(await rollbackPhoto.exists(), isTrue);
      expect(await stagingManager.journalFile.exists(), isTrue);
    });

    test('Scenario D2: Nonempty truncated JPEG missing EOI marker fails completeness verification', () async {
      final db = await DatabaseHelper.instance.database;
      const restoreToken = 'token_test_d2';
      await db.insert('app_metadata', {'key': 'restore_token', 'value': restoreToken});

      await stagingManager.photosBackupDir.create(recursive: true);
      final rollbackPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await rollbackPhoto.writeAsBytes(createValidJpegBytes());

      await db.insert('progress_photos', {
        'id': 'photo_d2',
        'file_path': 'progress_photos/photo_d2.jpg',
        'angle': 'FRONT',
        'taken_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Active file is a truncated JPEG missing EOI [0xFF, 0xD9]
      await stagingManager.photosDir.create(recursive: true);
      final activeFile = File('${stagingManager.photosDir.path}/photo_d2.jpg');
      await activeFile.writeAsBytes(createTruncatedJpegBytes());

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': restoreToken,
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // Active photosDir exists on disk (but does NOT contain outsideFile)
      await stagingManager.photosDir.create(recursive: true);

      final result = await stagingManager.recoverPendingJournal(repository: repository);

      expect(result.isFailure, isTrue,
          reason: 'Truncated JPEG missing EOI marker must fail completeness check');
      expect(await stagingManager.photosBackupDir.exists(), isTrue);
      expect(await rollbackPhoto.exists(), isTrue);
      expect(await stagingManager.journalFile.exists(), isTrue);
    });

    test('Scenario E: Canonical valid JPEG photos roundtrip and cleanly finalize', () async {
      final db = await DatabaseHelper.instance.database;
      const restoreToken = 'token_test_e';
      await db.insert('app_metadata', {'key': 'restore_token', 'value': restoreToken});

      await stagingManager.photosBackupDir.create(recursive: true);
      final rollbackPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await rollbackPhoto.writeAsBytes(createValidJpegBytes());

      await db.insert('progress_photos', {
        'id': 'photo_e',
        'file_path': 'progress_photos/photo_e.jpg',
        'angle': 'FRONT',
        'taken_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Active photo is a complete valid JPEG
      await stagingManager.photosDir.create(recursive: true);
      final activeFile = File('${stagingManager.photosDir.path}/photo_e.jpg');
      await activeFile.writeAsBytes(createValidJpegBytes(256));

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': restoreToken,
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // Active photosDir exists on disk (but does NOT contain outsideFile)
      await stagingManager.photosDir.create(recursive: true);

      final result = await stagingManager.recoverPendingJournal(repository: repository);

      expect(result.isSuccess, isTrue);
      expect(result.action, equals('finalized'));
      // Rollback dir and journal should now be cleaned up
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
      // Active photo remains intact
      expect(await activeFile.exists(), isTrue);
      expect(await activeFile.length(), equals(256));
    });

    test('Scenario F: Recovery retry succeeds after corrupted photo is repaired', () async {
      final db = await DatabaseHelper.instance.database;
      const restoreToken = 'token_test_f';
      await db.insert('app_metadata', {'key': 'restore_token', 'value': restoreToken});

      await stagingManager.photosBackupDir.create(recursive: true);
      final rollbackPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await rollbackPhoto.writeAsBytes(createValidJpegBytes());

      await db.insert('progress_photos', {
        'id': 'photo_f',
        'file_path': 'progress_photos/photo_f.jpg',
        'angle': 'FRONT',
        'taken_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Initially truncated
      await stagingManager.photosDir.create(recursive: true);
      final activeFile = File('${stagingManager.photosDir.path}/photo_f.jpg');
      await activeFile.writeAsBytes(createTruncatedJpegBytes());

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': restoreToken,
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // Run 1: Fails
      final result1 = await stagingManager.recoverPendingJournal(repository: repository);
      expect(result1.isFailure, isTrue);
      expect(await stagingManager.photosBackupDir.exists(), isTrue);
      expect(await stagingManager.journalFile.exists(), isTrue);

      // Fix the photo by writing complete JPEG
      await activeFile.writeAsBytes(createValidJpegBytes(512));

      // Run 2: Retrying recovery now succeeds
      final result2 = await stagingManager.recoverPendingJournal(repository: repository);
      expect(result2.isSuccess, isTrue);
      expect(result2.action, equals('finalized'));
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
      expect(await activeFile.exists(), isTrue);
    });

    test('Scenario G: WorkoutRepository.restoreDataSnapshot rejects non-canonical photo path', () async {
      const badSnapshot = HomesetsDataSnapshot(
        progressPhotos: [
          {
            'id': 'bad_photo_g',
            'file_path': 'progress_photos/../../etc/passwd',
            'angle': 'FRONT',
            'taken_at': '2026-11-22T10:00:00.000Z',
          }
        ],
      );

      await expectLater(
        () => repository.restoreDataSnapshot(badSnapshot),
        throwsA(isA<BackupSecurityException>()),
      );
    });

    test('Scenario H: WorkoutRepository.saveProgressPhoto rejects non-canonical photo path', () async {
      final badPhoto = ProgressPhoto(
        id: 'bad_photo_h',
        filePath: '/data/user/0/com.abuhmaid.homesets/files/outside.jpg',
        angle: PhotoAngle.front,
        takenAt: DateTime.now().toUtc(),
      );

      await expectLater(
        () => repository.saveProgressPhoto(badPhoto),
        throwsArgumentError,
      );
    });

    test('Scenario I: Valid P5 photo records preserved and queryable without destructive migration', () async {
      final validPhoto = ProgressPhoto(
        id: 'p5_valid_01',
        filePath: 'progress_photos/p5_valid_01.jpg',
        angle: PhotoAngle.front,
        takenAt: DateTime.parse('2026-11-22T08:00:00Z'),
        notes: 'P5 baseline verification',
      );

      await repository.saveProgressPhoto(validPhoto);

      final photos = await repository.getProgressPhotos();
      expect(photos.length, equals(1));
      expect(photos.first.id, equals('p5_valid_01'));
      expect(photos.first.filePath, equals('progress_photos/p5_valid_01.jpg'));
      expect(photos.first.notes, equals('P5 baseline verification'));

      final snapshot = await repository.createDataSnapshot();
      expect(snapshot.progressPhotos.length, equals(1));
      expect(snapshot.progressPhotos.first['file_path'], equals('progress_photos/p5_valid_01.jpg'));
    });
  });
}
