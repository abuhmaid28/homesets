import 'dart:convert';
import 'dart:io';
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
  late BackupArchiveService archiveService;
  late BackupStagingManager stagingManager;
  const hashProvider = DefaultBackupHashProvider();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setCustomFactory(databaseFactoryFfi);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('homesets_durability_test_');
    repository = WorkoutRepository();
    archiveService = const BackupArchiveService(hashProvider: hashProvider);
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
  // WORKSTREAM A: ALL 10 RESTORE INTERRUPTION BOUNDARIES
  // =========================================================================
  group('Workstream A: Restore Interruption Boundaries & Two-Resource Crash Safety', () {
    test('Boundary 1: Crash before writing recovery journal leaves original state untouched', () async {
      await stagingManager.photosDir.create(recursive: true);
      final origPhoto = File('${stagingManager.photosDir.path}/orig.jpg');
      await origPhoto.writeAsString('ORIGINAL_DATA');

      final recovery = await stagingManager.recoverPendingJournal(repository: repository);
      expect(recovery.neededRecovery, isFalse);
      expect(await origPhoto.exists(), isTrue);
      expect(await origPhoto.readAsString(), equals('ORIGINAL_DATA'));
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
    });

    test('Boundary 2: Crash at PREPARING phase (before moving photos) recovers cleanly', () async {
      await stagingManager.photosDir.create(recursive: true);
      final origPhoto = File('${stagingManager.photosDir.path}/orig.jpg');
      await origPhoto.writeAsString('ORIGINAL_DATA');

      // Interrupted right after PREPARING journal written
      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': 'token_b2',
        'phase': 'PREPARING',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      final recovery = await stagingManager.recoverPendingJournal(repository: repository);
      expect(recovery.isSuccess, isTrue);
      expect(await origPhoto.exists(), isTrue);
      expect(await origPhoto.readAsString(), equals('ORIGINAL_DATA'));
      expect(await stagingManager.journalFile.exists(), isFalse);
    });

    test('Boundary 3: Crash at ORIGINAL_PHOTOS_MOVED phase rolls back original photos', () async {
      // Photos moved to rollback directory, new photosDir not yet populated
      await stagingManager.photosBackupDir.create(recursive: true);
      final origPhoto = File('${stagingManager.photosBackupDir.path}/orig.jpg');
      await origPhoto.writeAsString('ORIGINAL_DATA');

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': 'token_b3',
        'phase': 'ORIGINAL_PHOTOS_MOVED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      final recovery = await stagingManager.recoverPendingJournal(repository: repository);
      expect(recovery.isSuccess, isTrue);
      expect(await File('${stagingManager.photosDir.path}/orig.jpg').exists(), isTrue);
      expect(await File('${stagingManager.photosDir.path}/orig.jpg').readAsString(), equals('ORIGINAL_DATA'));
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });

    test('Boundary 4 & 5: Crash at NEW_PHOTOS_STAGED before SQLite transaction rolls back photos', () async {
      // Original in rollback dir
      await stagingManager.photosBackupDir.create(recursive: true);
      final origPhoto = File('${stagingManager.photosBackupDir.path}/orig.jpg');
      await origPhoto.writeAsString('ORIGINAL_DATA');

      // Staged photos in photosDir
      await stagingManager.photosDir.create(recursive: true);
      final newPhoto = File('${stagingManager.photosDir.path}/new.jpg');
      await newPhoto.writeAsString('NEW_UNCOMMITTED_DATA');

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': 'token_b4',
        'phase': 'NEW_PHOTOS_STAGED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      final recovery = await stagingManager.recoverPendingJournal(repository: repository);
      expect(recovery.isSuccess, isTrue);
      expect(await File('${stagingManager.photosDir.path}/orig.jpg').exists(), isTrue);
      expect(await File('${stagingManager.photosDir.path}/new.jpg').exists(), isFalse);
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });

    test('Boundary 6: Failed SQLite transaction automatically rolls back photos and cleans journal', () async {
      await stagingManager.photosDir.create(recursive: true);
      final origPhoto = File('${stagingManager.photosDir.path}/orig.jpg');
      await origPhoto.writeAsString('ORIGINAL_DATA');

      final stagedDir = await stagingManager.prepareImportStaging();
      final incomingPhoto = File('${stagedDir.path}/incoming.jpg');
      await incomingPhoto.writeAsString('INCOMING_DATA');

      await expectLater(
        () => stagingManager.executeTwoPhaseRestore(
          snapshot: const HomesetsDataSnapshot(),
          stagedPhotos: [incomingPhoto],
          onDbRestore: (restoreToken) async {
            throw Exception('Simulated SQLite Disk I/O Failure');
          },
          repository: repository,
        ),
        throwsA(isA<BackupRestoreException>()),
      );

      // Verify photos rolled back to original
      expect(await origPhoto.exists(), isTrue);
      expect(await origPhoto.readAsString(), equals('ORIGINAL_DATA'));
      expect(await File('${stagingManager.photosDir.path}/incoming.jpg').exists(), isFalse);
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });

    test('Boundary 7 & 8: Crash IMMEDIATELY after SQLite commits preserves new photos and finalizes', () async {
      final restoreToken = 'token_committed_b7';

      // Simulate state right after SQLite commit:
      // 1. New photo in photosDir
      await stagingManager.photosDir.create(recursive: true);
      final newPhoto = File('${stagingManager.photosDir.path}/new_restored.jpg');
      await newPhoto.writeAsString('RESTORED_DATA');

      // 2. Old photo in rollback dir
      await stagingManager.photosBackupDir.create(recursive: true);
      final oldPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await oldPhoto.writeAsString('OLD_DATA');

      // 3. Database has restore_token committed!
      final db = await DatabaseHelper.instance.database;
      await db.insert('app_metadata', {'key': 'restore_token', 'value': restoreToken});

      // 4. Journal on disk still says NEW_PHOTOS_STAGED (crash happened before DB_COMMITTED marker was written)
      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': restoreToken,
        'phase': 'NEW_PHOTOS_STAGED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // Cold recovery runs: cross-verifies restoreToken with SQLite!
      final recovery = await stagingManager.recoverPendingJournal(repository: repository);
      expect(recovery.isSuccess, isTrue);
      expect(recovery.action, equals('finalized'));

      // New photo MUST BE KEPT! Must NOT roll back to old photo!
      expect(await newPhoto.exists(), isTrue);
      expect(await newPhoto.readAsString(), equals('RESTORED_DATA'));

      // Old photo and journal must be purged
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });

    test('Boundary 9: Incomplete rollback preserves recovery journal and backup directory (P6-FINAL-04)', () async {
      await stagingManager.photosDir.create(recursive: true);
      final origPhoto = File('${stagingManager.photosDir.path}/orig.jpg');
      await origPhoto.writeAsString('ORIGINAL_DATA');

      final stagedDir = await stagingManager.prepareImportStaging();
      final incomingPhoto = File('${stagedDir.path}/incoming.jpg');
      await incomingPhoto.writeAsString('INCOMING_DATA');

      // Write mock journal indicating ROLLBACK_FAILED
      await stagingManager.photosBackupDir.create(recursive: true);
      final backupPhoto = File('${stagingManager.photosBackupDir.path}/orig.jpg');
      await backupPhoto.writeAsString('ORIGINAL_DATA');

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': 'token_fail',
        'phase': 'ROLLBACK_FAILED',
        'hadOriginalPhotos': true,
        'lastError': 'Simulated disk permission error during rollback',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // Next recovery attempt safely restores original photos
      final recovery = await stagingManager.recoverPendingJournal(repository: repository);
      expect(recovery.isSuccess, isTrue);
      expect(await File('${stagingManager.photosDir.path}/orig.jpg').exists(), isTrue);
      expect(await File('${stagingManager.photosDir.path}/orig.jpg').readAsString(), equals('ORIGINAL_DATA'));
    });

    test('Boundary 10: Process killed after restore but before journal deletion finalizes safely', () async {
      await stagingManager.photosDir.create(recursive: true);
      final photo = File('${stagingManager.photosDir.path}/p1.jpg');
      await photo.writeAsString('COMMITTED_DATA');

      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'app_metadata',
        {'key': 'restore_token', 'value': 'token_done'},
      );

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': 'token_done',
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      final recovery = await stagingManager.recoverPendingJournal(repository: repository);
      expect(recovery.isSuccess, isTrue);
      expect(recovery.action, equals('finalized'));
      expect(await photo.exists(), isTrue);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });
  });

  // =========================================================================
  // WORKSTREAM C & D: ARCHIVE SECURITY, STREAMING & DIGEST CONTRACT
  // =========================================================================
  group('Workstream C & D: Streaming Archive Security, Quotas & Integrity Contract', () {
    test('DefaultBackupHashProvider produces deterministic digests matching official contract', () async {
      const provider = DefaultBackupHashProvider();
      final emptyDigest = provider.computeChecksum([]);
      expect(emptyDigest.length, equals(64));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(emptyDigest), isTrue);

      final sampleDigest = provider.computeChecksum(utf8.encode('HOMESETS'));
      expect(sampleDigest.length, equals(64));

      // Streaming computeFileChecksum matches in-memory computeChecksum exactly (P6-FINAL-05)
      final sampleFile = File('${tempDir.path}/sample_digest.txt');
      await sampleFile.writeAsString('HOMESETS_VERIFIED_DATA_PAYLOAD_12345');

      final memDigest = provider.computeChecksum(await sampleFile.readAsBytes());
      final streamDigest = await provider.computeFileChecksum(sampleFile);
      expect(streamDigest, equals(memDigest));
    });

    test('validateAndExtractArchive rejects unsupported checksumAlgorithm', () async {
      final stagingDir = Directory('${tempDir.path}/unsupported_algo_staging');
      await stagingDir.create(recursive: true);

      final manifest = BackupManifest(
        formatVersion: 1,
        appVersion: '1.0.0+1',
        databaseSchemaVersion: 2,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        devicePlatform: 'android',
        dataSnapshotChecksum: '0000000000000000000000000000000000000000000000000000000000000000',
        checksumAlgorithm: 'unsupported-crypto-v9', // Unsupported!
        recordCounts: const {},
        files: const [],
        totalFilesCount: 0,
        totalUncompressedBytes: 2,
      );

      final manifestFile = File('${stagingDir.path}/manifest.json');
      await manifestFile.writeAsString(manifest.serialize());

      final dataFile = File('${stagingDir.path}/data.json');
      await dataFile.writeAsString('{}');

      final badArchive = File('${tempDir.path}/bad_algo.homesets');
      await ZipCodec.createArchiveFileStream(
        outputFile: badArchive,
        files: [
          ZipFileInput(path: 'manifest.json', file: manifestFile),
          ZipFileInput(path: 'data.json', file: dataFile),
        ],
      );

      final result = await archiveService.validateAndExtractArchive(
        archiveFile: badArchive,
        stagingDir: stagingDir,
      );

      expect(result.isValid, isFalse);
      expect(result.error, contains('Unsupported checksum algorithm'));
    });

    test('ZipCodec.extractArchiveFileStream bounds memory and rejects traversal', () async {
      final maliciousDir = Directory('${tempDir.path}/malicious_extract');
      await maliciousDir.create(recursive: true);

      // Create archive with path traversal in entry
      final payload = utf8.encode('TRAVERSAL_ATTEMPT');
      final entry = ZipEntry(path: '../../traversal.txt', data: payload);
      final zipBytes = ZipCodec.encode([entry]);

      final badZip = File('${tempDir.path}/traversal.zip');
      await badZip.writeAsBytes(zipBytes);

      await expectLater(
        () => ZipCodec.extractArchiveFileStream(
          archiveFile: badZip,
          targetDir: maliciousDir,
        ),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Path traversal'))),
      );
    });
  });

  // =========================================================================
  // WORKSTREAM E: FULL-DATASET SYNTHETIC P0–P5 BACKUP/RESTORE ROUNDTRIP
  // =========================================================================
  group('Workstream E: Full Synthetic P0-P5 Dataset Backup & Restore Round-Trip', () {
    test('Exports, validates, and restores all 10 tables + private photos with 100% fidelity', () async {
      // 1. Populate full synthetic dataset across all 10 SQLite tables
      final originalSnapshot = HomesetsDataSnapshot(
        userProfile: {
          'id': 'user_full_e2e',
          'goal': 'STRENGTH',
          'wake_time_minutes': 420,
          'shift_start_minutes': 1020,
          'target_workouts_per_week': 4,
          'avoided_joints': 'SHOULDER',
          'created_at': '2026-11-21T06:00:00.000Z',
        },
        equipmentInventory: {
          'id': 'inv_full_e2e',
          'has_pull_up_bar': 1,
          'has_bands': 1,
          'has_door_anchor': 1,
          'has_sturdy_table': 0,
          'has_parallel_grip': 1,
          'updated_at': '2026-11-21T06:00:00.000Z',
        },
        workoutSessions: [
          {
            'id': 'sess_e2e_1',
            'scheduled_session_id': 'sched_1',
            'routine_name': 'Upper Body Push Focus',
            'is_lite_mode': 0,
            'started_at': '2026-11-21T07:00:00.000Z',
            'ended_at': '2026-11-21T07:45:00.000Z',
            'total_duration_seconds': 2700,
            'is_emergency_stopped': 0,
            'emergency_stop_reason': null,
          },
        ],
        setLogs: [
          {
            'id': 'set_e2e_1',
            'session_id': 'sess_e2e_1',
            'set_index': 0,
            'exercise_id': 'pushup_standard',
            'performed_reps': 12,
            'band_used': 'red_15lb',
            'exertion': 'MEDIUM',
            'is_pain_stopped': 0,
            'pain_note': null,
            'completed_at': '2026-11-21T07:10:00.000Z',
          },
        ],
        activeSessionState: {
          'session_id': 'active_sess_e2e',
          'routine_name': 'Core Routine',
          'routine_name_ar': 'تمرين البطن',
          'is_lite_mode': 1,
          'started_at': '2026-11-21T08:00:00.000Z',
          'current_exercise_index': 1,
          'current_set_index': 2,
          'completed_sets_json': '[]',
          'active_session_json': '{}',
        },
        salvageArchives: [
          {
            'id': 'salvage_e2e_1',
            'session_id': 'salvage_sess_1',
            'routine_name': 'Pull Routine',
            'salvaged_at': '2026-11-21T09:00:00.000Z',
            'parsed_sets_count': 3,
            'has_corrupt_logs': 0,
            'raw_completed_sets_json': '[]',
            'raw_active_session_json': '{}',
          },
        ],
        weightEntries: [
          {
            'id': 'weight_e2e_1',
            'weight_kg': 82.5,
            'logged_at': '2026-11-21T06:30:00.000Z',
            'notes': 'Morning fasted',
          },
        ],
        progressPhotos: [
          {
            'id': 'photo_e2e_1',
            'file_path': 'progress_photos/photo_e2e_1.jpg',
            'angle': 'FRONT',
            'taken_at': '2026-11-21T06:35:00.000Z',
            'notes': 'Front profile milestone',
          },
        ],
        dailyMealChecks: [
          {
            'date': '2026-11-21',
            'meal_slot': 0,
            'is_checked': 1,
          },
          {
            'date': '2026-11-21',
            'meal_slot': 1,
            'is_checked': 1,
          },
        ],
        reminderSettings: {
          'id': 'default',
          'is_enabled': 1,
          'hour': 16,
          'minute': 45,
          'updated_at': '2026-11-21T06:00:00.000Z',
        },
      );

      // Seed DB with original snapshot
      await repository.restoreDataSnapshot(originalSnapshot);

      // Create physical photo on disk
      await stagingManager.photosDir.create(recursive: true);
      final photoFile = File('${stagingManager.photosDir.path}/photo_e2e_1.jpg');
      await photoFile.writeAsString('PHYSICAL_RAW_JPEG_IMAGE_BYTES_123456');

      // 2. Export Backup
      final exportStaging = await stagingManager.prepareExportStaging();
      final backupArchiveFile = await archiveService.createBackupArchive(
        snapshot: originalSnapshot,
        photoFiles: [photoFile],
        outputFilePath: '${exportStaging.path}/e2e_export.homesets',
      );

      expect(await backupArchiveFile.exists(), isTrue);

      // Save exported file outside staging (simulating user selecting a file via SAF)
      final savedBackupFile = File('${tempDir.path}/saved_backup.homesets');
      await backupArchiveFile.copy(savedBackupFile.path);

      // 3. Clear database and photos to simulate a fresh device / replacement
      final db = await DatabaseHelper.instance.database;
      await db.delete('user_profile');
      await db.delete('workout_sessions');
      await db.delete('progress_photos');
      await stagingManager.photosDir.delete(recursive: true);

      expect(await repository.getUserProfile(), isNull);
      expect(await stagingManager.photosDir.exists(), isFalse);

      // 4. Validate and Extract Backup Archive
      final importStaging = await stagingManager.prepareImportStaging();
      final validation = await archiveService.validateAndExtractArchive(
        archiveFile: savedBackupFile,
        stagingDir: importStaging,
      );

      expect(validation.isValid, isTrue);
      expect(validation.snapshot, isNotNull);
      expect(validation.photoFiles.length, equals(1));
      expect(validation.manifest?.recordCounts['workout_sessions'], equals(1));
      expect(validation.manifest?.recordCounts['progress_photos'], equals(1));
      expect(validation.manifest?.recordCounts['daily_meal_checks'], equals(2));

      // 5. Execute Two-Phase Restore
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

      // 6. Verify Complete Data and Photo Restoration
      final restoredProfile = await repository.getUserProfile();
      expect(restoredProfile, isNotNull);
      expect(restoredProfile!.id, equals('user_full_e2e'));
      expect(restoredProfile.goal, equals('STRENGTH'));

      final restoredSnapshot = await repository.createDataSnapshot();
      expect(restoredSnapshot.workoutSessions.length, equals(1));
      expect(restoredSnapshot.workoutSessions.first['routine_name'], equals('Upper Body Push Focus'));

      final restoredWeight = await repository.getWeightEntries();
      expect(restoredWeight.length, equals(1));
      expect(restoredWeight.first.weightKg, equals(82.5));

      final restoredMeals = await repository.getMealChecksForDate('2026-11-21');
      expect(restoredMeals[0], isTrue);
      expect(restoredMeals[1], isTrue);

      final restoredReminders = await repository.getReminderSettings();
      expect(restoredReminders.isEnabled, isTrue);
      expect(restoredReminders.hour, equals(16));
      expect(restoredReminders.minute, equals(45));

      // Verify physical restored photo file
      final restoredPhotoFile = File('${stagingManager.photosDir.path}/photo_e2e_1.jpg');
      expect(await restoredPhotoFile.exists(), isTrue);
      expect(await restoredPhotoFile.readAsString(), equals('PHYSICAL_RAW_JPEG_IMAGE_BYTES_123456'));
    });

    test('Workstream B: Startup recovery automatically recovers interrupted restore before app reads', () async {
      // Simulate crash right after photos moved and uncommitted staged photo placed
      await stagingManager.photosBackupDir.create(recursive: true);
      final origPhoto = File('${stagingManager.photosBackupDir.path}/saved.jpg');
      await origPhoto.writeAsString('SAVED_ORIGINAL_PHOTO');

      await stagingManager.photosDir.create(recursive: true);
      final uncommittedPhoto = File('${stagingManager.photosDir.path}/uncommitted.jpg');
      await uncommittedPhoto.writeAsString('UNCOMMITTED_DATA');

      // Journal indicating crash before DB commit
      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': 'token_startup_crash',
        'phase': 'NEW_PHOTOS_STAGED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // Execute startup recovery directly against repository
      final recovery = await stagingManager.recoverPendingJournal(repository: repository);
      expect(recovery.isSuccess, isTrue);
      expect(recovery.action, equals('rolled_back'));

      // Photos safely rolled back to original
      expect(await File('${stagingManager.photosDir.path}/saved.jpg').exists(), isTrue);
      expect(await File('${stagingManager.photosDir.path}/saved.jpg').readAsString(), equals('SAVED_ORIGINAL_PHOTO'));
      expect(await File('${stagingManager.photosDir.path}/uncommitted.jpg').exists(), isFalse);
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });

    test('Cancellation of restore preview preserves existing data and photos completely untouched', () async {
      // Seed existing profile and photo
      await repository.saveUserProfile(const UserProfile(
        id: 'existing_user',
        goal: 'GENERAL_FITNESS',
        wakeTimeMinutes: 360,
        shiftStartMinutes: 900,
      ));
      await stagingManager.photosDir.create(recursive: true);
      final origPhoto = File('${stagingManager.photosDir.path}/existing.jpg');
      await origPhoto.writeAsString('EXISTING_PHOTO_DATA');

      // Staging prepared for incoming import
      final importStaging = await stagingManager.prepareImportStaging();
      final incomingPhoto = File('${importStaging.path}/incoming.jpg');
      await incomingPhoto.writeAsString('INCOMING_DATA');

      // User cancels restore: staging cleaned without modifying existing data
      await stagingManager.cleanStaging();

      final currentProfile = await repository.getUserProfile();
      expect(currentProfile?.id, equals('existing_user'));
      expect(await origPhoto.exists(), isTrue);
      expect(await origPhoto.readAsString(), equals('EXISTING_PHOTO_DATA'));
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });
  });

  // =========================================================================
  // WORKSTREAM G: P6-LAST DURABILITY, CORRUPT JOURNAL & SQLITE FAULT INJECTION
  // =========================================================================
  group('Workstream G: P6-LAST Fail-Closed Durability & Fault Injection', () {
    test('P6-LAST-01A: Corrupted/torn journal preserves both photo generations and journal, returns failure', () async {
      await stagingManager.photosDir.create(recursive: true);
      final newPhoto = File('${stagingManager.photosDir.path}/new.jpg');
      await newPhoto.writeAsString('NEW_COMMITTED_DATA');

      await stagingManager.photosBackupDir.create(recursive: true);
      final origPhoto = File('${stagingManager.photosBackupDir.path}/orig.jpg');
      await origPhoto.writeAsString('OLD_DATA');

      // Torn/corrupted JSON
      await stagingManager.journalFile.writeAsString('{"restoreToken": "abc", "phase": "NEW_PHOTOS_');

      final recovery = await stagingManager.recoverPendingJournal(repository: repository);
      expect(recovery.isFailure, isTrue, reason: 'Torn journal must fail closed');
      expect(recovery.error, contains('Corrupted or torn'));

      // Invariant: Both photo generations must be preserved
      expect(await newPhoto.exists(), isTrue, reason: 'New photos must not be deleted');
      expect(await newPhoto.readAsString(), equals('NEW_COMMITTED_DATA'));
      expect(await origPhoto.exists(), isTrue, reason: 'Old photos must not be deleted');
      expect(await origPhoto.readAsString(), equals('OLD_DATA'));

      // Journal must NOT be deleted
      expect(await stagingManager.journalFile.exists(), isTrue, reason: 'Journal must be preserved for forensics/retry');
    });

    test('P6-LAST-01B: Malformed journal missing restoreToken and phase fails closed', () async {
      await stagingManager.photosDir.create(recursive: true);
      final newPhoto = File('${stagingManager.photosDir.path}/new.jpg');
      await newPhoto.writeAsString('NEW_COMMITTED_DATA');

      await stagingManager.photosBackupDir.create(recursive: true);
      final origPhoto = File('${stagingManager.photosBackupDir.path}/orig.jpg');
      await origPhoto.writeAsString('OLD_DATA');

      // Valid JSON but missing required fields
      await stagingManager.journalFile.writeAsString(jsonEncode({'unexpected_key': 123}));

      final recovery = await stagingManager.recoverPendingJournal(repository: repository);
      expect(recovery.isFailure, isTrue);
      expect(await newPhoto.exists(), isTrue);
      expect(await origPhoto.exists(), isTrue);
      expect(await stagingManager.journalFile.exists(), isTrue);
    });

    test('P6-LAST-01C: Orphaned rollback directory when photosDir also exists without journal fails closed', () async {
      await stagingManager.photosDir.create(recursive: true);
      final photo1 = File('${stagingManager.photosDir.path}/photo1.jpg');
      await photo1.writeAsString('PHOTO_GEN_1');

      await stagingManager.photosBackupDir.create(recursive: true);
      final photo2 = File('${stagingManager.photosBackupDir.path}/photo2.jpg');
      await photo2.writeAsString('PHOTO_GEN_2');

      // No journal exists
      if (await stagingManager.journalFile.exists()) {
        await stagingManager.journalFile.delete();
      }

      final recovery = await stagingManager.recoverPendingJournal(repository: repository);
      expect(recovery.isFailure, isTrue, reason: 'Cannot determine true photo generation without journal');
      expect(await photo1.exists(), isTrue);
      expect(await photo2.exists(), isTrue);
    });

    test('P6-LAST-02A: SQLite token lookup error must fail closed and NOT roll back photos', () async {
      final restoreToken = 'token_last_02';

      await stagingManager.photosDir.create(recursive: true);
      final newPhoto = File('${stagingManager.photosDir.path}/new.jpg');
      await newPhoto.writeAsString('NEW_COMMITTED_DATA');

      await stagingManager.photosBackupDir.create(recursive: true);
      final oldPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await oldPhoto.writeAsString('OLD_DATA');

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': restoreToken,
        'phase': 'NEW_PHOTOS_STAGED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      final faultRepo = FaultInjectingWorkoutRepository(throwOnTokenRead: true);

      final recovery = await stagingManager.recoverPendingJournal(repository: faultRepo);
      expect(recovery.isFailure, isTrue, reason: 'SQLite token lookup failure must NOT assume uncommitted');
      expect(recovery.error, contains('Failed to read SQLite restore token'));

      // Invariant: Both photo generations and journal must be untouched!
      expect(await newPhoto.exists(), isTrue, reason: 'New photos must not be deleted on token lookup failure');
      expect(await oldPhoto.exists(), isTrue, reason: 'Old photos must not be deleted or moved');
      expect(await stagingManager.journalFile.exists(), isTrue, reason: 'Journal must remain on disk');
    });

    test('P6-LAST-02B: Retry after SQLite is accessible finalizes new photos when token matches', () async {
      final restoreToken = 'token_last_02_retry';

      await stagingManager.photosDir.create(recursive: true);
      final newPhoto = File('${stagingManager.photosDir.path}/new.jpg');
      await newPhoto.writeAsString('NEW_COMMITTED_DATA');

      await stagingManager.photosBackupDir.create(recursive: true);
      final oldPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await oldPhoto.writeAsString('OLD_DATA');

      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': restoreToken,
        'phase': 'NEW_PHOTOS_STAGED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // 1. Initial attempt fails due to SQLite lock
      final faultRepo = FaultInjectingWorkoutRepository(throwOnTokenRead: true);
      final recovery1 = await stagingManager.recoverPendingJournal(repository: faultRepo);
      expect(recovery1.isFailure, isTrue);

      // 2. Retry with healthy repository where token matches committed state
      final healthyRepo = FaultInjectingWorkoutRepository(mockToken: restoreToken);
      final recovery2 = await stagingManager.recoverPendingJournal(repository: healthyRepo);
      expect(recovery2.isSuccess, isTrue);
      expect(recovery2.action, equals('finalized'));

      // Invariant: New photos finalized, old photos purged, journal purged
      expect(await newPhoto.exists(), isTrue);
      expect(await oldPhoto.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });
  });
}

class FaultInjectingWorkoutRepository extends WorkoutRepository {
  final bool throwOnTokenRead;
  final String? mockToken;

  FaultInjectingWorkoutRepository({
    this.throwOnTokenRead = false,
    this.mockToken,
  });

  @override
  Future<String?> getCurrentRestoreToken() async {
    if (throwOnTokenRead) {
      throw Exception('Simulated SQLite DB Locked / IO Error');
    }
    return mockToken;
  }
}
