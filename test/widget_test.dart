import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:homesets/main.dart';
import 'package:homesets/data/database/database_helper.dart';
import 'package:homesets/data/repositories/workout_repository.dart';
import 'package:homesets/features/onboarding/onboarding_screen.dart';

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

  testWidgets('HomesetsApp initializes and presents OnboardingScreen for first-time user', (tester) async {
    final repo = WorkoutRepository();

    await tester.pumpWidget(HomesetsApp(repository: repo));
    for (int i = 0; i < 25; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(OnboardingScreen).evaluate().isNotEmpty) break;
    }

    // Verify OnboardingScreen is shown
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('HOMESETS'), findsOneWidget);
  });
}
