import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:homesets/domain/engine/workout_engine.dart';
import 'package:homesets/domain/models/domain_models.dart';
import 'package:homesets/data/database/database_helper.dart';
import 'package:homesets/data/repositories/workout_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setCustomFactory(databaseFactoryFfi);
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('user_profile');
    await db.delete('equipment_inventory');
    await db.delete('workout_sessions');
    await db.delete('set_logs');
    await db.delete('active_session_state');
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  group('C3R2 Reproduction Tests (WP01)', () {
    const inventory = EquipmentInventory(
      hasPullUpBar: true,
      hasBands: true,
      hasDoorAnchor: true,
      hasParallelGrip: true,
    );
    const profile = UserProfile(id: 'user_repro');

    test('REPRO-01: Rotation double-skip bug (12h gap after Routine A should NOT skip Routine B)', () {
      final now = DateTime(2026, 11, 15, 20, 0); // 8:00 PM
      final lastWorkoutA = now.subtract(const Duration(hours: 12)); // 8:00 AM (Routine A completed)
      final engine = WorkoutEngine(inventory: inventory, profile: profile, now: now);

      // User completed Routine A (LATS_BICEPS) 12 hours ago.
      // Next scheduled cycle in sequence is B (CHEST_TRICEPS).
      // Since CHEST_TRICEPS was NOT trained 12 hours ago, Routine B is completely unfatigued!
      final session = engine.generateNextSession(
        routineCycle: 'B',
        lastWorkoutTime: lastWorkoutA,
        lastTargetMuscleGroup: 'LATS_BICEPS',
        clock: now,
      );

      // EXPECTATION: Routine B must be prescribed! It must NOT be skipped to Routine C!
      expect(session.targetMuscleGroup, equals('CHEST_TRICEPS'),
          reason: 'Routine B (CHEST_TRICEPS) must NOT be skipped when last workout was Routine A (LATS_BICEPS)');
      expect(session.routineName, contains('Routine B'));
    });

    test('REPRO-02: Zero-set session must NOT receive weekly consistency credit', () async {
      final repo = WorkoutRepository();
      final now = DateTime.now();

      // Save a session with 0 completed sets
      final emptySession = CompletedWorkoutSession(
        id: 'session_empty_1',
        scheduledSessionId: 'sched_empty_1',
        routineName: 'Routine A: Upper Pull & Biceps',
        isLiteMode: false,
        startedAt: now.subtract(const Duration(minutes: 5)),
        endedAt: now,
        totalDurationSeconds: 300,
        completedSets: const [],
        isEmergencyStopped: false,
      );
      await repo.saveCompletedSession(emptySession);

      final credit = await repo.getWeeklyConsistencyCredit();
      // EXPECTATION: 0 credit for a 0-set session
      expect(credit, equals(0),
          reason: 'A session with 0 completed sets must earn 0 consistency credit');

      // Now add a valid session with 1 completed non-pain set (reps > 0)
      final validSession = CompletedWorkoutSession(
        id: 'session_valid_1',
        scheduledSessionId: 'sched_valid_1',
        routineName: 'Routine B: Upper Push & Triceps',
        isLiteMode: false,
        startedAt: now.subtract(const Duration(minutes: 30)),
        endedAt: now,
        totalDurationSeconds: 1800,
        completedSets: [
          SetLog(
            setIndex: 1,
            exerciseId: 'pushup_standard',
            performedReps: 10,
            exertion: ExertionRating.targetSweetspot,
            completedAt: now.subtract(const Duration(minutes: 10)),
          ),
        ],
        isEmergencyStopped: false,
      );
      await repo.saveCompletedSession(validSession);

      final creditAfterValid = await repo.getWeeklyConsistencyCredit();
      expect(creditAfterValid, equals(1),
          reason: 'A session with at least 1 completed set must earn 1 consistency credit');
    });

    test('REPRO-03: Corrupt active session JSON must be safely recovered preserving isLiteMode & routine', () async {
      final repo = WorkoutRepository();
      final db = await DatabaseHelper.instance.database;

      // Insert corrupt JSON directly into active_session_state
      await db.insert('active_session_state', {
        'session_id': 'corrupt_session_456',
        'routine_name': 'Routine B: Upper Push & Triceps',
        'routine_name_ar': 'التمرين الثاني',
        'is_lite_mode': 1, // Lite mode must be preserved!
        'started_at': DateTime.now().toIso8601String(),
        'current_exercise_index': 0,
        'current_set_index': 1,
        'completed_sets_json': '[]',
        'active_session_json': '{invalid_corrupted_json:::###}',
      });

      // Recover active session snapshot
      final snapshot = await repo.getActiveSessionState();
      expect(snapshot, isNotNull);
      expect(snapshot!.sessionId, equals('corrupt_session_456'));
      expect(snapshot.routineName, equals('Routine B: Upper Push & Triceps'));
      expect(snapshot.isLiteMode, isTrue, reason: 'Lite mode flag must NEVER be mutated to standard on corrupt JSON');
      expect(snapshot.scheduledSession, isNotNull);
      expect(snapshot.scheduledSession!.targetMuscleGroup, equals('CHEST_TRICEPS'));
      expect(snapshot.scheduledSession!.isLiteMode, isTrue);
      expect(snapshot.scheduledSession!.exercises.isNotEmpty, isTrue);
    });

    test('REPRO-04: Absence deload evaluates 0%, 25%, 40% volume reduction with zero streak penalty', () {
      final res0 = WorkoutEngine.evaluateAbsenceDeload(daysSinceLastWorkout: 3, plannedSetsBaseline: 3);
      expect(res0.action, equals(EngineAction.normalRotationResume));
      expect(res0.volumeReductionPercent, equals(0));
      expect(res0.streakPenaltyApplied, isFalse);
      expect(res0.guiltFreeMessaging, isTrue);

      final res1 = WorkoutEngine.evaluateAbsenceDeload(daysSinceLastWorkout: 8, plannedSetsBaseline: 3);
      expect(res1.action, equals(EngineAction.lightReentryDeload));
      expect(res1.volumeReductionPercent, equals(25));
      expect(res1.streakPenaltyApplied, isFalse);
      expect(res1.guiltFreeMessaging, isTrue);

      final res2 = WorkoutEngine.evaluateAbsenceDeload(daysSinceLastWorkout: 15, plannedSetsBaseline: 3);
      expect(res2.action, equals(EngineAction.adaptationReentryDeload));
      expect(res2.volumeReductionPercent, equals(40));
      expect(res2.streakPenaltyApplied, isFalse);
      expect(res2.guiltFreeMessaging, isTrue);
    });

    test('REPRO-05: Cadence pause tempo cue progression applied to generated session', () {
      final engine = WorkoutEngine(inventory: inventory, profile: profile);
      // Create history with ceiling reached for pullup_standard (e.g. 10 reps)
      final history = {
        'pullup_standard': [
          SetLog(
            setIndex: 1,
            exerciseId: 'pullup_standard',
            performedReps: 10,
            exertion: ExertionRating.easyReserve,
            completedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          SetLog(
            setIndex: 2,
            exerciseId: 'pullup_standard',
            performedReps: 10,
            exertion: ExertionRating.easyReserve,
            completedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
      };

      final session = engine.generateNextSession(
        routineCycle: 'A',
        exerciseHistory: history,
      );

      final pullupPlanned = session.exercises.firstWhere((e) => e.exercise.id == 'pullup_standard');
      expect(pullupPlanned.sets.first.tempoCue, isNotNull,
          reason: 'Hitting ceiling on pullup_standard must apply tempoCue for cadence pause overload');
      expect(pullupPlanned.sets.first.tempoCue, contains('2s pause'));
    });

    test('REPRO-06: Integrated cycle flow across consecutive days and short/long gaps', () {
      final now = DateTime(2026, 11, 15, 10, 0);
      final engine = WorkoutEngine(inventory: inventory, profile: profile, now: now);

      // Long gap (40h): routine should follow normal cycle
      final longGapSession = engine.generateNextSession(
        routineCycle: 'B',
        lastWorkoutTime: now.subtract(const Duration(hours: 40)),
        lastTargetMuscleGroup: 'CHEST_TRICEPS',
        clock: now,
      );
      expect(longGapSession.targetMuscleGroup, equals('CHEST_TRICEPS'),
          reason: '>= 36h gap allows same muscle group without collision');

      // Short gap (12h) targeting SAME muscle group: MUST rotate away!
      final collisionSession = engine.generateNextSession(
        routineCycle: 'B',
        lastWorkoutTime: now.subtract(const Duration(hours: 12)),
        lastTargetMuscleGroup: 'CHEST_TRICEPS',
        clock: now,
      );
      expect(collisionSession.targetMuscleGroup, isNot('CHEST_TRICEPS'),
          reason: '<36h on same muscle group must rotate away to protect joint/muscle recovery');
    });
  });
}
