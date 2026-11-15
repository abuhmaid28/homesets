import 'package:flutter_test/flutter_test.dart';
import 'package:homesets/domain/models/domain_models.dart';
import 'package:homesets/domain/catalog/exercise_catalog.dart';
import 'package:homesets/domain/engine/workout_engine.dart';

void main() {
  group('WorkoutEngine Equipment Eligibility (GOV13)', () {
    test('excludes pull-up bar exercises if user has no bar', () {
      const inventory = EquipmentInventory(hasPullUpBar: false, hasBands: true);
      const profile = UserProfile(id: 'user_1');
      const engine = WorkoutEngine(inventory: inventory, profile: profile);

      final pullup = ExerciseCatalog.getById('pullup_standard');
      final chinup = ExerciseCatalog.getById('chinup_neutral');
      final bandRow = ExerciseCatalog.getById('row_band_bent_over');

      expect(engine.isExerciseEligible(pullup), isFalse);
      expect(engine.isExerciseEligible(chinup), isFalse);
      expect(engine.isExerciseEligible(bandRow), isTrue);
    });

    test('excludes pulldown_door_band when door anchor is unverified/false', () {
      const inventory = EquipmentInventory(hasPullUpBar: false, hasBands: true, hasDoorAnchor: false);
      const profile = UserProfile(id: 'user_1');
      const engine = WorkoutEngine(inventory: inventory, profile: profile);

      final doorPulldown = ExerciseCatalog.getById('pulldown_door_band');
      expect(engine.isExerciseEligible(doorPulldown), isFalse);

      final withAnchor = inventory.copyWith(hasDoorAnchor: true);
      final engineWithAnchor = WorkoutEngine(inventory: withAnchor, profile: profile);
      expect(engineWithAnchor.isExerciseEligible(doorPulldown), isTrue);
    });

    test('excludes row_table_inverted when sturdy table is unverified/false', () {
      const inventory = EquipmentInventory(hasPullUpBar: true, hasBands: false, hasSturdyTable: false);
      const profile = UserProfile(id: 'user_1');
      const engine = WorkoutEngine(inventory: inventory, profile: profile);

      final tableRow = ExerciseCatalog.getById('row_table_inverted');
      expect(engine.isExerciseEligible(tableRow), isFalse);

      final withTable = inventory.copyWith(hasSturdyTable: true);
      final engineWithTable = WorkoutEngine(inventory: withTable, profile: profile);
      expect(engineWithTable.isExerciseEligible(tableRow), isTrue);
    });
  });

  group('WorkoutEngine Safety Invariants & Pain STOP (SAFE-01, GOV14)', () {
    test('strictly filters out exercises matching avoided joints in profile', () {
      const inventory = EquipmentInventory(
        hasPullUpBar: true,
        hasBands: true,
        hasParallelGrip: true,
      );
      const profile = UserProfile(
        id: 'user_1',
        avoidedJoints: [JointImpactTag.shoulderSubacromial],
      );
      const engine = WorkoutEngine(inventory: inventory, profile: profile);

      final widePullup = ExerciseCatalog.getById('pullup_wide');
      final standardPullup = ExerciseCatalog.getById('pullup_standard');
      final chinup = ExerciseCatalog.getById('chinup_neutral'); // Only medial elbow tag

      expect(engine.isExerciseEligible(widePullup), isFalse);
      expect(engine.isExerciseEligible(standardPullup), isFalse);
      expect(engine.isExerciseEligible(chinup), isTrue);
    });

    test('strictly excludes chinup_neutral when parallel grip is absent (C3R-05)', () {
      const inventory = EquipmentInventory(
        hasPullUpBar: true,
        hasBands: true,
        hasParallelGrip: false,
      );
      const profile = UserProfile(id: 'user_1');
      const engine = WorkoutEngine(inventory: inventory, profile: profile);

      final chinup = ExerciseCatalog.getById('chinup_neutral');
      expect(engine.isExerciseEligible(chinup), isFalse);
    });

    test('evaluates pain stop as immediate session termination without loaded substitute', () {
      final logs = [
        SetLog(
          setIndex: 1,
          exerciseId: 'pullup_standard',
          performedReps: 6,
          exertion: ExertionRating.targetSweetspot,
          completedAt: DateTime.now(),
        ),
        SetLog(
          setIndex: 2,
          exerciseId: 'pullup_standard',
          performedReps: 3,
          exertion: ExertionRating.painStopped,
          isPainStopped: true,
          painNote: 'Shoulder twinge',
          completedAt: DateTime.now(),
        ),
      ];

      final action = WorkoutEngine.evaluateProgression(
        sets: logs,
        targetMinReps: 6,
        targetMaxReps: 8,
      );

      expect(action, equals(EngineAction.terminateSessionSafely));
    });
  });

  group('WorkoutEngine Adaptive Lite Mode (D12, WP28)', () {
    test('generates exactly 4 working sets and estimated duration <= 15 minutes', () {
      const inventory = EquipmentInventory(hasPullUpBar: true, hasBands: true);
      const profile = UserProfile(id: 'user_1');
      const engine = WorkoutEngine(inventory: inventory, profile: profile);

      final session = engine.generateNextSession(
        routineCycle: 'A',
        isLiteMode: true,
      );

      expect(session.isLiteMode, isTrue);
      expect(session.estimatedDurationMinutes, lessThanOrEqualTo(15));
      expect(session.exercises.length, lessThanOrEqualTo(2));

      final totalSets = session.exercises.fold<int>(0, (sum, ex) => sum + ex.sets.length);
      expect(totalSets, equals(4));

      // Rest intervals must NOT be rushed (must remain >= 90s per set)
      for (final ex in session.exercises) {
        for (final s in ex.sets) {
          expect(s.targetRestSeconds, greaterThanOrEqualTo(90));
        }
      }
    });
  });

  group('WorkoutEngine Empty-Catalog & Unviable Fallback (WP02, C3R-01)', () {
    test('returns unviable session and does NOT throw RangeError when all movements are barred', () {
      const inventory = EquipmentInventory(
        hasPullUpBar: false,
        hasBands: false,
        hasDoorAnchor: false,
        hasSturdyTable: false,
        hasParallelGrip: false,
      );
      const profile = UserProfile(
        id: 'user_injured',
        avoidedJoints: JointImpactTag.values, // All joints avoided
      );
      const engine = WorkoutEngine(inventory: inventory, profile: profile);

      // Standard mode
      final stdSession = engine.generateNextSession(routineCycle: 'A', isLiteMode: false);
      expect(stdSession.isViable, isFalse);
      expect(stdSession.exercises, isEmpty);
      expect(stdSession.unviableReason, isNotNull);

      // Lite mode must NOT throw RangeError (Bad state: No element)
      final liteSession = engine.generateNextSession(routineCycle: 'A', isLiteMode: true);
      expect(liteSession.isViable, isFalse);
      expect(liteSession.exercises, isEmpty);
      expect(liteSession.unviableReason, isNotNull);
    });
  });

  group('WorkoutEngine Deterministic Rotation & Clock Injection (WP03, C3R-02)', () {
    test('rotates away from fatigued muscle group when < 36 hours elapsed', () {
      const inventory = EquipmentInventory();
      const profile = UserProfile(id: 'user_clock');
      const engine = WorkoutEngine(inventory: inventory, profile: profile);

      final t0 = DateTime(2026, 11, 15, 8, 0);

      // Request Routine A with last workout completed 12 hours ago
      final session12h = engine.generateNextSession(
        routineCycle: 'A',
        lastWorkoutTime: t0,
        clock: t0.add(const Duration(hours: 12)),
      );

      // Must rotate to Routine B (CHEST_TRICEPS)
      expect(session12h.targetMuscleGroup, equals('CHEST_TRICEPS'));
      expect(session12h.routineName, contains('Routine B'));

      // Request Routine A with last workout completed 40 hours ago (> 36h)
      final session40h = engine.generateNextSession(
        routineCycle: 'A',
        lastWorkoutTime: t0,
        clock: t0.add(const Duration(hours: 40)),
      );

      // Fatigue expired: Routine A is cleared
      expect(session40h.targetMuscleGroup, equals('LATS_BICEPS'));
      expect(session40h.routineName, contains('Routine A'));
    });

    test('progresses through A -> B -> C -> A 3-way rotation', () {
      const inventory = EquipmentInventory();
      const profile = UserProfile(id: 'user_rot');
      const engine = WorkoutEngine(inventory: inventory, profile: profile);

      final sessionA = engine.generateNextSession(routineCycle: 'A');
      expect(sessionA.targetMuscleGroup, equals('LATS_BICEPS'));

      final sessionB = engine.generateNextSession(routineCycle: 'B');
      expect(sessionB.targetMuscleGroup, equals('CHEST_TRICEPS'));

      final sessionC = engine.generateNextSession(routineCycle: 'C');
      expect(sessionC.targetMuscleGroup, equals('LEGS_GLUTES'));
    });
  });

  group('WorkoutEngine Progression Physics (D17, WP16)', () {
    test('advances bracket floor when hitting bracket top', () {
      final logs = [
        SetLog(setIndex: 1, exerciseId: 'pushup_standard', performedReps: 10, exertion: ExertionRating.targetSweetspot, completedAt: DateTime.now()),
        SetLog(setIndex: 2, exerciseId: 'pushup_standard', performedReps: 10, exertion: ExertionRating.targetSweetspot, completedAt: DateTime.now()),
        SetLog(setIndex: 3, exerciseId: 'pushup_standard', performedReps: 10, exertion: ExertionRating.targetSweetspot, completedAt: DateTime.now()),
      ];

      final action = WorkoutEngine.evaluateProgression(
        sets: logs,
        targetMinReps: 8,
        targetMaxReps: 10,
      );

      expect(action, equals(EngineAction.advanceBracket));
    });

    test('triggers cadence pause overload when hitting 3x10 ceiling with easy reserve', () {
      final logs = [
        SetLog(setIndex: 1, exerciseId: 'pullup_standard', performedReps: 10, exertion: ExertionRating.easyReserve, completedAt: DateTime.now()),
        SetLog(setIndex: 2, exerciseId: 'pullup_standard', performedReps: 10, exertion: ExertionRating.targetSweetspot, completedAt: DateTime.now()),
        SetLog(setIndex: 3, exerciseId: 'pullup_standard', performedReps: 10, exertion: ExertionRating.targetSweetspot, completedAt: DateTime.now()),
      ];

      final action = WorkoutEngine.evaluateProgression(
        sets: logs,
        targetMinReps: 8,
        targetMaxReps: 10,
      );

      expect(action, equals(EngineAction.cadencePauseOverload));
    });
  });
}
