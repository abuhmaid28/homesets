import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:homesets/domain/models/domain_models.dart';
import 'package:homesets/data/database/database_helper.dart';
import 'package:homesets/data/repositories/workout_repository.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for headless desktop tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setCustomFactory(databaseFactoryFfi);
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  group('WorkoutRepository Offline Persistence (WP20, WP21, WP22, WP23)', () {
    test('persists and retrieves user profile with avoided joints', () async {
      final repo = WorkoutRepository();
      const profile = UserProfile(
        id: 'user_test_1',
        goal: 'MUSCLE_BUILDING',
        wakeTimeMinutes: 900,
        shiftStartMinutes: 1140,
        targetWorkoutsPerWeek: 4,
        avoidedJoints: [JointImpactTag.shoulderSubacromial, JointImpactTag.elbowMedial],
      );

      await repo.saveUserProfile(profile);
      final retrieved = await repo.getUserProfile();

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('user_test_1'));
      expect(retrieved.wakeTimeMinutes, equals(900));
      expect(retrieved.avoidedJoints.length, equals(2));
      expect(retrieved.avoidedJoints, contains(JointImpactTag.shoulderSubacromial));
      expect(retrieved.avoidedJoints, contains(JointImpactTag.elbowMedial));
    });

    test('persists and retrieves hardware equipment inventory', () async {
      final repo = WorkoutRepository();
      const inventory = EquipmentInventory(
        hasPullUpBar: true,
        hasBands: true,
        hasDoorAnchor: false,
        hasSturdyTable: true,
        hasParallelGrip: false,
      );

      await repo.saveEquipmentInventory(inventory);
      final retrieved = await repo.getEquipmentInventory();

      expect(retrieved.hasPullUpBar, isTrue);
      expect(retrieved.hasBands, isTrue);
      expect(retrieved.hasDoorAnchor, isFalse);
      expect(retrieved.hasSturdyTable, isTrue);
      expect(retrieved.hasParallelGrip, isFalse);
    });

    test('recovers active session state after crash or app restart (WP22)', () async {
      final repo = WorkoutRepository();
      final startTime = DateTime.now();
      final snapshot = ActiveSessionSnapshot(
        sessionId: 'session_active_123',
        routineName: 'Routine A',
        routineNameAr: 'التمرين الأول',
        isLiteMode: false,
        startedAt: startTime,
        currentExerciseIndex: 1,
        currentSetIndex: 2,
        completedSets: [
          SetLog(
            setIndex: 1,
            exerciseId: 'pullup_standard',
            performedReps: 8,
            exertion: ExertionRating.targetSweetspot,
            completedAt: startTime.add(const Duration(minutes: 2)),
          ),
          SetLog(
            setIndex: 2,
            exerciseId: 'pullup_standard',
            performedReps: 8,
            exertion: ExertionRating.targetSweetspot,
            completedAt: startTime.add(const Duration(minutes: 5)),
          ),
          SetLog(
            setIndex: 3,
            exerciseId: 'pullup_standard',
            performedReps: 8,
            exertion: ExertionRating.targetSweetspot,
            completedAt: startTime.add(const Duration(minutes: 8)),
          ),
        ],
      );

      // Save active session state (simulates write-order before rest timer)
      await repo.saveActiveSessionState(snapshot);

      // Query active session state (simulates app relaunch after crash)
      final recovered = await repo.getActiveSessionState();
      expect(recovered, isNotNull);
      expect(recovered!.sessionId, equals('session_active_123'));
      expect(recovered.currentExerciseIndex, equals(1));
      expect(recovered.currentSetIndex, equals(2));
      expect(recovered.completedSets.length, equals(3));
      expect(recovered.completedSets.first.performedReps, equals(8));

      // Finalize completed workout
      final completed = CompletedWorkoutSession(
        id: 'session_active_123',
        scheduledSessionId: 'sched_123',
        routineName: 'Routine A: Upper Pull',
        isLiteMode: false,
        startedAt: startTime,
        endedAt: DateTime.now(),
        totalDurationSeconds: 1200,
        completedSets: recovered.completedSets,
      );

      await repo.saveCompletedSession(completed);

      // Active session state must be automatically purged after completion
      final postCompletedState = await repo.getActiveSessionState();
      expect(postCompletedState, isNull);

      // Weekly consistency must now count 1 session
      final credit = await repo.getWeeklyConsistencyCredit();
      expect(credit, equals(1));
    });

    test('weekly consistency credit strictly ignores emergency stopped sessions (WP07, C3R-07)', () async {
      final repo = WorkoutRepository();
      final now = DateTime.now();

      // Save an emergency stopped session
      final emergencySession = CompletedWorkoutSession(
        id: 'emergency_session_1',
        scheduledSessionId: 'sched_emg',
        routineName: 'Routine A',
        isLiteMode: false,
        startedAt: now.subtract(const Duration(minutes: 5)),
        endedAt: now,
        totalDurationSeconds: 300,
        completedSets: const [],
        isEmergencyStopped: true,
        emergencyStopReason: 'Acute joint pain stop (SAFE-01)',
      );
      await repo.saveCompletedSession(emergencySession);

      // Weekly consistency must NOT count emergency stop as completed workout
      final creditAfterEmergency = await repo.getWeeklyConsistencyCredit();
      expect(creditAfterEmergency, equals(0));

      // Save a valid completed workout with completed sets
      final normalSession = CompletedWorkoutSession(
        id: 'normal_session_1',
        scheduledSessionId: 'sched_norm',
        routineName: 'Routine A',
        isLiteMode: false,
        startedAt: now.subtract(const Duration(minutes: 30)),
        endedAt: now,
        totalDurationSeconds: 1800,
        completedSets: [
          SetLog(
            setIndex: 1,
            exerciseId: 'pullup_standard',
            performedReps: 8,
            exertion: ExertionRating.targetSweetspot,
            completedAt: now.subtract(const Duration(minutes: 10)),
          ),
          SetLog(
            setIndex: 2,
            exerciseId: 'pullup_standard',
            performedReps: 8,
            exertion: ExertionRating.targetSweetspot,
            completedAt: now.subtract(const Duration(minutes: 7)),
          ),
          SetLog(
            setIndex: 3,
            exerciseId: 'pullup_standard',
            performedReps: 8,
            exertion: ExertionRating.targetSweetspot,
            completedAt: now.subtract(const Duration(minutes: 4)),
          ),
        ],
        isEmergencyStopped: false,
      );
      await repo.saveCompletedSession(normalSession);

      final creditAfterNormal = await repo.getWeeklyConsistencyCredit();
      expect(creditAfterNormal, equals(1));
    });

    test('getNextRoutineCycle deterministically cycles A -> B -> C -> A based on completed sessions (WP03, C3R-02)', () async {
      final repo = WorkoutRepository();
      final now = DateTime.now();

      // No workouts: starts at A
      final cycle0 = await repo.getNextRoutineCycle();
      expect(cycle0, equals('A'));

      // Finish Routine A: next is B
      await repo.saveCompletedSession(CompletedWorkoutSession(
        id: 'sess_a',
        scheduledSessionId: 'sched_a',
        routineName: 'Routine A: Upper Pull & Biceps',
        startedAt: now.subtract(const Duration(days: 3)),
        endedAt: now.subtract(const Duration(days: 3, minutes: -30)),
        totalDurationSeconds: 1800,
        completedSets: const [],
      ));
      final cycle1 = await repo.getNextRoutineCycle();
      expect(cycle1, equals('B'));

      // Finish Routine B: next is C
      await repo.saveCompletedSession(CompletedWorkoutSession(
        id: 'sess_b',
        scheduledSessionId: 'sched_b',
        routineName: 'Routine B: Upper Push & Triceps',
        startedAt: now.subtract(const Duration(days: 2)),
        endedAt: now.subtract(const Duration(days: 2, minutes: -30)),
        totalDurationSeconds: 1800,
        completedSets: const [],
      ));
      final cycle2 = await repo.getNextRoutineCycle();
      expect(cycle2, equals('C'));

      // Finish Routine C: next is A
      await repo.saveCompletedSession(CompletedWorkoutSession(
        id: 'sess_c',
        scheduledSessionId: 'sched_c',
        routineName: 'Routine C: Legs & Stability',
        startedAt: now.subtract(const Duration(days: 1)),
        endedAt: now.subtract(const Duration(days: 1, minutes: -30)),
        totalDurationSeconds: 1800,
        completedSets: const [],
      ));
      final cycle3 = await repo.getNextRoutineCycle();
      expect(cycle3, equals('A'));
    });

    test('recovers exact original ScheduledSession on crash resume (WP04, C3R-03)', () async {
      final repo = WorkoutRepository();
      final startTime = DateTime.now();
      const scheduled = ScheduledSession(
        id: 'custom_lite_session_456',
        routineName: 'Routine B: Upper Push',
        routineNameAr: 'التمرين الثاني',
        isLiteMode: true,
        estimatedDurationMinutes: 12,
        targetMuscleGroup: 'CHEST_TRICEPS',
        exercises: [],
      );

      final snapshot = ActiveSessionSnapshot(
        sessionId: 'custom_lite_session_456',
        routineName: 'Routine B: Upper Push',
        routineNameAr: 'التمرين الثاني',
        isLiteMode: true,
        startedAt: startTime,
        currentExerciseIndex: 1,
        currentSetIndex: 2,
        completedSets: const [],
        scheduledSession: scheduled,
      );

      await repo.saveActiveSessionState(snapshot);

      final recovered = await repo.getActiveSessionState();
      expect(recovered, isNotNull);
      expect(recovered!.scheduledSession, isNotNull);
      expect(recovered.scheduledSession!.id, equals('custom_lite_session_456'));
      expect(recovered.scheduledSession!.isLiteMode, isTrue);
      expect(recovered.scheduledSession!.targetMuscleGroup, equals('CHEST_TRICEPS'));
    });

    test('getLastWorkoutMuscleGroup returns target group of latest completed workout (WP02)', () async {
      final repo = WorkoutRepository();
      final now = DateTime.now();

      final group0 = await repo.getLastWorkoutMuscleGroup();
      expect(group0, isNull);

      await repo.saveCompletedSession(CompletedWorkoutSession(
        id: 'sess_group_b',
        scheduledSessionId: 'sched_group_b',
        routineName: 'Routine B: Upper Push & Triceps',
        startedAt: now.subtract(const Duration(hours: 5)),
        endedAt: now.subtract(const Duration(hours: 4)),
        totalDurationSeconds: 1800,
        completedSets: [
          SetLog(
            setIndex: 1,
            exerciseId: 'pushup_standard',
            performedReps: 10,
            exertion: ExertionRating.targetSweetspot,
            completedAt: now.subtract(const Duration(hours: 4)),
          ),
        ],
      ));

      final group1 = await repo.getLastWorkoutMuscleGroup();
      expect(group1, equals('CHEST_TRICEPS'));
    });

    test('getRecentExerciseHistory retrieves completed sets grouped by exerciseId (WP06)', () async {
      final repo = WorkoutRepository();
      final now = DateTime.now();

      await repo.saveCompletedSession(CompletedWorkoutSession(
        id: 'sess_hist_1',
        scheduledSessionId: 'sched_hist_1',
        routineName: 'Routine A: Upper Pull & Biceps',
        startedAt: now.subtract(const Duration(days: 1)),
        endedAt: now.subtract(const Duration(days: 1, minutes: -30)),
        totalDurationSeconds: 1800,
        completedSets: [
          SetLog(
            setIndex: 1,
            exerciseId: 'pullup_standard',
            performedReps: 10,
            exertion: ExertionRating.targetSweetspot,
            completedAt: now.subtract(const Duration(days: 1)),
          ),
          SetLog(
            setIndex: 2,
            exerciseId: 'pullup_standard',
            performedReps: 10,
            exertion: ExertionRating.targetSweetspot,
            completedAt: now.subtract(const Duration(days: 1)),
          ),
        ],
      ));

      final history = await repo.getRecentExerciseHistory();
      expect(history.containsKey('pullup_standard'), isTrue);
      expect(history['pullup_standard']!.length, equals(2));
      expect(history['pullup_standard']!.first.performedReps, equals(10));
    });
  });
}
