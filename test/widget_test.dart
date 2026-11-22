import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:homesets/main.dart';
import 'package:homesets/data/database/database_helper.dart';
import 'package:homesets/data/repositories/workout_repository.dart';
import 'package:homesets/data/services/backup_staging_manager.dart';
import 'package:homesets/features/onboarding/onboarding_screen.dart';

void main() {
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setCustomFactory(databaseFactoryFfi);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('homesets_widget_test_');
    final db = await DatabaseHelper.instance.database;
    await db.delete('user_profile');
    await db.delete('equipment_inventory');
    await db.delete('workout_sessions');
    await db.delete('set_logs');
    await db.delete('active_session_state');
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  testWidgets('P6-LAST-03: HomesetsApp fails closed when app documents storage lookup fails', (tester) async {
    final repo = WorkoutRepository();

    // No backupStagingManager provided -> getApplicationDocumentsDirectory() throws MissingPluginException in headless test
    await tester.pumpWidget(HomesetsApp(repository: repo));
    for (int i = 0; i < 10; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Recovery Incomplete').evaluate().isNotEmpty) break;
    }

    expect(find.text('Recovery Incomplete'), findsOneWidget);
    expect(find.textContaining('Storage initialization failed'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('HomesetsApp initializes and presents OnboardingScreen for first-time user when storage provided', (tester) async {
    final repo = WorkoutRepository();
    final stagingManager = BackupStagingManager(appDocsDir: tempDir);

    await tester.pumpWidget(HomesetsApp(
      repository: repo,
      backupStagingManager: stagingManager,
    ));
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
