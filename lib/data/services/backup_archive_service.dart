import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:homesets/data/services/backup_hash_provider.dart';
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
class BackupArchiveService {
  static const int maxArchiveBytes = 250 * 1024 * 1024; // 250 MB
  static const int maxUncompressedBytes = 500 * 1024 * 1024; // 500 MB
  static const int maxFileCount = 1000;
  static const int supportedFormatVersion = 1;
  static const int currentDatabaseSchemaVersion = 2;

  final BackupHashProvider hashProvider;

  static final RegExp _validPhotoPathPattern = RegExp(r'^progress_photos/[a-zA-Z0-9_\-]+\.jpg$');

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
    // 1. Serialize Data Snapshot to JSON
    final snapshotJson = jsonEncode(snapshot.toJson());
    final snapshotBytes = utf8.encode(snapshotJson);
    final snapshotChecksum = hashProvider.computeChecksum(snapshotBytes);

    // 2. Read and hash photo files
    final fileEntries = <BackupFileEntry>[];
    final zipEntries = <ZipEntry>[];
    var totalBytes = snapshotBytes.length;

    for (final photoFile in photoFiles) {
      if (!await photoFile.exists()) {
        continue;
      }
      final rawPhotoBytes = await photoFile.readAsBytes();
      final filename = photoFile.uri.pathSegments.last;
      final relPath = 'progress_photos/$filename';
      final photoHash = hashProvider.computeChecksum(rawPhotoBytes);

      fileEntries.add(BackupFileEntry(
        relativePath: relPath,
        byteLength: rawPhotoBytes.length,
        sha256: photoHash,
      ));

      zipEntries.add(ZipEntry(
        path: relPath,
        data: rawPhotoBytes,
      ));

      totalBytes += rawPhotoBytes.length;
    }

    // 3. Create Manifest
    final manifest = BackupManifest(
      formatVersion: supportedFormatVersion,
      appVersion: appVersion,
      databaseSchemaVersion: currentDatabaseSchemaVersion,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      devicePlatform: devicePlatform,
      dataSnapshotChecksum: snapshotChecksum,
      recordCounts: snapshot.computeRecordCounts(),
      files: fileEntries,
      totalFilesCount: fileEntries.length,
      totalUncompressedBytes: totalBytes,
    );

    final manifestJson = jsonEncode(manifest.toJson());
    final manifestBytes = utf8.encode(manifestJson);

    // Add manifest and data.json as first entries
    zipEntries.insert(0, ZipEntry(
      path: 'manifest.json',
      data: Uint8List.fromList(manifestBytes),
    ));
    zipEntries.insert(1, ZipEntry(
      path: 'data.json',
      data: Uint8List.fromList(snapshotBytes),
    ));

    // 4. Encode ZIP container
    final archiveBytes = ZipCodec.encode(zipEntries, compress: true);

    if (archiveBytes.length > maxArchiveBytes) {
      throw BackupSecurityException(
        'Created archive exceeds maximum size limit ($maxArchiveBytes bytes): ${archiveBytes.length} bytes',
      );
    }

    final outFile = File(outputFilePath);
    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(archiveBytes, flush: true);
    return outFile;
  }

  /// Unpacks and rigorously validates a `.homesets` archive file into [stagingDir].
  ///
  /// Enforces THREAT-01 (Path Traversal), THREAT-02 (Decompression Bomb),
  /// THREAT-03 (Checksum Tampering), THREAT-04 (Schema Incompatibility),
  /// and THREAT-05 (Dangling Photo References).
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

      // 2. Decode ZIP archive container
      final archiveBytes = await archiveFile.readAsBytes();
      List<ZipEntry> entries;
      try {
        entries = ZipCodec.decode(archiveBytes);
      } catch (e) {
        return BackupValidationResult.failure('Corrupt or invalid backup container format: $e');
      }

      // 3. Enforce member file count (THREAT-02)
      if (entries.length > maxFileCount) {
        return BackupValidationResult.failure(
          'Archive contains too many files ($maxFileCount max): ${entries.length}',
        );
      }

      // Clean extract destination
      final extractDir = Directory('${stagingDir.path}/extracted');
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      var cumulativeUncompressedBytes = 0;
      ZipEntry? manifestEntry;
      ZipEntry? dataEntry;
      final extractedPhotos = <File>[];

      // 4. Validate each member path and byte budget (THREAT-01, THREAT-02)
      for (final entry in entries) {
        final path = entry.path;

        // Path Traversal Defenses: reject `..`, `\`, leading `/`, drive letters
        if (path.contains('..') ||
            path.contains('\\') ||
            path.startsWith('/') ||
            path.contains(':')) {
          await _purgeDirectory(extractDir);
          throw BackupSecurityException('Path traversal attempt detected in entry: $path');
        }

        // Whitelist check: only manifest.json, data.json, or progress_photos/<id>.jpg
        final isManifest = path == 'manifest.json';
        final isData = path == 'data.json';
        final isPhoto = _validPhotoPathPattern.hasMatch(path);

        if (!isManifest && !isData && !isPhoto) {
          await _purgeDirectory(extractDir);
          throw BackupSecurityException('Unauthorized or unexpected file in backup: $path');
        }

        cumulativeUncompressedBytes += entry.data.length;
        if (cumulativeUncompressedBytes > maxUncompressedBytes) {
          await _purgeDirectory(extractDir);
          throw BackupSecurityException(
            'Decompression bomb defense triggered: uncompressed size exceeds limit ($maxUncompressedBytes bytes)',
          );
        }

        // Write file to isolated staging
        final targetFile = File('${extractDir.path}/$path');
        await targetFile.parent.create(recursive: true);
        await targetFile.writeAsBytes(entry.data, flush: true);

        if (isManifest) manifestEntry = entry;
        if (isData) dataEntry = entry;
        if (isPhoto) extractedPhotos.add(targetFile);
      }

      if (manifestEntry == null) {
        await _purgeDirectory(extractDir);
        return BackupValidationResult.failure('Archive is missing manifest.json');
      }
      if (dataEntry == null) {
        await _purgeDirectory(extractDir);
        return BackupValidationResult.failure('Archive is missing data.json');
      }

      // 5. Parse and validate manifest (THREAT-04)
      BackupManifest manifest;
      try {
        final manifestMap = jsonDecode(utf8.decode(manifestEntry.data)) as Map<String, dynamic>;
        manifest = BackupManifest.fromJson(manifestMap);
      } catch (e) {
        await _purgeDirectory(extractDir);
        return BackupValidationResult.failure('Invalid manifest.json content: $e');
      }

      if (manifest.formatVersion > supportedFormatVersion) {
        await _purgeDirectory(extractDir);
        return BackupValidationResult.failure(
          'Backup format version (${manifest.formatVersion}) is newer than supported ($supportedFormatVersion). Please update HOMESETS.',
        );
      }

      if (manifest.databaseSchemaVersion > currentDatabaseSchemaVersion) {
        await _purgeDirectory(extractDir);
        return BackupValidationResult.failure(
          'Database schema version (${manifest.databaseSchemaVersion}) is newer than supported ($currentDatabaseSchemaVersion). Please update HOMESETS.',
        );
      }

      // 6. Verify checksum of data.json (THREAT-03)
      final actualDataChecksum = hashProvider.computeChecksum(dataEntry.data);
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

        final photoBytes = await photoFile.readAsBytes();
        final actualHash = hashProvider.computeChecksum(photoBytes);
        if (actualHash != expectedMeta.sha256) {
          await _purgeDirectory(extractDir);
          return BackupValidationResult.failure(
            'Photo file checksum mismatch for $relPath: file may be corrupted',
          );
        }
      }

      // 8. Parse Data Snapshot & Check Referential Integrity (THREAT-05)
      HomesetsDataSnapshot snapshot;
      try {
        final snapshotMap = jsonDecode(utf8.decode(dataEntry.data)) as Map<String, dynamic>;
        snapshot = HomesetsDataSnapshot.fromJson(snapshotMap);
      } catch (e) {
        await _purgeDirectory(extractDir);
        return BackupValidationResult.failure('Invalid data.json content: $e');
      }

      final warnings = <String>[];
      final extractedPhotoNames = extractedPhotos.map((f) => f.uri.pathSegments.last).toSet();

      for (final photoEntry in snapshot.progressPhotos) {
        final filePath = photoEntry['file_path'] as String? ?? '';
        final photoId = photoEntry['id'] as String? ?? 'unknown';
        final expectedName = filePath.split('/').last.split('\\').last;
        if (expectedName.isNotEmpty && !extractedPhotoNames.contains(expectedName)) {
          warnings.add('Photo entry $photoId ($expectedName) is missing from archive files');
        }
      }

      return BackupValidationResult(
        isValid: true,
        manifest: manifest,
        snapshot: snapshot,
        photoFiles: extractedPhotos,
        warnings: warnings,
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
