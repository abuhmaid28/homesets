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
    await db.delete('session_salvage_archive');
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

      // Now add a valid session with >=3 completed non-pain sets for Standard mode (F6)
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
            completedAt: now.subtract(const Duration(minutes: 20)),
          ),
          SetLog(
            setIndex: 2,
            exerciseId: 'pushup_standard',
            performedReps: 10,
            exertion: ExertionRating.targetSweetspot,
            completedAt: now.subtract(const Duration(minutes: 15)),
          ),
          SetLog(
            setIndex: 3,
            exerciseId: 'pushup_standard',
            performedReps: 8,
            exertion: ExertionRating.targetSweetspot,
            completedAt: now.subtract(const Duration(minutes: 10)),
          ),
        ],
        isEmergencyStopped: false,
      );
      await repo.saveCompletedSession(validSession);

      final creditAfterValid = await repo.getWeeklyConsistencyCredit();
      expect(creditAfterValid, equals(1),
          reason: 'A session with >=3 completed sets in Standard mode must earn 1 consistency credit');
    });

    test('REPRO-03 / F1: Corrupt active session JSON must be safely marked unrecoverable without fabricated exercises', () async {
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
      // F1: Plan must be marked unrecoverable; repository must NEVER fabricate exercises
      expect(snapshot.isPlanUnrecoverable, isTrue);
      expect(snapshot.scheduledSession, isNull,
          reason: 'Corrupt plan must result in null scheduledSession rather than fabricated exercises bypassing equipment/joint safety');
    });

    test('F1: Routine C corrupt snapshot with 0 sets does NOT return viable session with 0 exercises', () async {
      final repo = WorkoutRepository();
      final db = await DatabaseHelper.instance.database;

      await db.insert('active_session_state', {
        'session_id': 'corrupt_routine_c',
        'routine_name': 'Routine C: Legs & Stability',
        'routine_name_ar': 'التمرين الثالث',
        'is_lite_mode': 0,
        'started_at': DateTime.now().toIso8601String(),
        'current_exercise_index': 0,
        'current_set_index': 1,
        'completed_sets_json': '[]',
        'active_session_json': '{}', // Empty JSON
      });

      final snapshot = await repo.getActiveSessionState();
      expect(snapshot, isNotNull);
      expect(snapshot!.isPlanUnrecoverable, isTrue);
      expect(snapshot.scheduledSession, isNull,
          reason: 'Corrupt Routine C draft must never fabricate exercises or return viable session with 0 exercises');
    });

    test('F2: Corrupt entry in completed_sets_json preserves valid sets and flags hasCorruptSetLogs', () async {
      final repo = WorkoutRepository();
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();

      final mixedSetsJson = '[{"setIndex":1,"exerciseId":"pullup_standard","performedReps":8,"exertion":"targetSweetspot","completedAt":"${now.toIso8601String()}"},{"corrupt_invalid_set": true},{"setIndex":2,"exerciseId":"pullup_standard","performedReps":7,"exertion":"targetSweetspot","completedAt":"${now.toIso8601String()}"}]';

      await db.insert('active_session_state', {
        'session_id': 'partial_corrupt_sets',
        'routine_name': 'Routine A: Upper Pull & Biceps',
        'routine_name_ar': 'التمرين الأول',
        'is_lite_mode': 0,
        'started_at': now.toIso8601String(),
        'current_exercise_index': 0,
        'current_set_index': 2,
        'completed_sets_json': mixedSetsJson,
        'active_session_json': '{}',
      });

      final snapshot = await repo.getActiveSessionState();
      expect(snapshot, isNotNull);
      expect(snapshot!.completedSets.length, equals(2),
          reason: 'Valid sets must be preserved even if an adjacent array element is corrupted');
      expect(snapshot.hasCorruptSetLogs, isTrue,
          reason: 'Corrupt set logs must be flagged for safe diagnostic inspection');
      expect(snapshot.rawCompletedSetsJson, equals(mixedSetsJson),
          reason: 'Raw JSON bytes must be preserved for non-destructive recovery');
    });

    test('F3: Rapid A -> B -> C -> A within 36h identifies all groups fatigued and returns recovery session', () {
      final now = DateTime(2026, 11, 15, 22, 0);
      final engine = WorkoutEngine(inventory: inventory, profile: profile, now: now);

      // All 3 groups trained recently:
      // A (LATS_BICEPS) at 30h ago (<36h)
      // B (CHEST_TRICEPS) at 18h ago (<36h)
      // C (LEGS_GLUTES) at 6h ago (<36h)
      final historyMap = {
        'LATS_BICEPS': now.subtract(const Duration(hours: 30)),
        'CHEST_TRICEPS': now.subtract(const Duration(hours: 18)),
        'LEGS_GLUTES': now.subtract(const Duration(hours: 6)),
      };

      final session = engine.generateNextSession(
        routineCycle: 'A',
        lastWorkoutTimePerGroup: historyMap,
        clock: now,
      );

      expect(session.isViable, isFalse,
          reason: 'When all muscle groups are under 36h recovery window, no routine is viable without violating recovery');
      expect(session.targetMuscleGroup, equals('RECOVERY'));
      expect(session.unviableReason, contains('recovery'));
    });

    test('F5: Absence deload automatically integrates into planned volume after 8+ days missed', () {
      final now = DateTime(2026, 11, 15, 10, 0);
      final eightDaysAgo = now.subtract(const Duration(days: 8));
      final engine = WorkoutEngine(inventory: inventory, profile: profile, now: now);

      final session = engine.generateNextSession(
        routineCycle: 'A',
        lastWorkoutTime: eightDaysAgo,
        clock: now,
      );

      expect(session.absenceDeloadResult, isNotNull,
          reason: '8-day absence must trigger an AbsenceDeloadResult on the scheduled session');
      expect(session.absenceDeloadResult!.action, equals(EngineAction.lightReentryDeload));
      expect(session.absenceDeloadResult!.volumeReductionPercent, equals(25));
      expect(session.absenceDeloadResult!.streakPenaltyApplied, isFalse);
      expect(session.absenceDeloadResult!.guiltFreeMessaging, isTrue);

      // With 25% deload on Standard mode, volume is reduced to 2 sets per exercise
      for (final ex in session.exercises) {
        expect(ex.sets.length, lessThanOrEqualTo(2),
            reason: 'Volume must be reduced to <= 2 sets per exercise during light reentry deload');
      }
    });

    test('F5: Progression evaluates latest session sets rather than 30-day pooled sets', () async {
      final repo = WorkoutRepository();
      final now = DateTime.now();

      // Session 1 (20 days ago): Low reps (e.g. 6 reps)
      await repo.saveCompletedSession(CompletedWorkoutSession(
        id: 'sess_old_1',
        scheduledSessionId: 'sched_old_1',
        routineName: 'Routine A: Upper Pull & Biceps',
        isLiteMode: false,
        startedAt: now.subtract(const Duration(days: 20)),
        endedAt: now.subtract(const Duration(days: 20, minutes: -30)),
        totalDurationSeconds: 1800,
        completedSets: [
          SetLog(setIndex: 1, exerciseId: 'pullup_standard', performedReps: 6, exertion: ExertionRating.targetSweetspot, completedAt: now.subtract(const Duration(days: 20))),
          SetLog(setIndex: 2, exerciseId: 'pullup_standard', performedReps: 6, exertion: ExertionRating.targetSweetspot, completedAt: now.subtract(const Duration(days: 20))),
        ],
      ));

      // Session 2 (2 days ago): User hit ceiling (10 reps with easy reserve!)
      await repo.saveCompletedSession(CompletedWorkoutSession(
        id: 'sess_recent_2',
        scheduledSessionId: 'sched_recent_2',
        routineName: 'Routine A: Upper Pull & Biceps',
        isLiteMode: false,
        startedAt: now.subtract(const Duration(days: 2)),
        endedAt: now.subtract(const Duration(days: 2, minutes: -30)),
        totalDurationSeconds: 1800,
        completedSets: [
          SetLog(setIndex: 1, exerciseId: 'pullup_standard', performedReps: 10, exertion: ExertionRating.easyReserve, completedAt: now.subtract(const Duration(days: 2))),
          SetLog(setIndex: 2, exerciseId: 'pullup_standard', performedReps: 10, exertion: ExertionRating.easyReserve, completedAt: now.subtract(const Duration(days: 2))),
        ],
      ));

      // Query recent exercise history: MUST contain only the latest session's sets!
      final history = await repo.getRecentExerciseHistory();
      expect(history['pullup_standard']!.length, equals(2));
      expect(history['pullup_standard']!.every((s) => s.performedReps == 10), isTrue,
          reason: 'History must isolate latest session sets so old sets do not block progression');

      final engine = WorkoutEngine(inventory: inventory, profile: profile);
      final session = engine.generateNextSession(
        routineCycle: 'A',
        exerciseHistory: history,
      );

      final pullupPlanned = session.exercises.firstWhere((e) => e.exercise.id == 'pullup_standard');
      expect(pullupPlanned.sets.first.tempoCue, isNotNull,
          reason: 'Hitting ceiling on recent session must advance progression with cadence pause tempo cue');
    });

    test('F6: Partially quit session (<2 sets Lite, <3 sets Standard) does NOT earn weekly credit', () async {
      final repo = WorkoutRepository();
      final now = DateTime.now();

      // Standard session with only 1 set completed out of planned sets -> Incomplete/quit!
      await repo.saveCompletedSession(CompletedWorkoutSession(
        id: 'sess_partial_std',
        scheduledSessionId: 'sched_p_std',
        routineName: 'Routine A: Upper Pull & Biceps',
        isLiteMode: false,
        startedAt: now.subtract(const Duration(minutes: 5)),
        endedAt: now,
        totalDurationSeconds: 300,
        completedSets: [
          SetLog(setIndex: 1, exerciseId: 'pullup_standard', performedReps: 5, exertion: ExertionRating.targetSweetspot, completedAt: now),
        ],
      ));

      final credit1 = await repo.getWeeklyConsistencyCredit();
      expect(credit1, equals(0),
          reason: 'Standard session with only 1 set (< 3 threshold) must earn 0 consistency credit');

      // Lite session with only 1 set completed (< 2 threshold) -> Incomplete/quit!
      await repo.saveCompletedSession(CompletedWorkoutSession(
        id: 'sess_partial_lite',
        scheduledSessionId: 'sched_p_lite',
        routineName: 'Routine B: Upper Push & Triceps',
        isLiteMode: true,
        startedAt: now.subtract(const Duration(minutes: 5)),
        endedAt: now,
        totalDurationSeconds: 300,
        completedSets: [
          SetLog(setIndex: 1, exerciseId: 'pushup_standard', performedReps: 8, exertion: ExertionRating.targetSweetspot, completedAt: now),
        ],
      ));

      final credit2 = await repo.getWeeklyConsistencyCredit();
      expect(credit2, equals(0),
          reason: 'Lite session with only 1 set (< 2 threshold) must earn 0 consistency credit');

      // Valid completed Lite session (>= 2 sets) -> Earns credit!
      await repo.saveCompletedSession(CompletedWorkoutSession(
        id: 'sess_valid_lite',
        scheduledSessionId: 'sched_v_lite',
        routineName: 'Routine C: Legs & Stability',
        isLiteMode: true,
        startedAt: now.subtract(const Duration(minutes: 15)),
        endedAt: now,
        totalDurationSeconds: 900,
        completedSets: [
          SetLog(setIndex: 1, exerciseId: 'squat_bodyweight', performedReps: 12, exertion: ExertionRating.targetSweetspot, completedAt: now),
          SetLog(setIndex: 2, exerciseId: 'lunge_reverse', performedReps: 10, exertion: ExertionRating.targetSweetspot, completedAt: now),
        ],
      ));

      final credit3 = await repo.getWeeklyConsistencyCredit();
      expect(credit3, equals(1),
          reason: 'Valid Lite session with >= 2 sets must earn 1 consistency credit');
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

    test('WP-A / CORE-FINAL-01: Corrupt session salvage must durably preserve raw bytes in SQLite archive and not earn weekly consistency credit', () async {
      final repo = WorkoutRepository();
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();

      final mixedSetsJson = '[{"setIndex":1,"exerciseId":"pullup_standard","performedReps":8,"exertion":"targetSweetspot","completedAt":"${now.toIso8601String()}"},{"corrupt_invalid_set": true},{"setIndex":2,"exerciseId":"pullup_standard","performedReps":8,"exertion":"targetSweetspot","completedAt":"${now.toIso8601String()}"},{"setIndex":3,"exerciseId":"pullup_standard","performedReps":8,"exertion":"targetSweetspot","completedAt":"${now.toIso8601String()}"}]';

      await db.insert('active_session_state', {
        'session_id': 'corrupt_salvage_sess',
        'routine_name': 'Routine A: Upper Pull & Biceps',
        'routine_name_ar': 'التمرين الأول',
        'is_lite_mode': 0,
        'started_at': now.subtract(const Duration(minutes: 30)).toIso8601String(),
        'current_exercise_index': 0,
        'current_set_index': 2,
        'completed_sets_json': mixedSetsJson,
        'active_session_json': '{}',
      });

      final snapshot = await repo.getActiveSessionState();
      expect(snapshot, isNotNull);
      expect(snapshot!.hasCorruptSetLogs, isTrue);
      expect(snapshot.completedSets.length, equals(3));

      // Salvage session with durable raw byte preservation
      await repo.salvageCorruptSession(
        session: CompletedWorkoutSession(
          id: snapshot.sessionId,
          scheduledSessionId: snapshot.sessionId,
          routineName: snapshot.routineName,
          isLiteMode: snapshot.isLiteMode,
          startedAt: snapshot.startedAt,
          endedAt: now,
          totalDurationSeconds: 1800,
          completedSets: snapshot.completedSets,
        ),
        rawCompletedSetsJson: snapshot.rawCompletedSetsJson,
        rawActiveSessionJson: snapshot.rawActiveSessionJson,
        hasCorruptSetLogs: snapshot.hasCorruptSetLogs,
      );

      // Verify raw bytes are durably archived in session_salvage_archive
      final archive = await repo.getSalvagedSessionArchive();
      expect(archive.length, equals(1));
      expect(archive.first['raw_completed_sets_json'], equals(mixedSetsJson));
      expect(archive.first['has_corrupt_logs'], equals(1));

      // Verify weekly consistency credit is ZERO
      final credit = await repo.getWeeklyConsistencyCredit();
      expect(credit, equals(0), reason: 'Corrupt partial salvage must never earn consistency credit');

      // Verify active_session_state is cleanly purged after archiving
      final remainingActive = await repo.getActiveSessionState();
      expect(remainingActive, isNull);
    });

    test('WP-B / CORE-FINAL-02: Atomic emergency pain stop executes atomically and does not create partial state', () async {
      final repo = WorkoutRepository();
      final now = DateTime.now();

      // Seed initial user profile with avoided joints
      await repo.saveUserProfile(const UserProfile(
        id: 'user_pain_atomic',
        avoidedJoints: [JointImpactTag.wristCompression],
      ));

      final painSession = CompletedWorkoutSession(
        id: 'pain_atomic_sess_1',
        scheduledSessionId: 'sched_pain_1',
        routineName: 'Routine B: Upper Push',
        isLiteMode: false,
        startedAt: now.subtract(const Duration(minutes: 10)),
        endedAt: now,
        totalDurationSeconds: 600,
        completedSets: [
          SetLog(
            setIndex: 1,
            exerciseId: 'pushup_standard',
            performedReps: 0,
            exertion: ExertionRating.painStopped,
            isPainStopped: true,
            painNote: 'Pain stop',
            completedAt: now,
          ),
        ],
        isEmergencyStopped: true,
        emergencyStopReason: 'Acute joint pain stop (SAFE-01)',
      );

      await repo.saveEmergencyPainStopSession(
        session: painSession,
        avoidedJointTags: const [JointImpactTag.shoulderAnterior, JointImpactTag.elbowMedial],
      );

      // Verify profile has both original and quarantined joints atomically
      final updatedProfile = await repo.getUserProfile();
      expect(updatedProfile, isNotNull);
      expect(updatedProfile!.avoidedJoints, contains(JointImpactTag.wristCompression));
      expect(updatedProfile.avoidedJoints, contains(JointImpactTag.shoulderAnterior));
      expect(updatedProfile.avoidedJoints, contains(JointImpactTag.elbowMedial));

      // Verify session was durably saved as emergency stop (0 credit)
      final credit = await repo.getWeeklyConsistencyCredit();
      expect(credit, equals(0));
    });

    test('WP-C: Final set interruption flags isPendingFinalization and avoids replaying final exercise set 1', () async {
      final repo = WorkoutRepository();
      final now = DateTime.now();

      // Create snapshot representing completion of the final set of the final exercise
      final finalSetSnapshot = ActiveSessionSnapshot(
        sessionId: 'session_final_interrupted',
        routineName: 'Routine A: Upper Pull & Biceps',
        routineNameAr: 'التمرين الأول',
        isLiteMode: false,
        startedAt: now.subtract(const Duration(minutes: 25)),
        currentExerciseIndex: 1, // Final exercise index
        currentSetIndex: 3,     // Final set
        completedSets: [
          SetLog(setIndex: 1, exerciseId: 'pullup_standard', performedReps: 8, exertion: ExertionRating.targetSweetspot, completedAt: now.subtract(const Duration(minutes: 15))),
          SetLog(setIndex: 2, exerciseId: 'pullup_standard', performedReps: 8, exertion: ExertionRating.targetSweetspot, completedAt: now.subtract(const Duration(minutes: 10))),
          SetLog(setIndex: 3, exerciseId: 'pullup_standard', performedReps: 8, exertion: ExertionRating.targetSweetspot, completedAt: now.subtract(const Duration(minutes: 5))),
        ],
        scheduledSession: const ScheduledSession(
          id: 'session_final_interrupted',
          routineName: 'Routine A: Upper Pull & Biceps',
          routineNameAr: 'التمرين الأول',
          isLiteMode: false,
          estimatedDurationMinutes: 25,
          targetMuscleGroup: 'LATS_BICEPS',
          exercises: [],
        ),
        isPendingFinalization: true,
      );

      await repo.saveActiveSessionState(finalSetSnapshot);

      final recovered = await repo.getActiveSessionState();
      expect(recovered, isNotNull);
      expect(recovered!.currentSetIndex, equals(3),
          reason: 'Final set index must stay on final set and not reset to 1');
    });
  });
}
