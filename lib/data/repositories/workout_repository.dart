import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../domain/backup/backup_models.dart';
import '../../domain/models/domain_models.dart';
import '../database/database_helper.dart';

class ActiveSessionSnapshot {
  final String sessionId;
  final String routineName;
  final String routineNameAr;
  final bool isLiteMode;
  final DateTime startedAt;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final List<SetLog> completedSets;
  final ScheduledSession? scheduledSession;
  final bool hasCorruptSetLogs;
  final String rawCompletedSetsJson;
  final String rawActiveSessionJson;
  final bool isPlanUnrecoverable;
  final bool isPendingFinalization;

  bool get isDraftDamaged =>
      hasCorruptSetLogs || isPlanUnrecoverable || scheduledSession == null || scheduledSession!.exercises.isEmpty;

  const ActiveSessionSnapshot({
    required this.sessionId,
    required this.routineName,
    required this.routineNameAr,
    required this.isLiteMode,
    required this.startedAt,
    required this.currentExerciseIndex,
    required this.currentSetIndex,
    required this.completedSets,
    this.scheduledSession,
    this.hasCorruptSetLogs = false,
    this.rawCompletedSetsJson = '[]',
    this.rawActiveSessionJson = '{}',
    this.isPlanUnrecoverable = false,
    this.isPendingFinalization = false,
  });
}

/// Offline Workout Repository managing SQLite data operations (WP21, WP22, WP23, WP04, WP07).
class WorkoutRepository {
  final DatabaseHelper _dbHelper;

  WorkoutRepository([DatabaseHelper? dbHelper]) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // ==================== USER PROFILE ====================

  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await _dbHelper.database;
    final avoidedStr = profile.avoidedJoints.map((j) => j.name).join(',');
    await db.insert(
      'user_profile',
      {
        'id': profile.id,
        'goal': profile.goal,
        'wake_time_minutes': profile.wakeTimeMinutes,
        'shift_start_minutes': profile.shiftStartMinutes,
        'target_workouts_per_week': profile.targetWorkoutsPerWeek,
        'avoided_joints': avoidedStr,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfile?> getUserProfile() async {
    final db = await _dbHelper.database;
    final rows = await db.query('user_profile', limit: 1);
    if (rows.isEmpty) return null;

    final row = rows.first;
    final avoidedRaw = (row['avoided_joints'] as String).trim();
    final avoidedList = <JointImpactTag>[];
    if (avoidedRaw.isNotEmpty) {
      for (final s in avoidedRaw.split(',')) {
        for (final tag in JointImpactTag.values) {
          if (tag.name == s.trim()) avoidedList.add(tag);
        }
      }
    }

    return UserProfile(
      id: row['id'] as String,
      goal: row['goal'] as String,
      wakeTimeMinutes: row['wake_time_minutes'] as int,
      shiftStartMinutes: row['shift_start_minutes'] as int,
      targetWorkoutsPerWeek: row['target_workouts_per_week'] as int,
      avoidedJoints: avoidedList,
    );
  }

  // ==================== EQUIPMENT INVENTORY ====================

  Future<void> saveEquipmentInventory(EquipmentInventory inventory) async {
    final db = await _dbHelper.database;
    await db.insert(
      'equipment_inventory',
      {
        'id': 'primary_inventory',
        'has_pull_up_bar': inventory.hasPullUpBar ? 1 : 0,
        'has_bands': inventory.hasBands ? 1 : 0,
        'has_door_anchor': inventory.hasDoorAnchor ? 1 : 0,
        'has_sturdy_table': inventory.hasSturdyTable ? 1 : 0,
        'has_parallel_grip': inventory.hasParallelGrip ? 1 : 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<EquipmentInventory> getEquipmentInventory() async {
    final db = await _dbHelper.database;
    final rows = await db.query('equipment_inventory', limit: 1);
    if (rows.isEmpty) {
      // Default to standard D09 hardware (bar + bands, unverified accessories = false)
      return const EquipmentInventory(
        hasPullUpBar: true,
        hasBands: true,
        hasDoorAnchor: false,
        hasSturdyTable: false,
        hasParallelGrip: false,
      );
    }

    final row = rows.first;
    return EquipmentInventory(
      hasPullUpBar: (row['has_pull_up_bar'] as int) == 1,
      hasBands: (row['has_bands'] as int) == 1,
      hasDoorAnchor: (row['has_door_anchor'] as int) == 1,
      hasSturdyTable: (row['has_sturdy_table'] as int) == 1,
      hasParallelGrip: (row['has_parallel_grip'] as int) == 1,
    );
  }

  // ==================== SESSION PERSISTENCE & IMMEDIATE WRITES ====================

  Future<void> saveActiveSessionState(ActiveSessionSnapshot snapshot) async {
    final db = await _dbHelper.database;
    final setsJson = jsonEncode(snapshot.completedSets.map((s) => {
      'setIndex': s.setIndex,
      'exerciseId': s.exerciseId,
      'performedReps': s.performedReps,
      'bandUsed': s.bandUsed,
      'exertion': s.exertion.name,
      'isPainStopped': s.isPainStopped,
      'painNote': s.painNote,
      'completedAt': s.completedAt.toIso8601String(),
    }).toList());

    final sessionJson = snapshot.scheduledSession != null
        ? jsonEncode(snapshot.scheduledSession!.toJson())
        : '{}';

    // Defense-in-depth (GATE-A): If snapshot has corrupt set logs and raw bytes were retained,
    // archive them to session_salvage_archive BEFORE updating active_session_state so raw data is never lost.
    if (snapshot.hasCorruptSetLogs && snapshot.rawCompletedSetsJson.isNotEmpty) {
      await db.insert(
        'session_salvage_archive',
        {
          'id': 'salvage_auto_${snapshot.sessionId}_${DateTime.now().millisecondsSinceEpoch}',
          'session_id': snapshot.sessionId,
          'routine_name': snapshot.routineName,
          'salvaged_at': DateTime.now().toIso8601String(),
          'parsed_sets_count': snapshot.completedSets.length,
          'has_corrupt_logs': 1,
          'raw_completed_sets_json': snapshot.rawCompletedSetsJson,
          'raw_active_session_json': snapshot.rawActiveSessionJson,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await db.insert(
      'active_session_state',
      {
        'session_id': snapshot.sessionId,
        'routine_name': snapshot.routineName,
        'routine_name_ar': snapshot.routineNameAr,
        'is_lite_mode': snapshot.isLiteMode ? 1 : 0,
        'started_at': snapshot.startedAt.toIso8601String(),
        'current_exercise_index': snapshot.currentExerciseIndex,
        'current_set_index': snapshot.currentSetIndex,
        'completed_sets_json': setsJson,
        'active_session_json': sessionJson,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ActiveSessionSnapshot?> getActiveSessionState() async {
    final db = await _dbHelper.database;
    final rows = await db.query('active_session_state', limit: 1);
    if (rows.isEmpty) return null;

    final row = rows.first;
    final setsList = <SetLog>[];
    bool hasCorruptSetLogs = false;
    final rawSetsJson = row['completed_sets_json'] as String? ?? '[]';

    // F2: Defensive item-by-item parsing so a single corrupt entry does NOT wipe valid set history
    try {
      final decoded = jsonDecode(rawSetsJson) as List<dynamic>;
      for (final item in decoded) {
        try {
          final m = item as Map<String, dynamic>;
          ExertionRating rating = ExertionRating.targetSweetspot;
          for (final r in ExertionRating.values) {
            if (r.name == m['exertion']) rating = r;
          }

          setsList.add(SetLog(
            setIndex: m['setIndex'] as int,
            exerciseId: m['exerciseId'] as String,
            performedReps: m['performedReps'] as int,
            bandUsed: m['bandUsed'] as String?,
            exertion: rating,
            isPainStopped: m['isPainStopped'] as bool? ?? false,
            painNote: m['painNote'] as String?,
            completedAt: DateTime.parse(m['completedAt'] as String),
          ));
        } catch (_) {
          hasCorruptSetLogs = true;
        }
      }
    } catch (_) {
      hasCorruptSetLogs = true;
    }

    ScheduledSession? scheduledSession;
    bool isPlanUnrecoverable = false;
    final rawSession = row['active_session_json'] as String?;

    // F1: Safely deserialize original plan. NEVER fabricate fallback exercises on corrupt state!
    if (rawSession != null && rawSession.isNotEmpty && rawSession != '{}') {
      try {
        scheduledSession = ScheduledSession.fromJson(jsonDecode(rawSession) as Map<String, dynamic>);
      } catch (_) {
        isPlanUnrecoverable = true;
      }
    } else {
      isPlanUnrecoverable = true;
    }

    bool isPendingFinalization = false;
    if (scheduledSession != null && scheduledSession.exercises.isNotEmpty) {
      final totalPlannedSets = scheduledSession.exercises.fold<int>(
        0,
        (sum, e) => sum + e.sets.length,
      );
      if (setsList.length >= totalPlannedSets && totalPlannedSets > 0) {
        isPendingFinalization = true;
      }
    }

    return ActiveSessionSnapshot(
      sessionId: row['session_id'] as String,
      routineName: row['routine_name'] as String,
      routineNameAr: row['routine_name_ar'] as String,
      isLiteMode: (row['is_lite_mode'] as int) == 1,
      startedAt: DateTime.parse(row['started_at'] as String),
      currentExerciseIndex: row['current_exercise_index'] as int,
      currentSetIndex: row['current_set_index'] as int,
      completedSets: setsList,
      scheduledSession: scheduledSession,
      hasCorruptSetLogs: hasCorruptSetLogs,
      rawCompletedSetsJson: rawSetsJson,
      rawActiveSessionJson: rawSession ?? '{}',
      isPlanUnrecoverable: isPlanUnrecoverable,
      isPendingFinalization: isPendingFinalization,
    );
  }

  Future<void> clearActiveSessionState() async {
    final db = await _dbHelper.database;
    await db.delete('active_session_state');
  }

  Future<void> saveCompletedSession(CompletedWorkoutSession session) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        'workout_sessions',
        {
          'id': session.id,
          'scheduled_session_id': session.scheduledSessionId,
          'routine_name': session.routineName,
          'is_lite_mode': session.isLiteMode ? 1 : 0,
          'started_at': session.startedAt.toIso8601String(),
          'ended_at': session.endedAt.toIso8601String(),
          'total_duration_seconds': session.totalDurationSeconds,
          'is_emergency_stopped': session.isEmergencyStopped ? 1 : 0,
          'emergency_stop_reason': session.emergencyStopReason,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final s in session.completedSets) {
        await txn.insert(
          'set_logs',
          {
            'id': '${session.id}_set_${s.setIndex}_${s.exerciseId}',
            'session_id': session.id,
            'set_index': s.setIndex,
            'exercise_id': s.exerciseId,
            'performed_reps': s.performedReps,
            'band_used': s.bandUsed,
            'exertion': s.exertion.name,
            'is_pain_stopped': s.isPainStopped ? 1 : 0,
            'pain_note': s.painNote,
            'completed_at': s.completedAt.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Automatically purge active session state upon successful finalization
      await txn.delete('active_session_state');
    });
  }

  /// Safely salvages valid set logs from an unrecoverable/corrupted active session draft (WP-A).
  /// Durably archives raw JSON bytes in `session_salvage_archive` BEFORE clearing active state,
  /// saves valid parsed sets into `set_logs`, and marks the session with `isEmergencyStopped = 1`
  /// so it NEVER falsely earns weekly consistency credit or masquerades as a full normal completion.
  Future<void> salvageCorruptSession({
    required CompletedWorkoutSession session,
    required String rawCompletedSetsJson,
    required String rawActiveSessionJson,
    required bool hasCorruptSetLogs,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Durably archive the raw JSON bytes in SQLite
      await txn.insert(
        'session_salvage_archive',
        {
          'id': 'salvage_${session.id}_${DateTime.now().millisecondsSinceEpoch}',
          'session_id': session.id,
          'routine_name': session.routineName,
          'salvaged_at': DateTime.now().toIso8601String(),
          'parsed_sets_count': session.completedSets.length,
          'has_corrupt_logs': hasCorruptSetLogs ? 1 : 0,
          'raw_completed_sets_json': rawCompletedSetsJson,
          'raw_active_session_json': rawActiveSessionJson,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Persist the salvaged workout marked as emergency stopped / partial salvage
      await txn.insert(
        'workout_sessions',
        {
          'id': session.id,
          'scheduled_session_id': session.scheduledSessionId,
          'routine_name': session.routineName,
          'is_lite_mode': session.isLiteMode ? 1 : 0,
          'started_at': session.startedAt.toIso8601String(),
          'ended_at': session.endedAt.toIso8601String(),
          'total_duration_seconds': session.totalDurationSeconds,
          'is_emergency_stopped': 1,
          'emergency_stop_reason': hasCorruptSetLogs
              ? 'Partial salvage from corrupt draft: raw logs archived (WP-A)'
              : 'Draft plan unrecoverable: raw logs archived (WP-A)',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 3. Persist valid parsed set logs
      for (final s in session.completedSets) {
        await txn.insert(
          'set_logs',
          {
            'id': '${session.id}_set_${s.setIndex}_${s.exerciseId}',
            'session_id': session.id,
            'set_index': s.setIndex,
            'exercise_id': s.exerciseId,
            'performed_reps': s.performedReps,
            'band_used': s.bandUsed,
            'exertion': s.exertion.name,
            'is_pain_stopped': s.isPainStopped ? 1 : 0,
            'pain_note': s.painNote,
            'completed_at': s.completedAt.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 4. Safely purge active_session_state only AFTER durable archiving
      await txn.delete('active_session_state');
    });
  }

  /// Queries all archived corrupt session logs (WP-A).
  Future<List<Map<String, dynamic>>> getSalvagedSessionArchive() async {
    final db = await _dbHelper.database;
    return await db.query(
      'session_salvage_archive',
      orderBy: 'salvaged_at DESC',
    );
  }

  /// Atomically executes emergency pain STOP persistence (WP-B, SAFE-01, GOV14).
  /// Updates user profile avoided joints, logs the emergency completed session and set logs,
  /// and purges active session state in a single SQLite transaction.
  /// Eliminates risk of partial persistence state if disk/IO errors occur.
  Future<void> saveEmergencyPainStopSession({
    required CompletedWorkoutSession session,
    required List<JointImpactTag> avoidedJointTags,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Atomically quarantine joint(s) in user profile
      if (avoidedJointTags.isNotEmpty) {
        final profileRows = await txn.query('user_profile', limit: 1);
        if (profileRows.isNotEmpty) {
          final profileMap = profileRows.first;
          final currentAvoided = (profileMap['avoided_joints'] as String)
              .split(',')
              .where((s) => s.isNotEmpty)
              .toSet();
          currentAvoided.addAll(avoidedJointTags.map((j) => j.name));
          await txn.update(
            'user_profile',
            {'avoided_joints': currentAvoided.join(',')},
            where: 'id = ?',
            whereArgs: [profileMap['id']],
          );
        }
      }

      // 2. Persist completed emergency session
      await txn.insert(
        'workout_sessions',
        {
          'id': session.id,
          'scheduled_session_id': session.scheduledSessionId,
          'routine_name': session.routineName,
          'is_lite_mode': session.isLiteMode ? 1 : 0,
          'started_at': session.startedAt.toIso8601String(),
          'ended_at': session.endedAt.toIso8601String(),
          'total_duration_seconds': session.totalDurationSeconds,
          'is_emergency_stopped': 1,
          'emergency_stop_reason': session.emergencyStopReason,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 3. Persist completed set logs
      for (final s in session.completedSets) {
        await txn.insert(
          'set_logs',
          {
            'id': '${session.id}_set_${s.setIndex}_${s.exerciseId}',
            'session_id': session.id,
            'set_index': s.setIndex,
            'exercise_id': s.exerciseId,
            'performed_reps': s.performedReps,
            'band_used': s.bandUsed,
            'exertion': s.exertion.name,
            'is_pain_stopped': s.isPainStopped ? 1 : 0,
            'pain_note': s.painNote,
            'completed_at': s.completedAt.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 4. Purge active session state
      await txn.delete('active_session_state');
    });
  }

  /// Calculates completed workout sessions in the rolling 7 days (D11).
  /// Strictly filters out emergency-stopped sessions (C3R-07) and partially abandoned workouts (C3R2 F6):
  /// legitimate completion requires >= 2 sets for Lite mode (out of 4 planned), >= 3 sets for Standard mode.
  Future<int> getWeeklyConsistencyCredit() async {
    final db = await _dbHelper.database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COUNT(ws.id) as count FROM workout_sessions ws '
      'WHERE ws.ended_at >= ? AND ws.is_emergency_stopped = 0 '
      'AND ('
      '  (ws.is_lite_mode = 1 AND (SELECT COUNT(*) FROM set_logs sl WHERE sl.session_id = ws.id AND sl.is_pain_stopped = 0 AND sl.performed_reps > 0) >= 2) '
      '  OR '
      '  (ws.is_lite_mode = 0 AND (SELECT COUNT(*) FROM set_logs sl WHERE sl.session_id = ws.id AND sl.is_pain_stopped = 0 AND sl.performed_reps > 0) >= 3)'
      ')',
      [sevenDaysAgo],
    );
    if (result.isEmpty) return 0;
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns the target muscle group of the latest non-emergency completed workout session (C3R2 WP02).
  Future<String?> getLastWorkoutMuscleGroup() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'workout_sessions',
      columns: ['routine_name'],
      where: 'is_emergency_stopped = 0',
      orderBy: 'ended_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final lastRoutine = (rows.first['routine_name'] as String).toUpperCase();
    if (lastRoutine.contains('ROUTINE A') || lastRoutine.contains('A:') || lastRoutine.contains('LATS') || lastRoutine.contains('PULL')) {
      return 'LATS_BICEPS';
    } else if (lastRoutine.contains('ROUTINE B') || lastRoutine.contains('B:') || lastRoutine.contains('CHEST') || lastRoutine.contains('PUSH')) {
      return 'CHEST_TRICEPS';
    } else if (lastRoutine.contains('ROUTINE C') || lastRoutine.contains('C:') || lastRoutine.contains('LEGS') || lastRoutine.contains('LOWER')) {
      return 'LEGS_GLUTES';
    }
    return null;
  }

  /// Returns the latest completion timestamp per target muscle group across all non-emergency sessions (C3R2 F3).
  Future<Map<String, DateTime>> getLastWorkoutTimePerMuscleGroup() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'workout_sessions',
      columns: ['routine_name', 'ended_at'],
      where: 'is_emergency_stopped = 0',
      orderBy: 'ended_at DESC',
    );

    final result = <String, DateTime>{};
    for (final row in rows) {
      final routine = (row['routine_name'] as String).toUpperCase();
      String? group;
      if (routine.contains('ROUTINE A') || routine.contains('A:') || routine.contains('LATS') || routine.contains('PULL')) {
        group = 'LATS_BICEPS';
      } else if (routine.contains('ROUTINE B') || routine.contains('B:') || routine.contains('CHEST') || routine.contains('PUSH')) {
        group = 'CHEST_TRICEPS';
      } else if (routine.contains('ROUTINE C') || routine.contains('C:') || routine.contains('LEGS') || routine.contains('LOWER')) {
        group = 'LEGS_GLUTES';
      }
      if (group != null && !result.containsKey(group)) {
        result[group] = DateTime.parse(row['ended_at'] as String);
      }
    }
    return result;
  }

  /// Returns recent completed sets per exerciseId from the latest completed session (C3R2 F5).
  /// Isolates latest session sets so older sets from weeks prior do not permanently suppress progression.
  Future<Map<String, List<SetLog>>> getRecentExerciseHistory() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT sl.*, ws.ended_at FROM set_logs sl '
      'JOIN workout_sessions ws ON sl.session_id = ws.id '
      'WHERE ws.is_emergency_stopped = 0 '
      'ORDER BY ws.ended_at DESC, sl.set_index ASC',
    );

    final history = <String, List<SetLog>>{};
    final seenSessionPerExercise = <String, String>{};

    for (final row in rows) {
      final exId = row['exercise_id'] as String;
      final sessionId = row['session_id'] as String;

      // Strictly isolate sets from the single latest session of this exercise
      if (!seenSessionPerExercise.containsKey(exId)) {
        seenSessionPerExercise[exId] = sessionId;
      }
      if (seenSessionPerExercise[exId] == sessionId) {
        ExertionRating rating = ExertionRating.targetSweetspot;
        for (final r in ExertionRating.values) {
          if (r.name == row['exertion']) rating = r;
        }
        final setLog = SetLog(
          setIndex: row['set_index'] as int,
          exerciseId: exId,
          performedReps: row['performed_reps'] as int,
          bandUsed: row['band_used'] as String?,
          exertion: rating,
          isPainStopped: (row['is_pain_stopped'] as int) == 1,
          painNote: row['pain_note'] as String?,
          completedAt: DateTime.parse(row['completed_at'] as String),
        );
        history.putIfAbsent(exId, () => []).add(setLog);
      }
    }
    return history;
  }

  /// Returns the latest non-emergency workout completion time.
  Future<DateTime?> getLastWorkoutTime() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'workout_sessions',
      columns: ['ended_at'],
      where: 'is_emergency_stopped = 0',
      orderBy: 'ended_at DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return DateTime.parse(result.first['ended_at'] as String);
  }

  /// Returns the next routine cycle (A -> B -> C -> A) deterministically based on
  /// the latest completed non-emergency workout session (WP03, C3R-02).
  Future<String> getNextRoutineCycle() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'workout_sessions',
      columns: ['routine_name'],
      where: 'is_emergency_stopped = 0',
      orderBy: 'ended_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return 'A';

    final lastRoutine = (rows.first['routine_name'] as String).toUpperCase();
    if (lastRoutine.contains('ROUTINE A') || lastRoutine.contains('A:')) {
      return 'B';
    } else if (lastRoutine.contains('ROUTINE B') || lastRoutine.contains('B:')) {
      return 'C';
    } else if (lastRoutine.contains('ROUTINE C') || lastRoutine.contains('C:')) {
      return 'A';
    }
    return 'A';
  }

  // =========================================================================
  // P5 PROGRESS TRACKING PERSISTENCE (WP02, WP03, WP04, WP06, WP07, WP08)
  // =========================================================================

  /// Persists or updates a body weight entry (WP03).
  Future<void> saveWeightEntry(WeightEntry entry) async {
    final db = await _dbHelper.database;
    await db.insert(
      'weight_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all body weight entries ordered chronologically descending (latest first).
  Future<List<WeightEntry>> getWeightEntries() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'weight_entries',
      orderBy: 'logged_at DESC',
    );
    return rows.map((r) => WeightEntry.fromMap(r)).toList();
  }

  /// Retrieves the single most recent body weight entry.
  Future<WeightEntry?> getLatestWeightEntry() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'weight_entries',
      orderBy: 'logged_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WeightEntry.fromMap(rows.first);
  }

  /// Deletes a body weight entry by ID.
  Future<void> deleteWeightEntry(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'weight_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Persists metadata for an app-private progress photo (WP07, WP08).
  Future<void> saveProgressPhoto(ProgressPhoto photo) async {
    final db = await _dbHelper.database;
    await db.insert(
      'progress_photos',
      photo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all progress photos, optionally filtered by angle, ordered newest first.
  Future<List<ProgressPhoto>> getProgressPhotos({PhotoAngle? angle}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'progress_photos',
      where: angle != null ? 'angle = ?' : null,
      whereArgs: angle != null ? [angle.toDbString()] : null,
      orderBy: 'taken_at DESC',
    );
    return rows.map((r) => ProgressPhoto.fromMap(r)).toList();
  }

  /// Deletes a progress photo record by ID.
  Future<void> deleteProgressPhoto(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'progress_photos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Persists a checkbox state for a daily meal slot (WP06).
  Future<void> saveMealCheck(String date, int mealSlot, bool isChecked) async {
    final db = await _dbHelper.database;
    await db.insert(
      'daily_meal_checks',
      {
        'date': date,
        'meal_slot': mealSlot,
        'is_checked': isChecked ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all meal check states for a specific date (YYYY-MM-DD).
  Future<Map<int, bool>> getMealChecksForDate(String date) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'daily_meal_checks',
      where: 'date = ?',
      whereArgs: [date],
    );
    final map = <int, bool>{};
    for (final r in rows) {
      map[r['meal_slot'] as int] = (r['is_checked'] as int) == 1;
    }
    return map;
  }

  /// Retrieves distinct exercise IDs that have at least one completed non-pain set (WP04).
  Future<List<String>> getLoggedExerciseIds() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT sl.exercise_id
      FROM set_logs sl
      JOIN workout_sessions ws ON sl.session_id = ws.id
      WHERE sl.is_pain_stopped = 0
        AND sl.performed_reps > 0
        AND ws.is_emergency_stopped = 0
      ORDER BY sl.completed_at DESC
    ''');
    return rows.map((r) => r['exercise_id'] as String).toList();
  }

  /// Retrieves distinct band configurations logged for [exerciseId] to enable like-for-like comparison (P5-R05).
  /// Returns 'none' for unassisted bodyweight sets, plus any specific band identifiers.
  Future<List<String>> getAvailableBandConfigurations(String exerciseId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT sl.band_used
      FROM set_logs sl
      JOIN workout_sessions ws ON sl.session_id = ws.id
      WHERE sl.exercise_id = ?
        AND sl.is_pain_stopped = 0
        AND sl.performed_reps > 0
        AND ws.is_emergency_stopped = 0
    ''', [exerciseId]);

    final configs = <String>{};
    for (final r in rows) {
      final band = r['band_used'] as String?;
      if (band == null || band.trim().isEmpty) {
        configs.add('none');
      } else {
        configs.add(band.trim());
      }
    }
    final sorted = configs.toList();
    sorted.sort();
    return sorted;
  }

  /// Computes aggregated strength data points over time for a given exercise (WP04, P5-R05).
  /// Excludes emergency-stopped sessions, pain-stopped sets, and zero-rep logs.
  /// If [bandFilter] is provided ('none' for bodyweight, or a specific band id), strictly filters to that configuration.
  Future<List<StrengthDataPoint>> getStrengthHistoryForExercise(
    String exerciseId, {
    String? bandFilter,
  }) async {
    final db = await _dbHelper.database;
    String filterClause = '';
    final args = <dynamic>[exerciseId];

    if (bandFilter != null && bandFilter != 'all') {
      if (bandFilter == 'none' || bandFilter == 'bodyweight') {
        filterClause = "AND (sl.band_used IS NULL OR sl.band_used = '')";
      } else {
        filterClause = 'AND sl.band_used = ?';
        args.add(bandFilter);
      }
    }

    final rows = await db.rawQuery('''
      SELECT 
        sl.session_id,
        ws.is_lite_mode,
        sl.performed_reps,
        sl.band_used,
        sl.completed_at
      FROM set_logs sl
      JOIN workout_sessions ws ON sl.session_id = ws.id
      WHERE sl.exercise_id = ?
        AND sl.is_pain_stopped = 0
        AND sl.performed_reps > 0
        AND ws.is_emergency_stopped = 0
        $filterClause
      ORDER BY sl.completed_at ASC
    ''', args);

    if (rows.isEmpty) return [];

    // Group rows by session_id AND band_used to prevent mixing assisted and unassisted sets in the same session
    final groupMap = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final sessId = row['session_id'] as String;
      final band = (row['band_used'] as String?)?.trim() ?? '';
      final groupKey = '$sessId##$band';
      groupMap.putIfAbsent(groupKey, () => []).add(row);
    }

    final dataPoints = <StrengthDataPoint>[];
    for (final entry in groupMap.entries) {
      final sessRows = entry.value;
      int maxReps = 0;
      int totalReps = 0;
      String? bandUsed;
      DateTime? sessionDate;
      bool isLite = false;
      final sessId = sessRows.first['session_id'] as String;

      for (final r in sessRows) {
        final reps = r['performed_reps'] as int;
        if (reps > maxReps) maxReps = reps;
        totalReps += reps;
        final b = (r['band_used'] as String?)?.trim();
        if (b != null && b.isNotEmpty) {
          bandUsed = b;
        }
        final completedAt = DateTime.parse(r['completed_at'] as String);
        if (sessionDate == null || completedAt.isAfter(sessionDate)) {
          sessionDate = completedAt;
        }
        isLite = (r['is_lite_mode'] as int) == 1;
      }

      if (sessionDate != null && maxReps > 0) {
        dataPoints.add(StrengthDataPoint(
          date: sessionDate,
          maxReps: maxReps,
          totalReps: totalReps,
          setsCount: sessRows.length,
          bandUsed: bandUsed,
          isLiteMode: isLite,
          sessionId: sessId,
        ));
      }
    }

    // Sort chronologically ascending
    dataPoints.sort((a, b) => a.date.compareTo(b.date));
    return dataPoints;
  }

  /// Exports full P0-P5 data snapshot from SQLite database (WP04).
  Future<HomesetsDataSnapshot> createDataSnapshot() async {
    final db = await _dbHelper.database;

    final profileRows = await db.query('user_profile', limit: 1);
    final inventoryRows = await db.query('equipment_inventory', limit: 1);
    final workoutRows = await db.query('workout_sessions');
    final setLogRows = await db.query('set_logs');
    final activeRows = await db.query('active_session_state', limit: 1);
    final salvageRows = await db.query('session_salvage_archive');
    final weightRows = await db.query('weight_entries');
    final photoRows = await db.query('progress_photos');
    final mealRows = await db.query('daily_meal_checks');

    return HomesetsDataSnapshot(
      userProfile: profileRows.isNotEmpty ? profileRows.first : null,
      equipmentInventory: inventoryRows.isNotEmpty ? inventoryRows.first : null,
      workoutSessions: workoutRows,
      setLogs: setLogRows,
      activeSessionState: activeRows.isNotEmpty ? activeRows.first : null,
      salvageArchives: salvageRows,
      weightEntries: weightRows,
      progressPhotos: photoRows,
      dailyMealChecks: mealRows,
    );
  }

  /// Restores full P0-P5 data snapshot transactionally into SQLite database (WP13).
  Future<void> restoreDataSnapshot(HomesetsDataSnapshot snapshot) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // 1. Clear existing tables in safe order respecting foreign keys
      await txn.delete('set_logs');
      await txn.delete('workout_sessions');
      await txn.delete('user_profile');
      await txn.delete('equipment_inventory');
      await txn.delete('active_session_state');
      await txn.delete('session_salvage_archive');
      await txn.delete('weight_entries');
      await txn.delete('progress_photos');
      await txn.delete('daily_meal_checks');

      // 2. Insert user profile
      if (snapshot.userProfile != null) {
        await txn.insert('user_profile', snapshot.userProfile!,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 3. Insert equipment inventory
      if (snapshot.equipmentInventory != null) {
        await txn.insert('equipment_inventory', snapshot.equipmentInventory!,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 4. Insert workout sessions
      for (final row in snapshot.workoutSessions) {
        await txn.insert('workout_sessions', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 5. Insert set logs
      for (final row in snapshot.setLogs) {
        await txn.insert('set_logs', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 6. Insert active session state
      if (snapshot.activeSessionState != null) {
        await txn.insert('active_session_state', snapshot.activeSessionState!,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 7. Insert session salvage archives
      for (final row in snapshot.salvageArchives) {
        await txn.insert('session_salvage_archive', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 8. Insert weight entries
      for (final row in snapshot.weightEntries) {
        await txn.insert('weight_entries', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 9. Insert progress photos
      for (final row in snapshot.progressPhotos) {
        await txn.insert('progress_photos', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 10. Insert daily meal checks
      for (final row in snapshot.dailyMealChecks) {
        await txn.insert('daily_meal_checks', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
