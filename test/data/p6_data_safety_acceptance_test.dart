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

void main() {
  late Directory tempDir;
  late WorkoutRepository repository;
  late BackupStagingManager stagingManager;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setCustomFactory(databaseFactoryFfi);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('homesets_safety_acceptance_');
    repository = WorkoutRepository();
    stagingManager = BackupStagingManager(appDocsDir: tempDir);

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

  // =========================================================================
  // WORKSTREAM A: REPRODUCE P6-EXIT-01 (PHOTO RECOVERY INTEGRITY DEFECT)
  // =========================================================================
  group('P6-EXIT-01: Photo Recovery Integrity Validation', () {
    test('Scenario 1: Matching restore token but missing active photo directory fails closed', () async {
      final db = await DatabaseHelper.instance.database;
      const restoreToken = 'token_exit_01_sc1';
      await db.insert('app_metadata', {'key': 'restore_token', 'value': restoreToken});

      // Add a committed photo record to SQLite
      await repository.saveProgressPhoto(ProgressPhoto(
        id: 'photo_sc1',
        filePath: 'progress_photos/photo_sc1.jpg',
        angle: PhotoAngle.front,
        takenAt: DateTime.now().toUtc(),
      ));

      // Rollback directory exists with original photo
      await stagingManager.photosBackupDir.create(recursive: true);
      final rollbackPhoto = File('${stagingManager.photosBackupDir.path}/old_photo.jpg');
      await rollbackPhoto.writeAsString('OLD_ORIGINAL_PHOTO_BYTES');

      // Journal claims DB_COMMITTED
      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': restoreToken,
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // Active photosDir DOES NOT EXIST
      expect(await stagingManager.photosDir.exists(), isFalse);

      // Execute startup recovery
      final result = await stagingManager.recoverPendingJournal(repository: repository);

      // Must fail closed because active photo directory is missing!
      expect(result.isFailure, isTrue,
          reason: 'Must fail closed when active photos directory is missing');
      // Original rollback photos and journal MUST NOT be deleted!
      expect(await stagingManager.photosBackupDir.exists(), isTrue,
          reason: 'Rollback photos must be preserved');
      expect(await rollbackPhoto.exists(), isTrue);
      expect(await stagingManager.journalFile.exists(), isTrue,
          reason: 'Recovery journal must be preserved for retry');
    });

    test('Scenario 2: Matching restore token with one missing referenced photo fails closed', () async {
      final db = await DatabaseHelper.instance.database;
      const restoreToken = 'token_exit_01_sc2';
      await db.insert('app_metadata', {'key': 'restore_token', 'value': restoreToken});

      // Add two committed photos in SQLite
      await repository.saveProgressPhoto(ProgressPhoto(
        id: 'photo_sc2_1',
        filePath: 'progress_photos/photo_sc2_1.jpg',
        angle: PhotoAngle.front,
        takenAt: DateTime.now().toUtc(),
      ));
      await repository.saveProgressPhoto(ProgressPhoto(
        id: 'photo_sc2_2',
        filePath: 'progress_photos/photo_sc2_2.jpg',
        angle: PhotoAngle.side,
        takenAt: DateTime.now().toUtc(),
      ));

      // Rollback dir exists with old photo
      await stagingManager.photosBackupDir.create(recursive: true);
      final rollbackPhoto = File('${stagingManager.photosBackupDir.path}/old_photo.jpg');
      await rollbackPhoto.writeAsString('OLD_ORIGINAL_PHOTO_BYTES');

      // Active photosDir exists but ONLY contains photo 1 (photo 2 is missing!)
      await stagingManager.photosDir.create(recursive: true);
      final activePhoto1 = File('${stagingManager.photosDir.path}/photo_sc2_1.jpg');
      await activePhoto1.writeAsString('NEW_PHOTO_1_BYTES');

      // Journal claims DB_COMMITTED
      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': restoreToken,
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // Execute startup recovery
      final result = await stagingManager.recoverPendingJournal(repository: repository);

      // Must fail closed because photo 2 is missing on disk!
      expect(result.isFailure, isTrue,
          reason: 'Must fail closed when a committed photo is missing on disk');
      expect(await stagingManager.photosBackupDir.exists(), isTrue,
          reason: 'Rollback photos must NOT be deleted when active set is incomplete');
      expect(await stagingManager.journalFile.exists(), isTrue);
    });

    test('Scenario 3: Matching restore token with corrupted/incomplete (0-byte) photo fails closed', () async {
      final db = await DatabaseHelper.instance.database;
      const restoreToken = 'token_exit_01_sc3';
      await db.insert('app_metadata', {'key': 'restore_token', 'value': restoreToken});

      await repository.saveProgressPhoto(ProgressPhoto(
        id: 'photo_sc3',
        filePath: 'progress_photos/photo_sc3.jpg',
        angle: PhotoAngle.front,
        takenAt: DateTime.now().toUtc(),
      ));

      await stagingManager.photosBackupDir.create(recursive: true);
      final rollbackPhoto = File('${stagingManager.photosBackupDir.path}/old_photo.jpg');
      await rollbackPhoto.writeAsString('OLD_ORIGINAL_PHOTO_BYTES');

      // Active photo exists but has 0 bytes (corrupted/torn file)
      await stagingManager.photosDir.create(recursive: true);
      final activePhoto = File('${stagingManager.photosDir.path}/photo_sc3.jpg');
      await activePhoto.writeAsBytes([]); // 0 bytes!

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': restoreToken,
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      final result = await stagingManager.recoverPendingJournal(repository: repository);

      expect(result.isFailure, isTrue,
          reason: 'Must fail closed when active photo file is 0 bytes');
      expect(await stagingManager.photosBackupDir.exists(), isTrue);
      expect(await stagingManager.journalFile.exists(), isTrue);
    });

    test('Scenario 4: Matching restore token with all expected photos present finalizes cleanly', () async {
      final db = await DatabaseHelper.instance.database;
      const restoreToken = 'token_exit_01_sc4';
      await db.insert('app_metadata', {'key': 'restore_token', 'value': restoreToken});

      await repository.saveProgressPhoto(ProgressPhoto(
        id: 'photo_sc4',
        filePath: 'progress_photos/photo_sc4.jpg',
        angle: PhotoAngle.front,
        takenAt: DateTime.now().toUtc(),
      ));

      await stagingManager.photosBackupDir.create(recursive: true);
      final rollbackPhoto = File('${stagingManager.photosBackupDir.path}/old_photo.jpg');
      await rollbackPhoto.writeAsString('OLD_ORIGINAL_PHOTO_BYTES');

      // Active photo exists and has valid content
      await stagingManager.photosDir.create(recursive: true);
      final activePhoto = File('${stagingManager.photosDir.path}/photo_sc4.jpg');
      await activePhoto.writeAsBytes(Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03, 0x04,
        0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0xFF, 0xD9,
      ]));

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': restoreToken,
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      final result = await stagingManager.recoverPendingJournal(repository: repository);

      expect(result.isSuccess, isTrue);
      expect(result.action, equals('finalized'));
      // Now rollback directory and journal should be cleanly purged
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
      expect(await activePhoto.exists(), isTrue);
    });

    test('Scenario 5 & 6: Interrupted verification, restart, and recovery retry after fixing missing photo', () async {
      final db = await DatabaseHelper.instance.database;
      const restoreToken = 'token_exit_01_sc5_6';
      await db.insert('app_metadata', {'key': 'restore_token', 'value': restoreToken});

      await repository.saveProgressPhoto(ProgressPhoto(
        id: 'photo_retry',
        filePath: 'progress_photos/photo_retry.jpg',
        angle: PhotoAngle.front,
        takenAt: DateTime.now().toUtc(),
      ));

      await stagingManager.photosBackupDir.create(recursive: true);
      await File('${stagingManager.photosBackupDir.path}/old.jpg').writeAsString('OLD');

      await stagingManager.photosDir.create(recursive: true);
      // Photo is initially missing!

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': restoreToken,
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // First run: fails closed
      final firstAttempt = await stagingManager.recoverPendingJournal(repository: repository);
      expect(firstAttempt.isFailure, isTrue);
      expect(await stagingManager.photosBackupDir.exists(), isTrue);
      expect(await stagingManager.journalFile.exists(), isTrue);

      // Simulate restart with new stagingManager instance
      final restartedManager = BackupStagingManager(appDocsDir: tempDir);
      final secondAttempt = await restartedManager.recoverPendingJournal(repository: repository);
      expect(secondAttempt.isFailure, isTrue, reason: 'Restart still fails closed safely');
      expect(await stagingManager.photosBackupDir.exists(), isTrue);

      // Now fix the missing photo file
      final fixedPhoto = File('${restartedManager.photosDir.path}/photo_retry.jpg');
      await fixedPhoto.writeAsBytes(Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03, 0x04,
        0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0xFF, 0xD9,
      ]));

      // Third run: now photo is present, recovery succeeds and finalizes
      final thirdAttempt = await restartedManager.recoverPendingJournal(repository: repository);
      expect(thirdAttempt.isSuccess, isTrue);
      expect(thirdAttempt.action, equals('finalized'));
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });
  });

  // =========================================================================
  // WORKSTREAM B: REPRODUCE P6-EXIT-02 (ZIP METADATA MEMORY DEFECT)
  // =========================================================================
  group('P6-EXIT-02: ZIP Metadata Memory Safety', () {
    test('Rejects archive declaring oversized central directory metadata before allocation', () async {
      final archiveFile = File('${tempDir.path}/oversized_cd.zip');

      // Craft an archive where EOCD declares a 10MB central directory
      // but file is small (or even if file is large enough, 10MB exceeds the 2MB metadata budget)
      final dummyBytes = Uint8List(100);
      final eocd = ByteData(22);
      eocd.setUint32(0, 0x06054b50, Endian.little); // EOCD signature
      eocd.setUint16(4, 0, Endian.little);
      eocd.setUint16(6, 0, Endian.little);
      eocd.setUint16(8, 1, Endian.little);
      eocd.setUint16(10, 1, Endian.little); // 1 entry
      eocd.setUint32(12, 10 * 1024 * 1024, Endian.little); // 10MB central directory size!
      eocd.setUint32(16, 0, Endian.little); // cdOffset = 0
      eocd.setUint16(20, 0, Endian.little);

      final bb = BytesBuilder();
      bb.add(dummyBytes);
      bb.add(eocd.buffer.asUint8List());
      await archiveFile.writeAsBytes(bb.toBytes());

      final extractDir = Directory('${tempDir.path}/extract_oversized');

      expect(
        () async => await ZipCodec.extractArchiveFileStream(
          archiveFile: archiveFile,
          targetDir: extractDir,
        ),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('exceeds metadata budget'),
        )),
      );
    });

    test('Rejects archive declaring central directory size smaller than minimum entry headers', () async {
      final archiveFile = File('${tempDir.path}/undersized_cd.zip');

      // 10 entries declared, but cdSize = 20 bytes (less than 10 * 46 = 460 bytes)
      final eocd = ByteData(22);
      eocd.setUint32(0, 0x06054b50, Endian.little);
      eocd.setUint16(4, 0, Endian.little);
      eocd.setUint16(6, 0, Endian.little);
      eocd.setUint16(8, 10, Endian.little);
      eocd.setUint16(10, 10, Endian.little); // 10 entries
      eocd.setUint32(12, 20, Endian.little); // cdSize = 20 (impossible!)
      eocd.setUint32(16, 0, Endian.little);
      eocd.setUint16(20, 0, Endian.little);

      final bb = BytesBuilder();
      bb.add(Uint8List(50));
      bb.add(eocd.buffer.asUint8List());
      await archiveFile.writeAsBytes(bb.toBytes());

      final extractDir = Directory('${tempDir.path}/extract_undersized');

      expect(
        () async => await ZipCodec.extractArchiveFileStream(
          archiveFile: archiveFile,
          targetDir: extractDir,
        ),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('smaller than minimum'),
        )),
      );
    });

    test('Rejects archive with central directory offset extending beyond archive boundary', () async {
      final archiveFile = File('${tempDir.path}/offset_beyond_cd.zip');

      final eocd = ByteData(22);
      eocd.setUint32(0, 0x06054b50, Endian.little);
      eocd.setUint16(4, 0, Endian.little);
      eocd.setUint16(6, 0, Endian.little);
      eocd.setUint16(8, 1, Endian.little);
      eocd.setUint16(10, 1, Endian.little);
      eocd.setUint32(12, 50, Endian.little);
      eocd.setUint32(16, 1000, Endian.little); // cdOffset = 1000 (well past 100 bytes length!)
      eocd.setUint16(20, 0, Endian.little);

      final bb = BytesBuilder();
      bb.add(Uint8List(50));
      bb.add(eocd.buffer.asUint8List());
      await archiveFile.writeAsBytes(bb.toBytes());

      final extractDir = Directory('${tempDir.path}/extract_offset_beyond');

      expect(
        () async => await ZipCodec.extractArchiveFileStream(
          archiveFile: archiveFile,
          targetDir: extractDir,
        ),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('extends beyond archive boundary'),
        )),
      );
    });

    test('Rejects central directory entry with excessive entry name length', () async {
      final archiveFile = File('${tempDir.path}/long_name_cd.zip');

      // Craft 1 entry with name length 2000 bytes (> maxEntryNameBytes of 1024)
      final cdHeader = ByteData(46);
      cdHeader.setUint32(0, 0x02014b50, Endian.little);
      cdHeader.setUint16(10, 0, Endian.little); // STORE
      cdHeader.setUint32(16, 0, Endian.little); // crc
      cdHeader.setUint32(20, 0, Endian.little); // comp size
      cdHeader.setUint32(24, 0, Endian.little); // uncomp size
      cdHeader.setUint16(28, 2000, Endian.little); // nameLen = 2000!
      cdHeader.setUint16(30, 0, Endian.little);
      cdHeader.setUint16(32, 0, Endian.little);
      cdHeader.setUint32(42, 0, Endian.little);

      final cdBytes = BytesBuilder();
      cdBytes.add(cdHeader.buffer.asUint8List());
      cdBytes.add(Uint8List(2000)); // 2000 bytes of name
      final cdPayload = cdBytes.toBytes();

      final eocd = ByteData(22);
      eocd.setUint32(0, 0x06054b50, Endian.little);
      eocd.setUint16(4, 0, Endian.little);
      eocd.setUint16(6, 0, Endian.little);
      eocd.setUint16(8, 1, Endian.little);
      eocd.setUint16(10, 1, Endian.little);
      eocd.setUint32(12, cdPayload.length, Endian.little);
      eocd.setUint32(16, 0, Endian.little);
      eocd.setUint16(20, 0, Endian.little);

      final fullFile = BytesBuilder();
      fullFile.add(cdPayload);
      fullFile.add(eocd.buffer.asUint8List());
      await archiveFile.writeAsBytes(fullFile.toBytes());

      final extractDir = Directory('${tempDir.path}/extract_long_name');

      expect(
        () async => await ZipCodec.extractArchiveFileStream(
          archiveFile: archiveFile,
          targetDir: extractDir,
        ),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Entry name length (2000 bytes) exceeds limit'),
        )),
      );
    });

    test('Rejects central directory entry extending beyond declared cdSize boundary', () async {
      final archiveFile = File('${tempDir.path}/cd_boundary_overflow.zip');

      // cdSize says 50 bytes, but entry has 46 header + 10 name = 56 bytes (> 50)
      final cdHeader = ByteData(46);
      cdHeader.setUint32(0, 0x02014b50, Endian.little);
      cdHeader.setUint16(28, 10, Endian.little); // nameLen = 10 -> total record = 56

      final eocd = ByteData(22);
      eocd.setUint32(0, 0x06054b50, Endian.little);
      eocd.setUint16(8, 1, Endian.little);
      eocd.setUint16(10, 1, Endian.little);
      eocd.setUint32(12, 50, Endian.little); // declares only 50 bytes!
      eocd.setUint32(16, 0, Endian.little);

      final fullFile = BytesBuilder();
      fullFile.add(cdHeader.buffer.asUint8List());
      fullFile.add(utf8.encode('1234567890'));
      fullFile.add(eocd.buffer.asUint8List());
      await archiveFile.writeAsBytes(fullFile.toBytes());

      final extractDir = Directory('${tempDir.path}/extract_boundary_overflow');

      expect(
        () async => await ZipCodec.extractArchiveFileStream(
          archiveFile: archiveFile,
          targetDir: extractDir,
        ),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('extends beyond central directory'),
        )),
      );
    });

    test('Rejects central directory with unexpected trailing unparsed bytes', () async {
      final archiveFile = File('${tempDir.path}/cd_trailing_garbage.zip');

      // 1 entry of 46 header + 5 name = 51 bytes.
      // But cdSize declares 60 bytes (9 bytes of trailing garbage).
      final cdHeader = ByteData(46);
      cdHeader.setUint32(0, 0x02014b50, Endian.little);
      cdHeader.setUint16(28, 5, Endian.little);

      final eocd = ByteData(22);
      eocd.setUint32(0, 0x06054b50, Endian.little);
      eocd.setUint16(8, 1, Endian.little);
      eocd.setUint16(10, 1, Endian.little);
      eocd.setUint32(12, 60, Endian.little); // declares 60 bytes!
      eocd.setUint32(16, 0, Endian.little);

      final fullFile = BytesBuilder();
      fullFile.add(cdHeader.buffer.asUint8List());
      fullFile.add(utf8.encode('valid'));
      fullFile.add(Uint8List(9)); // 9 bytes trailing garbage
      fullFile.add(eocd.buffer.asUint8List());
      await archiveFile.writeAsBytes(fullFile.toBytes());

      final extractDir = Directory('${tempDir.path}/extract_trailing_garbage');

      expect(
        () async => await ZipCodec.extractArchiveFileStream(
          archiveFile: archiveFile,
          targetDir: extractDir,
        ),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('unexpected trailing bytes'),
        )),
      );
    });
  });

  // =========================================================================
  // WORKSTREAM C: FULL DATA INTEGRITY & WORKOUT SAFETY REGRESSION
  // =========================================================================
  group('Workstream C: Full P0-P5 Data Integrity & Safety Regression', () {
    test('Complete 10-table roundtrip with binary photos, cancellation, and corrupt archive safety', () async {
      const hashProvider = DefaultBackupHashProvider();
      final archiveService = const BackupArchiveService(hashProvider: hashProvider);

      // 1. Populate comprehensive synthetic dataset across all 10 SQLite production tables
      final originalSnapshot = HomesetsDataSnapshot(
        userProfile: {
          'id': 'user_full_acceptance',
          'goal': 'STRENGTH',
          'wake_time_minutes': 420,
          'shift_start_minutes': 1020,
          'target_workouts_per_week': 4,
          'avoided_joints': 'SHOULDER',
          'created_at': '2026-11-22T06:00:00.000Z',
        },
        equipmentInventory: {
          'id': 'inv_safety_acceptance',
          'has_pull_up_bar': 1,
          'has_bands': 1,
          'has_door_anchor': 0,
          'has_sturdy_table': 1,
          'has_parallel_grip': 1,
          'updated_at': '2026-11-22T06:00:00.000Z',
        },
        workoutSessions: [
          {
            'id': 'sess_safety_01',
            'scheduled_session_id': 'sched_1',
            'routine_name': 'Upper Push Strength Focus',
            'is_lite_mode': 0,
            'started_at': '2026-11-22T08:00:00.000Z',
            'ended_at': '2026-11-22T08:45:00.000Z',
            'total_duration_seconds': 2700,
            'is_emergency_stopped': 0,
            'emergency_stop_reason': null,
          },
        ],
        setLogs: [
          {
            'id': 'set_safety_01',
            'session_id': 'sess_safety_01',
            'set_index': 0,
            'exercise_id': 'pushup_standard',
            'performed_reps': 15,
            'band_used': 'bodyweight',
            'exertion': 'MEDIUM',
            'is_pain_stopped': 0,
            'pain_note': null,
            'completed_at': '2026-11-22T08:10:00.000Z',
          },
          {
            'id': 'set_safety_02',
            'session_id': 'sess_safety_01',
            'set_index': 1,
            'exercise_id': 'banded_overhead_press',
            'performed_reps': 10,
            'band_used': 'heavy_black_band',
            'exertion': 'HARD',
            'is_pain_stopped': 0,
            'pain_note': null,
            'completed_at': '2026-11-22T08:25:00.000Z',
          },
        ],
        activeSessionState: {
          'session_id': 'active_sess_safety',
          'routine_name': 'Push Routine',
          'routine_name_ar': 'تمرين الدفع',
          'is_lite_mode': 0,
          'started_at': '2026-11-22T08:00:00.000Z',
          'current_exercise_index': 1,
          'current_set_index': 2,
          'completed_sets_json': '[]',
          'active_session_json': '{}',
        },
        salvageArchives: [
          {
            'id': 'salvage_safety_01',
            'session_id': 'salvage_sess_01',
            'routine_name': 'Push Routine',
            'salvaged_at': '2026-11-22T08:46:00.000Z',
            'parsed_sets_count': 2,
            'has_corrupt_logs': 0,
            'raw_completed_sets_json': '[]',
            'raw_active_session_json': '{}',
          },
        ],
        weightEntries: [
          {
            'id': 'weight_safety_01',
            'weight_kg': 78.5,
            'logged_at': '2026-11-22T07:30:00.000Z',
            'notes': 'Fasted morning weigh-in',
          },
        ],
        progressPhotos: [
          {
            'id': 'photo_safety_01',
            'file_path': 'progress_photos/photo_front_01.jpg',
            'angle': 'FRONT',
            'taken_at': '2026-11-22T07:35:00.000Z',
            'notes': 'Front profile acceptance test',
          },
          {
            'id': 'photo_safety_02',
            'file_path': 'progress_photos/photo_side_01.jpg',
            'angle': 'SIDE',
            'taken_at': '2026-11-22T07:36:00.000Z',
            'notes': 'Side profile acceptance test',
          },
        ],
        dailyMealChecks: [
          {
            'date': '2026-11-22',
            'meal_slot': 0,
            'is_checked': 1,
          },
          {
            'date': '2026-11-22',
            'meal_slot': 1,
            'is_checked': 1,
          },
        ],
        reminderSettings: {
          'id': 'default',
          'is_enabled': 1,
          'hour': 15,
          'minute': 30,
          'updated_at': '2026-11-22T06:00:00.000Z',
        },
      );

      // Seed DB with original snapshot
      await repository.restoreDataSnapshot(originalSnapshot);

      // Create physical photos on disk
      await stagingManager.photosDir.create(recursive: true);
      final photoFile1 = File('${stagingManager.photosDir.path}/photo_front_01.jpg');
      await photoFile1.writeAsBytes(Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03, 0x04,
        0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0xFF, 0xD9,
      ]));
      final photoFile2 = File('${stagingManager.photosDir.path}/photo_side_01.jpg');
      await photoFile2.writeAsBytes(Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0xFF, 0xD9,
      ]));

      // 2. Export Backup Archive
      final exportStaging = await stagingManager.prepareExportStaging();
      final backupArchiveFile = await archiveService.createBackupArchive(
        snapshot: originalSnapshot,
        photoFiles: [photoFile1, photoFile2],
        outputFilePath: '${exportStaging.path}/safety_acceptance_backup.homesets',
      );
      expect(await backupArchiveFile.exists(), isTrue);

      final savedBackupFile = File('${tempDir.path}/saved_safety_backup.homesets');
      await backupArchiveFile.copy(savedBackupFile.path);

      // 3. Test Preview Cancellation:
      // Opening preview dialog and cancelling must leave active DB and photos 100% untouched
      final cancelStaging = await stagingManager.prepareImportStaging();
      final previewValidation = await archiveService.validateAndExtractArchive(
        archiveFile: savedBackupFile,
        stagingDir: cancelStaging,
      );
      expect(previewValidation.isValid, isTrue);
      expect(previewValidation.manifest?.recordCounts['workout_sessions'], equals(1));
      expect(previewValidation.manifest?.recordCounts['set_logs'], equals(2));
      expect(previewValidation.manifest?.recordCounts['progress_photos'], equals(2));

      // User cancels preview -> cleans staging
      await stagingManager.cleanStaging();
      expect(await cancelStaging.exists(), isFalse);
      expect((await repository.getUserProfile())?.id, equals('user_full_acceptance'));
      expect(await photoFile1.exists(), isTrue);
      expect(await photoFile2.exists(), isTrue);

      // 4. Test Corrupted Backup Rejection:
      // Tampering archive causes rejection without touching local state
      final tamperedArchive = File('${tempDir.path}/tampered_safety.homesets');
      final tamperedBytes = Uint8List.fromList(await savedBackupFile.readAsBytes());
      tamperedBytes[tamperedBytes.length - 30] ^= 0xFF;
      await tamperedArchive.writeAsBytes(tamperedBytes);

      final tamperedStaging = await stagingManager.prepareImportStaging();
      final tamperedValidation = await archiveService.validateAndExtractArchive(
        archiveFile: tamperedArchive,
        stagingDir: tamperedStaging,
      );
      expect(tamperedValidation.isValid, isFalse, reason: 'Tampered archive must be rejected');
      await stagingManager.cleanStaging();

      // Verify active state remains untouched
      expect((await repository.getUserProfile())?.id, equals('user_full_acceptance'));

      // 5. Clear database and photos to simulate restore onto clean state
      final db = await DatabaseHelper.instance.database;
      await db.delete('user_profile');
      await db.delete('equipment_inventory');
      await db.delete('workout_sessions');
      await db.delete('set_logs');
      await db.delete('active_session_state');
      await db.delete('session_salvage_archive');
      await db.delete('weight_entries');
      await db.delete('progress_photos');
      await db.delete('daily_meal_checks');
      await db.delete('reminder_settings');
      await stagingManager.photosDir.delete(recursive: true);

      expect(await repository.getUserProfile(), isNull);
      expect(await stagingManager.photosDir.exists(), isFalse);

      // 6. Restore from valid backup
      final importStaging = await stagingManager.prepareImportStaging();
      final validation = await archiveService.validateAndExtractArchive(
        archiveFile: savedBackupFile,
        stagingDir: importStaging,
      );
      expect(validation.isValid, isTrue);
      expect(validation.snapshot, isNotNull);
      expect(validation.photoFiles.length, equals(2));

      await stagingManager.executeTwoPhaseRestore(
        snapshot: validation.snapshot!,
        stagedPhotos: validation.photoFiles,
        onDbRestore: (restoreToken) async {
          await repository.restoreDataSnapshot(
            validation.snapshot!,
            restoreToken: restoreToken,
          );
        },
        repository: repository,
      );

      // 7. Verify bit-for-bit restored records and real photo binary bytes across all 10 tables
      final restoredSnapshot = await repository.createDataSnapshot();
      expect(restoredSnapshot.userProfile?['id'], equals('user_full_acceptance'));
      expect(restoredSnapshot.equipmentInventory?['has_pull_up_bar'], equals(1));
      expect(restoredSnapshot.workoutSessions.length, equals(1));
      expect(restoredSnapshot.workoutSessions.first['routine_name'], equals('Upper Push Strength Focus'));
      expect(restoredSnapshot.setLogs.length, equals(2));
      expect(restoredSnapshot.setLogs[0]['exercise_id'], equals('pushup_standard'));
      expect(restoredSnapshot.setLogs[0]['performed_reps'], equals(15));
      expect(restoredSnapshot.setLogs[1]['exercise_id'], equals('banded_overhead_press'));
      expect(restoredSnapshot.setLogs[1]['band_used'], equals('heavy_black_band'));
      expect(restoredSnapshot.activeSessionState?['session_id'], equals('active_sess_safety'));
      expect(restoredSnapshot.salvageArchives.length, equals(1));
      expect(restoredSnapshot.weightEntries.length, equals(1));
      expect(restoredSnapshot.weightEntries.first['weight_kg'], equals(78.5));
      expect(restoredSnapshot.progressPhotos.length, equals(2));
      expect(restoredSnapshot.dailyMealChecks.length, equals(2));
      expect(restoredSnapshot.reminderSettings?['hour'], equals(15));
      expect(restoredSnapshot.reminderSettings?['minute'], equals(30));

      final restoredPhoto1 = File('${stagingManager.photosDir.path}/photo_front_01.jpg');
      final restoredPhoto2 = File('${stagingManager.photosDir.path}/photo_side_01.jpg');
      expect(await restoredPhoto1.exists(), isTrue);
      expect(await restoredPhoto2.exists(), isTrue);
      expect(await restoredPhoto1.readAsBytes(), equals([
        0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03, 0x04,
        0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0xFF, 0xD9,
      ]));
      expect(await restoredPhoto2.readAsBytes(), equals([
        0xFF, 0xD8, 0xFF, 0xE0, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0xFF, 0xD9,
      ]));

      // 8. Verify clean post-restore state
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
      expect(await stagingManager.stagingDir.exists(), isFalse);
    });
  });
}
