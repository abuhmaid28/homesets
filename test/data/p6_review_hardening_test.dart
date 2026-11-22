import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesets/data/repositories/workout_repository.dart';
import 'package:homesets/data/services/backup_archive_service.dart';
import 'package:homesets/data/services/backup_hash_provider.dart';
import 'package:homesets/data/services/backup_staging_manager.dart';
import 'package:homesets/data/services/zip_codec.dart';
import 'package:homesets/domain/backup/backup_models.dart';
import 'package:homesets/domain/models/domain_models.dart';

void main() {
  late Directory tempDir;
  late Directory stagingDir;
  late BackupArchiveService archiveService;
  const hashProvider = DefaultBackupHashProvider();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('homesets_p6r_hardening_');
    stagingDir = Directory('${tempDir.path}/staging');
    await stagingDir.create(recursive: true);
    archiveService = const BackupArchiveService(hashProvider: hashProvider);
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('P6-R03: Checksum Determinism & Algorithm Contract', () {
    test('DefaultBackupHashProvider produces deterministic 256-bit hexadecimal digest', () {
      final hashEmpty = hashProvider.computeChecksum(utf8.encode(''));
      expect(hashEmpty.length, equals(64));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hashEmpty), isTrue);
      // Fixed known test vector for empty input (P6-LAST-04)
      expect(hashEmpty, equals('8e9b30c57e3e1f91f14c4df09bb9a32e70b9288f36465e4250218c1508981abd'));

      final hash1 = hashProvider.computeChecksum(utf8.encode('hello world'));
      final hash2 = hashProvider.computeChecksum(utf8.encode('hello world'));
      expect(hash1, equals(hash2));

      final hashDiff = hashProvider.computeChecksum(utf8.encode('hello world!'));
      expect(hash1, isNot(equals(hashDiff)));
    });
  });

  group('P6-R01 & P6-R06: Backup Photo Consistency & Completeness', () {
    test('createBackupArchive fails closed if any declared photo file does not exist on disk', () async {
      final snapshot = const HomesetsDataSnapshot(
        userProfile: {'id': 'u1'},
        equipmentInventory: {'has_bands': 1},
        progressPhotos: [
          {'id': 'p1', 'file_path': 'progress_photos/photo_non_existent.jpg'},
        ],
      );

      final nonExistentFile = File('${tempDir.path}/photo_non_existent.jpg');
      final outputFile = '${stagingDir.path}/test_out.homesets';

      // Must throw an exception rather than silently omitting missing photo
      expect(
        () => archiveService.createBackupArchive(
          snapshot: snapshot,
          photoFiles: [nonExistentFile],
          outputFilePath: outputFile,
        ),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('validateAndExtractArchive rejects archive with missing referenced photos as invalid', () async {
      // Build an archive that references photo_missing in snapshot, but doesn't include it in ZIP
      final snapshot = const HomesetsDataSnapshot(
        userProfile: {'id': 'u1'},
        equipmentInventory: {'has_bands': 1},
        progressPhotos: [
          {'id': 'p1', 'file_path': 'progress_photos/photo_missing.jpg'},
        ],
      );

      final snapshotBytes = utf8.encode(jsonEncode(snapshot.toJson()));
      final manifest = BackupManifest(
        formatVersion: 1,
        appVersion: '1.0.0+1',
        databaseSchemaVersion: 2,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        devicePlatform: 'android',
        dataSnapshotChecksum: hashProvider.computeChecksum(snapshotBytes),
        recordCounts: snapshot.recordCounts,
        files: const [], // missing photo
        totalFilesCount: 0,
        totalUncompressedBytes: snapshotBytes.length,
      );

      final zipBytes = ZipCodec.encode([
        ZipEntry(path: 'manifest.json', data: utf8.encode(jsonEncode(manifest.toJson()))),
        ZipEntry(path: 'data.json', data: snapshotBytes),
      ]);

      final archiveFile = File('${tempDir.path}/missing_photo.homesets');
      await archiveFile.writeAsBytes(zipBytes);

      final result = await archiveService.validateAndExtractArchive(
        archiveFile: archiveFile,
        stagingDir: stagingDir,
      );

      expect(result.isValid, isFalse, reason: 'Archive with missing referenced photo must fail validation');
      expect(result.error, contains('missing'));
    });

    test('validateAndExtractArchive rejects version 0 or negative formatVersion', () async {
      final snapshot = const HomesetsDataSnapshot(userProfile: {'id': 'u1'});
      final snapshotBytes = utf8.encode(jsonEncode(snapshot.toJson()));
      final manifest = BackupManifest(
        formatVersion: 0, // Invalid version
        appVersion: '1.0.0+1',
        databaseSchemaVersion: 2,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        devicePlatform: 'android',
        dataSnapshotChecksum: hashProvider.computeChecksum(snapshotBytes),
        recordCounts: snapshot.recordCounts,
        files: const [],
        totalFilesCount: 0,
        totalUncompressedBytes: snapshotBytes.length,
      );

      final zipBytes = ZipCodec.encode([
        ZipEntry(path: 'manifest.json', data: utf8.encode(jsonEncode(manifest.toJson()))),
        ZipEntry(path: 'data.json', data: snapshotBytes),
      ]);

      final archiveFile = File('${tempDir.path}/invalid_ver.homesets');
      await archiveFile.writeAsBytes(zipBytes);

      final result = await archiveService.validateAndExtractArchive(
        archiveFile: archiveFile,
        stagingDir: stagingDir,
      );

      expect(result.isValid, isFalse);
      expect(result.error, contains('format version'));
    });

    test('validateAndExtractArchive rejects mismatched record counts', () async {
      final snapshot = const HomesetsDataSnapshot(
        userProfile: {'id': 'u1'},
        setLogs: [
          {'id': 's1', 'exercise_id': 'pushup'},
        ],
      );
      final snapshotBytes = utf8.encode(jsonEncode(snapshot.toJson()));
      final manifest = BackupManifest(
        formatVersion: 1,
        appVersion: '1.0.0+1',
        databaseSchemaVersion: 2,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        devicePlatform: 'android',
        dataSnapshotChecksum: hashProvider.computeChecksum(snapshotBytes),
        recordCounts: {'set_logs': 99}, // Mismatched!
        files: const [],
        totalFilesCount: 0,
        totalUncompressedBytes: snapshotBytes.length,
      );

      final zipBytes = ZipCodec.encode([
        ZipEntry(path: 'manifest.json', data: utf8.encode(jsonEncode(manifest.toJson()))),
        ZipEntry(path: 'data.json', data: snapshotBytes),
      ]);

      final archiveFile = File('${tempDir.path}/mismatched_counts.homesets');
      await archiveFile.writeAsBytes(zipBytes);

      final result = await archiveService.validateAndExtractArchive(
        archiveFile: archiveFile,
        stagingDir: stagingDir,
      );

      expect(result.isValid, isFalse);
      expect(result.error, contains('Record count mismatch'));
    });
  });

  group('P6-R02: Hostile ZIP Defense & Limit Checks', () {
    test('ZipCodec.decode rejects duplicate entry paths', () {
      final dummyData = utf8.encode('hello');
      final duplicateEntries = [
        ZipEntry(path: 'data.json', data: dummyData),
        ZipEntry(path: 'data.json', data: dummyData),
      ];

      final zipBytes = ZipCodec.encode(duplicateEntries);

      expect(
        () => ZipCodec.decode(zipBytes),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Duplicate'))),
      );
    });

    test('ZipCodec.decode rejects path traversal in entry path', () {
      final dummyData = utf8.encode('malicious');
      final badEntry = ZipEntry(path: '../../etc/passwd', data: dummyData);
      final zipBytes = ZipCodec.encode([badEntry]);

      expect(
        () => ZipCodec.decode(zipBytes),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Path traversal'))),
      );
    });

    test('ZipCodec.decode rejects archive exceeding max file count before decoding', () {
      // Craft archive or call with totalEntries > maxFileCount
      final manyEntries = List.generate(
        1001,
        (i) => ZipEntry(path: 'file_$i.txt', data: Uint8List(1)),
      );
      final zipBytes = ZipCodec.encode(manyEntries);

      expect(
        () => ZipCodec.decode(zipBytes, maxFileCount: 1000),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('maximum file count'))),
      );
    });
  });

  group('P6-R04: Two-Resource Restore Crash Journal & Rollback', () {
    test('Cold recovery rolls back photos when crash happened before DB commit', () async {
      final appDocsDir = Directory('${tempDir.path}/app_docs');
      await appDocsDir.create(recursive: true);

      final stagingManager = BackupStagingManager(appDocsDir: appDocsDir);

      // Create original photos
      await stagingManager.photosDir.create(recursive: true);
      final origPhoto = File('${stagingManager.photosDir.path}/orig.jpg');
      await origPhoto.writeAsString('ORIGINAL_CONTENT');

      // Simulate a crash at PHOTOS_PRESERVED phase:
      // 1. Rename photosDir to photosBackupDir
      await stagingManager.photosDir.rename(stagingManager.photosBackupDir.path);
      // 2. Create new photosDir with staged photos
      await stagingManager.photosDir.create(recursive: true);
      final newPhoto = File('${stagingManager.photosDir.path}/new.jpg');
      await newPhoto.writeAsString('NEW_UNCOMMITTED_CONTENT');
      // 3. Write journal indicating PHOTOS_PRESERVED with hadOriginalPhotos = true and valid token
      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': 'token_p6r_precommit',
        'phase': 'PHOTOS_PRESERVED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // Run cold recovery with repository where SQLite did not commit
      final recovered = await stagingManager.recoverPendingJournal(
        repository: _HardeningMockRepository(token: null),
      );
      expect(recovered.isSuccess, isTrue);

      // Original photo must be restored
      expect(await origPhoto.exists(), isTrue);
      expect(await origPhoto.readAsString(), equals('ORIGINAL_CONTENT'));

      // New uncommitted photo must be gone
      expect(await newPhoto.exists(), isFalse);

      // Rollback dir and journal file must be cleaned
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });

    test('Cold recovery finalizes photos when crash happened after DB commit', () async {
      final appDocsDir = Directory('${tempDir.path}/app_docs');
      await appDocsDir.create(recursive: true);

      final stagingManager = BackupStagingManager(appDocsDir: appDocsDir);

      // Old photos in rollback dir
      await stagingManager.photosBackupDir.create(recursive: true);
      final oldPhoto = File('${stagingManager.photosBackupDir.path}/old.jpg');
      await oldPhoto.writeAsString('OLD_CONTENT');

      // New photos already in photosDir (DB commit completed)
      await stagingManager.photosDir.create(recursive: true);
      final committedPhoto = File('${stagingManager.photosDir.path}/committed.jpg');
      await committedPhoto.writeAsBytes(Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03, 0x04,
        0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0xFF, 0xD9,
      ]));

      // Write journal indicating DB_COMMITTED with confirmed token
      await stagingManager.journalFile.writeAsString(jsonEncode({
        'restoreToken': 'token_p6r_committed',
        'phase': 'DB_COMMITTED',
        'hadOriginalPhotos': true,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }));

      // Run cold recovery with repository where SQLite committed token_p6r_committed
      final recovered = await stagingManager.recoverPendingJournal(
        repository: _HardeningMockRepository(
          token: 'token_p6r_committed',
          photos: [
            ProgressPhoto(
              id: 'committed_1',
              filePath: 'progress_photos/committed.jpg',
              angle: PhotoAngle.front,
              takenAt: DateTime.now().toUtc(),
            ),
          ],
        ),
      );
      expect(recovered.isSuccess, isTrue);

      // Committed photo remains
      expect(await committedPhoto.exists(), isTrue);
      expect(await committedPhoto.readAsBytes(), equals([
        0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03, 0x04,
        0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0xFF, 0xD9,
      ]));

      // Old rollback dir and journal must be purged
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });

    test('Rollback with no original photos deletes newly staged photos and leaves no orphans', () async {
      final appDocsDir = Directory('${tempDir.path}/app_docs');
      await appDocsDir.create(recursive: true);

      final stagingManager = BackupStagingManager(appDocsDir: appDocsDir);
      // Ensure photosDir does not exist initially
      if (await stagingManager.photosDir.exists()) {
        await stagingManager.photosDir.delete(recursive: true);
      }

      final stagingIncomingDir = await stagingManager.prepareImportStaging();
      final incomingPhoto = File('${stagingIncomingDir.path}/incoming.jpg');
      await incomingPhoto.writeAsString('INCOMING_DATA');

      // Execute restore where DB fails
      await expectLater(
        () => stagingManager.executeTwoPhaseRestore(
          snapshot: const HomesetsDataSnapshot(),
          stagedPhotos: [incomingPhoto],
          onDbRestore: () async {
            throw Exception('DB failure on fresh install without original photos');
          },
        ),
        throwsA(isA<BackupRestoreException>()),
      );

      // photosDir must not contain leaked incoming photo
      final leaked = File('${stagingManager.photosDir.path}/incoming.jpg');
      expect(await leaked.exists(), isFalse);
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
      expect(await stagingManager.journalFile.exists(), isFalse);
    });
  });
}

class _HardeningMockRepository extends WorkoutRepository {
  final String? token;
  final List<ProgressPhoto> photos;
  _HardeningMockRepository({this.token, this.photos = const []});

  @override
  Future<String?> getCurrentRestoreToken() async {
    return token;
  }

  @override
  Future<List<ProgressPhoto>> getProgressPhotos({PhotoAngle? angle}) async {
    return photos;
  }
}
