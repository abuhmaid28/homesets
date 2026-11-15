/// Pure-Dart Immutable Domain Models for HOMESETS (Zero Flutter Dependencies)
/// Strictly aligns with DOMAIN_MODEL_SPEC.md, DECISION_REGISTER.md (D04, D09, D17, GOV13, GOV14).
library;

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'pattern': pattern.name,
    'primaryMuscles': primaryMuscles,
    'secondaryMuscles': secondaryMuscles,
    'jointStressTags': jointStressTags.map((t) => t.name).toList(),
    'requiredEquipment': requiredEquipment,
    'optionalAccessories': optionalAccessories,
    'supportsBandAssistance': supportsBandAssistance,
    'supportsBandResistance': supportsBandResistance,
    'unprovocativeAlternativeId': unprovocativeAlternativeId,
    'skillPrerequisiteReps': skillPrerequisiteReps,
    'cuesAr': cuesAr,
    'cuesEn': cuesEn,
  };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    slug: json['slug'] as String,
    nameAr: json['nameAr'] as String,
    nameEn: json['nameEn'] as String,
    pattern: MovementPattern.values.byName(json['pattern'] as String),
    primaryMuscles: List<String>.from(json['primaryMuscles'] as List),
    secondaryMuscles: List<String>.from(json['secondaryMuscles'] as List),
    jointStressTags: (json['jointStressTags'] as List)
        .map((t) => JointImpactTag.values.byName(t as String))
        .toList(),
    requiredEquipment: List<String>.from(json['requiredEquipment'] as List),
    optionalAccessories: json['optionalAccessories'] != null
        ? List<String>.from(json['optionalAccessories'] as List)
        : const [],
    supportsBandAssistance: json['supportsBandAssistance'] as bool,
    supportsBandResistance: json['supportsBandResistance'] as bool,
    unprovocativeAlternativeId: json['unprovocativeAlternativeId'] as String?,
    skillPrerequisiteReps: (json['skillPrerequisiteReps'] as num).toInt(),
    cuesAr: json['cuesAr'] as String,
    cuesEn: json['cuesEn'] as String,
  );
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

  Map<String, dynamic> toJson() => {
    'setIndex': setIndex,
    'targetMinReps': targetMinReps,
    'targetMaxReps': targetMaxReps,
    'prescribedBandRung': prescribedBandRung,
    'tempoCue': tempoCue,
    'targetRestSeconds': targetRestSeconds,
  };

  factory PlannedSet.fromJson(Map<String, dynamic> json) => PlannedSet(
    setIndex: (json['setIndex'] as num).toInt(),
    targetMinReps: (json['targetMinReps'] as num).toInt(),
    targetMaxReps: (json['targetMaxReps'] as num).toInt(),
    prescribedBandRung: json['prescribedBandRung'] as String?,
    tempoCue: json['tempoCue'] as String?,
    targetRestSeconds: (json['targetRestSeconds'] as num?)?.toInt() ?? 90,
  );
}

class PlannedExercise {
  final Exercise exercise;
  final List<PlannedSet> sets;

  const PlannedExercise({
    required this.exercise,
    required this.sets,
  });

  Map<String, dynamic> toJson() => {
    'exercise': exercise.toJson(),
    'sets': sets.map((s) => s.toJson()).toList(),
  };

  factory PlannedExercise.fromJson(Map<String, dynamic> json) => PlannedExercise(
    exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
    sets: (json['sets'] as List)
        .map((s) => PlannedSet.fromJson(s as Map<String, dynamic>))
        .toList(),
  );
}

class ScheduledSession {
  final String id;
  final String routineName;
  final String routineNameAr;
  final List<PlannedExercise> exercises;
  final bool isLiteMode;
  final int estimatedDurationMinutes;
  final String targetMuscleGroup;
  final bool isViable;
  final String? unviableReason;
  final String? unviableReasonAr;

  const ScheduledSession({
    required this.id,
    required this.routineName,
    required this.routineNameAr,
    required this.exercises,
    this.isLiteMode = false,
    required this.estimatedDurationMinutes,
    required this.targetMuscleGroup,
    this.isViable = true,
    this.unviableReason,
    this.unviableReasonAr,
  });

  factory ScheduledSession.unviable({
    required String id,
    required String routineName,
    required String routineNameAr,
    required String targetMuscleGroup,
    required bool isLiteMode,
    String? reasonEn,
    String? reasonAr,
  }) {
    return ScheduledSession(
      id: id,
      routineName: routineName,
      routineNameAr: routineNameAr,
      exercises: const [],
      isLiteMode: isLiteMode,
      estimatedDurationMinutes: 0,
      targetMuscleGroup: targetMuscleGroup,
      isViable: false,
      unviableReason: reasonEn ?? 'No safe exercises available for your equipment and avoided joints.',
      unviableReasonAr: reasonAr ?? 'لا توجد تمارين مناسبة للأدوات المتوفرة مع استبعاد المفاصل المجهدة.',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'routineName': routineName,
    'routineNameAr': routineNameAr,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'isLiteMode': isLiteMode,
    'estimatedDurationMinutes': estimatedDurationMinutes,
    'targetMuscleGroup': targetMuscleGroup,
    'isViable': isViable,
    'unviableReason': unviableReason,
    'unviableReasonAr': unviableReasonAr,
  };

  factory ScheduledSession.fromJson(Map<String, dynamic> json) => ScheduledSession(
    id: json['id'] as String,
    routineName: json['routineName'] as String,
    routineNameAr: json['routineNameAr'] as String,
    exercises: (json['exercises'] as List)
        .map((e) => PlannedExercise.fromJson(e as Map<String, dynamic>))
        .toList(),
    isLiteMode: json['isLiteMode'] as bool? ?? false,
    estimatedDurationMinutes: (json['estimatedDurationMinutes'] as num).toInt(),
    targetMuscleGroup: json['targetMuscleGroup'] as String,
    isViable: json['isViable'] as bool? ?? true,
    unviableReason: json['unviableReason'] as String?,
    unviableReasonAr: json['unviableReasonAr'] as String?,
  );
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
