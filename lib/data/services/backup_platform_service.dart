import 'package:flutter/services.dart';

/// Platform interface for SAF-based backup file export and import.
abstract class BackupPlatformService {
  Future<bool> exportBackupFile({
    required String stagedFilePath,
    required String suggestedFileName,
  });

  Future<String?> pickBackupFile({
    required String targetStagingPath,
  });
}

/// Android native implementation using Storage Access Framework (SAF).
class AndroidBackupPlatformService implements BackupPlatformService {
  static const MethodChannel _channel = MethodChannel('com.abuhmaid.homesets/backup');

  const AndroidBackupPlatformService();

  @override
  Future<bool> exportBackupFile({
    required String stagedFilePath,
    required String suggestedFileName,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('exportBackup', {
        'stagedFilePath': stagedFilePath,
        'suggestedFileName': suggestedFileName,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<String?> pickBackupFile({
    required String targetStagingPath,
  }) async {
    try {
      return await _channel.invokeMethod<String>('importBackup', {
        'targetStagingPath': targetStagingPath,
      });
    } on PlatformException {
      return null;
    }
  }
}

/// In-memory mock platform service for tests and non-Android environments.
class MockBackupPlatformService implements BackupPlatformService {
  bool exportSuccess;
  String? importFilePath;

  MockBackupPlatformService({
    this.exportSuccess = true,
    this.importFilePath,
  });

  @override
  Future<bool> exportBackupFile({
    required String stagedFilePath,
    required String suggestedFileName,
  }) async {
    return exportSuccess;
  }

  @override
  Future<String?> pickBackupFile({
    required String targetStagingPath,
  }) async {
    return importFilePath;
  }
}
