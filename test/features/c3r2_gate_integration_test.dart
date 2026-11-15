import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:homesets/core/theme/homesets_theme.dart';
import 'package:homesets/data/database/database_helper.dart';
import 'package:homesets/data/repositories/workout_repository.dart';
import 'package:homesets/domain/models/domain_models.dart';
import 'package:homesets/features/today/today_screen.dart';
import 'package:homesets/features/summary/summary_screen.dart';
import 'package:homesets/features/shared/kinetic_button.dart';
import 'package:homesets/l10n/app_localizations.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setCustomFactory(databaseFactoryFfi);
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('user_profile');
    await db.delete('equipment_inventory');
    await db.delete('workout_sessions');
    await db.delete('set_logs');
    await db.delete('active_session_state');
    await db.delete('session_salvage_archive');
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  Widget createTestWidget(Widget child, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: HomesetsTheme.darkTheme,
      home: Scaffold(body: child),
    );
  }

  group('GATE-A: Corrupt set logs with valid scheduled plan must block Resume and require salvage', () {
    testWidgets('TodayScreen blocks Resume and shows Archive Raw Salvaged Sets when set logs are corrupt', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = WorkoutRepository();
      final now = DateTime.now();

      // 1. Create a VALID ScheduledSession
      const validScheduled = ScheduledSession(
        id: 'sched_gate_a',
        routineName: 'Routine A: Upper Pull & Biceps',
        routineNameAr: 'التمرين الأول',
        isLiteMode: false,
        estimatedDurationMinutes: 30,
        targetMuscleGroup: 'LATS_BICEPS',
        exercises: [
          PlannedExercise(
            exercise: Exercise(
              id: 'pullup_standard',
              slug: 'pullup_standard',
              nameAr: 'عقلة قياسية',
              nameEn: 'Standard Pull-Up',
              pattern: MovementPattern.verticalPull,
              primaryMuscles: ['latissimus_dorsi', 'biceps_brachii'],
              secondaryMuscles: ['rhomboids'],
              jointStressTags: [JointImpactTag.shoulderAnterior],
              requiredEquipment: ['pull_up_bar'],
              supportsBandAssistance: true,
              supportsBandResistance: false,
              skillPrerequisiteReps: 0,
              cuesAr: 'مسار مستقيم',
              cuesEn: 'Full ROM',
            ),
            sets: [
              PlannedSet(setIndex: 1, targetMinReps: 6, targetMaxReps: 10, targetRestSeconds: 90),
              PlannedSet(setIndex: 2, targetMinReps: 6, targetMaxReps: 10, targetRestSeconds: 90),
            ],
          ),
        ],
      );

      // 2. Insert active_session_state with VALID plan JSON but CORRUPT set logs (2 valid, 1 corrupt)
      final corruptSetsJson = jsonEncode([
        {
          'setIndex': 1,
          'exerciseId': 'pullup_standard',
          'performedReps': 8,
          'exertion': 'targetSweetspot',
          'isPainStopped': false,
          'completedAt': now.subtract(const Duration(minutes: 10)).toIso8601String(),
        },
        '__CORRUPTED_NON_MAP_SET_LOG__',
        {
          'setIndex': 2,
          'exerciseId': 'pullup_standard',
          'performedReps': 8,
          'exertion': 'targetSweetspot',
          'isPainStopped': false,
          'completedAt': now.subtract(const Duration(minutes: 5)).toIso8601String(),
        },
      ]);

      ActiveSessionSnapshot? snapshot;
      await tester.runAsync(() async {
        await repo.saveUserProfile(const UserProfile(
          id: 'u_gate_a',
          avoidedJoints: [],
        ));
        await repo.saveEquipmentInventory(const EquipmentInventory(
          hasPullUpBar: true,
          hasBands: true,
        ));
        final db = await DatabaseHelper.instance.database;
        await db.insert('active_session_state', {
          'session_id': 'sess_gate_a_corrupt',
          'routine_name': 'Routine A: Upper Pull & Biceps',
          'routine_name_ar': 'التمرين الأول',
          'is_lite_mode': 0,
          'started_at': now.subtract(const Duration(minutes: 15)).toIso8601String(),
          'current_exercise_index': 0,
          'current_set_index': 2,
          'completed_sets_json': corruptSetsJson,
          'active_session_json': jsonEncode(validScheduled.toJson()),
        });
        snapshot = await repo.getActiveSessionState();
      });

      // Verify repository parsing state
      expect(snapshot, isNotNull);
      expect(snapshot!.hasCorruptSetLogs, isTrue, reason: 'Snapshot must detect corrupted set log entry');
      expect(snapshot!.scheduledSession, isNotNull, reason: 'Original plan was completely valid');
      expect(snapshot!.completedSets.length, equals(2), reason: 'Two valid sets parsed');

      // 3. Pump TodayScreen inside runAsync so native FFI calls in initState complete properly
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestWidget(TodayScreen(
          repository: repo,
          onStartWorkout: (session, isResume) {},
          onOpenSettings: () {},
        )));
        await Future.delayed(const Duration(milliseconds: 400));
      });
      await tester.pump();

      // 4. Assert: Resume Workout MUST NOT be offered!
      expect(find.text('Resume Workout'), findsNothing,
          reason: 'GATE-A: Must NOT offer Resume Workout when draft contains corrupt set logs');
      expect(find.text('استئناف التمرين'), findsNothing);

      // 5. Assert: Corrupt warning card & Archive button MUST be displayed
      expect(find.textContaining('Draft contains corrupt entries'), findsOneWidget,
          reason: 'GATE-A: Must show warning that draft contains corrupt entries');
      final archiveBtn = find.widgetWithText(KineticButton, 'Archive Raw & Save Salvaged Sets');
      expect(archiveBtn, findsOneWidget,
          reason: 'GATE-A: Must show Archive Raw & Save Salvaged Sets button');

      // 6. Tap Archive button and verify raw corrupt bytes are transactionally archived
      await tester.scrollUntilVisible(archiveBtn, 200);
      await tester.tap(archiveBtn);
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      await tester.runAsync(() async {
        final archive = await repo.getSalvagedSessionArchive();
        expect(archive.length, equals(1));
        expect(archive.first['raw_completed_sets_json'], equals(corruptSetsJson),
            reason: 'Raw corrupt JSON must be durably preserved in salvage archive');
        expect(archive.first['has_corrupt_logs'], equals(1));

        // Verify active state is cleared
        final activeRemaining = await repo.getActiveSessionState();
        expect(activeRemaining, isNull);

        // Verify 0 weekly credit awarded
        final credit = await repo.getWeeklyConsistencyCredit();
        expect(credit, equals(0), reason: 'Corrupt draft salvage must earn 0 consistency credit');
      });
    });
  });

  group('GATE-B: Unsaved Pain STOP exit must show truthful Summary and NO consistency credit', () {
    testWidgets('SummaryScreen with isPersisted == false shows Unsaved notice and NO consistency badge', (tester) async {
      final now = DateTime.now();
      final unsavedSession = CompletedWorkoutSession(
        id: 'sess_unsaved_1',
        scheduledSessionId: 'sched_unsaved_1',
        routineName: 'Routine B: Upper Push',
        isLiteMode: false,
        startedAt: now.subtract(const Duration(minutes: 10)),
        endedAt: now,
        totalDurationSeconds: 600,
        completedSets: [
          SetLog(
            setIndex: 1,
            exerciseId: 'pushup_standard',
            performedReps: 8,
            exertion: ExertionRating.targetSweetspot,
            completedAt: now.subtract(const Duration(minutes: 5)),
          ),
          SetLog(
            setIndex: 2,
            exerciseId: 'pushup_standard',
            performedReps: 0,
            exertion: ExertionRating.painStopped,
            isPainStopped: true,
            painNote: 'Pain STOP',
            completedAt: now,
          ),
        ],
        isEmergencyStopped: true,
        emergencyStopReason: 'Acute joint pain stop (SAFE-01)',
        isPersisted: false, // Explicit unsaved exit!
      );

      await tester.pumpWidget(createTestWidget(SummaryScreen(
        session: unsavedSession,
        onBackToToday: () {},
      )));
      await tester.pump();

      // 1. Must NOT claim completed sets were preserved
      expect(find.textContaining('Completed sets preserved'), findsNothing,
          reason: 'GATE-B: Unsaved exit must not claim completed sets preserved');

      // 2. Must show truthful unsaved notice
      expect(find.textContaining('Session Ended (Unsaved)'), findsOneWidget,
          reason: 'GATE-B: Must show explicit unsaved title');
      expect(find.textContaining('No sets were written to local history'), findsOneWidget,
          reason: 'GATE-B: Must truthfully indicate no sets were written');

      // 3. Must NOT show lime weekly consistency credit badge
      expect(find.textContaining('+1 Weekly Consistency Credit'), findsNothing,
          reason: 'GATE-B: Unsaved exit must NEVER show consistency credit badge');
    });

    testWidgets('SummaryScreen for persisted Emergency Pain Stop shows joint safety and NO consistency credit badge', (tester) async {
      final now = DateTime.now();
      final painStopSession = CompletedWorkoutSession(
        id: 'sess_pain_saved',
        scheduledSessionId: 'sched_pain_saved',
        routineName: 'Routine B: Upper Push',
        isLiteMode: false,
        startedAt: now.subtract(const Duration(minutes: 10)),
        endedAt: now,
        totalDurationSeconds: 600,
        completedSets: [
          SetLog(
            setIndex: 1,
            exerciseId: 'pushup_standard',
            performedReps: 8,
            exertion: ExertionRating.targetSweetspot,
            completedAt: now.subtract(const Duration(minutes: 5)),
          ),
        ],
        isEmergencyStopped: true,
        emergencyStopReason: 'Acute joint pain stop (SAFE-01)',
        isPersisted: true,
      );

      await tester.pumpWidget(createTestWidget(SummaryScreen(
        session: painStopSession,
        onBackToToday: () {},
      )));
      await tester.pump();

      // 1. Must show Joint Safety Respected
      expect(find.textContaining('Joint Safety Respected'), findsOneWidget);
      expect(find.textContaining('Completed sets preserved'), findsOneWidget);

      // 2. Must NOT show consistency credit badge!
      expect(find.textContaining('+1 Weekly Consistency Credit'), findsNothing,
          reason: 'GATE-B: Emergency stopped workouts must NEVER display consistency credit badge');
    });

    testWidgets('SummaryScreen for normal eligible completed session shows lime consistency credit badge', (tester) async {
      final now = DateTime.now();
      final completedSession = CompletedWorkoutSession(
        id: 'sess_normal_complete',
        scheduledSessionId: 'sched_normal',
        routineName: 'Routine A: Upper Pull & Biceps',
        isLiteMode: false,
        startedAt: now.subtract(const Duration(minutes: 30)),
        endedAt: now,
        totalDurationSeconds: 1800,
        completedSets: [
          SetLog(setIndex: 1, exerciseId: 'pullup_standard', performedReps: 8, exertion: ExertionRating.targetSweetspot, completedAt: now.subtract(const Duration(minutes: 20))),
          SetLog(setIndex: 2, exerciseId: 'pullup_standard', performedReps: 8, exertion: ExertionRating.targetSweetspot, completedAt: now.subtract(const Duration(minutes: 10))),
          SetLog(setIndex: 3, exerciseId: 'pullup_standard', performedReps: 8, exertion: ExertionRating.targetSweetspot, completedAt: now.subtract(const Duration(minutes: 2))),
        ],
        isEmergencyStopped: false,
        isPersisted: true,
      );

      await tester.pumpWidget(createTestWidget(SummaryScreen(
        session: completedSession,
        onBackToToday: () {},
      )));
      await tester.pump();

      // Normal session with 3 completed sets MUST show consistency credit badge
      expect(find.textContaining('+1 Weekly Consistency Credit'), findsOneWidget,
          reason: 'Legitimate completed workout session earns consistency credit badge');
    });
  });

  group('GATE-C: Final-set process restart integration test with real nonempty plan', () {
    testWidgets('App restart after final set interruption allows clean finalization without set duplication', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = WorkoutRepository();
      final now = DateTime.now();

      // Real nonempty scheduled workout: 2 exercises x 3 sets = 6 sets total
      final realScheduled = ScheduledSession(
        id: 'sched_gate_c_real',
        routineName: 'Routine A: Upper Pull & Biceps',
        routineNameAr: 'التمرين الأول',
        isLiteMode: false,
        estimatedDurationMinutes: 25,
        targetMuscleGroup: 'LATS_BICEPS',
        exercises: [
          PlannedExercise(
            exercise: const Exercise(
              id: 'pullup_standard',
              slug: 'pullup_standard',
              nameAr: 'عقلة قياسية',
              nameEn: 'Standard Pull-Up',
              pattern: MovementPattern.verticalPull,
              primaryMuscles: ['latissimus_dorsi', 'biceps_brachii'],
              secondaryMuscles: ['rhomboids'],
              jointStressTags: [JointImpactTag.shoulderAnterior],
              requiredEquipment: ['pull_up_bar'],
              supportsBandAssistance: true,
              supportsBandResistance: false,
              skillPrerequisiteReps: 0,
              cuesAr: 'مسار مستقيم',
              cuesEn: 'Full ROM',
            ),
            sets: [
              const PlannedSet(setIndex: 1, targetMinReps: 6, targetMaxReps: 10, targetRestSeconds: 90),
              const PlannedSet(setIndex: 2, targetMinReps: 6, targetMaxReps: 10, targetRestSeconds: 90),
              const PlannedSet(setIndex: 3, targetMinReps: 6, targetMaxReps: 10, targetRestSeconds: 90),
            ],
          ),
          PlannedExercise(
            exercise: const Exercise(
              id: 'chinup_standard',
              slug: 'chinup_standard',
              nameAr: 'عقلة أمامية',
              nameEn: 'Standard Chin-Up',
              pattern: MovementPattern.verticalPull,
              primaryMuscles: ['biceps_brachii', 'latissimus_dorsi'],
              secondaryMuscles: ['brachialis'],
              jointStressTags: [JointImpactTag.shoulderAnterior],
              requiredEquipment: ['pull_up_bar'],
              supportsBandAssistance: true,
              supportsBandResistance: false,
              skillPrerequisiteReps: 0,
              cuesAr: 'قبضة عكسية',
              cuesEn: 'Supinated grip',
            ),
            sets: [
              const PlannedSet(setIndex: 1, targetMinReps: 6, targetMaxReps: 10, targetRestSeconds: 90),
              const PlannedSet(setIndex: 2, targetMinReps: 6, targetMaxReps: 10, targetRestSeconds: 90),
              const PlannedSet(setIndex: 3, targetMinReps: 6, targetMaxReps: 10, targetRestSeconds: 90),
            ],
          ),
        ],
      );

      // Simulate completed all 6 sets
      final allSixSets = <SetLog>[
        SetLog(setIndex: 1, exerciseId: 'pullup_standard', performedReps: 8, exertion: ExertionRating.targetSweetspot, completedAt: now.subtract(const Duration(minutes: 20))),
        SetLog(setIndex: 2, exerciseId: 'pullup_standard', performedReps: 8, exertion: ExertionRating.targetSweetspot, completedAt: now.subtract(const Duration(minutes: 16))),
        SetLog(setIndex: 3, exerciseId: 'pullup_standard', performedReps: 8, exertion: ExertionRating.targetSweetspot, completedAt: now.subtract(const Duration(minutes: 12))),
        SetLog(setIndex: 1, exerciseId: 'chinup_standard', performedReps: 7, exertion: ExertionRating.targetSweetspot, completedAt: now.subtract(const Duration(minutes: 8))),
        SetLog(setIndex: 2, exerciseId: 'chinup_standard', performedReps: 7, exertion: ExertionRating.targetSweetspot, completedAt: now.subtract(const Duration(minutes: 4))),
        SetLog(setIndex: 3, exerciseId: 'chinup_standard', performedReps: 7, exertion: ExertionRating.targetSweetspot, completedAt: now),
      ];

      ActiveSessionSnapshot? recovered;
      await tester.runAsync(() async {
        await repo.saveUserProfile(const UserProfile(
          id: 'u_gate_c',
          avoidedJoints: [],
        ));
        await repo.saveEquipmentInventory(const EquipmentInventory(
          hasPullUpBar: true,
          hasBands: true,
        ));
        // Save crash state right at final set boundary
        await repo.saveActiveSessionState(ActiveSessionSnapshot(
          sessionId: 'sess_crash_final_set',
          routineName: 'Routine A: Upper Pull & Biceps',
          routineNameAr: 'التمرين الأول',
          isLiteMode: false,
          startedAt: now.subtract(const Duration(minutes: 25)),
          currentExerciseIndex: 1,
          currentSetIndex: 3,
          completedSets: allSixSets,
          scheduledSession: realScheduled,
          isPendingFinalization: true,
        ));
        recovered = await repo.getActiveSessionState();
      });

      // 1. Recover snapshot from SQLite and verify isPendingFinalization reconstruction
      expect(recovered, isNotNull);
      expect(recovered!.isPendingFinalization, isTrue,
          reason: 'GATE-C: Must reconstruct isPendingFinalization == true when all planned sets logged');
      expect(recovered!.currentExerciseIndex, equals(1));
      expect(recovered!.currentSetIndex, equals(3), reason: 'Must NOT reset set index to 1');
      expect(recovered!.completedSets.length, equals(6));

      // 2. Pump TodayScreen inside runAsync so native FFI in initState completes properly
      await tester.runAsync(() async {
        await tester.pumpWidget(createTestWidget(TodayScreen(
          repository: repo,
          onStartWorkout: (session, isResume) {},
          onOpenSettings: () {},
        )));
        await Future.delayed(const Duration(milliseconds: 400));
      });
      await tester.pump();

      expect(find.text('Finish & Finalize Workout'), findsOneWidget,
          reason: 'GATE-C: TodayScreen must offer Finish & Finalize Workout button');
      expect(find.text('Resume Workout'), findsNothing,
          reason: 'GATE-C: TodayScreen must not offer Resume Workout when final set completed');

      // 3. Tap Finish & Finalize
      final finishBtn = find.widgetWithText(KineticButton, 'Finish & Finalize Workout');
      await tester.scrollUntilVisible(finishBtn, 200);
      await tester.runAsync(() async {
        await tester.tap(finishBtn);
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      // 4. Verify SQLite database: exactly 1 workout session, exactly 6 sets, 1 consistency credit
      await tester.runAsync(() async {
        final db = await DatabaseHelper.instance.database;
        final savedSessions = await db.query('workout_sessions');
        expect(savedSessions.length, equals(1), reason: 'Exactly one finalized workout session');

        final savedSets = await db.query('set_logs', where: 'session_id = ?', whereArgs: ['sess_crash_final_set']);
        expect(savedSets.length, equals(6), reason: 'All 6 sets saved without duplication');

        final credit = await repo.getWeeklyConsistencyCredit();
        expect(credit, equals(1), reason: 'Exactly one weekly consistency credit awarded');

        // Active state cleared
        final active = await repo.getActiveSessionState();
        expect(active, isNull);
      });
    });
  });
}
