import 'dart:convert';
import 'dart:io';
import 'package:homesets/data/repositories/workout_repository.dart';
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
/// Implements a verifiable two-resource crash protocol across SQLite and filesystem (P6-FINAL-01, P6-FINAL-02, P6-FINAL-04).
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
  /// Cross-verifies the database restore token before deciding whether to roll back or finalize photos.
  Future<RestoreRecoveryResult> recoverPendingJournal({
    WorkoutRepository? repository,
  }) async {
    try {
      if (await journalFile.exists()) {
        Map<String, dynamic> data;
        try {
          final content = await journalFile.readAsString();
          data = jsonDecode(content) as Map<String, dynamic>;
        } catch (e) {
          // Corrupted journal JSON
          if (await photosBackupDir.exists() && !await photosDir.exists()) {
            await _restoreBackupDir();
          }
          await cleanStaging();
          if (await journalFile.exists()) {
            await journalFile.delete();
          }
          return RestoreRecoveryResult.success(action: 'recovered_corrupted_journal');
        }

        final restoreToken = data['restoreToken'] as String? ?? '';
        final phase = data['phase'] as String? ?? '';
        final hadOriginalPhotos = data['hadOriginalPhotos'] as bool? ?? true;

        String? currentDbToken;
        if (repository != null) {
          try {
            currentDbToken = await repository.getCurrentRestoreToken();
          } catch (_) {}
        }

        // DB is committed if the restoreToken matches in SQLite or phase was DB_COMMITTED
        final dbCommitted = (restoreToken.isNotEmpty && currentDbToken == restoreToken) ||
            phase == 'DB_COMMITTED';

        if (dbCommitted) {
          // Crash occurred AFTER DB commit; finalize photos by purging rollback directory
          if (await photosBackupDir.exists()) {
            await photosBackupDir.delete(recursive: true);
          }
          await cleanStaging();
          if (await journalFile.exists()) {
            await journalFile.delete();
          }
          return RestoreRecoveryResult.success(action: 'finalized');
        } else {
          // Crash occurred BEFORE or DURING DB commit; roll back photos to original state
          if (await photosBackupDir.exists()) {
            if (await photosDir.exists()) {
              await photosDir.delete(recursive: true);
            }
            await _restoreBackupDir();
            if (!await photosDir.exists()) {
              return RestoreRecoveryResult.failure(
                'Failed to restore original photos directory during startup recovery',
              );
            }
          } else if (phase != 'PREPARING' && !hadOriginalPhotos) {
            // Fresh install with no original photos: delete uncommitted staged photos
            if (await photosDir.exists()) {
              await photosDir.delete(recursive: true);
            }
          }
          // Note: If photosBackupDir does not exist and phase == 'PREPARING',
          // original photos were never moved from photosDir and are safe untouched.

          await cleanStaging();
          if (await journalFile.exists()) {
            await journalFile.delete();
          }
          return RestoreRecoveryResult.success(action: 'rolled_back');
        }
      } else if (await photosBackupDir.exists()) {
        if (!await photosDir.exists()) {
          await _restoreBackupDir();
          return RestoreRecoveryResult.success(action: 'rolled_back');
        } else {
          await photosBackupDir.delete(recursive: true);
          return RestoreRecoveryResult.success(action: 'cleaned_orphan_backup');
        }
      }
      return RestoreRecoveryResult.none();
    } catch (e) {
      return RestoreRecoveryResult.failure('Startup recovery encountered an error: $e');
    }
  }

  /// Executes a durable restart-safe two-phase restoration of both photo files and SQLite database.
  Future<void> executeTwoPhaseRestore({
    required HomesetsDataSnapshot snapshot,
    required List<File> stagedPhotos,
    required Function onDbRestore,
    WorkoutRepository? repository,
  }) async {
    // 1. Recover any pending journal before starting
    final recovery = await recoverPendingJournal(repository: repository);
    if (recovery.isFailure) {
      throw BackupRestoreException('Cannot start restore: previous recovery failed: ${recovery.error}');
    }

    final restoreToken =
        'restore_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';

    var hadOriginalPhotos = false;
    if (await photosDir.exists()) {
      final list = photosDir.listSync();
      hadOriginalPhotos = list.isNotEmpty;
    }

    var phase = 'INIT';

    // Step 1: Write journal BEFORE moving photos on disk (P6-FINAL-01)
    await journalFile.writeAsString(
      jsonEncode({
        'restoreToken': restoreToken,
        'phase': 'PREPARING',
        'hadOriginalPhotos': hadOriginalPhotos,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }),
      flush: true,
    );
    phase = 'PREPARING';

    try {
      // Step 2: Move original photos into rollback directory
      if (hadOriginalPhotos) {
        if (await photosBackupDir.exists()) {
          await photosBackupDir.delete(recursive: true);
        }
        await photosDir.rename(photosBackupDir.path);
      }
      await journalFile.writeAsString(
        jsonEncode({
          'restoreToken': restoreToken,
          'phase': 'ORIGINAL_PHOTOS_MOVED',
          'hadOriginalPhotos': hadOriginalPhotos,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );
      phase = 'ORIGINAL_PHOTOS_MOVED';

      // Step 3: Copy staged photos to the active photos directory
      await photosDir.create(recursive: true);
      for (final stagedPhoto in stagedPhotos) {
        final filename = stagedPhoto.uri.pathSegments.last;
        final destinationFile = File('${photosDir.path}/$filename');
        await stagedPhoto.copy(destinationFile.path);
      }
      await journalFile.writeAsString(
        jsonEncode({
          'restoreToken': restoreToken,
          'phase': 'NEW_PHOTOS_STAGED',
          'hadOriginalPhotos': hadOriginalPhotos,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );
      phase = 'NEW_PHOTOS_STAGED';

      // Step 4: Execute database transaction with generation restoreToken (P6-FINAL-02)
      if (onDbRestore is Future<void> Function(String)) {
        await onDbRestore(restoreToken);
      } else if (onDbRestore is Future<void> Function()) {
        await onDbRestore();
      } else {
        await (onDbRestore as dynamic)(restoreToken);
      }

      // Step 5: Record DB_COMMITTED in journal
      await journalFile.writeAsString(
        jsonEncode({
          'restoreToken': restoreToken,
          'phase': 'DB_COMMITTED',
          'hadOriginalPhotos': hadOriginalPhotos,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );
      phase = 'DB_COMMITTED';

      // Step 6: Success - purge rollback backup directory and journal
      if (hadOriginalPhotos && await photosBackupDir.exists()) {
        await photosBackupDir.delete(recursive: true);
      }
      await cleanStaging();
      if (await journalFile.exists()) {
        await journalFile.delete();
      }
    } catch (e) {
      // Step 7: Handle failure and roll back safely
      var dbCommitted = false;
      if (repository != null) {
        try {
          final currentToken = await repository.getCurrentRestoreToken();
          dbCommitted = currentToken == restoreToken;
        } catch (_) {}
      }

      if (phase == 'DB_COMMITTED' || dbCommitted) {
        // DB COMMITTED! Do NOT roll back photos; finalize new photos
        try {
          if (hadOriginalPhotos && await photosBackupDir.exists()) {
            await photosBackupDir.delete(recursive: true);
          }
          await cleanStaging();
          if (await journalFile.exists()) {
            await journalFile.delete();
          }
        } catch (_) {}
        return;
      }

      // DB DID NOT COMMIT: Roll back photos to original state
      var rollbackSucceeded = false;
      try {
        if (await photosDir.exists()) {
          await photosDir.delete(recursive: true);
        }
        if (hadOriginalPhotos) {
          if (await photosBackupDir.exists()) {
            await _restoreBackupDir();
            rollbackSucceeded = await photosDir.exists();
          } else {
            rollbackSucceeded = false;
          }
        } else {
          rollbackSucceeded = true;
        }
      } catch (_) {
        rollbackSucceeded = false;
      }

      if (rollbackSucceeded) {
        await cleanStaging();
        if (await journalFile.exists()) {
          await journalFile.delete();
        }
        throw BackupRestoreException('Failed to restore backup, rolled back to original state', e);
      } else {
        // Rollback FAILED: PRESERVE FORENSIC/JOURNAL METADATA (P6-FINAL-04)
        try {
          await journalFile.writeAsString(
            jsonEncode({
              'restoreToken': restoreToken,
              'phase': 'ROLLBACK_FAILED',
              'hadOriginalPhotos': hadOriginalPhotos,
              'lastError': e.toString(),
              'timestamp': DateTime.now().toUtc().toIso8601String(),
            }),
            flush: true,
          );
        } catch (_) {}
        throw BackupRestoreException(
          'Failed to restore backup and rollback encountered errors. Recovery metadata preserved for restart.',
          e,
        );
      }
    }
  }

  Future<void> _restoreBackupDir() async {
    try {
      if (await photosDir.exists()) {
        await photosDir.delete(recursive: true);
      }
      await photosBackupDir.rename(photosDir.path);
    } catch (_) {
      await photosDir.create(recursive: true);
      final entities = photosBackupDir.existsSync() ? photosBackupDir.listSync() : <FileSystemEntity>[];
      for (final entity in entities) {
        if (entity is File) {
          final filename = entity.uri.pathSegments.last;
          await entity.copy('${photosDir.path}/$filename');
        }
      }
      if (await photosBackupDir.exists()) {
        await photosBackupDir.delete(recursive: true);
      }
    }
  }
}
