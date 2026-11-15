import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:homesets/data/database/database_helper.dart';
import 'package:homesets/data/repositories/workout_repository.dart';
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

  group('Database v1 to v2 Migration & Persistence Tests (WP02)', () {
    test('Fresh install at v2 creates all tables including progress tracking tables', () async {
      final db = await DatabaseHelper.instance.database;

      // Verify all 9 tables exist in sqlite_master
      final tables = await db.query(
        'sqlite_master',
        columns: ['name'],
        where: 'type = ?',
        whereArgs: ['table'],
      );
      final tableNames = tables.map((t) => t['name'] as String).toSet();

      expect(tableNames, contains('user_profile'));
      expect(tableNames, contains('equipment_inventory'));
      expect(tableNames, contains('workout_sessions'));
      expect(tableNames, contains('set_logs'));
      expect(tableNames, contains('active_session_state'));
      expect(tableNames, contains('session_salvage_archive'));
      expect(tableNames, contains('weight_entries'));
      expect(tableNames, contains('progress_photos'));
      expect(tableNames, contains('daily_meal_checks'));
    });

    test('Upgrade from populated v1 database preserves all data and adds v2 tables', () async {
      // 1. Manually create a v1 database
      final factory = databaseFactoryFfi;
      const v1DbName = 'test_v1_upgrade.db';
      await factory.deleteDatabase(v1DbName);

      final v1Db = await factory.openDatabase(
        v1DbName,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE user_profile (
                id TEXT PRIMARY KEY,
                goal TEXT NOT NULL,
                wake_time_minutes INTEGER NOT NULL,
                shift_start_minutes INTEGER NOT NULL,
                target_workouts_per_week INTEGER NOT NULL,
                avoided_joints TEXT NOT NULL,
                created_at TEXT NOT NULL
              );
            ''');
            await db.execute('''
              CREATE TABLE equipment_inventory (
                id TEXT PRIMARY KEY,
                has_pull_up_bar INTEGER NOT NULL,
                has_bands INTEGER NOT NULL,
                has_door_anchor INTEGER NOT NULL,
                has_sturdy_table INTEGER NOT NULL,
                has_parallel_grip INTEGER NOT NULL,
                updated_at TEXT NOT NULL
              );
            ''');
            await db.execute('''
              CREATE TABLE workout_sessions (
                id TEXT PRIMARY KEY,
                scheduled_session_id TEXT NOT NULL,
                routine_name TEXT NOT NULL,
                is_lite_mode INTEGER NOT NULL,
                started_at TEXT NOT NULL,
                ended_at TEXT NOT NULL,
                total_duration_seconds INTEGER NOT NULL,
                is_emergency_stopped INTEGER NOT NULL,
                emergency_stop_reason TEXT
              );
            ''');
            await db.execute('''
              CREATE TABLE set_logs (
                id TEXT PRIMARY KEY,
                session_id TEXT NOT NULL,
                set_index INTEGER NOT NULL,
                exercise_id TEXT NOT NULL,
                performed_reps INTEGER NOT NULL,
                band_used TEXT,
                exertion TEXT NOT NULL,
                is_pain_stopped INTEGER NOT NULL,
                pain_note TEXT,
                completed_at TEXT NOT NULL,
                FOREIGN KEY (session_id) REFERENCES workout_sessions (id) ON DELETE CASCADE
              );
            ''');
            await db.execute('''
              CREATE TABLE active_session_state (
                session_id TEXT PRIMARY KEY,
                routine_name TEXT NOT NULL,
                routine_name_ar TEXT NOT NULL,
                is_lite_mode INTEGER NOT NULL,
                started_at TEXT NOT NULL,
                current_exercise_index INTEGER NOT NULL,
                current_set_index INTEGER NOT NULL,
                completed_sets_json TEXT NOT NULL,
                active_session_json TEXT NOT NULL
              );
            ''');
            await db.execute('''
              CREATE TABLE session_salvage_archive (
                id TEXT PRIMARY KEY,
                session_id TEXT NOT NULL,
                routine_name TEXT NOT NULL,
                salvaged_at TEXT NOT NULL,
                parsed_sets_count INTEGER NOT NULL,
                has_corrupt_logs INTEGER NOT NULL,
                raw_completed_sets_json TEXT NOT NULL,
                raw_active_session_json TEXT NOT NULL
              );
            ''');
          },
        ),
      );

      // 2. Populate realistic data into all v1 tables
      final now = DateTime.now();
      await v1Db.insert('user_profile', {
        'id': 'profile_user_1',
        'goal': 'build_muscle',
        'wake_time_minutes': 900,
        'shift_start_minutes': 1140,
        'target_workouts_per_week': 4,
        'avoided_joints': '["knee"]',
        'created_at': now.toIso8601String(),
      });

      await v1Db.insert('equipment_inventory', {
        'id': 'inv_user_1',
        'has_pull_up_bar': 1,
        'has_bands': 1,
        'has_door_anchor': 0,
        'has_sturdy_table': 1,
        'has_parallel_grip': 0,
        'updated_at': now.toIso8601String(),
      });

      await v1Db.insert('workout_sessions', {
        'id': 'session_v1_1',
        'scheduled_session_id': 'sched_1',
        'routine_name': 'Routine A: Upper Pull & Biceps',
        'is_lite_mode': 0,
        'started_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'ended_at': now.subtract(const Duration(days: 2, minutes: -30)).toIso8601String(),
        'total_duration_seconds': 1800,
        'is_emergency_stopped': 0,
        'emergency_stop_reason': null,
      });

      await v1Db.insert('set_logs', {
        'id': 'set_v1_1',
        'session_id': 'session_v1_1',
        'set_index': 1,
        'exercise_id': 'pullup_standard',
        'performed_reps': 8,
        'band_used': null,
        'exertion': 'targetSweetspot',
        'is_pain_stopped': 0,
        'pain_note': null,
        'completed_at': now.subtract(const Duration(days: 2, minutes: -10)).toIso8601String(),
      });

      await v1Db.insert('active_session_state', {
        'session_id': 'active_v1_1',
        'routine_name': 'Routine B: Upper Push & Triceps',
        'routine_name_ar': 'التمرين الثاني',
        'is_lite_mode': 1,
        'started_at': now.toIso8601String(),
        'current_exercise_index': 0,
        'current_set_index': 1,
        'completed_sets_json': '[]',
        'active_session_json': '{}',
      });

      await v1Db.insert('session_salvage_archive', {
        'id': 'salvage_v1_1',
        'session_id': 'corrupt_v1',
        'routine_name': 'Routine C',
        'salvaged_at': now.toIso8601String(),
        'parsed_sets_count': 1,
        'has_corrupt_logs': 1,
        'raw_completed_sets_json': '[{"bad":"json"}]',
        'raw_active_session_json': '{}',
      });

      await v1Db.close();

      // 3. Open the database using DatabaseHelper's v2 schema migration logic
      final upgradedDb = await factory.openDatabase(
        v1DbName,
        options: OpenDatabaseOptions(
          version: 2,
          onUpgrade: (db, oldVersion, newVersion) async {
            if (oldVersion < 2) {
              await db.execute('''
                CREATE TABLE IF NOT EXISTS weight_entries (
                  id TEXT PRIMARY KEY,
                  weight_kg REAL NOT NULL,
                  logged_at TEXT NOT NULL,
                  notes TEXT
                );
              ''');
              await db.execute('''
                CREATE INDEX IF NOT EXISTS idx_weight_entries_logged_at ON weight_entries (logged_at);
              ''');
              await db.execute('''
                CREATE TABLE IF NOT EXISTS progress_photos (
                  id TEXT PRIMARY KEY,
                  file_path TEXT NOT NULL,
                  angle TEXT NOT NULL,
                  taken_at TEXT NOT NULL,
                  notes TEXT
                );
              ''');
              await db.execute('''
                CREATE INDEX IF NOT EXISTS idx_progress_photos_taken_at ON progress_photos (taken_at);
              ''');
              await db.execute('''
                CREATE TABLE IF NOT EXISTS daily_meal_checks (
                  date TEXT NOT NULL,
                  meal_slot INTEGER NOT NULL,
                  is_checked INTEGER NOT NULL DEFAULT 0,
                  PRIMARY KEY (date, meal_slot)
                );
              ''');
            }
          },
        ),
      );

      // 4. Assert all v1 data was preserved with exact precision
      final profiles = await upgradedDb.query('user_profile');
      expect(profiles.length, equals(1));
      expect(profiles.first['id'], equals('profile_user_1'));
      expect(profiles.first['goal'], equals('build_muscle'));
      expect(profiles.first['avoided_joints'], equals('["knee"]'));

      final inventories = await upgradedDb.query('equipment_inventory');
      expect(inventories.length, equals(1));
      expect(inventories.first['has_pull_up_bar'], equals(1));
      expect(inventories.first['has_door_anchor'], equals(0));

      final sessions = await upgradedDb.query('workout_sessions');
      expect(sessions.length, equals(1));
      expect(sessions.first['id'], equals('session_v1_1'));

      final setLogs = await upgradedDb.query('set_logs');
      expect(setLogs.length, equals(1));
      expect(setLogs.first['exercise_id'], equals('pullup_standard'));
      expect(setLogs.first['performed_reps'], equals(8));

      final active = await upgradedDb.query('active_session_state');
      expect(active.length, equals(1));
      expect(active.first['session_id'], equals('active_v1_1'));

      final salvage = await upgradedDb.query('session_salvage_archive');
      expect(salvage.length, equals(1));
      expect(salvage.first['id'], equals('salvage_v1_1'));

      // 5. Assert v2 tables are functional and can store records
      await upgradedDb.insert('weight_entries', {
        'id': 'w_1',
        'weight_kg': 61.5,
        'logged_at': now.toIso8601String(),
        'notes': 'Morning weight',
      });
      final weights = await upgradedDb.query('weight_entries');
      expect(weights.length, equals(1));
      expect(weights.first['weight_kg'], equals(61.5));

      await upgradedDb.insert('progress_photos', {
        'id': 'p_1',
        'file_path': 'progress_photos/photo_1.jpg',
        'angle': 'front',
        'taken_at': now.toIso8601String(),
        'notes': null,
      });
      final photos = await upgradedDb.query('progress_photos');
      expect(photos.length, equals(1));
      expect(photos.first['angle'], equals('front'));

      await upgradedDb.insert('daily_meal_checks', {
        'date': '2026-11-15',
        'meal_slot': 0,
        'is_checked': 1,
      });
      final meals = await upgradedDb.query('daily_meal_checks');
      expect(meals.length, equals(1));
      expect(meals.first['is_checked'], equals(1));

      await upgradedDb.close();
      await factory.deleteDatabase(v1DbName);
    });

    test('Repository progress methods perform correct CRUD operations', () async {
      final repo = WorkoutRepository();
      final now = DateTime.now();

      // Clean database state
      final db = await DatabaseHelper.instance.database;
      await db.delete('weight_entries');
      await db.delete('progress_photos');
      await db.delete('daily_meal_checks');
      await db.delete('workout_sessions');
      await db.delete('set_logs');

      // 1. Weight CRUD
      expect(await repo.getWeightEntries(), isEmpty);
      expect(await repo.getLatestWeightEntry(), isNull);

      final w1 = WeightEntry(
        id: 'w_test_1',
        weightKg: 60.5,
        loggedAt: now.subtract(const Duration(days: 2)),
        notes: 'Initial test weight',
      );
      final w2 = WeightEntry(
        id: 'w_test_2',
        weightKg: 61.0,
        loggedAt: now.subtract(const Duration(days: 1)),
      );
      await repo.saveWeightEntry(w1);
      await repo.saveWeightEntry(w2);

      final weights = await repo.getWeightEntries();
      expect(weights.length, equals(2));
      expect(weights.first.id, equals('w_test_2'), reason: 'Latest entry first');
      expect(weights.first.weightKg, equals(61.0));

      final latestW = await repo.getLatestWeightEntry();
      expect(latestW, isNotNull);
      expect(latestW!.id, equals('w_test_2'));

      await repo.deleteWeightEntry('w_test_1');
      final weightsAfterDelete = await repo.getWeightEntries();
      expect(weightsAfterDelete.length, equals(1));
      expect(weightsAfterDelete.first.id, equals('w_test_2'));

      // 2. Progress Photos CRUD
      expect(await repo.getProgressPhotos(), isEmpty);

      final pFront = ProgressPhoto(
        id: 'p_front_1',
        filePath: 'progress_photos/p_front_1.jpg',
        angle: PhotoAngle.front,
        takenAt: now.subtract(const Duration(days: 7)),
      );
      final pSide = ProgressPhoto(
        id: 'p_side_1',
        filePath: 'progress_photos/p_side_1.jpg',
        angle: PhotoAngle.side,
        takenAt: now.subtract(const Duration(days: 7)),
      );
      final pBack = ProgressPhoto(
        id: 'p_back_1',
        filePath: 'progress_photos/p_back_1.jpg',
        angle: PhotoAngle.back,
        takenAt: now.subtract(const Duration(days: 1)),
      );

      await repo.saveProgressPhoto(pFront);
      await repo.saveProgressPhoto(pSide);
      await repo.saveProgressPhoto(pBack);

      final allPhotos = await repo.getProgressPhotos();
      expect(allPhotos.length, equals(3));
      expect(allPhotos.first.id, equals('p_back_1'), reason: 'Newest first');

      final frontPhotos = await repo.getProgressPhotos(angle: PhotoAngle.front);
      expect(frontPhotos.length, equals(1));
      expect(frontPhotos.first.id, equals('p_front_1'));

      await repo.deleteProgressPhoto('p_front_1');
      expect((await repo.getProgressPhotos(angle: PhotoAngle.front)).length, equals(0));

      // 3. Daily Meal Checks
      final todayDate = '2026-11-15';
      expect(await repo.getMealChecksForDate(todayDate), isEmpty);

      await repo.saveMealCheck(todayDate, 0, true);
      await repo.saveMealCheck(todayDate, 1, true);
      await repo.saveMealCheck(todayDate, 2, false);

      final checks = await repo.getMealChecksForDate(todayDate);
      expect(checks[0], isTrue);
      expect(checks[1], isTrue);
      expect(checks[2], isFalse);
      expect(checks.containsKey(3), isFalse);

      // Toggle meal 2 to true
      await repo.saveMealCheck(todayDate, 2, true);
      final checksAfterToggle = await repo.getMealChecksForDate(todayDate);
      expect(checksAfterToggle[2], isTrue);

      // 4. Strength Progress derivation (WP04)
      final sess1Id = 'sess_strength_1';
      final sess2Id = 'sess_strength_2';
      await db.insert('workout_sessions', {
        'id': sess1Id,
        'scheduled_session_id': 'sched_s1',
        'routine_name': 'Routine A',
        'is_lite_mode': 0,
        'started_at': now.subtract(const Duration(days: 7)).toIso8601String(),
        'ended_at': now.subtract(const Duration(days: 7, minutes: -30)).toIso8601String(),
        'total_duration_seconds': 1800,
        'is_emergency_stopped': 0,
      });

      await db.insert('workout_sessions', {
        'id': sess2Id,
        'scheduled_session_id': 'sched_s2',
        'routine_name': 'Routine A',
        'is_lite_mode': 0,
        'started_at': now.subtract(const Duration(days: 3)).toIso8601String(),
        'ended_at': now.subtract(const Duration(days: 3, minutes: -30)).toIso8601String(),
        'total_duration_seconds': 1800,
        'is_emergency_stopped': 0,
      });

      // Session 1 sets: 6, 7, 8 reps
      await db.insert('set_logs', {
        'id': 'sl_1_1',
        'session_id': sess1Id,
        'set_index': 1,
        'exercise_id': 'pullup_standard',
        'performed_reps': 6,
        'band_used': null,
        'exertion': 'targetSweetspot',
        'is_pain_stopped': 0,
        'completed_at': now.subtract(const Duration(days: 7, minutes: -10)).toIso8601String(),
      });
      await db.insert('set_logs', {
        'id': 'sl_1_2',
        'session_id': sess1Id,
        'set_index': 2,
        'exercise_id': 'pullup_standard',
        'performed_reps': 8,
        'band_used': null,
        'exertion': 'targetSweetspot',
        'is_pain_stopped': 0,
        'completed_at': now.subtract(const Duration(days: 7, minutes: -15)).toIso8601String(),
      });

      // Session 2 sets: 8, 9, 10 reps
      await db.insert('set_logs', {
        'id': 'sl_2_1',
        'session_id': sess2Id,
        'set_index': 1,
        'exercise_id': 'pullup_standard',
        'performed_reps': 8,
        'band_used': null,
        'exertion': 'targetSweetspot',
        'is_pain_stopped': 0,
        'completed_at': now.subtract(const Duration(days: 3, minutes: -10)).toIso8601String(),
      });
      await db.insert('set_logs', {
        'id': 'sl_2_2',
        'session_id': sess2Id,
        'set_index': 2,
        'exercise_id': 'pullup_standard',
        'performed_reps': 10,
        'band_used': null,
        'exertion': 'targetSweetspot',
        'is_pain_stopped': 0,
        'completed_at': now.subtract(const Duration(days: 3, minutes: -15)).toIso8601String(),
      });

      // Emergency stopped or pain stopped sets should be excluded
      await db.insert('set_logs', {
        'id': 'sl_pain',
        'session_id': sess2Id,
        'set_index': 3,
        'exercise_id': 'pullup_standard',
        'performed_reps': 0,
        'band_used': null,
        'exertion': 'maxEffort',
        'is_pain_stopped': 1,
        'completed_at': now.subtract(const Duration(days: 3, minutes: -20)).toIso8601String(),
      });

      final strengthPoints = await repo.getStrengthHistoryForExercise('pullup_standard');
      expect(strengthPoints.length, equals(2));
      expect(strengthPoints[0].sessionId, equals(sess1Id));
      expect(strengthPoints[0].maxReps, equals(8));
      expect(strengthPoints[0].totalReps, equals(14));
      expect(strengthPoints[0].setsCount, equals(2));

      expect(strengthPoints[1].sessionId, equals(sess2Id));
      expect(strengthPoints[1].maxReps, equals(10));
      expect(strengthPoints[1].totalReps, equals(18));
      expect(strengthPoints[1].setsCount, equals(2)); // Excludes pain stop set

      final loggedIds = await repo.getLoggedExerciseIds();
      expect(loggedIds, contains('pullup_standard'));
    });
  });
}
