import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:homesets/main.dart';
import 'package:homesets/data/database/database_helper.dart';
import 'package:homesets/data/repositories/workout_repository.dart';
import 'package:homesets/features/onboarding/onboarding_screen.dart';
import 'package:homesets/features/today/today_screen.dart';
import 'package:homesets/features/workout/workout_player_screen.dart';
import 'package:homesets/features/summary/summary_screen.dart';
import 'package:homesets/features/shared/kinetic_button.dart';

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
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  testWidgets('Complete End-to-End User Flow with Pain Stop (English)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = WorkoutRepository();

    // 1. Launch App -> Expect Onboarding
    await tester.pumpWidget(HomesetsApp(
      repository: repo,
      locale: const Locale('en'),
    ));
    for (int i = 0; i < 6; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Set Up Your Training'), findsOneWidget);

    // 2. Scroll down and tap "Start Training"
    final startTrainingBtn = find.widgetWithText(KineticButton, 'Start Training');
    await tester.scrollUntilVisible(startTrainingBtn, 200);
    await tester.pump();
    expect(startTrainingBtn, findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(startTrainingBtn);
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    // 3. Today Screen
    expect(find.byType(TodayScreen), findsOneWidget);
    for (int i = 0; i < 10; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Weekly Consistency'), findsOneWidget);

    // Verify workout card exists and tap "Start Workout"
    final startWorkoutBtn = find.widgetWithText(KineticButton, 'Start Workout');
    expect(startWorkoutBtn, findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(startWorkoutBtn);
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // 4. Workout Player Screen
    expect(find.byType(WorkoutPlayerScreen), findsOneWidget);

    // Test SAFE-01: Tap 1-tap Emergency Pain Stop
    final painStopBtn = find.widgetWithText(KineticButton, '🛑 Joint Discomfort / Pain Stop');
    expect(painStopBtn, findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(painStopBtn);
      await Future.delayed(const Duration(milliseconds: 300));
    });
    for (int i = 0; i < 6; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Confirm dialog appears
    expect(find.text('Safety Priority: Stop Exercise'), findsOneWidget);
    final confirmStopBtn = find.widgetWithText(ElevatedButton, 'Stop Exercise Now');
    expect(confirmStopBtn, findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(confirmStopBtn);
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // 5. Summary Screen
    expect(find.byType(SummaryScreen), findsOneWidget);
    expect(find.text('Joint Safety Respected ✓'), findsOneWidget);

    // Tap "Back to Today"
    final backBtn = find.widgetWithText(KineticButton, 'Back to Today');
    expect(backBtn, findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(backBtn);
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // Back on TodayScreen
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('Complete End-to-End User Flow with Pain Stop (Egyptian Arabic RTL)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = WorkoutRepository();

    // 1. Launch App in Arabic
    await tester.pumpWidget(HomesetsApp(
      repository: repo,
      locale: const Locale('ar'),
    ));
    for (int i = 0; i < 6; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('تجهيز خطة تمرينك'), findsOneWidget);

    // 2. Scroll down and tap "ابدأ على بركة الله"
    final startTrainingBtnAr = find.widgetWithText(KineticButton, 'ابدأ على بركة الله');
    await tester.scrollUntilVisible(startTrainingBtnAr, 200);
    await tester.pump();
    expect(startTrainingBtnAr, findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(startTrainingBtnAr);
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    // 3. Today Screen in Arabic
    expect(find.byType(TodayScreen), findsOneWidget);
    for (int i = 0; i < 10; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('النهاردة'), findsOneWidget);
    expect(find.text('الاستمرارية الأسبوعية'), findsOneWidget);

    // Tap "ابدأ التمرين الكامل"
    final startWorkoutBtnAr = find.widgetWithText(KineticButton, 'ابدأ التمرين الكامل');
    expect(startWorkoutBtnAr, findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(startWorkoutBtnAr);
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // 4. Workout Player Screen in Arabic
    expect(find.byType(WorkoutPlayerScreen), findsOneWidget);
    expect(find.text('مجموعة 1 من 3'), findsOneWidget);

    // Tap 1-tap pain stop
    final painStopBtnAr = find.widgetWithText(KineticButton, '🛑 ألم أو انزعاج مفصلي (وقف التمرين)');
    expect(painStopBtnAr, findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(painStopBtnAr);
      await Future.delayed(const Duration(milliseconds: 300));
    });
    for (int i = 0; i < 6; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Confirm dialog in Arabic
    expect(find.text('سلامة مفاصلك أولاً'), findsOneWidget);
    final confirmStopBtnAr = find.widgetWithText(ElevatedButton, 'وقف التمرين فوراً');
    expect(confirmStopBtnAr, findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(confirmStopBtnAr);
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // 5. Summary Screen in Arabic
    expect(find.byType(SummaryScreen), findsOneWidget);
    expect(find.text('سلامة مفاصلك أولاً ✓'), findsOneWidget);

    // Tap "رجوع للرئيسية"
    final backBtnAr = find.widgetWithText(KineticButton, 'رجوع للرئيسية');
    expect(backBtnAr, findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(backBtnAr);
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // Back on TodayScreen
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('Workout Player: Rep Stepper, Log Set, Exertion Rating, and Rest Timer Flow', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = WorkoutRepository();

    // Launch App and pass onboarding
    await tester.pumpWidget(HomesetsApp(
      repository: repo,
      locale: const Locale('en'),
    ));
    for (int i = 0; i < 6; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    final startTrainingBtn = find.widgetWithText(KineticButton, 'Start Training');
    await tester.scrollUntilVisible(startTrainingBtn, 200);
    await tester.runAsync(() async {
      await tester.tap(startTrainingBtn);
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    for (int i = 0; i < 10; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Start standard workout
    final startWorkoutBtn = find.widgetWithText(KineticButton, 'Start Workout');
    await tester.runAsync(() async {
      await tester.tap(startWorkoutBtn);
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    expect(find.byType(WorkoutPlayerScreen), findsOneWidget);
    expect(find.text('Set 1 of 3'), findsOneWidget);

    // Tap + on RepCounterStepper
    final addRepBtn = find.byIcon(Icons.add);
    expect(addRepBtn, findsOneWidget);
    await tester.tap(addRepBtn);
    await tester.pump();

    // Tap "Log Set & Rest"
    final logSetBtn = find.widgetWithText(KineticButton, 'Log Set & Rest');
    expect(logSetBtn, findsOneWidget);
    await tester.tap(logSetBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Exertion prompt sheet should be open
    expect(find.text('How did that set feel?'), findsOneWidget);
    expect(find.text('Perfect Stimulus 👍'), findsOneWidget);

    // Confirm sheet by tapping "Log Set & Rest" inside bottom sheet
    final confirmLogBtn = find.widgetWithText(KineticButton, 'Log Set & Rest').last;
    await tester.tap(confirmLogBtn);
    await tester.pump();

    for (int i = 0; i < 10; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Rest interval screen is now visible
    expect(find.text('Rest Interval'), findsOneWidget);
    expect(find.text('+30s Rest'), findsOneWidget);

    // Tap "+30s Rest"
    final addThirtyBtn = find.widgetWithText(KineticButton, '+30s Rest');
    await tester.tap(addThirtyBtn);
    await tester.pump();

    // Tap "Skip Rest"
    final skipRestBtn = find.widgetWithText(KineticButton, 'Skip Rest');
    expect(skipRestBtn, findsOneWidget);
    await tester.tap(skipRestBtn);
    await tester.pump();

    for (int i = 0; i < 8; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Returned to player: now Set 2 of 3 is active!
    expect(find.byType(WorkoutPlayerScreen), findsOneWidget);
    expect(find.text('Set 2 of 3'), findsOneWidget);
  });

  testWidgets('Adaptive Lite Mode Launch and Verification', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = WorkoutRepository();

    // Launch App and pass onboarding
    await tester.pumpWidget(HomesetsApp(
      repository: repo,
      locale: const Locale('en'),
    ));
    for (int i = 0; i < 6; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    final startTrainingBtn = find.widgetWithText(KineticButton, 'Start Training');
    await tester.scrollUntilVisible(startTrainingBtn, 200);
    await tester.runAsync(() async {
      await tester.tap(startTrainingBtn);
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    for (int i = 0; i < 10; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Scroll to Lite Mode card
    final startLiteBtn = find.widgetWithText(KineticButton, 'Start Lite Workout');
    await tester.scrollUntilVisible(startLiteBtn, 200);
    await tester.pump();
    expect(startLiteBtn, findsOneWidget);

    // Tap "Start Lite Workout"
    await tester.runAsync(() async {
      await tester.tap(startLiteBtn);
      await Future.delayed(const Duration(milliseconds: 300));
    });
    for (int i = 0; i < 5; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    // WorkoutPlayer opened with Lite Mode session (2 sets total for first exercise)
    expect(find.byType(WorkoutPlayerScreen), findsOneWidget);
    expect(find.text('Set 1 of 2'), findsOneWidget);
  });
}
