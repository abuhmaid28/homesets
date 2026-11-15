import '../models/domain_models.dart';
import '../catalog/exercise_catalog.dart';

/// Pure-Dart Deterministic Workout Plan & Progression Engine (Zero Dependencies).
/// Strictly enforces GOV13 (Equipment Eligibility), GOV14 (Pain STOP), D10, D12, D17.
class WorkoutEngine {
  final EquipmentInventory inventory;
  final UserProfile profile;

  const WorkoutEngine({
    required this.inventory,
    required this.profile,
  });

  /// Evaluates whether an exercise is physically eligible based on verified hardware and safety tags.
  bool isExerciseEligible(Exercise exercise) {
    // 1. Joint Pain Safety Check (SAFE-01, GOV14)
    for (final tag in exercise.jointStressTags) {
      if (profile.avoidedJoints.contains(tag)) {
        return false;
      }
    }

    // 2. Hardware Availability Checks (D09, GOV13)
    for (final eq in exercise.requiredEquipment) {
      if (eq == 'pull_up_bar' && !inventory.hasPullUpBar) return false;
      if (eq == 'resistance_bands' && !inventory.hasBands) return false;
    }

    // 3. Strict Accessory & Furniture Checks (GOV13)
    // pulldown_door_band is EXCLUDED unless door anchor is explicitly verified
    if (exercise.id == 'pulldown_door_band' && !inventory.hasDoorAnchor) {
      return false;
    }

    // row_table_inverted is EXCLUDED unless sturdy load-bearing table is explicitly verified
    if (exercise.id == 'row_table_inverted' && !inventory.hasSturdyTable) {
      return false;
    }

    return true;
  }

  /// Generates the next scheduled workout session deterministically.
  ScheduledSession generateNextSession({
    required String routineCycle, // 'A', 'B', or 'C'
    DateTime? lastWorkoutTime,
    bool isLiteMode = false,
  }) {
    String routineName;
    String routineNameAr;
    String targetGroup;
    List<Exercise> candidateExercises;

    // Check muscle recovery window (36 hours minimum)
    final now = DateTime.now();
    bool requiresRotation = false;
    if (lastWorkoutTime != null) {
      final hoursElapsed = now.difference(lastWorkoutTime).inHours;
      if (hoursElapsed < 36) {
        requiresRotation = true;
      }
    }

    var selectedCycle = routineCycle;
    if (requiresRotation) {
      // Rotate away from recently fatigued group
      if (selectedCycle == 'A') {
        selectedCycle = 'B';
      } else if (selectedCycle == 'B') {
        selectedCycle = 'C';
      } else {
        selectedCycle = 'A';
      }
    }

    if (selectedCycle == 'A') {
      routineName = 'Routine A: Upper Pull & Biceps';
      routineNameAr = 'التمرين الأول: سحب علوي وبايسبس';
      targetGroup = 'LATS_BICEPS';
      candidateExercises = [
        ExerciseCatalog.getById('pullup_standard'),
        ExerciseCatalog.getById('row_band_bent_over'),
        ExerciseCatalog.getById('curl_band_biceps'),
      ];
    } else if (selectedCycle == 'B') {
      routineName = 'Routine B: Chest, Shoulders & Triceps';
      routineNameAr = 'التمرين الثاني: ضغط الصدر والكتف والترايسبس';
      targetGroup = 'CHEST_TRICEPS';
      candidateExercises = [
        ExerciseCatalog.getById('pushup_standard'),
        ExerciseCatalog.getById('pushup_incline_hands_elevated'),
        ExerciseCatalog.getById('pushup_band_resisted'),
      ];
    } else {
      routineName = 'Routine C: Legs & Stability';
      routineNameAr = 'التمرين الثالث: الأرجل وتوازن الجسم';
      targetGroup = 'LEGS_GLUTES';
      candidateExercises = [
        ExerciseCatalog.getById('squat_bodyweight'),
        ExerciseCatalog.getById('lunge_reverse'),
      ];
    }

    // Filter candidate exercises through strict eligibility predicates
    final eligibleExercises = <Exercise>[];
    for (final ex in candidateExercises) {
      if (isExerciseEligible(ex)) {
        eligibleExercises.add(ex);
      } else {
        // Fallback to unprovocative alternative if eligible
        if (ex.unprovocativeAlternativeId != null) {
          final alt = ExerciseCatalog.getById(ex.unprovocativeAlternativeId!);
          if (isExerciseEligible(alt) && !eligibleExercises.contains(alt)) {
            eligibleExercises.add(alt);
          }
        }
      }
    }

    // Ensure at least one compound movement exists
    if (eligibleExercises.isEmpty) {
      // Bodyweight push/squat default emergency safe fallbacks
      final fallbackPush = ExerciseCatalog.getById('pushup_standard');
      final fallbackSquat = ExerciseCatalog.getById('squat_bodyweight');
      if (isExerciseEligible(fallbackPush)) eligibleExercises.add(fallbackPush);
      if (isExerciseEligible(fallbackSquat)) eligibleExercises.add(fallbackSquat);
    }

    // Build planned exercises & set counts
    final plannedExercises = <PlannedExercise>[];
    if (isLiteMode) {
      // Adaptive Lite Mode: Cap at 2 exercises × 2 working sets (4 sets total, ~11-12m)
      final primary = eligibleExercises.first;
      plannedExercises.add(PlannedExercise(
        exercise: primary,
        sets: const [
          PlannedSet(setIndex: 1, targetMinReps: 8, targetMaxReps: 10, targetRestSeconds: 90),
          PlannedSet(setIndex: 2, targetMinReps: 8, targetMaxReps: 10, targetRestSeconds: 90),
        ],
      ));

      if (eligibleExercises.length > 1) {
        final accessory = eligibleExercises[1];
        plannedExercises.add(PlannedExercise(
          exercise: accessory,
          sets: const [
            PlannedSet(setIndex: 1, targetMinReps: 10, targetMaxReps: 12, targetRestSeconds: 90),
            PlannedSet(setIndex: 2, targetMinReps: 10, targetMaxReps: 12, targetRestSeconds: 90),
          ],
        ));
      }
    } else {
      // Standard Routine: 2-3 exercises × 3 working sets (~22-25m)
      for (final ex in eligibleExercises.take(3)) {
        plannedExercises.add(PlannedExercise(
          exercise: ex,
          sets: const [
            PlannedSet(setIndex: 1, targetMinReps: 8, targetMaxReps: 10, targetRestSeconds: 90),
            PlannedSet(setIndex: 2, targetMinReps: 8, targetMaxReps: 10, targetRestSeconds: 90),
            PlannedSet(setIndex: 3, targetMinReps: 8, targetMaxReps: 10, targetRestSeconds: 90),
          ],
        ));
      }
    }

    final estimatedDuration = isLiteMode ? 12 : 24;

    return ScheduledSession(
      id: 'session_${selectedCycle}_${DateTime.now().millisecondsSinceEpoch}',
      routineName: routineName,
      routineNameAr: routineNameAr,
      exercises: plannedExercises,
      isLiteMode: isLiteMode,
      estimatedDurationMinutes: estimatedDuration,
      targetMuscleGroup: targetGroup,
    );
  }

  /// Progression evaluation for the next session based on previous set performance.
  static EngineAction evaluateProgression({
    required List<SetLog> sets,
    required int targetMinReps,
    required int targetMaxReps,
  }) {
    if (sets.isEmpty) return EngineAction.holdLoad;

    // Check for acute joint pain STOP (SAFE-01)
    if (sets.any((s) => s.isPainStopped || s.exertion == ExertionRating.painStopped)) {
      return EngineAction.terminateSessionSafely;
    }

    final allHitCeiling = sets.every((s) => s.performedReps >= targetMaxReps);
    final allHitFloor = sets.every((s) => s.performedReps >= targetMinReps);
    final anyStruggledBelowFloor = sets.any((s) => s.performedReps < targetMinReps);

    if (allHitCeiling) {
      final easyReserve = sets.any((s) => s.exertion == ExertionRating.easyReserve);
      if (easyReserve && targetMaxReps >= 10) {
        return EngineAction.cadencePauseOverload;
      }
      return EngineAction.advanceBracket;
    }

    if (allHitFloor) {
      return EngineAction.expandBracket;
    }

    if (anyStruggledBelowFloor) {
      return EngineAction.holdLoad;
    }

    return EngineAction.holdLoad;
  }
}
