import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:homesets/core/theme/homesets_theme.dart';
import 'package:homesets/data/database/database_helper.dart';
import 'package:homesets/data/repositories/workout_repository.dart';
import 'package:homesets/data/services/photo_service.dart';
import 'package:homesets/domain/models/domain_models.dart';
import 'package:homesets/features/progress/progress_hub_screen.dart';
import 'package:homesets/features/progress/widgets/log_weight_dialog.dart';
import 'package:homesets/features/progress/widgets/photo_comparison_view.dart';
import 'package:homesets/features/progress/widgets/progress_charts.dart';
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
    await db.delete('weight_entries');
    await db.delete('progress_photos');
    await db.delete('daily_meal_checks');
    await db.delete('active_session_state');
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
      home: child,
    );
  }

  Future<void> pumpAsync(WidgetTester tester, [int count = 6]) async {
    for (int i = 0; i < count; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> seedInitialData(WorkoutRepository repo, MockPhotoService photoService) async {
    // 1. Profile & Equipment
    await repo.saveUserProfile(const UserProfile(
      id: 'user_p5_test',
      wakeTimeMinutes: 360,
      shiftStartMinutes: 480,
      targetWorkoutsPerWeek: 4,
      avoidedJoints: [],
    ));

    await repo.saveEquipmentInventory(const EquipmentInventory(
      hasPullUpBar: true,
      hasBands: true,
    ));

    // 2. Weight Entries (3 days)
    final now = DateTime.now();
    await repo.saveWeightEntry(WeightEntry(
      id: 'wt_1',
      weightKg: 78.5,
      loggedAt: now.subtract(const Duration(days: 4)),
    ));
    await repo.saveWeightEntry(WeightEntry(
      id: 'wt_2',
      weightKg: 78.0,
      loggedAt: now.subtract(const Duration(days: 2)),
    ));
    await repo.saveWeightEntry(WeightEntry(
      id: 'wt_3',
      weightKg: 77.8,
      loggedAt: now,
    ));

    // 3. Completed workout session with set logs for strength curve
    final session = CompletedWorkoutSession(
      id: 'sess_strength_1',
      scheduledSessionId: 'sched_1',
      routineName: 'Push A',
      isLiteMode: false,
      startedAt: now.subtract(const Duration(days: 5)),
      endedAt: now.subtract(const Duration(days: 5, hours: -1)),
      totalDurationSeconds: 3600,
      completedSets: [
        SetLog(
          setIndex: 1,
          exerciseId: 'standard_push_up',
          performedReps: 12,
          exertion: ExertionRating.targetSweetspot,
          completedAt: now.subtract(const Duration(days: 5)),
        ),
        SetLog(
          setIndex: 2,
          exerciseId: 'standard_push_up',
          performedReps: 10,
          exertion: ExertionRating.maxEffort,
          completedAt: now.subtract(const Duration(days: 5)),
        ),
      ],
    );
    await repo.saveCompletedSession(session);

    final session2 = CompletedWorkoutSession(
      id: 'sess_strength_2',
      scheduledSessionId: 'sched_2',
      routineName: 'Push A',
      isLiteMode: false,
      startedAt: now.subtract(const Duration(days: 1)),
      endedAt: now.subtract(const Duration(days: 1, hours: -1)),
      totalDurationSeconds: 3600,
      completedSets: [
        SetLog(
          setIndex: 1,
          exerciseId: 'standard_push_up',
          performedReps: 15,
          exertion: ExertionRating.targetSweetspot,
          completedAt: now.subtract(const Duration(days: 1)),
        ),
      ],
    );
    await repo.saveCompletedSession(session2);

    // 4. Photos (Front, Side)
    photoService.seedVirtualFile('progress_photos/photo_1.jpg', [0xFF, 0xD8, 0xFF, 0xE0]);
    photoService.seedVirtualFile('progress_photos/photo_2.jpg', [0xFF, 0xD8, 0xFF, 0xE0]);
    await repo.saveProgressPhoto(ProgressPhoto(
      id: 'photo_1',
      filePath: 'progress_photos/photo_1.jpg',
      angle: PhotoAngle.front,
      takenAt: now.subtract(const Duration(days: 10)),
    ));
    await repo.saveProgressPhoto(ProgressPhoto(
      id: 'photo_2',
      filePath: 'progress_photos/photo_2.jpg',
      angle: PhotoAngle.front,
      takenAt: now.subtract(const Duration(days: 1)),
    ));
  }

  testWidgets('Progress Hub: Overview Tab & Top Metrics (English)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = WorkoutRepository();
    final photoService = MockPhotoService();
    await tester.runAsync(() async {
      await seedInitialData(repo, photoService);
    });

    await tester.runAsync(() async {
      await tester.pumpWidget(createTestWidget(ProgressHubScreen(
        repository: repo,
        photoService: photoService,
      )));
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await pumpAsync(tester, 6);

    // Overview Tab Content
    expect(find.text('Progress Tracking'), findsOneWidget);
    expect(find.text('100% Private'), findsOneWidget);
    expect(find.text('Current Weight'), findsOneWidget);
    expect(find.text('77.8 kg'), findsOneWidget);
    expect(find.byType(WeightTrendChart), findsOneWidget);
    expect(find.text('Physique Photos'), findsOneWidget);
  });

  testWidgets('Progress Hub: Weight Logging & Range Validation (English)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = WorkoutRepository();
    final photoService = MockPhotoService();
    await tester.runAsync(() async {
      await seedInitialData(repo, photoService);
    });

    await tester.runAsync(() async {
      await tester.pumpWidget(createTestWidget(ProgressHubScreen(
        repository: repo,
        photoService: photoService,
      )));
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await pumpAsync(tester, 6);

    // Switch to "Weight" tab via Key('tab_chip_1')
    await tester.runAsync(() async {
      await tester.ensureVisible(find.byKey(const Key('tab_chip_1')));
      await tester.tap(find.byKey(const Key('tab_chip_1')));
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await pumpAsync(tester, 6);

    expect(find.text('Weight History'), findsOneWidget);
    expect(find.text('77.8 kg'), findsOneWidget);

    // Tap "Log Weight" button
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('log_weight_main_btn')));
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await pumpAsync(tester, 6);

    // Verify LogWeightDialog appeared
    expect(find.byType(LogWeightDialog), findsOneWidget);

    // Test invalid weight boundary (e.g., 20 kg < 30 kg)
    final textField = find.byType(TextField);
    await tester.enterText(textField, '20.0');
    await tester.runAsync(() async {
      await tester.tap(find.text('Save Weight'));
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await pumpAsync(tester, 6);

    // Must show validation error and stay open
    expect(find.text('Weight must be between 30 and 300 kg'), findsOneWidget);
    expect(find.byType(LogWeightDialog), findsOneWidget);

    // Enter valid weight (77.2 kg)
    await tester.enterText(textField, '77.2');
    await tester.runAsync(() async {
      await tester.tap(find.text('Save Weight'));
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await pumpAsync(tester, 8);

    // Dialog should dismiss and new weight entry appear
    expect(find.byType(LogWeightDialog), findsNothing);
    expect(find.text('77.2 kg'), findsWidgets);
  });

  testWidgets('Progress Hub: Photos Tab & Side-by-Side Comparison (English)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = WorkoutRepository();
    final photoService = MockPhotoService();
    await tester.runAsync(() async {
      await seedInitialData(repo, photoService);
    });

    await tester.runAsync(() async {
      await tester.pumpWidget(createTestWidget(ProgressHubScreen(
        repository: repo,
        photoService: photoService,
      )));
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await pumpAsync(tester, 6);

    // Switch to Photos tab via Key('tab_chip_2')
    await tester.runAsync(() async {
      await tester.ensureVisible(find.byKey(const Key('tab_chip_2')));
      await tester.tap(find.byKey(const Key('tab_chip_2')));
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await pumpAsync(tester, 6);

    expect(find.text('Add Photo'), findsOneWidget);
    expect(find.byIcon(Icons.compare_arrows), findsOneWidget);

    // Toggle Compare Mode
    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.compare_arrows));
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await pumpAsync(tester, 6);

    expect(find.textContaining('Select 2 photos to compare'), findsOneWidget);

    // Tap the two seeded photos by their unique keys
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('photo_tile_photo_1')));
      await Future.delayed(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('photo_tile_photo_2')));
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await pumpAsync(tester, 6);

    // Now 2 photos selected, Compare button becomes available
    final compareBtn = find.byKey(const Key('compare_now_btn'));
    expect(compareBtn, findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(compareBtn);
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await pumpAsync(tester, 6);

    // Verify side-by-side PhotoComparisonView
    expect(find.byType(PhotoComparisonView), findsOneWidget);
    expect(find.text('Before'), findsOneWidget);
    expect(find.text('After'), findsOneWidget);

    // Close comparison
    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.close));
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await pumpAsync(tester, 6);

    expect(find.byType(PhotoComparisonView), findsNothing);
  });

  testWidgets('Progress Hub: Strength Progression Analytics (English)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = WorkoutRepository();
    final photoService = MockPhotoService();
    await tester.runAsync(() async {
      await seedInitialData(repo, photoService);
    });

    await tester.runAsync(() async {
      await tester.pumpWidget(createTestWidget(ProgressHubScreen(
        repository: repo,
        photoService: photoService,
      )));
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await pumpAsync(tester, 6);

    // Switch to Strength tab via Key('tab_chip_3')
    await tester.runAsync(() async {
      await tester.ensureVisible(find.byKey(const Key('tab_chip_3')));
      await tester.tap(find.byKey(const Key('tab_chip_3')));
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await pumpAsync(tester, 6);

    // Verify Dropdown has standard_push_up
    expect(find.text('STANDARD PUSH UP'), findsOneWidget);

    // Baseline: 12 reps, Best: 15 reps, Recent: 15 reps, Delta: +3 reps
    expect(find.text('12 reps'), findsOneWidget);
    expect(find.text('15 reps'), findsNWidgets(2)); // Best & Recent
    expect(find.text('+3 reps vs baseline'), findsOneWidget);
    expect(find.byType(StrengthProgressionChart), findsOneWidget);
  });

  testWidgets('Progress Hub: Nutrition Daily Checklist & Suggestions (English)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = WorkoutRepository();
    final photoService = MockPhotoService();
    await tester.runAsync(() async {
      await seedInitialData(repo, photoService);
    });

    await tester.runAsync(() async {
      await tester.pumpWidget(createTestWidget(ProgressHubScreen(
        repository: repo,
        photoService: photoService,
      )));
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await pumpAsync(tester, 6);

    // Switch to Nutrition tab via Key('tab_chip_4')
    await tester.runAsync(() async {
      await tester.ensureVisible(find.byKey(const Key('tab_chip_4')));
      await tester.tap(find.byKey(const Key('tab_chip_4')));
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await pumpAsync(tester, 6);

    expect(find.text('Daily Protein Checklist'), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('Inexpensive Egyptian Protein Ideas'), findsOneWidget);
    expect(find.text('Boiled Eggs'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);

    // Tap Breakfast checkbox
    await tester.runAsync(() async {
      await tester.tap(find.text('Breakfast'));
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await pumpAsync(tester, 6);

    // Count updates to 1/3
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('Progress Hub: Egyptian Arabic RTL & Responsive Text Scaling (360x780, 1.5x font)', (tester) async {
    tester.view.physicalSize = const Size(720, 1560); // 360 x 780 @ 2.0x
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = WorkoutRepository();
    final photoService = MockPhotoService();
    await tester.runAsync(() async {
      await seedInitialData(repo, photoService);
    });

    await tester.runAsync(() async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 780),
            textScaler: TextScaler.linear(1.5),
          ),
          child: createTestWidget(
            ProgressHubScreen(
              repository: repo,
              photoService: photoService,
            ),
            locale: const Locale('ar'),
          ),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await pumpAsync(tester, 6);

    // Verify Arabic titles and no layout overflows
    expect(find.text('متابعة التطور والنتائج'), findsOneWidget);
    expect(find.text('الوزن الحالي'), findsOneWidget);
    expect(find.text('صور الجسم والتطور'), findsOneWidget);

    // Switch between all tabs under 1.5x scale factor to verify zero RenderFlex overflow
    await tester.runAsync(() async {
      await tester.ensureVisible(find.byKey(const Key('tab_chip_1')));
      await tester.tap(find.byKey(const Key('tab_chip_1')));
      await Future.delayed(const Duration(milliseconds: 150));
    });
    await pumpAsync(tester, 6);
    expect(tester.takeException(), isNull);

    await tester.runAsync(() async {
      await tester.ensureVisible(find.byKey(const Key('tab_chip_2')));
      await tester.tap(find.byKey(const Key('tab_chip_2')));
      await Future.delayed(const Duration(milliseconds: 150));
    });
    await pumpAsync(tester, 6);
    expect(tester.takeException(), isNull);

    await tester.runAsync(() async {
      await tester.ensureVisible(find.byKey(const Key('tab_chip_3')));
      await tester.tap(find.byKey(const Key('tab_chip_3')));
      await Future.delayed(const Duration(milliseconds: 150));
    });
    await pumpAsync(tester, 6);
    expect(tester.takeException(), isNull);

    await tester.runAsync(() async {
      await tester.ensureVisible(find.byKey(const Key('tab_chip_4')));
      await tester.tap(find.byKey(const Key('tab_chip_4')));
      await Future.delayed(const Duration(milliseconds: 150));
    });
    await pumpAsync(tester, 6);
    expect(tester.takeException(), isNull);
  });
}
