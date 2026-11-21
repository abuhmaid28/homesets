import 'dart:convert';
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

/// Manages staging directories, atomic file swaps, crash journals, and failure rollbacks for backups.
class BackupStagingManager {
  final Directory appDocsDir;

  const BackupStagingManager({required this.appDocsDir});

  Directory get stagingDir => Directory('${appDocsDir.path}/backup_staging');
  Directory get photosDir => Directory('${appDocsDir.path}/progress_photos');
  Directory get photosBackupDir => Directory('${appDocsDir.path}/progress_photos_rollback');
  File get journalFile => File('${appDocsDir.path}/.restore_journal.json');

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

  /// Recovers any pending restoration from a crash or process kill based on the persistent journal.
  Future<bool> recoverPendingJournal() async {
    try {
      if (await journalFile.exists()) {
        final content = await journalFile.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final phase = data['phase'] as String? ?? '';
        final hadOriginalPhotos = data['hadOriginalPhotos'] as bool? ?? true;

        if (phase == 'PHOTOS_PRESERVED') {
          // Crash occurred before DB commit; roll back photos to original state
          if (await photosDir.exists()) {
            await photosDir.delete(recursive: true);
          }
          if (hadOriginalPhotos && await photosBackupDir.exists()) {
            await _restoreBackupDir();
          }
        } else if (phase == 'DB_COMMITTED') {
          // Crash occurred after DB commit; finalize photos by removing backup directory
          if (await photosBackupDir.exists()) {
            await photosBackupDir.delete(recursive: true);
          }
        }

        await cleanStaging();
        if (await journalFile.exists()) {
          await journalFile.delete();
        }
        return true;
      } else if (await photosBackupDir.exists()) {
        if (!await photosDir.exists()) {
          await _restoreBackupDir();
        } else {
          await photosBackupDir.delete(recursive: true);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Executes a durable restart-safe two-phase restoration of both photo files and SQLite database.
  Future<void> executeTwoPhaseRestore({
    required HomesetsDataSnapshot snapshot,
    required List<File> stagedPhotos,
    required Future<void> Function() onDbRestore,
  }) async {
    // 1. Recover any pending journal before starting
    await recoverPendingJournal();

    var hadOriginalPhotos = false;
    if (await photosDir.exists()) {
      final list = await photosDir.list().toList();
      hadOriginalPhotos = list.isNotEmpty;
    }

    var phase = 'INIT';

    try {
      // Step 1: Write journal before modifying photos on disk
      await journalFile.writeAsString(
        jsonEncode({
          'phase': 'PHOTOS_PRESERVED',
          'hadOriginalPhotos': hadOriginalPhotos,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );
      phase = 'PHOTOS_PRESERVED';

      if (hadOriginalPhotos) {
        if (await photosBackupDir.exists()) {
          await photosBackupDir.delete(recursive: true);
        }
        await photosDir.rename(photosBackupDir.path);
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

      // Step 4: Record DB_COMMITTED in journal
      await journalFile.writeAsString(
        jsonEncode({
          'phase': 'DB_COMMITTED',
          'hadOriginalPhotos': hadOriginalPhotos,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );
      phase = 'DB_COMMITTED';

      // Step 5: Success - purge rollback backup directory and journal
      if (hadOriginalPhotos && await photosBackupDir.exists()) {
        await photosBackupDir.delete(recursive: true);
      }
      await cleanStaging();
      if (await journalFile.exists()) {
        await journalFile.delete();
      }
    } catch (e) {
      // Step 6: Rollback on failure
      var rollbackSucceeded = false;
      try {
        if (phase == 'DB_COMMITTED') {
          // DB was already committed; do NOT revert photos
          if (await photosBackupDir.exists()) {
            await photosBackupDir.delete(recursive: true);
          }
          rollbackSucceeded = true;
        } else if (phase == 'PHOTOS_PRESERVED') {
          if (await photosDir.exists()) {
            await photosDir.delete(recursive: true);
          }
          if (hadOriginalPhotos && await photosBackupDir.exists()) {
            await _restoreBackupDir();
            rollbackSucceeded = await photosDir.exists();
          } else if (!hadOriginalPhotos) {
            rollbackSucceeded = true;
          }
        } else {
          rollbackSucceeded = true;
        }
      } catch (_) {
        rollbackSucceeded = false;
      } finally {
        await cleanStaging();
        if (await journalFile.exists()) {
          await journalFile.delete();
        }
      }

      if (!rollbackSucceeded) {
        throw BackupRestoreException('Failed to restore backup and rollback encountered errors', e);
      }
      throw BackupRestoreException('Failed to restore backup, rolled back to original state', e);
    }
  }

  Future<void> _restoreBackupDir() async {
    try {
      await photosBackupDir.rename(photosDir.path);
    } catch (_) {
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
