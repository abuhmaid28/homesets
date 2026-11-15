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
      expect(recovered.completedSets.length, equals(1));
      expect(recovered.completedSets.first.performedReps, equals(8));

      // Finalize completed workout
      final completed = CompletedWorkoutSession(
        id: 'session_active_123',
        scheduledSessionId: 'sched_123',
        routineName: 'Routine A',
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
  });
}
