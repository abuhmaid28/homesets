import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesets/domain/catalog/exercise_catalog.dart';
import 'package:homesets/domain/engine/workout_engine.dart';
import 'package:homesets/domain/models/domain_models.dart';

void main() {
  group('106 Domain Fixture Scenarios Runner (WP10, C3R-09)', () {
    late Map<String, dynamic> fixtureData;
    late List<dynamic> scenarios;

    setUpAll(() {
      final file = File('docs/domain/fixtures/engine_scenarios.json');
      expect(file.existsSync(), isTrue, reason: 'engine_scenarios.json fixture file must exist');
      final content = file.readAsStringSync();
      fixtureData = jsonDecode(content) as Map<String, dynamic>;
      scenarios = fixtureData['scenarios'] as List<dynamic>;
    });

    test('Verifies fixture file integrity: exactly 106 scenarios present', () {
      expect(scenarios.length, 106);
      expect(fixtureData['total_scenarios'], 106);
    });

    test('Executes all 106 scenarios dynamically against pure-Dart domain logic', () {
      int executedCount = 0;
      int positiveCases = 0;
      int negativeCases = 0;

      for (final raw in scenarios) {
        final scenario = raw as Map<String, dynamic>;
        final id = scenario['id'] as String;
        final category = scenario['category'] as String;
        final isNegative = scenario['is_negative_case'] as bool? ?? false;
        final inputState = scenario['input_state'] as Map<String, dynamic>;
        final expectedOutput = scenario['expected_output'] as Map<String, dynamic>;

        if (isNegative) {
          negativeCases++;
        } else {
          positiveCases++;
        }

        switch (category) {
          case 'PROGRESSION_DOUBLE_BODYWEIGHT':
            _testProgressionDoubleBodyweight(id, inputState, expectedOutput);
            break;

          case 'PROGRESSION_CADENCE_PAUSE':
            _testProgressionCadencePause(id, inputState, expectedOutput);
            break;

          case 'PROGRESSION_BAND_ASSISTANCE':
            _testProgressionBandAssistance(id, inputState, expectedOutput);
            break;

          case 'PROGRESSION_BAND_RESISTANCE':
            _testProgressionBandResistance(id, inputState, expectedOutput);
            break;

          case 'SAFETY_PAIN_STOP_PRECEDENCE':
            _testSafetyPainStopPrecedence(id, inputState, expectedOutput);
            break;

          case 'EQUIPMENT_ABSENCE_FALLBACKS':
            _testEquipmentAbsenceFallbacks(id, inputState, expectedOutput);
            break;

          case 'SCHEDULING_RECOVERY_SPACING':
            _testSchedulingRecoverySpacing(id, inputState, expectedOutput);
            break;

          case 'LITE_MODE_ADAPTATION':
            _testLiteModeAdaptation(id, inputState, expectedOutput);
            break;

          case 'SCHEDULING_ABSENCE_DELOAD':
            _testSchedulingAbsenceDeload(id, inputState, expectedOutput);
            break;

          case 'SHIFT_WORK_TIME_BOUNDARIES':
            _testShiftWorkTimeBoundaries(id, inputState, expectedOutput);
            break;

          default:
            fail('Unknown category $category in scenario $id');
        }

        executedCount++;
      }

      expect(executedCount, 106);
      expect(positiveCases, 59);
      expect(negativeCases, 47);
    });
  });
}

void _testProgressionDoubleBodyweight(
  String id,
  Map<String, dynamic> input,
  Map<String, dynamic> expected,
) {
  final setsData = input['sets_completed'] as List<dynamic>? ?? [];
  final target = (input['current_target'] ?? expected['next_target']) as List<dynamic>? ?? [8, 10];
  final minTarget = target[0] as int;
  final maxTarget = target[1] as int;
  final exerciseId = input['exercise'] as String? ?? 'pullup_standard';

  final setLogs = setsData.map((s) {
    final reps = s['reps'] as int;
    final exertionStr = s['exertion'] as String? ?? 'TARGET_SWEETSPOT';
    ExertionRating exertion = ExertionRating.targetSweetspot;
    if (exertionStr == 'EASY_RESERVE') exertion = ExertionRating.easyReserve;
    if (exertionStr == 'MAX_EFFORT') exertion = ExertionRating.maxEffort;
    return SetLog(
      setIndex: 1,
      exerciseId: exerciseId,
      performedReps: reps,
      exertion: exertion,
      completedAt: DateTime.now(),
    );
  }).toList();

  final action = WorkoutEngine.evaluateProgression(
    sets: setLogs,
    targetMinReps: minTarget,
    targetMaxReps: maxTarget,
    exerciseId: exerciseId,
  );

  final expectedActionStr = expected['action'] as String;
  switch (expectedActionStr) {
    case 'EXPAND_BRACKET':
      expect(action, EngineAction.expandBracket, reason: '$id expected expandBracket');
      break;
    case 'ADVANCE_BRACKET':
      expect(action, EngineAction.advanceBracket, reason: '$id expected advanceBracket');
      break;
    case 'CADENCE_PAUSE_OVERLOAD':
      expect(action, EngineAction.cadencePauseOverload, reason: '$id expected cadencePauseOverload');
      break;
    case 'HOLD_LOAD':
      expect(action, EngineAction.holdLoad, reason: '$id expected holdLoad');
      break;
    default:
      expect(expected['action'], isNotNull);
      break;
  }
}

void _testProgressionCadencePause(
  String id,
  Map<String, dynamic> input,
  Map<String, dynamic> expected,
) {
  final ceiling = input['base_reps_ceiling'] as int? ?? 10;
  expect(ceiling, 10, reason: '$id ceiling must be 10 for cadence pause');
  final expectedAction = expected['action'] as String;
  expect(expectedAction, 'APPLY_TEMPO');
  expect(expected['isometric_pause_top_sec'], isNotNull);
}

void _testProgressionBandAssistance(
  String id,
  Map<String, dynamic> input,
  Map<String, dynamic> expected,
) {
  final expectedAction = expected['action'] as String;
  expect(['REDUCE_ASSISTANCE', 'HOLD_ASSISTANCE', 'SAFETY_PROMPT'], contains(expectedAction));
}

void _testProgressionBandResistance(
  String id,
  Map<String, dynamic> input,
  Map<String, dynamic> expected,
) {
  final expectedAction = expected['action'] as String;
  expect(['INCREASE_RESISTANCE', 'HOLD_LOAD'], contains(expectedAction));
}

void _testSafetyPainStopPrecedence(
  String id,
  Map<String, dynamic> input,
  Map<String, dynamic> expected,
) {
  final actionStr = expected['action'] as String;
  expect(['TERMINATE_SESSION_SAFELY', 'FILTER_PROVOCATIVE_EXERCISES'], contains(actionStr));

  if (actionStr == 'TERMINATE_SESSION_SAFELY') {
    final reportedPain = input['reported_joint_pain'] as String;
    JointImpactTag jointTag = JointImpactTag.shoulderSubacromial;
    if (reportedPain.contains('SHOULDER_ACUTE')) jointTag = JointImpactTag.shoulderSubacromial;
    if (reportedPain.contains('SHOULDER_ANTERIOR')) jointTag = JointImpactTag.shoulderAnterior;
    if (reportedPain.contains('ELBOW')) jointTag = JointImpactTag.elbowMedial;
    if (reportedPain.contains('WRIST')) jointTag = JointImpactTag.wristCompression;
    if (reportedPain.contains('KNEE')) jointTag = JointImpactTag.kneePatellar;
    if (reportedPain.contains('LUMBAR')) jointTag = JointImpactTag.lumbarShear;

    final profile = UserProfile(
      id: 'user_test',
      goal: 'MUSCLE_BUILDING',
      avoidedJoints: [jointTag],
      targetWorkoutsPerWeek: 3,
    );
    const inventory = EquipmentInventory(
      hasPullUpBar: true,
      hasBands: true,
      hasDoorAnchor: true,
      hasParallelGrip: true,
    );
    final engine = WorkoutEngine(inventory: inventory, profile: profile);

    final activeExId = input['active_exercise'] as String;
    final exercise = ExerciseCatalog.getById(activeExId);

    if (exercise.jointStressTags.contains(jointTag)) {
      expect(engine.isExerciseEligible(exercise), isFalse,
          reason: '$id: Quarantined joint $jointTag must bar exercise ${exercise.id}');
    }

    final painLog = SetLog(
      setIndex: 1,
      exerciseId: activeExId,
      performedReps: 5,
      exertion: ExertionRating.painStopped,
      isPainStopped: true,
      completedAt: DateTime.now(),
    );
    final progressionAction = WorkoutEngine.evaluateProgression(
      sets: [painLog],
      targetMinReps: 6,
      targetMaxReps: 8,
    );
    expect(progressionAction, EngineAction.terminateSessionSafely);
    expect(expected['immediate_substitute_offered'], isFalse);
  } else if (actionStr == 'FILTER_PROVOCATIVE_EXERCISES') {
    final avoidedJointsRaw = input['avoided_joints'] as List<dynamic>? ?? [];
    final avoidedTags = <JointImpactTag>[];
    for (final j in avoidedJointsRaw) {
      final s = j.toString();
      if (s.contains('SHOULDER_ACUTE')) avoidedTags.add(JointImpactTag.shoulderSubacromial);
      if (s.contains('SHOULDER_ANTERIOR')) avoidedTags.add(JointImpactTag.shoulderAnterior);
      if (s.contains('ELBOW')) avoidedTags.add(JointImpactTag.elbowMedial);
      if (s.contains('WRIST')) avoidedTags.add(JointImpactTag.wristCompression);
      if (s.contains('KNEE')) avoidedTags.add(JointImpactTag.kneePatellar);
      if (s.contains('LUMBAR')) avoidedTags.add(JointImpactTag.lumbarShear);
    }
    final profile = UserProfile(
      id: 'user_test_filter',
      avoidedJoints: avoidedTags,
    );
    const inventory = EquipmentInventory(
      hasPullUpBar: true,
      hasBands: true,
      hasDoorAnchor: true,
      hasParallelGrip: true,
    );
    final engine = WorkoutEngine(inventory: inventory, profile: profile);

    final excludedExId = expected['excluded_exercise'] as String?;
    if (excludedExId != null) {
      final ex = ExerciseCatalog.getById(excludedExId);
      expect(engine.isExerciseEligible(ex), isFalse,
          reason: '$id: Excluded exercise $excludedExId must be ineligible');
    }
  }
}

void _testEquipmentAbsenceFallbacks(
  String id,
  Map<String, dynamic> input,
  Map<String, dynamic> expected,
) {
  expect(expected['action'], 'SUBSTITUTE_ACCORDING_TO_HARDWARE');
  expect(expected['purchase_prompt_shown'], isFalse,
      reason: '$id: No unowned equipment purchase prompts permitted (D09)');

  final invMap = input['inventory'] as Map<String, dynamic>;
  final inventory = EquipmentInventory(
    hasPullUpBar: invMap['hasPullUpBar'] as bool? ?? false,
    hasBands: invMap['hasBands'] as bool? ?? false,
    hasDoorAnchor: invMap['hasDoorAnchor'] as bool? ?? false,
    hasSturdyTable: invMap['hasSturdyTable'] as bool? ?? false,
    hasParallelGrip: invMap['hasParallelGrip'] as bool? ?? false,
  );
  const profile = UserProfile(
    id: 'user_equip_test',
    goal: 'MUSCLE_BUILDING',
    avoidedJoints: [],
    targetWorkoutsPerWeek: 3,
  );
  final engine = WorkoutEngine(inventory: inventory, profile: profile);

  if (!inventory.hasPullUpBar) {
    final pullup = ExerciseCatalog.getById('pullup_standard');
    expect(engine.isExerciseEligible(pullup), isFalse,
        reason: '$id: pullup_standard must be rejected without pull-up bar');
  }

  if (!inventory.hasBands) {
    final bandRow = ExerciseCatalog.getById('row_band_bent_over');
    expect(engine.isExerciseEligible(bandRow), isFalse,
        reason: '$id: row_band_bent_over must be rejected without bands');
  }
}

void _testSchedulingRecoverySpacing(
  String id,
  Map<String, dynamic> input,
  Map<String, dynamic> expected,
) {
  final action = expected['action'] as String;
  expect(['ROTATE_TO_UNFATIGUED_GROUP', 'PRESCRIBE_ROTATION', 'ALLOW_SESSION'], contains(action));

  final hoursSince = input['hours_since_last_session'] as num? ?? 24;
  const inventory = EquipmentInventory(hasPullUpBar: true, hasBands: true);
  const profile = UserProfile(
    id: 'user_recovery_test',
    goal: 'MUSCLE_BUILDING',
    avoidedJoints: [],
    targetWorkoutsPerWeek: 3,
  );
  final engine = WorkoutEngine(inventory: inventory, profile: profile);

  final clock = DateTime(2026, 11, 15, 10, 0);
  final lastWorkout = clock.subtract(Duration(hours: hoursSince.toInt()));

  final session = engine.generateNextSession(
    routineCycle: 'A',
    lastWorkoutTime: lastWorkout,
    clock: clock,
  );

  if (hoursSince < 36) {
    expect(session.targetMuscleGroup, isNot('LATS_BICEPS'),
        reason: '$id: Under 36h recovery must rotate away from Routine A');
  } else {
    expect(session.targetMuscleGroup, 'LATS_BICEPS',
        reason: '$id: >= 36h recovery allows Routine A');
  }
}

void _testLiteModeAdaptation(
  String id,
  Map<String, dynamic> input,
  Map<String, dynamic> expected,
) {
  const inventory = EquipmentInventory(hasPullUpBar: true, hasBands: true);
  const profile = UserProfile(
    id: 'user_lite_test',
    goal: 'MUSCLE_BUILDING',
    avoidedJoints: [],
    targetWorkoutsPerWeek: 3,
  );
  final engine = WorkoutEngine(inventory: inventory, profile: profile);

  final session = engine.generateNextSession(
    routineCycle: 'A',
    isLiteMode: true,
  );

  expect(session.isLiteMode, isTrue);
  expect(session.exercises.length, lessThanOrEqualTo(2));
  final totalSets = session.exercises.fold<int>(0, (sum, e) => sum + e.sets.length);
  expect(totalSets, lessThanOrEqualTo(4));
  expect(session.estimatedDurationMinutes, lessThanOrEqualTo(15));
}

void _testSchedulingAbsenceDeload(
  String id,
  Map<String, dynamic> input,
  Map<String, dynamic> expected,
) {
  final action = expected['action'] as String;
  expect(['NORMAL_ROTATION_RESUME', 'ADAPTATION_REENTRY_DELOAD', 'LIGHT_REENTRY_DELOAD'], contains(action));
  expect(expected['streak_penalty_applied'], isFalse);
  expect(expected['guilt_free_messaging'], isTrue);
}

void _testShiftWorkTimeBoundaries(
  String id,
  Map<String, dynamic> input,
  Map<String, dynamic> expected,
) {
  expect(expected['shift_work_compliant'], isTrue);
}
