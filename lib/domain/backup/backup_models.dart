import 'dart:convert';

/// Complete P0-P5 offline data snapshot contract for backup and restore (WP04).
class HomesetsDataSnapshot {
  final Map<String, dynamic>? userProfile;
  final Map<String, dynamic>? equipmentInventory;
  final List<Map<String, dynamic>> workoutSessions;
  final List<Map<String, dynamic>> setLogs;
  final Map<String, dynamic>? activeSessionState;
  final List<Map<String, dynamic>> salvageArchives;
  final List<Map<String, dynamic>> weightEntries;
  final List<Map<String, dynamic>> progressPhotos;
  final List<Map<String, dynamic>> dailyMealChecks;
  final Map<String, dynamic>? reminderSettings;

  const HomesetsDataSnapshot({
    this.userProfile,
    this.equipmentInventory,
    this.workoutSessions = const [],
    this.setLogs = const [],
    this.activeSessionState,
    this.salvageArchives = const [],
    this.weightEntries = const [],
    this.progressPhotos = const [],
    this.dailyMealChecks = const [],
    this.reminderSettings,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_profile': userProfile,
      'equipment_inventory': equipmentInventory,
      'workout_sessions': workoutSessions,
      'set_logs': setLogs,
      'active_session_state': activeSessionState,
      'session_salvage_archive': salvageArchives,
      'weight_entries': weightEntries,
      'progress_photos': progressPhotos,
      'daily_meal_checks': dailyMealChecks,
      'reminder_settings': reminderSettings,
    };
  }

  factory HomesetsDataSnapshot.fromJson(Map<String, dynamic> json) {
    return HomesetsDataSnapshot(
      userProfile: json['user_profile'] as Map<String, dynamic>?,
      equipmentInventory: json['equipment_inventory'] as Map<String, dynamic>?,
      workoutSessions: (json['workout_sessions'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      setLogs: (json['set_logs'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      activeSessionState:
          json['active_session_state'] as Map<String, dynamic>?,
      salvageArchives: (json['session_salvage_archive'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      weightEntries: (json['weight_entries'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      progressPhotos: (json['progress_photos'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      dailyMealChecks: (json['daily_meal_checks'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      reminderSettings: json['reminder_settings'] as Map<String, dynamic>?,
    );
  }

  Map<String, int> computeRecordCounts() {
    return {
      'user_profile': userProfile != null ? 1 : 0,
      'equipment_inventory': equipmentInventory != null ? 1 : 0,
      'workout_sessions': workoutSessions.length,
      'set_logs': setLogs.length,
      'active_session_state': activeSessionState != null ? 1 : 0,
      'session_salvage_archive': salvageArchives.length,
      'weight_entries': weightEntries.length,
      'progress_photos': progressPhotos.length,
      'daily_meal_checks': dailyMealChecks.length,
      'reminder_settings': reminderSettings != null ? 1 : 0,
    };
  }
}

/// Metadata entry for a single physical file bundled in a backup (WP05).
class BackupFileEntry {
  final String relativePath;
  final int byteLength;
  final String sha256;

  const BackupFileEntry({
    required this.relativePath,
    required this.byteLength,
    required this.sha256,
  });

  Map<String, dynamic> toJson() => {
        'relativePath': relativePath,
        'byteLength': byteLength,
        'sha256': sha256,
      };

  factory BackupFileEntry.fromJson(Map<String, dynamic> json) =>
      BackupFileEntry(
        relativePath: json['relativePath'] as String,
        byteLength: json['byteLength'] as int,
        sha256: json['sha256'] as String,
      );
}

/// Root manifest descriptor for the backup archive (WP05).
class BackupManifest {
  static const int currentFormatVersion = 1;
  static const int currentDatabaseSchemaVersion = 2;

  final int formatVersion;
  final String appVersion;
  final int databaseSchemaVersion;
  final String createdAt;
  final String devicePlatform;
  final String dataSnapshotChecksum;
  final Map<String, int> recordCounts;
  final List<BackupFileEntry> files;
  final int totalFilesCount;
  final int totalUncompressedBytes;

  const BackupManifest({
    required this.formatVersion,
    required this.appVersion,
    required this.databaseSchemaVersion,
    required this.createdAt,
    required this.devicePlatform,
    required this.dataSnapshotChecksum,
    required this.recordCounts,
    required this.files,
    required this.totalFilesCount,
    required this.totalUncompressedBytes,
  });

  Map<String, dynamic> toJson() => {
        'formatVersion': formatVersion,
        'appVersion': appVersion,
        'databaseSchemaVersion': databaseSchemaVersion,
        'createdAt': createdAt,
        'devicePlatform': devicePlatform,
        'dataSnapshotChecksum': dataSnapshotChecksum,
        'recordCounts': recordCounts,
        'files': files.map((f) => f.toJson()).toList(),
        'totalFilesCount': totalFilesCount,
        'totalUncompressedBytes': totalUncompressedBytes,
      };

  factory BackupManifest.fromJson(Map<String, dynamic> json) => BackupManifest(
        formatVersion: json['formatVersion'] as int? ?? 1,
        appVersion: json['appVersion'] as String? ?? '1.0.0+1',
        databaseSchemaVersion: json['databaseSchemaVersion'] as int? ?? 2,
        createdAt: json['createdAt'] as String,
        devicePlatform: json['devicePlatform'] as String? ?? 'android',
        dataSnapshotChecksum: json['dataSnapshotChecksum'] as String,
        recordCounts: Map<String, int>.from(json['recordCounts'] as Map),
        files: (json['files'] as List<dynamic>?)
                ?.map((e) => BackupFileEntry.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        totalFilesCount: json['totalFilesCount'] as int? ?? 0,
        totalUncompressedBytes: json['totalUncompressedBytes'] as int? ?? 0,
      );

  String serialize() => const JsonEncoder.withIndent('  ').convert(toJson());
}
