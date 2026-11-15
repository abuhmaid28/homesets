import 'dart:convert';
import 'package:sqflite/sqflite.dart';
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
    try {
      final decoded = jsonDecode(row['completed_sets_json'] as String) as List<dynamic>;
      for (final item in decoded) {
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
      }
    } catch (_) {}

    ScheduledSession? scheduledSession;
    try {
      final rawSession = row['active_session_json'] as String?;
      if (rawSession != null && rawSession.isNotEmpty && rawSession != '{}') {
        scheduledSession = ScheduledSession.fromJson(jsonDecode(rawSession) as Map<String, dynamic>);
      }
    } catch (_) {}

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

  /// Calculates completed workout sessions in the rolling 7 days.
  /// Strictly filters out emergency-stopped sessions (C3R-07): pain stops are NEVER
  /// credited as completed workouts toward the weekly consistency goal.
  Future<int> getWeeklyConsistencyCredit() async {
    final db = await _dbHelper.database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COUNT(id) as count FROM workout_sessions WHERE ended_at >= ? AND is_emergency_stopped = 0',
      [sevenDaysAgo],
    );
    if (result.isEmpty) return 0;
    return Sqflite.firstIntValue(result) ?? 0;
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
}
