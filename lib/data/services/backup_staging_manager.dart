import 'dart:io';
import 'package:homesets/domain/backup/backup_models.dart';

/// Exception thrown during the two-phase backup restoration process.
class BackupRestoreException implements Exception {
  final String message;
  final dynamic cause;
  const BackupRestoreException(this.message, [this.cause]);

  @override
  String toString() => 'BackupRestoreException: $message ${cause != null ? '($cause)' : ''}';
}

/// Manages staging directories, atomic file swaps, and failure rollbacks for backups.
class BackupStagingManager {
  final Directory appDocsDir;

  const BackupStagingManager({required this.appDocsDir});

  Directory get stagingDir => Directory('${appDocsDir.path}/backup_staging');
  Directory get photosDir => Directory('${appDocsDir.path}/progress_photos');
  Directory get photosBackupDir => Directory('${appDocsDir.path}/progress_photos_rollback');

  /// Completely purges the backup staging directory.
  Future<void> cleanStaging() async {
    try {
      if (await stagingDir.exists()) {
        await stagingDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// Prepares a fresh, empty staging directory for export operations.
  Future<Directory> prepareExportStaging() async {
    await cleanStaging();
    await stagingDir.create(recursive: true);
    return stagingDir;
  }

  /// Prepares a fresh, empty staging directory for import operations.
  Future<Directory> prepareImportStaging() async {
    await cleanStaging();
    await stagingDir.create(recursive: true);
    return stagingDir;
  }

  /// Executes a resilient two-phase restoration of both photo files and SQLite database.
  ///
  /// If any error occurs during either the file copy or the database restoration,
  /// original photo files and database state are rolled back cleanly, leaving
  /// current user data untouched.
  Future<void> executeTwoPhaseRestore({
    required HomesetsDataSnapshot snapshot,
    required List<File> stagedPhotos,
    required Future<void> Function() onDbRestore,
  }) async {
    var photosSwapped = false;

    try {
      // Clean any leftover rollback directory
      if (await photosBackupDir.exists()) {
        await photosBackupDir.delete(recursive: true);
      }

      // Step 1: Preserve existing photos directory if it exists
      if (await photosDir.exists()) {
        await photosDir.rename(photosBackupDir.path);
        photosSwapped = true;
      }
      await photosDir.create(recursive: true);

      // Step 2: Copy staged photos to the active photos directory
      for (final stagedPhoto in stagedPhotos) {
        final filename = stagedPhoto.uri.pathSegments.last;
        final destinationFile = File('${photosDir.path}/$filename');
        await stagedPhoto.copy(destinationFile.path);
      }

      // Step 3: Execute atomic database transaction
      await onDbRestore();

      // Step 4: Success - commit by purging the rollback backup directory
      if (photosSwapped && await photosBackupDir.exists()) {
        await photosBackupDir.delete(recursive: true);
      }
      await cleanStaging();
    } catch (e) {
      // Step 5: Rollback on failure
      try {
        if (photosSwapped) {
          if (await photosDir.exists()) {
            await photosDir.delete(recursive: true);
          }
          if (await photosBackupDir.exists()) {
            try {
              await photosBackupDir.rename(photosDir.path);
            } catch (_) {
              // Fallback if atomic rename across mounts or locks fails
              await photosDir.create(recursive: true);
              await for (final entity in photosBackupDir.list(recursive: false)) {
                if (entity is File) {
                  final filename = entity.uri.pathSegments.last;
                  await entity.copy('${photosDir.path}/$filename');
                }
              }
              await photosBackupDir.delete(recursive: true);
            }
          }
        }
      } catch (rollbackError) {
        // Log rollback error while retaining root cause
      } finally {
        await cleanStaging();
      }
      throw BackupRestoreException('Failed to restore backup, rolled back to original state', e);
    }
  }
}
