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
  applyTempo,
}

class CadencePauseResult {
  final String action;
  final int isometricPauseTopSec;
  final int eccentricSec;
  final int targetReps;

  const CadencePauseResult({
    this.action = 'APPLY_TEMPO',
    required this.isometricPauseTopSec,
    required this.eccentricSec,
    required this.targetReps,
  });
}

class BandAssistanceResult {
  final String action;
  final String? currentAssistanceRung;
  final String? nextAssistanceRung;
  final String? prescribedReps;
  final String? warning;
  final bool freezeProgression;

  const BandAssistanceResult({
    required this.action,
    this.currentAssistanceRung,
    this.nextAssistanceRung,
    this.prescribedReps,
    this.warning,
    this.freezeProgression = false,
  });
}

class BandResistanceResult {
  final String action;
  final int? nextResistanceRank;
  final List<int>? resetRepsTo;
  final String? reason;

  const BandResistanceResult({
    required this.action,
    this.nextResistanceRank,
    this.resetRepsTo,
    this.reason,
  });
}

class AbsenceDeloadResult {
  final EngineAction action;
  final int volumeReductionPercent;
  final bool streakPenaltyApplied;
  final bool guiltFreeMessaging;

  const AbsenceDeloadResult({
    required this.action,
    required this.volumeReductionPercent,
    this.streakPenaltyApplied = false,
    this.guiltFreeMessaging = true,
  });

  Map<String, dynamic> toJson() => {
    'action': action.name,
    'volumeReductionPercent': volumeReductionPercent,
    'streakPenaltyApplied': streakPenaltyApplied,
    'guiltFreeMessaging': guiltFreeMessaging,
  };

  factory AbsenceDeloadResult.fromJson(Map<String, dynamic> json) {
    final actionStr = json['action'] as String? ?? 'normalRotationResume';
    final action = EngineAction.values.firstWhere(
      (a) => a.name == actionStr,
      orElse: () => EngineAction.normalRotationResume,
    );
    return AbsenceDeloadResult(
      action: action,
      volumeReductionPercent: (json['volumeReductionPercent'] as num?)?.toInt() ?? 0,
      streakPenaltyApplied: json['streakPenaltyApplied'] as bool? ?? false,
      guiltFreeMessaging: json['guiltFreeMessaging'] as bool? ?? true,
    );
  }
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
  final AbsenceDeloadResult? absenceDeloadResult;

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
    this.absenceDeloadResult,
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
    'absenceDeloadResult': absenceDeloadResult?.toJson(),
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
    absenceDeloadResult: json['absenceDeloadResult'] != null
        ? AbsenceDeloadResult.fromJson(json['absenceDeloadResult'] as Map<String, dynamic>)
        : null,
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
  final bool isPersisted;

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
    this.isPersisted = true,
  });

  CompletedWorkoutSession copyWith({
    String? id,
    String? scheduledSessionId,
    String? routineName,
    bool? isLiteMode,
    DateTime? startedAt,
    DateTime? endedAt,
    int? totalDurationSeconds,
    List<SetLog>? completedSets,
    bool? isEmergencyStopped,
    String? emergencyStopReason,
    bool? isPersisted,
  }) {
    return CompletedWorkoutSession(
      id: id ?? this.id,
      scheduledSessionId: scheduledSessionId ?? this.scheduledSessionId,
      routineName: routineName ?? this.routineName,
      isLiteMode: isLiteMode ?? this.isLiteMode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      completedSets: completedSets ?? this.completedSets,
      isEmergencyStopped: isEmergencyStopped ?? this.isEmergencyStopped,
      emergencyStopReason: emergencyStopReason ?? this.emergencyStopReason,
      isPersisted: isPersisted ?? this.isPersisted,
    );
  }
}

/// Represents a manual body weight measurement (WP03).
class WeightEntry {
  final String id;
  final double weightKg;
  final DateTime loggedAt;
  final String? notes;

  const WeightEntry({
    required this.id,
    required this.weightKg,
    required this.loggedAt,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weight_kg': weightKg,
      'logged_at': loggedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] as String,
      weightKg: (map['weight_kg'] as num).toDouble(),
      loggedAt: DateTime.parse(map['logged_at'] as String),
      notes: map['notes'] as String?,
    );
  }

  WeightEntry copyWith({
    String? id,
    double? weightKg,
    DateTime? loggedAt,
    String? notes,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      weightKg: weightKg ?? this.weightKg,
      loggedAt: loggedAt ?? this.loggedAt,
      notes: notes ?? this.notes,
    );
  }
}

/// Perspective angle for physique progress photos (WP07, WP08).
enum PhotoAngle {
  front,
  side,
  back,
}

extension PhotoAngleExtension on PhotoAngle {
  String toDbString() => name;

  static PhotoAngle fromDbString(String str) {
    switch (str.toLowerCase()) {
      case 'side':
        return PhotoAngle.side;
      case 'back':
        return PhotoAngle.back;
      case 'front':
      default:
        return PhotoAngle.front;
    }
  }

  String labelEn() {
    switch (this) {
      case PhotoAngle.front:
        return 'Front';
      case PhotoAngle.side:
        return 'Side';
      case PhotoAngle.back:
        return 'Back';
    }
  }

  String labelAr() {
    switch (this) {
      case PhotoAngle.front:
        return 'أمامي';
      case PhotoAngle.side:
        return 'جانبي';
      case PhotoAngle.back:
        return 'خلفي';
    }
  }
}

/// Metadata record for an app-private progress photo (WP07, WP08).
class ProgressPhoto {
  final String id;
  final String filePath; // Relative path inside app-private files directory
  final PhotoAngle angle;
  final DateTime takenAt;
  final String? notes;

  const ProgressPhoto({
    required this.id,
    required this.filePath,
    required this.angle,
    required this.takenAt,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'angle': angle.toDbString(),
      'taken_at': takenAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory ProgressPhoto.fromMap(Map<String, dynamic> map) {
    return ProgressPhoto(
      id: map['id'] as String,
      filePath: map['file_path'] as String,
      angle: PhotoAngleExtension.fromDbString(map['angle'] as String),
      takenAt: DateTime.parse(map['taken_at'] as String),
      notes: map['notes'] as String?,
    );
  }

  ProgressPhoto copyWith({
    String? id,
    String? filePath,
    PhotoAngle? angle,
    DateTime? takenAt,
    String? notes,
  }) {
    return ProgressPhoto(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      angle: angle ?? this.angle,
      takenAt: takenAt ?? this.takenAt,
      notes: notes ?? this.notes,
    );
  }
}

/// Daily checkbox record for the meal checklist (WP06).
class DailyMealCheck {
  final String date; // YYYY-MM-DD
  final int mealSlot; // 0, 1, 2, 3, 4
  final bool isChecked;

  const DailyMealCheck({
    required this.date,
    required this.mealSlot,
    required this.isChecked,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'meal_slot': mealSlot,
      'is_checked': isChecked ? 1 : 0,
    };
  }

  factory DailyMealCheck.fromMap(Map<String, dynamic> map) {
    return DailyMealCheck(
      date: map['date'] as String,
      mealSlot: map['meal_slot'] as int,
      isChecked: (map['is_checked'] as int) == 1,
    );
  }
}

/// Aggregated performance metric for an exercise session (WP04).
class StrengthDataPoint {
  final DateTime date;
  final int maxReps;
  final int totalReps;
  final int setsCount;
  final String? bandUsed;
  final bool isLiteMode;
  final String sessionId;

  const StrengthDataPoint({
    required this.date,
    required this.maxReps,
    required this.totalReps,
    required this.setsCount,
    this.bandUsed,
    required this.isLiteMode,
    required this.sessionId,
  });
}


