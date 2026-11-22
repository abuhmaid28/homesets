import 'dart:convert';
import 'dart:io';
import 'package:homesets/data/services/backup_hash_provider.dart';
import 'package:homesets/data/services/photo_service.dart';
import 'package:homesets/data/services/zip_codec.dart';
import 'package:homesets/domain/backup/backup_models.dart';

/// Exception thrown when a backup archive violates security bounds or formatting constraints.
class BackupSecurityException implements Exception {
  final String message;
  const BackupSecurityException(this.message);

  @override
  String toString() => 'BackupSecurityException: $message';
}

/// Result of validating and extracting a backup archive in staging.
class BackupValidationResult {
  final bool isValid;
  final BackupManifest? manifest;
  final HomesetsDataSnapshot? snapshot;
  final List<File> photoFiles;
  final List<String> warnings;
  final String? error;

  const BackupValidationResult({
    required this.isValid,
    this.manifest,
    this.snapshot,
    this.photoFiles = const [],
    this.warnings = const [],
    this.error,
  });

  factory BackupValidationResult.failure(String error) {
    return BackupValidationResult(
      isValid: false,
      error: error,
    );
  }
}

/// Service handling packaging, unpacking, and hostile-threat validation of `.homesets` backup archives.
/// Employs bounded O(1) buffer streaming to eliminate high memory spikes (P6-FINAL-05).
class BackupArchiveService {
  static const int maxArchiveBytes = 250 * 1024 * 1024; // 250 MB
  static const int maxUncompressedBytes = 500 * 1024 * 1024; // 500 MB
  static const int maxFileCount = 1000;
  static const int supportedFormatVersion = 1;
  static const int currentDatabaseSchemaVersion = 2;

  final BackupHashProvider hashProvider;

  const BackupArchiveService({
    this.hashProvider = const DefaultBackupHashProvider(),
  });

  /// Packages a data snapshot and associated photo files into a `.homesets` archive file.
  Future<File> createBackupArchive({
    required HomesetsDataSnapshot snapshot,
    required List<File> photoFiles,
    required String outputFilePath,
    String appVersion = '1.0.0+1',
    String devicePlatform = 'android',
  }) async {
    final outFile = File(outputFilePath);
    final tempDir = Directory('${outFile.parent.path}/.temp_pkg_${DateTime.now().microsecondsSinceEpoch}');
    await tempDir.create(recursive: true);

    try {
      // P6-EXIT-03: Validate that all snapshot photo paths conform strictly to canonical relative paths
      for (final entry in snapshot.progressPhotos) {
        final filePath = entry['file_path'] as String? ?? '';
        final photoId = entry['id'] as String? ?? 'unknown';
        if (!PhotoService.isValidCanonicalPath(filePath)) {
          throw BackupValidationException(
            'Cannot package archive with non-canonical or unsafe photo path for entry $photoId: "$filePath"',
          );
        }
      }

      // 1. Serialize Data Snapshot to temporary JSON file
      final snapshotJson = jsonEncode(snapshot.toJson());
      final snapshotFile = File('${tempDir.path}/data.json');
      await snapshotFile.writeAsString(snapshotJson, flush: true);

      final snapshotLength = await snapshotFile.length();
      final snapshotChecksum = await hashProvider.computeFileChecksum(snapshotFile);

      // 2. Hash and prepare photo file inputs
      final fileEntries = <BackupFileEntry>[];
      final zipInputs = <ZipFileInput>[];
      var totalBytes = snapshotLength;

      for (final photoFile in photoFiles) {
        if (!await photoFile.exists()) {
          throw BackupValidationException('Missing tracked photo file on disk: ${photoFile.path}');
        }
        final filename = photoFile.uri.pathSegments.last;
        if (!PhotoService.canonicalFilenamePattern.hasMatch(filename)) {
          throw BackupValidationException('Non-canonical photo filename: $filename');
        }
        final relPath = 'progress_photos/$filename';
        if (!PhotoService.isValidCanonicalPath(relPath)) {
          throw BackupValidationException('Non-canonical photo relative path: $relPath');
        }
        final isComplete = await PhotoService.isCompleteImageFile(photoFile);
        if (!isComplete) {
          throw BackupValidationException(
            'Cannot archive invalid, corrupt, or truncated photo file: ${photoFile.path}',
          );
        }

        final photoLength = await photoFile.length();
        final photoHash = await hashProvider.computeFileChecksum(photoFile);

        fileEntries.add(BackupFileEntry(
          relativePath: relPath,
          byteLength: photoLength,
          checksum: photoHash,
        ));

        zipInputs.add(ZipFileInput(
          path: relPath,
          file: photoFile,
        ));

        totalBytes += photoLength;
      }

      if (fileEntries.length != snapshot.progressPhotos.length) {
        throw BackupValidationException(
          'Photo count mismatch: snapshot declares ${snapshot.progressPhotos.length} photos, but ${fileEntries.length} files were provided',
        );
      }

      // 3. Create Manifest file
      final manifest = BackupManifest(
        formatVersion: supportedFormatVersion,
        appVersion: appVersion,
        databaseSchemaVersion: currentDatabaseSchemaVersion,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        devicePlatform: devicePlatform,
        dataSnapshotChecksum: snapshotChecksum,
        checksumAlgorithm: BackupManifest.supportedChecksumAlgorithm,
        recordCounts: snapshot.computeRecordCounts(),
        files: fileEntries,
        totalFilesCount: fileEntries.length,
        totalUncompressedBytes: totalBytes,
      );

      final manifestFile = File('${tempDir.path}/manifest.json');
      await manifestFile.writeAsString(manifest.serialize(), flush: true);

      // Add manifest and data.json as first entries
      zipInputs.insert(0, ZipFileInput(path: 'manifest.json', file: manifestFile));
      zipInputs.insert(1, ZipFileInput(path: 'data.json', file: snapshotFile));

      // 4. Stream ZIP container creation directly to disk (P6-FINAL-05)
      await ZipCodec.createArchiveFileStream(
        outputFile: outFile,
        files: zipInputs,
        maxArchiveBytes: maxArchiveBytes,
      );

      return outFile;
    } finally {
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  /// Unpacks and rigorously validates a `.homesets` archive file into [stagingDir].
  ///
  /// Enforces THREAT-01 (Path Traversal), THREAT-02 (Decompression Bomb),
  /// THREAT-03 (Checksum Tampering), THREAT-04 (Schema Incompatibility),
  /// and THREAT-05 (Dangling Photo References) using streaming extraction (P6-FINAL-05).
  Future<BackupValidationResult> validateAndExtractArchive({
    required File archiveFile,
    required Directory stagingDir,
  }) async {
    try {
      if (!await archiveFile.exists()) {
        return BackupValidationResult.failure('Backup file does not exist: ${archiveFile.path}');
      }

      // 1. Check archive file size (THREAT-02)
      final archiveLength = await archiveFile.length();
      if (archiveLength == 0) {
        return BackupValidationResult.failure('Backup file is empty (0 bytes)');
      }
      if (archiveLength > maxArchiveBytes) {
        return BackupValidationResult.failure(
          'Archive size exceeds maximum allowed ($maxArchiveBytes bytes): $archiveLength bytes',
        );
      }

      // 2. Clean extract destination
      final extractDir = Directory('${stagingDir.path}/extracted');
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      // 3. Stream ZIP archive extraction directly to disk with pre-checked bounds (P6-FINAL-05)
      List<File> extractedFiles;
      try {
        extractedFiles = await ZipCodec.extractArchiveFileStream(
          archiveFile: archiveFile,
          targetDir: extractDir,
          maxFileCount: maxFileCount,
          maxArchiveBytes: maxArchiveBytes,
          maxUncompressedBytes: maxUncompressedBytes,
        );
      } catch (e) {
        return BackupValidationResult.failure('Corrupt or invalid backup container format: $e');
      }

      // 4. Validate all extracted member paths against whitelist (THREAT-01)
      final extractedPhotos = <File>[];
      for (final file in extractedFiles) {
        final relPath = file.path.substring(extractDir.path.length).replaceAll('\\', '/');
        final cleanPath = relPath.startsWith('/') ? relPath.substring(1) : relPath;
        if (cleanPath == 'manifest.json' || cleanPath == 'data.json') continue;

        if (!PhotoService.isValidCanonicalPath(cleanPath)) {
          await _purgeDirectory(extractDir);
          throw BackupSecurityException('Unauthorized or unexpected file in backup: $cleanPath');
        }

        // P6-EXIT-03: Verify image completeness of extracted photo
        final isComplete = await PhotoService.isCompleteImageFile(file);
        if (!isComplete) {
          await _purgeDirectory(extractDir);
          return BackupValidationResult.failure(
            'Extracted photo file is truncated, corrupt, or not a valid image: $cleanPath',
          );
        }

        extractedPhotos.add(file);
      }

      // 5. Verify presence of manifest.json and data.json
      final manifestFile = File('${extractDir.path}/manifest.json');
      final dataFile = File('${extractDir.path}/data.json');

      if (!await manifestFile.exists()) {
        await _purgeDirectory(extractDir);
        return BackupValidationResult.failure('Archive is missing manifest.json');
      }
      if (!await dataFile.exists()) {
        await _purgeDirectory(extractDir);
        return BackupValidationResult.failure('Archive is missing data.json');
      }

      // 6. Parse and validate manifest (THREAT-04)
      BackupManifest manifest;
      try {
        final manifestStr = await manifestFile.readAsString();
        final manifestMap = jsonDecode(manifestStr) as Map<String, dynamic>;
        manifest = BackupManifest.fromJson(manifestMap);
      } catch (e) {
        await _purgeDirectory(extractDir);
        return BackupValidationResult.failure('Invalid manifest.json content: $e');
      }

      if (manifest.formatVersion < 1 || manifest.formatVersion > supportedFormatVersion) {
        await _purgeDirectory(extractDir);
        return BackupValidationResult.failure(
          'Backup format version (${manifest.formatVersion}) is not supported. Supported versions: 1 to $supportedFormatVersion.',
        );
      }

      if (manifest.databaseSchemaVersion < 1 || manifest.databaseSchemaVersion > currentDatabaseSchemaVersion) {
        await _purgeDirectory(extractDir);
        return BackupValidationResult.failure(
          'Database schema version (${manifest.databaseSchemaVersion}) is not supported. Supported versions: 1 to $currentDatabaseSchemaVersion.',
        );
      }

      // Enforce recognized checksum algorithm (P6-FINAL-07)
      if (manifest.checksumAlgorithm != BackupManifest.supportedChecksumAlgorithm) {
        await _purgeDirectory(extractDir);
        return BackupValidationResult.failure(
          'Unsupported checksum algorithm: ${manifest.checksumAlgorithm}. Supported: ${BackupManifest.supportedChecksumAlgorithm}',
        );
      }

      // 6. Verify checksum of data.json (THREAT-03)
      final actualDataChecksum = await hashProvider.computeFileChecksum(dataFile);
      if (actualDataChecksum != manifest.dataSnapshotChecksum) {
        await _purgeDirectory(extractDir);
        return BackupValidationResult.failure(
          'Data snapshot checksum verification failed (data.json has been tampered with or corrupted)',
        );
      }

      // 7. Verify checksums of photos (THREAT-03)
      final manifestFilesByPath = {for (final f in manifest.files) f.relativePath: f};
      for (final photoFile in extractedPhotos) {
        final relPath = 'progress_photos/${photoFile.uri.pathSegments.last}';
        final expectedMeta = manifestFilesByPath[relPath];
        if (expectedMeta == null) {
          await _purgeDirectory(extractDir);
          throw BackupSecurityException('Extracted photo not declared in manifest: $relPath');
        }

        final actualHash = await hashProvider.computeFileChecksum(photoFile);
        if (actualHash != expectedMeta.checksum) {
          await _purgeDirectory(extractDir);
          return BackupValidationResult.failure(
            'Photo file checksum mismatch for $relPath: file may be corrupted',
          );
        }
      }

      // 9. Parse Data Snapshot & Strict Record & Photo Matching (THREAT-05 & P6-R06)
      HomesetsDataSnapshot snapshot;
      try {
        final dataStr = await dataFile.readAsString();
        final snapshotMap = jsonDecode(dataStr) as Map<String, dynamic>;
        snapshot = HomesetsDataSnapshot.fromJson(snapshotMap);
      } catch (e) {
        await _purgeDirectory(extractDir);
        return BackupValidationResult.failure('Invalid data.json content: $e');
      }

      // Strict record count verification
      final actualCounts = snapshot.computeRecordCounts();
      for (final entry in manifest.recordCounts.entries) {
        final actual = actualCounts[entry.key] ?? 0;
        if (actual != entry.value) {
          await _purgeDirectory(extractDir);
          return BackupValidationResult.failure(
            'Record count mismatch for ${entry.key}: manifest declared ${entry.value}, snapshot has $actual',
          );
        }
      }

      // Strict bidirectional photo file verification
      final extractedPhotoNames = extractedPhotos.map((f) => f.uri.pathSegments.last).toSet();
      for (final photoEntry in snapshot.progressPhotos) {
        final filePath = photoEntry['file_path'] as String? ?? '';
        final photoId = photoEntry['id'] as String? ?? 'unknown';

        // P6-EXIT-03: Enforce strict canonical relative path in snapshot
        if (!PhotoService.isValidCanonicalPath(filePath)) {
          await _purgeDirectory(extractDir);
          return BackupValidationResult.failure(
            'Non-canonical or unsafe photo path for entry $photoId: "$filePath". '
            'Must strictly match progress_photos/<id>.(jpg|jpeg) without traversal or absolute paths.',
          );
        }

        final expectedName = filePath.substring('progress_photos/'.length);
        if (!extractedPhotoNames.contains(expectedName)) {
          await _purgeDirectory(extractDir);
          return BackupValidationResult.failure(
            'Referenced photo file for entry $photoId ($expectedName) is missing from archive',
          );
        }
      }

      if (extractedPhotos.length != manifest.files.length) {
        await _purgeDirectory(extractDir);
        return BackupValidationResult.failure(
          'Extracted photo count (${extractedPhotos.length}) does not match manifest file count (${manifest.files.length})',
        );
      }

      if (manifest.files.length != snapshot.progressPhotos.length) {
        await _purgeDirectory(extractDir);
        return BackupValidationResult.failure(
          'Manifest file count (${manifest.files.length}) does not match snapshot photo count (${snapshot.progressPhotos.length})',
        );
      }

      return BackupValidationResult(
        isValid: true,
        manifest: manifest,
        snapshot: snapshot,
        photoFiles: extractedPhotos,
        warnings: const [],
      );
    } catch (e) {
      return BackupValidationResult.failure('Archive validation error: $e');
    }
  }

  Future<void> _purgeDirectory(Directory dir) async {
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
