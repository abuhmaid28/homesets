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

  /// Returns the target muscle group for a given routine cycle letter.
  static String targetGroupForCycle(String cycle) {
    switch (cycle.toUpperCase()) {
      case 'A':
        return 'LATS_BICEPS';
      case 'B':
        return 'CHEST_TRICEPS';
      case 'C':
        return 'LEGS_GLUTES';
      default:
        return 'LATS_BICEPS';
    }
  }

  /// Returns the next cycle letter in deterministic 3-way sequence (A -> B -> C -> A).
  static String nextCycleAfter(String cycle) {
    switch (cycle.toUpperCase()) {
      case 'A':
        return 'B';
      case 'B':
        return 'C';
      case 'C':
        return 'A';
      default:
        return 'A';
    }
  }

  /// Generates the next scheduled workout session deterministically.
  ScheduledSession generateNextSession({
    required String routineCycle, // 'A', 'B', or 'C'
    DateTime? lastWorkoutTime,
    String? lastTargetMuscleGroup,
    Map<String, DateTime>? lastWorkoutTimePerGroup,
    DateTime? clock,
    Map<String, List<SetLog>>? exerciseHistory,
    bool isLiteMode = false,
  }) {
    final effectiveNow = clock ?? now ?? DateTime.now();
    String routineName;
    String routineNameAr;
    String targetGroup;
    List<Exercise> candidateExercises;

    var selectedCycle = routineCycle.toUpperCase();
    if (selectedCycle != 'A' && selectedCycle != 'B' && selectedCycle != 'C') {
      selectedCycle = 'A';
    }

    // Check muscle recovery window (36 hours minimum per muscle group)
    // CRITICAL FIX (C3R2 F3): Evaluate fatigue per muscle group across recent history
    bool isGroupFatigued(String group) {
      if (lastWorkoutTimePerGroup != null && lastWorkoutTimePerGroup.containsKey(group)) {
        final lastTime = lastWorkoutTimePerGroup[group]!;
        return effectiveNow.difference(lastTime).inHours < 36;
      }
      if (lastWorkoutTime != null) {
        final fatiguedGroup = lastTargetMuscleGroup ?? 'LATS_BICEPS';
        if (group == fatiguedGroup) {
          return effectiveNow.difference(lastWorkoutTime).inHours < 36;
        }
      }
      return false;
    }

    if (isGroupFatigued(targetGroupForCycle(selectedCycle))) {
      final next1 = nextCycleAfter(selectedCycle);
      if (!isGroupFatigued(targetGroupForCycle(next1))) {
        selectedCycle = next1;
      } else {
        final next2 = nextCycleAfter(next1);
        if (!isGroupFatigued(targetGroupForCycle(next2))) {
          selectedCycle = next2;
        } else {
          // ALL 3 muscle groups fatigued within 36 hours! (C3R2 F3)
          return ScheduledSession.unviable(
            id: 'session_rest_${effectiveNow.millisecondsSinceEpoch}',
            routineName: 'Full Joint & Muscle Recovery',
            routineNameAr: 'راحة تامة وتعافي للمفاصل والعضلات',
            targetMuscleGroup: 'RECOVERY',
            isLiteMode: isLiteMode,
            reasonEn: 'All muscle groups were trained within the last 36 hours. Full recovery is essential to prevent chronic joint fatigue and injury.',
            reasonAr: 'تم تدريب جميع المجموعات العضلية خلال الـ 36 ساعة الماضية. الراحة التامة ضرورية لتجنب إجهاد المفاصل والإصابات.',
          );
        }
      }
    }

    // Check absence deload status (C3R2 F5, D11, D15)
    AbsenceDeloadResult? absenceDeloadResult;
    if (lastWorkoutTime != null) {
      final daysElapsed = effectiveNow.difference(lastWorkoutTime).inDays;
      if (daysElapsed >= 6) {
        absenceDeloadResult = evaluateAbsenceDeload(
          daysSinceLastWorkout: daysElapsed,
          plannedSetsBaseline: isLiteMode ? 2 : 3,
        );
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

    // Build planned exercises & set counts with progressive overload and absence deload applied (C3R2 F5)
    final plannedExercises = <PlannedExercise>[];
    if (isLiteMode) {
      // Adaptive Lite Mode: Take up to 2 eligible exercises
      final liteSetsCount = (absenceDeloadResult != null && absenceDeloadResult.volumeReductionPercent >= 25) ? 1 : 2;
      final liteEligible = eligibleExercises.take(2).toList();
      for (final ex in liteEligible) {
        int minReps = 8;
        int maxReps = 10;
        String? tempoCue;

        final history = exerciseHistory?[ex.id];
        if (history != null && history.isNotEmpty) {
          final progression = evaluateProgression(
            sets: history,
            targetMinReps: minReps,
            targetMaxReps: maxReps,
            exerciseId: ex.id,
          );
          if (progression == EngineAction.cadencePauseOverload) {
            tempoCue = '2s pause top, 3s eccentric';
          } else if (progression == EngineAction.advanceBracket) {
            minReps = (minReps + 2).clamp(6, 15);
            maxReps = (maxReps + 2).clamp(8, 20);
          } else if (progression == EngineAction.expandBracket) {
            minReps = (minReps + 1).clamp(6, maxReps);
          }
        }

        plannedExercises.add(PlannedExercise(
          exercise: ex,
          sets: List.generate(
            liteSetsCount,
            (setIdx) => PlannedSet(
              setIndex: setIdx + 1,
              targetMinReps: minReps,
              targetMaxReps: maxReps,
              tempoCue: tempoCue,
              targetRestSeconds: 90,
            ),
          ),
        ));
      }
    } else {
      // Standard Routine: Take up to 3 eligible movements
      final count = eligibleExercises.length > 3 ? 3 : eligibleExercises.length;
      for (int i = 0; i < count; i++) {
        final ex = eligibleExercises[i];
        int setsCount;
        if (absenceDeloadResult != null && absenceDeloadResult.volumeReductionPercent >= 40) {
          setsCount = (i == 0) ? 2 : 1;
        } else if (absenceDeloadResult != null && absenceDeloadResult.volumeReductionPercent >= 25) {
          setsCount = 2;
        } else {
          setsCount = (i == 0) ? 3 : 2;
        }

        int minReps = 8;
        int maxReps = 10;
        String? tempoCue;

        final history = exerciseHistory?[ex.id];
        if (history != null && history.isNotEmpty) {
          final progression = evaluateProgression(
            sets: history,
            targetMinReps: minReps,
            targetMaxReps: maxReps,
            exerciseId: ex.id,
          );
          if (progression == EngineAction.cadencePauseOverload) {
            tempoCue = '2s pause top, 3s eccentric';
          } else if (progression == EngineAction.advanceBracket) {
            minReps = (minReps + 2).clamp(6, 15);
            maxReps = (maxReps + 2).clamp(8, 20);
          } else if (progression == EngineAction.expandBracket) {
            minReps = (minReps + 1).clamp(6, maxReps);
          } else if (progression == EngineAction.stepBackBracket) {
            minReps = (minReps - 2).clamp(4, 8);
            maxReps = (maxReps - 2).clamp(6, 10);
          }
        }

        plannedExercises.add(PlannedExercise(
          exercise: ex,
          sets: List.generate(
            setsCount,
            (setIdx) => PlannedSet(
              setIndex: setIdx + 1,
              targetMinReps: minReps,
              targetMaxReps: maxReps,
              tempoCue: tempoCue,
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
      absenceDeloadResult: absenceDeloadResult,
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

  /// Evaluates cadence/tempo progression when bodyweight reps reach ceiling (SCEN-013 to SCEN-020).
  static CadencePauseResult evaluateCadencePause({
    required String exerciseId,
    required int baseRepsCeiling,
    required int cadenceLevel,
  }) {
    int isoPause;
    int eccentric;
    int targetReps;

    switch (cadenceLevel) {
      case 1:
        isoPause = 1;
        eccentric = 2;
        targetReps = 9;
        break;
      case 2:
        isoPause = 1;
        eccentric = 3;
        targetReps = 8;
        break;
      case 3:
        isoPause = 2;
        eccentric = 3;
        targetReps = 7;
        break;
      case 4:
        isoPause = 2;
        eccentric = 4;
        targetReps = 6;
        break;
      case 5:
        isoPause = 2;
        eccentric = 4;
        targetReps = 5;
        break;
      case 6:
      case 7:
      case 8:
      default:
        isoPause = 3;
        eccentric = 4;
        targetReps = 5;
        break;
    }

    return CadencePauseResult(
      action: 'APPLY_TEMPO',
      isometricPauseTopSec: isoPause,
      eccentricSec: eccentric,
      targetReps: targetReps,
    );
  }

  /// Evaluates band-assisted pull-up progression (inverse physics) (SCEN-021 to SCEN-032).
  static BandAssistanceResult evaluateBandAssistance({
    required String exerciseId,
    required String currentAssistanceRung,
    required List<Map<String, dynamic>> setsCompleted,
    bool anchorWarningReported = false,
  }) {
    if (anchorWarningReported) {
      return const BandAssistanceResult(
        action: 'SAFETY_PROMPT',
        warning: 'Loop band securely under both feet or use knee loop to prevent band snap',
        freezeProgression: false,
      );
    }

    const rungs = ['HEAVY_PURPLE', 'MEDIUM_BLACK', 'LIGHT_RED', 'EXTRA_LIGHT_YELLOW', 'UNASSISTED_BODYWEIGHT'];
    final currentIndex = rungs.indexOf(currentAssistanceRung.toUpperCase());

    final allHitTarget = setsCompleted.isNotEmpty &&
        setsCompleted.every((s) => (s['reps'] as int? ?? 0) >= 10 && (s['exertion'] as String? ?? '') == 'TARGET_SWEETSPOT');

    if (allHitTarget && currentIndex >= 0 && currentIndex < rungs.length - 1) {
      final nextRung = rungs[currentIndex + 1];
      return BandAssistanceResult(
        action: 'REDUCE_ASSISTANCE',
        nextAssistanceRung: nextRung,
        prescribedReps: '3x6-8',
      );
    }

    return BandAssistanceResult(
      action: 'HOLD_ASSISTANCE',
      currentAssistanceRung: currentAssistanceRung,
      prescribedReps: '3x6',
    );
  }

  /// Evaluates band resistance double progression (SCEN-033 to SCEN-044).
  static BandResistanceResult evaluateBandResistance({
    required String exerciseId,
    required int currentResistanceRank,
    required List<int> targetReps,
    required List<Map<String, dynamic>> sets,
  }) {
    final maxTarget = targetReps.length > 1 ? targetReps[1] : 12;
    final allHitCeiling = sets.isNotEmpty &&
        sets.every((s) => (s['reps'] as int? ?? 0) >= maxTarget && (s['exertion'] as String? ?? '') == 'TARGET_SWEETSPOT');

    if (allHitCeiling) {
      return BandResistanceResult(
        action: 'INCREASE_RESISTANCE',
        nextResistanceRank: currentResistanceRank + 1,
        resetRepsTo: const [8, 10],
        reason: 'Standard double progression: add tension, reset reps',
      );
    }

    return const BandResistanceResult(
      action: 'HOLD_LOAD',
    );
  }

  /// Evaluates absence deload without streak penalty (D11, D15, SCEN-069 to SCEN-078).
  static AbsenceDeloadResult evaluateAbsenceDeload({
    required int daysSinceLastWorkout,
    required int plannedSetsBaseline,
  }) {
    if (daysSinceLastWorkout <= 5) {
      return const AbsenceDeloadResult(
        action: EngineAction.normalRotationResume,
        volumeReductionPercent: 0,
        streakPenaltyApplied: false,
        guiltFreeMessaging: true,
      );
    } else if (daysSinceLastWorkout <= 10) {
      return const AbsenceDeloadResult(
        action: EngineAction.lightReentryDeload,
        volumeReductionPercent: 25,
        streakPenaltyApplied: false,
        guiltFreeMessaging: true,
      );
    } else {
      return const AbsenceDeloadResult(
        action: EngineAction.adaptationReentryDeload,
        volumeReductionPercent: 40,
        streakPenaltyApplied: false,
        guiltFreeMessaging: true,
      );
    }
  }

  /// Checks whether a session that spans midnight constitutes a single continuous session (SCEN-099).
  static bool isContinuousShiftWorkSession(DateTime startUtc, DateTime endUtc) {
    final diffMinutes = endUtc.difference(startUtc).inMinutes;
    return diffMinutes >= 1 && diffMinutes <= 180;
  }
}
