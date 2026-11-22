import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:homesets/data/database/database_helper.dart';
import 'package:homesets/data/repositories/workout_repository.dart';
import 'package:homesets/domain/backup/backup_models.dart';
import 'package:homesets/domain/models/domain_models.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setCustomFactory(databaseFactoryFfi);
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  group('Data Snapshot & Backup Manifest Tests (WP04, WP05)', () {
    test('HomesetsDataSnapshot serializes and deserializes all 9 P0-P5 tables', () {
      final snapshot = HomesetsDataSnapshot(
        userProfile: {
          'id': 'profile_1',
          'goal': 'hypertrophy',
          'wake_time_minutes': 480,
          'shift_start_minutes': 1200,
          'target_workouts_per_week': 4,
          'avoided_joints': '[]',
          'created_at': '2026-11-21T10:00:00.000Z',
        },
        equipmentInventory: {
          'id': 'equip_1',
          'has_pull_up_bar': 1,
          'has_bands': 1,
          'has_door_anchor': 0,
          'has_sturdy_table': 1,
          'has_parallel_grip': 0,
          'updated_at': '2026-11-21T10:00:00.000Z',
        },
        workoutSessions: [
          {
            'id': 'sess_1',
            'scheduled_session_id': 's1',
            'routine_name': 'Routine A',
            'is_lite_mode': 0,
            'started_at': '2026-11-20T10:00:00.000Z',
            'ended_at': '2026-11-20T11:00:00.000Z',
            'total_duration_seconds': 3600,
            'is_emergency_stopped': 0,
            'emergency_stop_reason': null,
          }
        ],
        setLogs: [
          {
            'id': 'log_1',
            'session_id': 'sess_1',
            'set_index': 1,
            'exercise_id': 'exercise_pullup',
            'performed_reps': 8,
            'band_used': null,
            'exertion': 'targetSweetspot',
            'is_pain_stopped': 0,
            'pain_note': null,
            'completed_at': '2026-11-20T10:15:00.000Z',
          }
        ],
        activeSessionState: {
          'session_id': 'active_1',
          'routine_name': 'Routine B',
          'routine_name_ar': 'تمرين ب',
          'is_lite_mode': 0,
          'started_at': '2026-11-21T11:00:00.000Z',
          'current_exercise_index': 0,
          'current_set_index': 1,
          'completed_sets_json': '[]',
          'active_session_json': '{}',
        },
        salvageArchives: [
          {
            'id': 'salvage_1',
            'session_id': 's_salvage',
            'routine_name': 'Routine A',
            'salvaged_at': '2026-11-19T10:00:00.000Z',
            'parsed_sets_count': 2,
            'has_corrupt_logs': 0,
            'raw_completed_sets_json': '[]',
            'raw_active_session_json': '{}',
          }
        ],
        weightEntries: [
          {
            'id': 'weight_1',
            'weight_kg': 78.5,
            'logged_at': '2026-11-21T08:00:00.000Z',
            'notes': 'Morning weight',
          }
        ],
        progressPhotos: [
          {
            'id': 'photo_1',
            'file_path': 'progress_photos/photo_1.jpg',
            'angle': 'front',
            'taken_at': '2026-11-21T08:30:00.000Z',
            'notes': null,
          }
        ],
        dailyMealChecks: [
          {
            'date': '2026-11-21',
            'meal_slot': 0,
            'is_checked': 1,
          }
        ],
      );

      final json = snapshot.toJson();
      final roundtrip = HomesetsDataSnapshot.fromJson(json);

      expect(roundtrip.userProfile?['id'], equals('profile_1'));
      expect(roundtrip.equipmentInventory?['has_pull_up_bar'], equals(1));
      expect(roundtrip.workoutSessions.length, equals(1));
      expect(roundtrip.setLogs.length, equals(1));
      expect(roundtrip.activeSessionState?['routine_name'], equals('Routine B'));
      expect(roundtrip.salvageArchives.length, equals(1));
      expect(roundtrip.weightEntries.length, equals(1));
      expect(roundtrip.progressPhotos.length, equals(1));
      expect(roundtrip.dailyMealChecks.length, equals(1));

      final counts = roundtrip.computeRecordCounts();
      expect(counts['user_profile'], equals(1));
      expect(counts['workout_sessions'], equals(1));
      expect(counts['set_logs'], equals(1));
      expect(counts['weight_entries'], equals(1));
      expect(counts['progress_photos'], equals(1));
      expect(counts['daily_meal_checks'], equals(1));
    });

    test('BackupManifest serializes and deserializes deterministically', () {
      final manifest = BackupManifest(
        formatVersion: 1,
        appVersion: '1.0.0+1',
        databaseSchemaVersion: 2,
        createdAt: '2026-11-21T18:00:00.000Z',
        devicePlatform: 'android',
        dataSnapshotChecksum: 'abcdef1234567890',
        recordCounts: {
          'user_profile': 1,
          'workout_sessions': 5,
          'progress_photos': 2,
        },
        files: [
          const BackupFileEntry(
            relativePath: 'progress_photos/photo_1.jpg',
            byteLength: 204800,
            sha256: 'deadbeef1234',
          ),
          const BackupFileEntry(
            relativePath: 'progress_photos/photo_2.jpg',
            byteLength: 307200,
            sha256: 'cafebabe5678',
          ),
        ],
        totalFilesCount: 2,
        totalUncompressedBytes: 512000,
      );

      final serialized = manifest.serialize();
      expect(serialized, contains('"formatVersion": 1'));
      expect(serialized, contains('"databaseSchemaVersion": 2'));
      expect(serialized, contains('photo_1.jpg'));

      final json = manifest.toJson();
      final roundtrip = BackupManifest.fromJson(json);

      expect(roundtrip.formatVersion, equals(1));
      expect(roundtrip.databaseSchemaVersion, equals(2));
      expect(roundtrip.files.length, equals(2));
      expect(roundtrip.files[0].relativePath, equals('progress_photos/photo_1.jpg'));
      expect(roundtrip.files[1].byteLength, equals(307200));
      expect(roundtrip.totalUncompressedBytes, equals(512000));
    });

    test('WorkoutRepository createDataSnapshot and restoreDataSnapshot work end-to-end', () async {
      final repo = WorkoutRepository();

      // Seed initial data
      await repo.saveUserProfile(const UserProfile(
        id: 'default',
        goal: 'MUSCLE_BUILDING',
        wakeTimeMinutes: 420,
        shiftStartMinutes: 1080,
        targetWorkoutsPerWeek: 4,
        avoidedJoints: [],
      ));

      await repo.saveEquipmentInventory(const EquipmentInventory(
        hasPullUpBar: true,
        hasBands: true,
        hasDoorAnchor: false,
        hasSturdyTable: true,
        hasParallelGrip: false,
      ));

      await repo.saveWeightEntry(WeightEntry(
        id: 'w_test_1',
        weightKg: 75.0,
        loggedAt: DateTime(2026, 11, 21),
      ));

      await repo.saveMealCheck('2026-11-21', 0, true);

      // Export snapshot
      final snapshot = await repo.createDataSnapshot();
      expect(snapshot.userProfile, isNotNull);
      expect(snapshot.equipmentInventory, isNotNull);
      expect(snapshot.weightEntries.length, equals(1));
      expect(snapshot.dailyMealChecks.length, equals(1));

      // Clear / mutate database
      await repo.saveWeightEntry(WeightEntry(
        id: 'w_test_2',
        weightKg: 85.0,
        loggedAt: DateTime(2026, 11, 22),
      ));
      final modifiedWeights = await repo.getWeightEntries();
      expect(modifiedWeights.length, equals(2));

      // Restore snapshot
      await repo.restoreDataSnapshot(snapshot);

      // Verify state was reverted cleanly to original snapshot
      final restoredWeights = await repo.getWeightEntries();
      expect(restoredWeights.length, equals(1));
      expect(restoredWeights.first.id, equals('w_test_1'));
      expect(restoredWeights.first.weightKg, equals(75.0));

      final restoredProfile = await repo.getUserProfile();
      expect(restoredProfile, isNotNull);
      expect(restoredProfile?.wakeTimeMinutes, equals(420));
    });
  });
}
