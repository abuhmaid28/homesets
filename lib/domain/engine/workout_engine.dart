import '../models/domain_models.dart';
import '../catalog/exercise_catalog.dart';

/// Pure-Dart Deterministic Workout Plan & Progression Engine (Zero Dependencies).
/// Strictly enforces GOV13 (Equipment Eligibility), GOV14 (Pain STOP), D10, D12, D17.
class WorkoutEngine {
  final EquipmentInventory inventory;
  final UserProfile profile;
  final DateTime? now;

  const WorkoutEngine({
    required this.inventory,
    required this.profile,
    this.now,
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

    // 3. Strict Accessory & Furniture Checks (GOV13, C3R-05)
    // Parallel / neutral grip handles required for neutral-grip chin-up
    if (exercise.id == 'chinup_neutral' && !inventory.hasParallelGrip) {
      return false;
    }

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
    String? lastTargetMuscleGroup,
    DateTime? clock,
    bool isLiteMode = false,
  }) {
    final effectiveNow = clock ?? now ?? DateTime.now();
    String routineName;
    String routineNameAr;
    String targetGroup;
    List<Exercise> candidateExercises;

    // Check muscle recovery window (36 hours minimum)
    bool requiresRotation = false;
    if (lastWorkoutTime != null) {
      final hoursElapsed = effectiveNow.difference(lastWorkoutTime).inHours;
      if (hoursElapsed < 36) {
        requiresRotation = true;
      }
    }

    var selectedCycle = routineCycle.toUpperCase();
    if (selectedCycle != 'A' && selectedCycle != 'B' && selectedCycle != 'C') {
      selectedCycle = 'A';
    }

    if (requiresRotation) {
      // Rotate away from recently fatigued group: A -> B -> C -> A
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
        ExerciseCatalog.getById('chinup_neutral'),
        ExerciseCatalog.getById('pullup_wide'),
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
        if (!eligibleExercises.contains(ex)) {
          eligibleExercises.add(ex);
        }
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

    // SAFE FALLBACK (C3R-01): If all candidate exercises and alternatives are barred by
    // joint pain or missing equipment, return an explicit unviable session.
    // NEVER override pain or equipment exclusions to force a workout!
    if (eligibleExercises.isEmpty) {
      return ScheduledSession.unviable(
        id: 'session_${selectedCycle}_${isLiteMode ? "lite" : "std"}_${effectiveNow.millisecondsSinceEpoch}',
        routineName: routineName,
        routineNameAr: routineNameAr,
        targetMuscleGroup: targetGroup,
        isLiteMode: isLiteMode,
        reasonEn: 'All movements for $routineName require hardware or joints currently marked as unavailable. Your joint health and safety come first.',
        reasonAr: 'جميع تمارين $routineNameAr تتطلب أدوات غير متوفرة أو مفاصل مستبعدة حالياً. سلامة مفاصلك أولوية قصوى.',
      );
    }

    // Build planned exercises & set counts
    final plannedExercises = <PlannedExercise>[];
    if (isLiteMode) {
      // Adaptive Lite Mode: Take up to 2 eligible exercises × 2 working sets (max 4 sets total, ~11-15m)
      final liteEligible = eligibleExercises.take(2).toList();
      for (final ex in liteEligible) {
        plannedExercises.add(PlannedExercise(
          exercise: ex,
          sets: const [
            PlannedSet(setIndex: 1, targetMinReps: 8, targetMaxReps: 10, targetRestSeconds: 90),
            PlannedSet(setIndex: 2, targetMinReps: 8, targetMaxReps: 10, targetRestSeconds: 90),
          ],
        ));
      }
    } else {
      // Standard Routine: Take up to 3 eligible movements
      final count = eligibleExercises.length > 3 ? 3 : eligibleExercises.length;
      for (int i = 0; i < count; i++) {
        final ex = eligibleExercises[i];
        final setsCount = (i == 0) ? 3 : 2;
        plannedExercises.add(PlannedExercise(
          exercise: ex,
          sets: List.generate(
            setsCount,
            (setIdx) => PlannedSet(
              setIndex: setIdx + 1,
              targetMinReps: 8,
              targetMaxReps: 10,
              targetRestSeconds: 90,
            ),
          ),
        ));
      }
    }

    final totalSets = plannedExercises.fold<int>(0, (sum, p) => sum + p.sets.length);
    final estimatedDuration = isLiteMode ? (totalSets * 3) : (totalSets * 4);

    return ScheduledSession(
      id: 'session_${selectedCycle}_${isLiteMode ? "lite" : "std"}_${effectiveNow.millisecondsSinceEpoch}',
      routineName: routineName,
      routineNameAr: routineNameAr,
      exercises: plannedExercises,
      isLiteMode: isLiteMode,
      estimatedDurationMinutes: estimatedDuration,
      targetMuscleGroup: targetGroup,
      isViable: true,
    );
  }

  /// Progression evaluation for the next session based on previous set performance.
  static EngineAction evaluateProgression({
    required List<SetLog> sets,
    required int targetMinReps,
    required int targetMaxReps,
    String? exerciseId,
  }) {
    if (sets.isEmpty) return EngineAction.holdLoad;

    // Check for acute joint pain STOP (SAFE-01)
    if (sets.any((s) => s.isPainStopped || s.exertion == ExertionRating.painStopped)) {
      return EngineAction.terminateSessionSafely;
    }

    final effectiveExerciseId = exerciseId ?? sets.first.exerciseId;
    final allHitCeiling = sets.every((s) => s.performedReps >= targetMaxReps);
    final allHitFloor = sets.every((s) => s.performedReps >= targetMinReps);
    final anyStruggledBelowFloor = sets.any((s) => s.performedReps < targetMinReps);

    if (allHitCeiling) {
      final easyReserve = sets.any((s) => s.exertion == ExertionRating.easyReserve);
      if (effectiveExerciseId == 'pullup_standard' && targetMaxReps >= 10) {
        return EngineAction.cadencePauseOverload;
      }
      if (easyReserve && targetMaxReps >= 10 && effectiveExerciseId != 'pushup_standard') {
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
