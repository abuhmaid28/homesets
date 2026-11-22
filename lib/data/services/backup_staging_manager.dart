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

  static const Set<String> validJournalPhases = {
    'PREPARING',
    'ORIGINAL_PHOTOS_MOVED',
    'NEW_PHOTOS_STAGED',
    'DB_COMMITTED',
    'ROLLBACK_FAILED',
    'TOKEN_VERIFY_FAILED',
    'PHOTOS_PRESERVED',
  };

  /// Resolves a photo path from SQLite against the app documents / photos directory.
  File _resolvePhotoFile(String filePath) {
    if (filePath.startsWith('progress_photos/') || filePath.startsWith(r'progress_photos\')) {
      final f = File('${appDocsDir.path}/$filePath');
      if (f.existsSync()) return f;
    }
    final filename = filePath.split(RegExp(r'[/\\]')).last;
    final inPhotos = File('${photosDir.path}/$filename');
    if (inPhotos.existsSync()) return inPhotos;

    final direct = File(filePath);
    if (direct.isAbsolute && direct.existsSync()) return direct;

    return inPhotos;
  }

  /// Validates that all committed photo records in SQLite are present on disk in [photosDir]
  /// and are non-empty files (P6-EXIT-01).
  Future<bool> validateActivePhotos(WorkoutRepository repository) async {
    final photoRecords = await repository.getProgressPhotos();
    if (photoRecords.isEmpty) {
      return true;
    }
    if (!await photosDir.exists()) {
      return false;
    }
    for (final photo in photoRecords) {
      final file = _resolvePhotoFile(photo.filePath);
      if (!await file.exists()) {
        return false;
      }
      final length = await file.length();
      if (length <= 0) {
        return false;
      }
    }
    return true;
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
          // P6-LAST-01: Corrupted or torn journal JSON.
          // DO NOT delete either photo generation (progress_photos/ or progress_photos_rollback/)!
          // DO NOT delete the journal!
          // Preserve forensic diagnostics and fail closed.
          return RestoreRecoveryResult.failure(
            'Corrupted or torn restore journal found ($e). Recovery aborted to prevent data loss. Both photo generations preserved.',
          );
        }

        // Strict field type and value validation (P6-CLOSE-02)
        final rawToken = data['restoreToken'];
        final rawPhase = data['phase'];
        final rawHadPhotos = data['hadOriginalPhotos'];

        if (rawToken is! String ||
            rawToken.trim().isEmpty ||
            rawPhase is! String ||
            !validJournalPhases.contains(rawPhase) ||
            rawHadPhotos is! bool) {
          return RestoreRecoveryResult.failure(
            'Malformed or invalid restore journal fields (restoreToken="$rawToken", phase="$rawPhase", hadOriginalPhotos=$rawHadPhotos). '
            'Recovery aborted to prevent data loss. Both photo generations preserved.',
          );
        }

        final restoreToken = rawToken.trim();
        final phase = rawPhase;
        final hadOriginalPhotos = rawHadPhotos;

        if (repository == null) {
          // Cannot verify SQLite restore token without repository! Fail closed.
          return RestoreRecoveryResult.failure(
            'WorkoutRepository is required to verify restore token for recovery. Both photo generations preserved.',
          );
        }

        String? currentDbToken;
        try {
          currentDbToken = await repository.getCurrentRestoreToken();
        } catch (e) {
          // P6-LAST-02: SQLite query failed (database locked, disk error, etc.)
          // We CANNOT determine whether DB committed or not!
          // MUST NOT assume not committed and MUST NOT roll back photos!
          // Return failure to trigger retry, preserving both generations and journal.
          return RestoreRecoveryResult.failure(
            'Failed to read SQLite restore token ($e). Recovery aborted to prevent data loss.',
          );
        }

        final dbMatches = currentDbToken != null && currentDbToken == restoreToken;

        if (dbMatches) {
          // SQLite HAS committed this exact restore generation.
          // P6-EXIT-01: Must validate that active photos are complete before deleting rollback photos!
          final photosComplete = await validateActivePhotos(repository);
          if (!photosComplete) {
            return RestoreRecoveryResult.failure(
              'Committed restore token matches, but active photo generation is missing, incomplete, or corrupted. '
              'Recovery aborted to prevent data loss. Both photo generations and recovery journal preserved.',
            );
          }

          // Finalize new photos by purging rollback directory.
          if (await photosBackupDir.exists()) {
            await photosBackupDir.delete(recursive: true);
          }
          await cleanStaging();
          if (await journalFile.exists()) {
            await journalFile.delete();
          }
          return RestoreRecoveryResult.success(action: 'finalized');
        }

        // SQLite does NOT match restoreToken (currentDbToken != restoreToken)
        if (phase == 'DB_COMMITTED') {
          // CRITICAL DISCREPANCY (P6-CLOSE-02): Journal claims DB_COMMITTED, but SQLite does not match!
          // Under NO circumstances delete old photos without SQLite corroboration.
          return RestoreRecoveryResult.failure(
            'Journal claims DB_COMMITTED but SQLite token does not match (expected "$restoreToken", got "$currentDbToken"). '
            'Recovery aborted to prevent data loss. Both photo generations preserved.',
          );
        }

        // Crash occurred before SQLite commit (PREPARING, ORIGINAL_PHOTOS_MOVED, NEW_PHOTOS_STAGED, PHOTOS_PRESERVED, ROLLBACK_FAILED, TOKEN_VERIFY_FAILED).
        // Roll back photos safely to restore original state.
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
        } else if (!hadOriginalPhotos) {
          // Fresh install with no original photos: delete uncommitted staged photos
          if (await photosDir.exists()) {
            await photosDir.delete(recursive: true);
          }
        } else if (phase == 'PREPARING') {
          // Original photos were never moved from photosDir and are intact
        } else {
          return RestoreRecoveryResult.failure(
            'Missing rollback directory for interrupted restore phase "$phase". Recovery aborted to prevent data loss.',
          );
        }

        await cleanStaging();
        if (await journalFile.exists()) {
          await journalFile.delete();
        }
        return RestoreRecoveryResult.success(action: 'rolled_back');
      } else if (await photosBackupDir.exists()) {
        if (!await photosDir.exists()) {
          await _restoreBackupDir();
          return RestoreRecoveryResult.success(action: 'rolled_back');
        } else {
          // P6-LAST-01C: Found orphaned rollback photos without recovery journal while photos directory also exists!
          // DO NOT delete photosBackupDir silently!
          return RestoreRecoveryResult.failure(
            'Found orphaned rollback photos without recovery journal while photos directory also exists. Both generations preserved.',
          );
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

      // Step 6: Success - validate active photos before purging rollback backup directory and journal (P6-EXIT-01)
      if (repository != null) {
        final photosComplete = await validateActivePhotos(repository);
        if (!photosComplete) {
          throw const BackupRestoreException(
            'Restore completed SQLite commit, but active photo files validation failed. '
            'Preserving rollback photos and journal for recovery.',
          );
        }
      }
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
      var tokenCheckFailed = false;
      if (repository != null) {
        try {
          final currentToken = await repository.getCurrentRestoreToken();
          dbCommitted = currentToken == restoreToken;
        } catch (_) {
          tokenCheckFailed = true;
        }
      }

      if (tokenCheckFailed) {
        // P6-LAST-02: SQLite token lookup failed during restore error handling.
        // DO NOT roll back or delete photos when status is uncertain!
        // Preserve both generations and journal for startup recovery retry.
        try {
          await journalFile.writeAsString(
            jsonEncode({
              'restoreToken': restoreToken,
              'phase': 'TOKEN_VERIFY_FAILED',
              'hadOriginalPhotos': hadOriginalPhotos,
              'lastError': e.toString(),
              'timestamp': DateTime.now().toUtc().toIso8601String(),
            }),
            flush: true,
          );
        } catch (_) {}
        throw BackupRestoreException(
          'Failed to restore backup and SQLite token verification threw an error. Both photo generations preserved.',
          e,
        );
      }

      if (dbCommitted) {
        // SQLite verified commit: finalize new photos only if active photos are complete
        try {
          if (repository != null && await validateActivePhotos(repository)) {
            if (hadOriginalPhotos && await photosBackupDir.exists()) {
              await photosBackupDir.delete(recursive: true);
            }
            await cleanStaging();
            if (await journalFile.exists()) {
              await journalFile.delete();
            }
          }
        } catch (_) {}
        return;
      }

      if (phase == 'DB_COMMITTED' && !dbCommitted) {
        // Discrepancy: phase reached DB_COMMITTED but SQLite token verification failed.
        // Preserve both generations!
        throw BackupRestoreException(
          'Restore failed: Journal phase reached DB_COMMITTED but SQLite token does not match. Both photo generations preserved.',
          e,
        );
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
