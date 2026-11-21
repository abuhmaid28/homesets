import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesets/data/services/backup_archive_service.dart';
import 'package:homesets/data/services/backup_hash_provider.dart';
import 'package:homesets/data/services/backup_staging_manager.dart';
import 'package:homesets/data/services/zip_codec.dart';
import 'package:homesets/domain/backup/backup_models.dart';

void main() {
  late Directory tempDir;
  late Directory stagingDir;
  late BackupArchiveService archiveService;
  const hashProvider = DefaultBackupHashProvider();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('homesets_backup_test_');
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

  group('BackupArchiveService (WP06, WP07, WP08)', () {
    test('End-to-end archive creation and validation round-trip with photos', () async {
      // 1. Create a dummy photo file
      final photoFile = File('${tempDir.path}/photo_1001.jpg');
      final dummyPhotoBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03, 0x04]);
      await photoFile.writeAsBytes(dummyPhotoBytes);

      // 2. Create sample snapshot using raw maps
      final snapshot = HomesetsDataSnapshot(
        userProfile: const {
          'id': 'u1',
          'goal': 'MUSCLE_BUILDING',
          'wake_time_minutes': 480,
          'shift_start_minutes': 1140,
        },
        equipmentInventory: const {
          'has_pull_up_bar': 1,
          'has_bands': 1,
        },
        workoutSessions: const [],
        setLogs: const [],
        salvageArchives: const [],
        weightEntries: const [
          {'id': 'w1', 'weight_kg': 80.5, 'logged_at': '2026-11-20T10:00:00.000Z'},
        ],
        progressPhotos: const [
          {
            'id': 'p1',
            'file_path': 'progress_photos/photo_1001.jpg',
            'pose': 'front',
            'logged_at': '2026-11-20T10:00:00.000Z',
          },
        ],
        dailyMealChecks: const [],
      );

      // 3. Create archive
      final archivePath = '${tempDir.path}/test_backup.homesets';
      final createdFile = await archiveService.createBackupArchive(
        snapshot: snapshot,
        photoFiles: [photoFile],
        outputFilePath: archivePath,
      );

      expect(await createdFile.exists(), isTrue);
      expect(await createdFile.length(), greaterThan(0));

      // 4. Validate and extract
      final result = await archiveService.validateAndExtractArchive(
        archiveFile: createdFile,
        stagingDir: stagingDir,
      );

      expect(result.isValid, isTrue);
      expect(result.error, isNull);
      expect(result.manifest, isNotNull);
      expect(result.manifest?.formatVersion, equals(1));
      expect(result.manifest?.databaseSchemaVersion, equals(2));
      expect(result.snapshot, isNotNull);
      expect(result.snapshot?.userProfile?['id'], equals('u1'));
      expect(result.photoFiles.length, equals(1));
      expect(await result.photoFiles.first.readAsBytes(), equals(dummyPhotoBytes));
      expect(result.warnings, isEmpty);
    });

    test('THREAT-01: Path traversal attempt with ../ is rejected and staging purged', () async {
      // Craft a hostile ZIP with a path traversal entry
      final hostileEntries = [
        ZipEntry(
          path: 'manifest.json',
          data: Uint8List.fromList(utf8.encode('{"formatVersion":1}')),
        ),
        ZipEntry(
          path: 'data.json',
          data: Uint8List.fromList(utf8.encode('{}')),
        ),
        ZipEntry(
          path: '../outside_file.txt',
          data: Uint8List.fromList(utf8.encode('MALICIOUS_PAYLOAD')),
        ),
      ];

      final hostileArchiveBytes = ZipCodec.encode(hostileEntries);
      final hostileArchiveFile = File('${tempDir.path}/hostile_traversal.homesets');
      await hostileArchiveFile.writeAsBytes(hostileArchiveBytes);

      final result = await archiveService.validateAndExtractArchive(
        archiveFile: hostileArchiveFile,
        stagingDir: stagingDir,
      );

      expect(result.isValid, isFalse);
      expect(result.error, contains('Path traversal attempt'));

      // Verify that malicious file was not written outside staging
      final outsideFile = File('${tempDir.path}/outside_file.txt');
      expect(await outsideFile.exists(), isFalse);
    });

    test('THREAT-01: Unauthorized entry path is rejected', () async {
      final hostileEntries = [
        ZipEntry(
          path: 'manifest.json',
          data: Uint8List.fromList(utf8.encode('{"formatVersion":1}')),
        ),
        ZipEntry(
          path: 'data.json',
          data: Uint8List.fromList(utf8.encode('{}')),
        ),
        ZipEntry(
          path: 'system/app.apk',
          data: Uint8List.fromList([1, 2, 3]),
        ),
      ];

      final hostileArchiveFile = File('${tempDir.path}/hostile_system.homesets');
      await hostileArchiveFile.writeAsBytes(ZipCodec.encode(hostileEntries));

      final result = await archiveService.validateAndExtractArchive(
        archiveFile: hostileArchiveFile,
        stagingDir: stagingDir,
      );

      expect(result.isValid, isFalse);
      expect(result.error, contains('Unauthorized or unexpected file in backup'));
    });

    test('THREAT-03: Tampered data.json checksum triggers rejection', () async {
      const snapshot = HomesetsDataSnapshot(
        workoutSessions: [],
        setLogs: [],
        salvageArchives: [],
        weightEntries: [],
        progressPhotos: [],
        dailyMealChecks: [],
      );

      final archivePath = '${tempDir.path}/tampered_checksum.homesets';
      final file = await archiveService.createBackupArchive(
        snapshot: snapshot,
        photoFiles: [],
        outputFilePath: archivePath,
      );

      // Decode the valid archive and alter data.json without changing manifest checksum
      final entries = ZipCodec.decode(await file.readAsBytes());
      final tamperedEntries = entries.map((e) {
        if (e.path == 'data.json') {
          return ZipEntry(
            path: 'data.json',
            data: Uint8List.fromList(utf8.encode('{"tampered": true}')),
          );
        }
        return e;
      }).toList();

      await file.writeAsBytes(ZipCodec.encode(tamperedEntries));

      final result = await archiveService.validateAndExtractArchive(
        archiveFile: file,
        stagingDir: stagingDir,
      );

      expect(result.isValid, isFalse);
      expect(result.error, contains('Data snapshot checksum verification failed'));
    });

    test('THREAT-04: Higher formatVersion fails closed', () async {
      final manifest = BackupManifest(
        formatVersion: 99, // Future unsupported version
        appVersion: '9.9.9',
        databaseSchemaVersion: 2,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        devicePlatform: 'android',
        dataSnapshotChecksum: hashProvider.computeChecksum(utf8.encode('{}')),
        recordCounts: const {},
        files: const [],
        totalFilesCount: 0,
        totalUncompressedBytes: 2,
      );

      final entries = [
        ZipEntry(path: 'manifest.json', data: Uint8List.fromList(utf8.encode(jsonEncode(manifest.toJson())))),
        ZipEntry(path: 'data.json', data: Uint8List.fromList(utf8.encode('{}'))),
      ];

      final file = File('${tempDir.path}/future_version.homesets');
      await file.writeAsBytes(ZipCodec.encode(entries));

      final result = await archiveService.validateAndExtractArchive(
        archiveFile: file,
        stagingDir: stagingDir,
      );

      expect(result.isValid, isFalse);
      expect(result.error, contains('format version (99)'));
    });

    test('THREAT-05: Missing referenced photo throws BackupValidationException on export', () async {
      const snapshot = HomesetsDataSnapshot(
        workoutSessions: [],
        setLogs: [],
        salvageArchives: [],
        weightEntries: [],
        progressPhotos: [
          {
            'id': 'photo_missing_1',
            'file_path': 'progress_photos/non_existent.jpg',
            'pose': 'back',
            'logged_at': '2026-11-21T10:00:00.000Z',
          },
        ],
        dailyMealChecks: [],
      );

      final archivePath = '${tempDir.path}/missing_photo.homesets';
      expect(
        () => archiveService.createBackupArchive(
          snapshot: snapshot,
          photoFiles: [], // Photo not included in archive
          outputFilePath: archivePath,
        ),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('BackupStagingManager two-phase restore rolls back photos when DB restore fails', () async {
      final appDocsDir = Directory('${tempDir.path}/app_docs');
      await appDocsDir.create(recursive: true);

      final stagingManager = BackupStagingManager(appDocsDir: appDocsDir);

      // Create existing active photos
      await stagingManager.photosDir.create(recursive: true);
      final existingPhoto = File('${stagingManager.photosDir.path}/existing_p1.jpg');
      await existingPhoto.writeAsString('ORIGINAL_PHOTO_CONTENT');

      // Create staged incoming photos
      final stagingIncomingDir = await stagingManager.prepareImportStaging();
      final incomingPhoto = File('${stagingIncomingDir.path}/incoming_p2.jpg');
      await incomingPhoto.writeAsString('INCOMING_PHOTO_CONTENT');

      // Execute restore where DB operation fails
      await expectLater(
        () => stagingManager.executeTwoPhaseRestore(
          snapshot: const HomesetsDataSnapshot(
            workoutSessions: [],
            setLogs: [],
            salvageArchives: [],
            weightEntries: [],
            progressPhotos: [],
            dailyMealChecks: [],
          ),
          stagedPhotos: [incomingPhoto],
          onDbRestore: () async {
            throw Exception('Simulated SQLite Transaction Failure');
          },
        ),
        throwsA(isA<BackupRestoreException>()),
      );

      // Verify that original photo was restored cleanly
      expect(await existingPhoto.exists(), isTrue);
      expect(await existingPhoto.readAsString(), equals('ORIGINAL_PHOTO_CONTENT'));

      // Verify that incoming photo was not left in photosDir
      final leakedPhoto = File('${stagingManager.photosDir.path}/incoming_p2.jpg');
      expect(await leakedPhoto.exists(), isFalse);

      // Verify rollback directory was cleaned
      expect(await stagingManager.photosBackupDir.exists(), isFalse);
    });
  });
}
