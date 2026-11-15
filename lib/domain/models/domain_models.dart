/// Pure-Dart Immutable Domain Models for HOMESETS (Zero Flutter Dependencies)
/// Strictly aligns with DOMAIN_MODEL_SPEC.md, DECISION_REGISTER.md (D04, D09, D17, GOV13, GOV14).

enum MovementPattern {
  verticalPull,
  horizontalPull,
  horizontalPush,
  quadDominant,
  isolationArm,
}

enum JointImpactTag {
  shoulderSubacromial,
  shoulderAnterior,
  elbowMedial,
  wristCompression,
  lumbarShear,
  kneePatellar,
}

enum ExertionRating {
  easyReserve,
  targetSweetspot,
  maxEffort,
  painStopped,
}

enum BandApplicationMode {
  assistance,
  resistance,
}

enum EngineAction {
  advanceBracket,
  expandBracket,
  holdLoad,
  stepBackBracket,
  cadencePauseOverload,
  reduceAssistance,
  holdAssistance,
  increaseResistance,
  unilateralOverload,
  leverageAdvance,
  leverageRegress,
  pruneToEssentials,
  substituteAccordingToHardware,
  terminateSessionSafely,
  filterProvocativeExercises,
  allowSession,
  rotateToUnfatiguedGroup,
  safetyPrompt,
  normalRotationResume,
  lightReentryDeload,
  adaptationReentryDeload,
  independentExerciseTracking,
}

class UserProfile {
  final String id;
  final String goal;
  final int wakeTimeMinutes; // Minutes from midnight (e.g. 900 = 15:00 / 3 PM)
  final int shiftStartMinutes; // e.g. 1140 = 19:00 / 7 PM
  final int targetWorkoutsPerWeek;
  final List<JointImpactTag> avoidedJoints;

  const UserProfile({
    required this.id,
    this.goal = 'MUSCLE_BUILDING',
    this.wakeTimeMinutes = 900,
    this.shiftStartMinutes = 1140,
    this.targetWorkoutsPerWeek = 4,
    this.avoidedJoints = const [],
  });

  UserProfile copyWith({
    String? id,
    String? goal,
    int? wakeTimeMinutes,
    int? shiftStartMinutes,
    int? targetWorkoutsPerWeek,
    List<JointImpactTag>? avoidedJoints,
  }) {
    return UserProfile(
      id: id ?? this.id,
      goal: goal ?? this.goal,
      wakeTimeMinutes: wakeTimeMinutes ?? this.wakeTimeMinutes,
      shiftStartMinutes: shiftStartMinutes ?? this.shiftStartMinutes,
      targetWorkoutsPerWeek: targetWorkoutsPerWeek ?? this.targetWorkoutsPerWeek,
      avoidedJoints: avoidedJoints ?? this.avoidedJoints,
    );
  }
}

class EquipmentInventory {
  final bool hasPullUpBar;
  final bool hasBands;
  final bool hasDoorAnchor;
  final bool hasSturdyTable;
  final bool hasParallelGrip;

  const EquipmentInventory({
    this.hasPullUpBar = true,
    this.hasBands = true,
    this.hasDoorAnchor = false,
    this.hasSturdyTable = false,
    this.hasParallelGrip = false,
  });

  EquipmentInventory copyWith({
    bool? hasPullUpBar,
    bool? hasBands,
    bool? hasDoorAnchor,
    bool? hasSturdyTable,
    bool? hasParallelGrip,
  }) {
    return EquipmentInventory(
      hasPullUpBar: hasPullUpBar ?? this.hasPullUpBar,
      hasBands: hasBands ?? this.hasBands,
      hasDoorAnchor: hasDoorAnchor ?? this.hasDoorAnchor,
      hasSturdyTable: hasSturdyTable ?? this.hasSturdyTable,
      hasParallelGrip: hasParallelGrip ?? this.hasParallelGrip,
    );
  }
}

class Exercise {
  final String id;
  final String slug;
  final String nameAr;
  final String nameEn;
  final MovementPattern pattern;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<JointImpactTag> jointStressTags;
  final List<String> requiredEquipment;
  final List<String> optionalAccessories;
  final bool supportsBandAssistance;
  final bool supportsBandResistance;
  final String? unprovocativeAlternativeId;
  final int skillPrerequisiteReps;
  final String cuesAr;
  final String cuesEn;

  const Exercise({
    required this.id,
    required this.slug,
    required this.nameAr,
    required this.nameEn,
    required this.pattern,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.jointStressTags,
    required this.requiredEquipment,
    this.optionalAccessories = const [],
    required this.supportsBandAssistance,
    required this.supportsBandResistance,
    this.unprovocativeAlternativeId,
    required this.skillPrerequisiteReps,
    required this.cuesAr,
    required this.cuesEn,
  });
}

class PlannedSet {
  final int setIndex;
  final int targetMinReps;
  final int targetMaxReps;
  final String? prescribedBandRung;
  final String? tempoCue;
  final int targetRestSeconds;

  const PlannedSet({
    required this.setIndex,
    required this.targetMinReps,
    required this.targetMaxReps,
    this.prescribedBandRung,
    this.tempoCue,
    this.targetRestSeconds = 90,
  });
}

class PlannedExercise {
  final Exercise exercise;
  final List<PlannedSet> sets;

  const PlannedExercise({
    required this.exercise,
    required this.sets,
  });
}

class ScheduledSession {
  final String id;
  final String routineName;
  final String routineNameAr;
  final List<PlannedExercise> exercises;
  final bool isLiteMode;
  final int estimatedDurationMinutes;
  final String targetMuscleGroup;

  const ScheduledSession({
    required this.id,
    required this.routineName,
    required this.routineNameAr,
    required this.exercises,
    this.isLiteMode = false,
    required this.estimatedDurationMinutes,
    required this.targetMuscleGroup,
  });
}

class SetLog {
  final int setIndex;
  final String exerciseId;
  final int performedReps;
  final String? bandUsed;
  final ExertionRating exertion;
  final bool isPainStopped;
  final String? painNote;
  final DateTime completedAt;

  const SetLog({
    required this.setIndex,
    required this.exerciseId,
    required this.performedReps,
    this.bandUsed,
    required this.exertion,
    this.isPainStopped = false,
    this.painNote,
    required this.completedAt,
  });
}

class CompletedWorkoutSession {
  final String id;
  final String scheduledSessionId;
  final String routineName;
  final bool isLiteMode;
  final DateTime startedAt;
  final DateTime endedAt;
  final int totalDurationSeconds;
  final List<SetLog> completedSets;
  final bool isEmergencyStopped;
  final String? emergencyStopReason;

  const CompletedWorkoutSession({
    required this.id,
    required this.scheduledSessionId,
    required this.routineName,
    this.isLiteMode = false,
    required this.startedAt,
    required this.endedAt,
    required this.totalDurationSeconds,
    required this.completedSets,
    this.isEmergencyStopped = false,
    this.emergencyStopReason,
  });
}
