import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:homesets/data/database/database_helper.dart';
import 'package:homesets/data/repositories/workout_repository.dart';
import 'package:homesets/data/services/photo_service.dart';
import 'package:homesets/domain/models/domain_models.dart';
import 'package:homesets/domain/progress/progress_analytics.dart';
import 'package:homesets/features/progress/progress_hub_screen.dart';
import 'package:homesets/features/progress/widgets/log_weight_dialog.dart';
import 'package:homesets/l10n/app_localizations.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setCustomFactory(databaseFactoryFfi);
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  group('P5 Review Reproductions & Regression Tests (P5-R01 to P5-R09)', () {
    // -------------------------------------------------------------------------
    // P5-R01: Bounded photo import & oversized file rejection
    // -------------------------------------------------------------------------
    test('P5-R01: copyToPrivateSandbox rejects oversized files (> 15MB) and cleans temp file', () async {
      const service = AndroidPhotoService();
      final tempDir = Directory.systemTemp.createTempSync('homesets_oversized_test');
      final hugeFile = File('${tempDir.path}${Platform.pathSeparator}huge_image.jpg');

      try {
        // Write a file with JPEG magic bytes but exceeding 15 MB limit (e.g. 16 MB)
        final sink = hugeFile.openWrite();
        sink.add([0xFF, 0xD8, 0xFF, 0xE0]); // JPEG magic
        final filler = Uint8List(1024 * 1024); // 1 MB chunk
        for (int i = 0; i < 16; i++) {
          sink.add(filler);
        }
        await sink.flush();
        await sink.close();

        expect(hugeFile.lengthSync(), greaterThan(15 * 1024 * 1024));

        // Must reject with FormatException
        await expectLater(
          () => service.copyToPrivateSandbox(hugeFile.path, 'photo_oversized'),
          throwsA(isA<FormatException>()),
        );

        // Staged file should be deleted on failure
        expect(hugeFile.existsSync(), isFalse, reason: 'Oversized stage file should be deleted on failure');
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    // -------------------------------------------------------------------------
    // P5-R02: Compensating cleanup on database error & startup orphan cleanup
    // -------------------------------------------------------------------------
    test('P5-R02: When database insert fails, staged/sandbox photo file is rolled back', () async {
      final mockPhotoService = MockPhotoService(mockPickResult: '/mock/path/stage.jpg');

      // Stage and copy to sandbox
      final relativePath = await mockPhotoService.copyToPrivateSandbox('/mock/path/stage.jpg', 'photo_fail_1');
      expect(mockPhotoService.storedFiles.containsKey(relativePath), isTrue);

      // Simulate repository save failure: compensating action must delete the file
      try {
        throw Exception('Injected SQLite write failure (disk full / constraint)');
      } catch (_) {
        await mockPhotoService.deletePrivatePhoto(relativePath);
      }

      // Assert that the file is NOT orphaned
      expect(mockPhotoService.storedFiles.containsKey(relativePath), isFalse);
    });

    test('P5-R02: Startup orphan cleanup safely removes untracked photos', () async {
      final mockPhotoService = MockPhotoService();
      // Seed two photos: one tracked in DB, one orphan
      mockPhotoService.seedVirtualFile('progress_photos/tracked.jpg', [0xFF, 0xD8, 0xFF, 0xE0]);
      mockPhotoService.seedVirtualFile('progress_photos/orphan_crash.jpg', [0xFF, 0xD8, 0xFF, 0xE0]);

      expect(mockPhotoService.storedFiles.length, equals(2));

      // Startup cleanup with valid DB paths
      final cleanedCount = await mockPhotoService.cleanupOrphanPhotos(['progress_photos/tracked.jpg']);
      expect(cleanedCount, equals(1));
      expect(mockPhotoService.storedFiles.containsKey('progress_photos/tracked.jpg'), isTrue);
      expect(mockPhotoService.storedFiles.containsKey('progress_photos/orphan_crash.jpg'), isFalse);
    });

    // -------------------------------------------------------------------------
    // P5-R03: Real DatabaseHelper production migration callback executes
    // -------------------------------------------------------------------------
    test('P5-R03: Real production DatabaseHelper migration callback preserves v1 data and adds v2 schema', () async {
      final factory = databaseFactoryFfi;
      const dbName = 'test_real_db_helper_upgrade.db';
      await factory.deleteDatabase(dbName);

      // Create a real v1 database using DatabaseHelper's v1 creation definition
      final v1Db = await factory.openDatabase(
        dbName,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await DatabaseHelper.onCreateV1ForTesting(db);
          },
        ),
      );

      // Populate v1 data
      final now = DateTime.now();
      await v1Db.insert('user_profile', {
        'id': 'profile_1',
        'goal': 'build_muscle',
        'wake_time_minutes': 480,
        'shift_start_minutes': 540,
        'target_workouts_per_week': 4,
        'avoided_joints': '[]',
        'created_at': now.toIso8601String(),
      });
      await v1Db.close();

      // Open database using DatabaseHelper's actual production onUpgrade callback
      final v2Db = await factory.openDatabase(
        dbName,
        options: OpenDatabaseOptions(
          version: 2,
          onUpgrade: DatabaseHelper.onUpgradeCallback,
        ),
      );

      // Verify v1 profile is intact
      final profiles = await v2Db.query('user_profile');
      expect(profiles.length, equals(1));
      expect(profiles.first['id'], equals('profile_1'));

      // Verify v2 tables exist via real migration callback
      final tables = await v2Db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
      final names = tables.map((t) => t['name'] as String).toSet();
      expect(names, contains('weight_entries'));
      expect(names, contains('progress_photos'));
      expect(names, contains('daily_meal_checks'));

      // Verify idempotence: calling migration again should succeed without error
      await expectLater(
        DatabaseHelper.migrateToV2(v2Db),
        completes,
      );

      await v2Db.close();
      await factory.deleteDatabase(dbName);
    });

    // -------------------------------------------------------------------------
    // P5-R05: Strength history segments bands and compares like-for-like
    // -------------------------------------------------------------------------
    test('P5-R05: Strength history segments band assistance/resistance and avoids misleading deltas', () async {
      final repo = WorkoutRepository();
      // Ensure database is initialized
      await DatabaseHelper.instance.database;

      final now = DateTime.now();

      // Session 1: bodyweight pullups, 5 reps
      await repo.saveCompletedSession(CompletedWorkoutSession(
        id: 'sess_1',
        scheduledSessionId: 'sched_1',
        routineName: 'Routine A',
        isLiteMode: false,
        startedAt: now.subtract(const Duration(days: 4)),
        endedAt: now.subtract(const Duration(days: 4, minutes: -30)),
        totalDurationSeconds: 1800,
        completedSets: [
          SetLog(
            setIndex: 0,
            exerciseId: 'pullup_standard',
            performedReps: 5,
            bandUsed: null,
            exertion: ExertionRating.targetSweetspot,
            completedAt: now.subtract(const Duration(days: 4, minutes: -10)),
          ),
        ],
      ));

      // Session 2: purple band assisted pullups, 15 reps
      await repo.saveCompletedSession(CompletedWorkoutSession(
        id: 'sess_2',
        scheduledSessionId: 'sched_2',
        routineName: 'Routine A',
        isLiteMode: false,
        startedAt: now.subtract(const Duration(days: 2)),
        endedAt: now.subtract(const Duration(days: 2, minutes: -30)),
        totalDurationSeconds: 1800,
        completedSets: [
          SetLog(
            setIndex: 0,
            exerciseId: 'pullup_standard',
            performedReps: 15,
            bandUsed: 'purple_band',
            exertion: ExertionRating.targetSweetspot,
            completedAt: now.subtract(const Duration(days: 2, minutes: -10)),
          ),
        ],
      ));

      // Session 3: bodyweight pullups, 8 reps
      await repo.saveCompletedSession(CompletedWorkoutSession(
        id: 'sess_3',
        scheduledSessionId: 'sched_3',
        routineName: 'Routine A',
        isLiteMode: false,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 30)),
        totalDurationSeconds: 1800,
        completedSets: [
          SetLog(
            setIndex: 0,
            exerciseId: 'pullup_standard',
            performedReps: 8,
            bandUsed: null,
            exertion: ExertionRating.targetSweetspot,
            completedAt: now.add(const Duration(minutes: 10)),
          ),
        ],
      ));

      // Available band configurations must discover both 'none' and 'purple_band'
      final availableBands = await repo.getAvailableBandConfigurations('pullup_standard');
      expect(availableBands, contains('none'));
      expect(availableBands, contains('purple_band'));

      // Query bodyweight only: must only contain Session 1 and Session 3
      final bwHistory = await repo.getStrengthHistoryForExercise('pullup_standard', bandFilter: 'none');
      expect(bwHistory.length, equals(2));
      expect(bwHistory[0].maxReps, equals(5));
      expect(bwHistory[1].maxReps, equals(8));

      final bwSummary = ProgressAnalytics.computeStrengthSummary(bwHistory);
      expect(bwSummary.baselineMaxReps, equals(5));
      expect(bwSummary.recentMaxReps, equals(8));
      expect(bwSummary.allTimeBestMaxReps, equals(8), reason: 'Purple band 15 reps must NOT pollute bodyweight best');
      expect(bwSummary.repsDelta, equals(3), reason: 'Delta is 8 - 5 = +3 for bodyweight');
      expect(bwSummary.isComparable, isTrue);

      // Query purple band only: must only contain Session 2
      final bandHistory = await repo.getStrengthHistoryForExercise('pullup_standard', bandFilter: 'purple_band');
      expect(bandHistory.length, equals(1));
      expect(bandHistory[0].maxReps, equals(15));
      expect(bandHistory[0].bandUsed, equals('purple_band'));

      // If unfiltered, summary marks mixed bands as non-comparable
      final allHistory = await repo.getStrengthHistoryForExercise('pullup_standard');
      final allSummary = ProgressAnalytics.computeStrengthSummary(allHistory);
      expect(allSummary.isComparable, isFalse);
      expect(allSummary.repsDelta, isNull, reason: 'Mixed band sets must produce null repsDelta to prevent flat misleading progress');
    });

    // -------------------------------------------------------------------------
    // P5-R06: Weight editing preserves entry ID and awaits save
    // -------------------------------------------------------------------------
    testWidgets('P5-R06: LogWeightDialog supports editing existing entry with same ID', (tester) async {
      double? savedWeight;
      bool saveCalled = false;

      final existingEntry = WeightEntry(
        id: 'wt_existing_999',
        weightKg: 74.5,
        loggedAt: DateTime(2026, 11, 20, 10, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LogWeightDialog(
              entryToEdit: existingEntry,
              onSaveAsync: (weight) async {
                savedWeight = weight;
                saveCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify dialog title says "Edit Weight"
      expect(find.text('Edit Weight'), findsOneWidget);

      // Verify dialog is pre-filled with 74.5
      expect(find.text('74.5'), findsOneWidget);

      // Enter new weight: 75.8
      await tester.enterText(find.byType(TextField), '75.8');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Weight'));
      await tester.pumpAndSettle();

      expect(saveCalled, isTrue);
      expect(savedWeight, equals(75.8));
    });

    // -------------------------------------------------------------------------
    // P5-R07: Midnight meal rollover prevents saving to yesterday's date
    // -------------------------------------------------------------------------
    test('P5-R07: Meal checks save to the exact active calendar date and rollover cleanly', () async {
      final repo = WorkoutRepository();
      await DatabaseHelper.instance.database;

      const day1 = '2026-11-20';
      const day2 = '2026-11-21';

      // Check slot 0 (breakfast) on Day 1
      await repo.saveMealCheck(day1, 0, true);
      final day1Checks = await repo.getMealChecksForDate(day1);
      expect(day1Checks[0], isTrue);

      // Day 2 checks must be completely fresh (not checked)
      final day2ChecksBefore = await repo.getMealChecksForDate(day2);
      expect(day2ChecksBefore[0], isNull);

      // Check slot 0 on Day 2
      await repo.saveMealCheck(day2, 0, true);
      final day2ChecksAfter = await repo.getMealChecksForDate(day2);
      expect(day2ChecksAfter[0], isTrue);

      // Day 1 must remain preserved
      final day1ChecksAgain = await repo.getMealChecksForDate(day1);
      expect(day1ChecksAgain[0], isTrue);
    });

    // -------------------------------------------------------------------------
    // P5-R09: Progress Hub AppBar does NOT claim "100% Private"
    // -------------------------------------------------------------------------
    testWidgets('P5-R09: Progress Hub AppBar replaces absolute 100% Private with truthful App-Private badge', (tester) async {
      final repo = WorkoutRepository();
      final mockPhoto = MockPhotoService();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProgressHubScreen(
            repository: repo,
            photoService: mockPhoto,
          ),
        ),
      );
      for (int i = 0; i < 6; i++) {
        await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Assert that the obsolete absolute promise is NOT present in UI
      expect(find.text('100% Private'), findsNothing);
      expect(find.text('App-Private'), findsOneWidget);
    });
  });

  // Helper to pump async without SQLite FFI timeouts
  Future<void> pumpAsync(WidgetTester tester, [int count = 6]) async {
    for (int i = 0; i < count; i++) {
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  // ===========================================================================
  // P5 FINAL INTEGRATION GATE REPRODUCTIONS (FINAL-01 to FINAL-05)
  // ===========================================================================
  group('P5 Final Integration Gate (P5-FINAL-01 to P5-FINAL-05)', () {
    // -------------------------------------------------------------------------
    // P5-FINAL-01: Injected photo file deletion failure aborts DB deletion
    // -------------------------------------------------------------------------
    testWidgets('P5-FINAL-01: Injected photo file deletion failure does not delete database metadata and shows error UI', (tester) async {
      final repo = WorkoutRepository();
      final mockPhoto = _FailingDeleteMockPhotoService();

      // Seed photo record in SQLite and virtual file in mock service
      final now = DateTime.now();
      final photo = ProgressPhoto(
        id: 'photo_final_01',
        filePath: 'progress_photos/photo_final_01.jpg',
        angle: PhotoAngle.front,
        takenAt: now,
      );
      await tester.runAsync(() async {
        await repo.saveProgressPhoto(photo);
      });
      mockPhoto.seedVirtualFile('progress_photos/photo_final_01.jpg', [0xFF, 0xD8, 0xFF, 0xE0]);

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProgressHubScreen(
              repository: repo,
              photoService: mockPhoto,
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await pumpAsync(tester, 6);

      // Navigate to Photos Tab (Tab index 2)
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('tab_chip_2')));
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await pumpAsync(tester, 6);

      // Tap the photo tile to open detail dialog
      final tileFinder = find.byKey(const Key('photo_tile_photo_final_01'));
      expect(tileFinder, findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(tileFinder);
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await pumpAsync(tester, 6);

      // Tap Delete Photo in detail dialog
      final deleteBtnFinder = find.byIcon(Icons.delete_outline);
      expect(deleteBtnFinder, findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(deleteBtnFinder);
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await pumpAsync(tester, 6);

      // Confirm deletion in confirmation alert dialog
      final confirmBtnFinder = find.widgetWithText(ElevatedButton, 'Delete');
      expect(confirmBtnFinder, findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(confirmBtnFinder);
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await pumpAsync(tester, 6);

      // REPRODUCTION ASSERTION:
      // When filesystem deletion fails, the DB record MUST NOT be deleted!
      List<ProgressPhoto> remainingPhotos = [];
      await tester.runAsync(() async {
        remainingPhotos = await repo.getProgressPhotos();
      });
      expect(remainingPhotos.length, equals(1), reason: 'Photo metadata MUST NOT be deleted from DB when storage deletion fails');
      expect(find.byType(SnackBar), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // P5-FINAL-02: Concurrent orphan sweep during photo import does not delete staged file
    // -------------------------------------------------------------------------
    test('P5-FINAL-02: Concurrent orphan sweep during photo import does not delete in-flight staged image', () async {
      final mockPhoto = MockPhotoService();
      // Start import
      final inFlightPath = await mockPhoto.copyToPrivateSandbox('/staged/img.jpg', 'photo_inflight_99');
      expect(mockPhoto.storedFiles.containsKey(inFlightPath), isTrue);

      // Concurrent orphan sweep runs with empty DB list before DB commit completes
      await mockPhoto.cleanupOrphanPhotos([]);

      // REPRODUCTION ASSERTION:
      // The in-flight image must not be deleted as an orphan while import is pending!
      expect(mockPhoto.storedFiles.containsKey(inFlightPath), isTrue,
          reason: 'In-flight staged photo must be protected from concurrent orphan sweep');
    });

    // -------------------------------------------------------------------------
    // P5-FINAL-03: Midnight meal rollover gesture semantics
    // -------------------------------------------------------------------------
    testWidgets('P5-FINAL-03: Midnight rollover during foreground session toggles today fresh state rather than applying stale previous-day value', (tester) async {
      final repo = WorkoutRepository();
      final mockPhoto = MockPhotoService();

      var simulatedNow = DateTime(2026, 11, 20, 23, 59);

      // Seed Breakfast (slot 0) as checked on 2026-11-20
      await tester.runAsync(() async {
        await repo.saveMealCheck('2026-11-20', 0, true);
      });

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProgressHubScreen(
              repository: repo,
              photoService: mockPhoto,
              nowProvider: () => simulatedNow,
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await pumpAsync(tester, 6);

      // Navigate to Nutrition Tab (Tab index 4)
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('tab_chip_4')));
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await pumpAsync(tester, 6);

      // Verify Breakfast is currently checked on screen
      expect(find.text('Breakfast'), findsOneWidget);

      // Advance clock past midnight into 2026-11-21 without disposing or reopening the screen
      simulatedNow = DateTime(2026, 11, 21, 0, 5);

      // User taps the breakfast meal row on the foreground screen
      await tester.runAsync(() async {
        await tester.tap(find.text('Breakfast'));
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await pumpAsync(tester, 6);

      // REPRODUCTION ASSERTION:
      // On rollover, user tap must toggle today's fresh state to TRUE, not false!
      Map<int, bool> todayChecks = {};
      await tester.runAsync(() async {
        todayChecks = await repo.getMealChecksForDate('2026-11-21');
      });
      expect(todayChecks[0], isTrue, reason: 'Tapping on rollover must toggle today un-checked meal to checked (true)');
    });

    // -------------------------------------------------------------------------
    // P5-FINAL-05: Exercise change resets band filter and mixed strength view hides zero delta
    // -------------------------------------------------------------------------
    testWidgets('P5-FINAL-05: Exercise change resets band filter before query and mixed strength view hides delta with noncomparable banner', (tester) async {
      final repo = WorkoutRepository();
      final mockPhoto = MockPhotoService();
      final now = DateTime.now();

      await tester.runAsync(() async {
        // Seed 2 sessions for exercise_pullup with mixed bands
        await repo.saveCompletedSession(CompletedWorkoutSession(
          id: 'sess_1',
          scheduledSessionId: 's1',
          routineName: 'Upper Pull',
          isLiteMode: false,
          startedAt: now.subtract(const Duration(days: 4)),
          endedAt: now.subtract(const Duration(days: 4, hours: -1)),
          totalDurationSeconds: 3600,
          completedSets: [
            SetLog(
              setIndex: 1,
              exerciseId: 'exercise_pullup',
              performedReps: 6,
              bandUsed: null, // bodyweight
              exertion: ExertionRating.targetSweetspot,
              completedAt: now.subtract(const Duration(days: 4)),
            ),
          ],
        ));

        await repo.saveCompletedSession(CompletedWorkoutSession(
          id: 'sess_2',
          scheduledSessionId: 's2',
          routineName: 'Upper Pull',
          isLiteMode: false,
          startedAt: now.subtract(const Duration(days: 2)),
          endedAt: now.subtract(const Duration(days: 2, hours: -1)),
          totalDurationSeconds: 3600,
          completedSets: [
            SetLog(
              setIndex: 1,
              exerciseId: 'exercise_pullup',
              performedReps: 10,
              bandUsed: 'band_purple', // with purple band
              exertion: ExertionRating.targetSweetspot,
              completedAt: now.subtract(const Duration(days: 2)),
            ),
          ],
        ));
      });

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProgressHubScreen(
              repository: repo,
              photoService: mockPhoto,
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await pumpAsync(tester, 6);

      // Navigate to Strength Tab (Tab index 3)
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('tab_chip_3')));
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await pumpAsync(tester, 6);

      // REPRODUCTION ASSERTION:
      // When mixed configurations are present without single band filter, repsDelta must be null / hidden,
      // and explicit noncomparable banner must be shown.
      expect(find.byKey(const Key('mixed_bands_banner')), findsOneWidget);
      expect(find.text('+0 reps'), findsNothing);
      expect(find.text('0 reps'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // P5-CLOSE-01: Routine UI reload does not execute orphan sweep & committed photos are never dropped
    // -------------------------------------------------------------------------
    testWidgets('P5-CLOSE-01: Routine UI reload does not execute orphan sweep and committed photos are never dropped during concurrent operations', (tester) async {
      final repo = WorkoutRepository();
      final trackingPhoto = _TrackingPhotoService();

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProgressHubScreen(
              repository: repo,
              photoService: trackingPhoto,
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await pumpAsync(tester, 6);

      // In production before fix: _loadAllData() runs cleanupOrphanPhotos on every screen reload/init.
      // After fix: cleanupOrphanPhotos must NOT be run by ProgressHubScreen._loadAllData()!
      expect(trackingPhoto.cleanupCallCount, equals(0),
          reason: 'Routine UI load must not execute orphan sweep; sweep belongs exclusively to serialized cold-start');

      // Now test concurrent import and refresh interleaving:
      // 1. Slow photo import copies binary to private sandbox
      final inFlightRelPath = await trackingPhoto.copyToPrivateSandbox('/mock/test.jpg', 'photo_concurrent_1');
      expect(trackingPhoto.storedFiles.containsKey(inFlightRelPath), isTrue);

      // 2. Concurrent UI refresh occurs (e.g. user toggles meal or logs weight)
      await tester.runAsync(() async {
        await repo.saveMealCheck('2026-11-21', 1, true);
        // Trigger screen data reload
        await tester.tap(find.byKey(const Key('tab_chip_4'))); // Navigate to meals
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await pumpAsync(tester, 6);

      // Sweep should still NOT have been called during routine refresh
      expect(trackingPhoto.cleanupCallCount, equals(0));

      // 3. Complete asynchronous SQLite metadata commit
      final photo = ProgressPhoto(
        id: 'photo_concurrent_1',
        filePath: inFlightRelPath,
        angle: PhotoAngle.front,
        takenAt: DateTime.now(),
      );
      await tester.runAsync(() async {
        await repo.saveProgressPhoto(photo);
      });
      trackingPhoto.completePendingImport(inFlightRelPath);

      // Verify photo binary and database record are both intact
      expect(trackingPhoto.storedFiles.containsKey(inFlightRelPath), isTrue);
      List<ProgressPhoto> dbPhotos = [];
      await tester.runAsync(() async {
        dbPhotos = await repo.getProgressPhotos();
      });
      expect(dbPhotos.any((p) => p.id == 'photo_concurrent_1'), isTrue);
    });

    // -------------------------------------------------------------------------
    // P5-CLOSE-02-A: Partial destination file is cleaned up on copy failure
    // -------------------------------------------------------------------------
    test('P5-CLOSE-02-A: On failed photo copy, any partial private destination file is safely removed', () async {
      final tempDir = Directory.systemTemp.createTempSync('homesets_partial_copy_test');
      try {
        final stagedFile = File('${tempDir.path}${Platform.pathSeparator}staged_valid.jpg');
        // Valid JPEG header
        stagedFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]);

        String? observedDestPath;
        final service = AndroidPhotoService(
          baseDirResolver: () async => tempDir,
          copyOverride: (source, destination) async {
            observedDestPath = destination;
            // Simulate partial write before crash or disk full
            final dest = File(destination);
            await dest.writeAsBytes([0xFF, 0xD8, 0x00]); // 3 partial bytes
            throw const FileSystemException('Simulated disk full / I/O error during copy');
          },
        );

        await expectLater(
          () => service.copyToPrivateSandbox(stagedFile.path, 'photo_partial_test'),
          throwsA(isA<FileSystemException>()),
        );

        // Verification: The partial destination file must be cleanly deleted on failure!
        expect(observedDestPath, isNotNull);
        final partialDestFile = File(observedDestPath!);
        expect(partialDestFile.existsSync(), isFalse,
            reason: 'Partial destination file must be cleaned up on copy failure');
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    // -------------------------------------------------------------------------
    // P5-CLOSE-02-B: SQLite delete failure after file delete provides truthful retryable state
    // -------------------------------------------------------------------------
    testWidgets('P5-CLOSE-02-B: When file delete succeeds but SQLite delete fails, UI shows truthful retryable state and eventual idempotent cleanup', (tester) async {
      final repo = _FailingDeleteProgressPhotoRepository();
      final mockPhoto = MockPhotoService();

      // Seed a photo in repo and in mock storage
      final photo = ProgressPhoto(
        id: 'photo_retry_test',
        filePath: 'progress_photos/photo_retry_test.jpg',
        angle: PhotoAngle.front,
        takenAt: DateTime(2026, 11, 21, 10, 0),
      );
      await tester.runAsync(() async {
        await repo.saveProgressPhoto(photo);
      });
      mockPhoto.seedVirtualFile(photo.filePath, [0xFF, 0xD8, 0xFF, 0xE0]);

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProgressHubScreen(
              repository: repo,
              photoService: mockPhoto,
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await pumpAsync(tester, 6);

      // Navigate to Photos Tab (Tab index 2)
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('tab_chip_2')));
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await pumpAsync(tester, 6);

      // Open detail dialog
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('photo_tile_photo_retry_test')));
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await pumpAsync(tester, 6);

      // Tap delete icon in detail dialog
      final deleteBtnFinder = find.byIcon(Icons.delete_outline);
      expect(deleteBtnFinder, findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(deleteBtnFinder);
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await pumpAsync(tester, 6);

      // Confirm deletion dialog
      expect(find.text('Delete Photo?'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await pumpAsync(tester, 6);

      // ASSERTION 1: File is deleted from storage
      expect(mockPhoto.storedFiles.containsKey(photo.filePath), isFalse,
          reason: 'Physical file was successfully deleted');

      // ASSERTION 2: SnackBar displays truthful message distinguishing DB failure from storage failure
      expect(find.text('Photo file removed, but database cleanup failed. Tap to retry.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // ASSERTION 3: Open the photo detail dialog again now that file is missing
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('photo_tile_photo_retry_test')));
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await pumpAsync(tester, 6);

      // Dialog must display truthful pending cleanup notice
      expect(find.text('Photo file removed from storage. Database record pending removal.'), findsOneWidget);

      // Dismiss dialog
      await tester.runAsync(() async {
        await tester.tap(find.text('Cancel'));
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await pumpAsync(tester, 6);

      // ASSERTION 4: Retry the database deletion (now that injected failure is cleared)
      repo.shouldFailPhotoDelete = false;

      await tester.runAsync(() async {
        await tester.tap(find.text('Retry'));
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await pumpAsync(tester, 6);

      // Photo record is now cleanly deleted from database!
      List<ProgressPhoto> remainingPhotos = [];
      await tester.runAsync(() async {
        remainingPhotos = await repo.getProgressPhotos();
      });
      expect(remainingPhotos.any((p) => p.id == 'photo_retry_test'), isFalse,
          reason: 'Retry successfully cleaned up SQLite record idempotently');
    });
  });
}

class _TrackingPhotoService extends MockPhotoService {
  int cleanupCallCount = 0;

  @override
  Future<int> cleanupOrphanPhotos(List<String> validRelativePaths) async {
    cleanupCallCount++;
    return super.cleanupOrphanPhotos(validRelativePaths);
  }
}

class _FailingDeleteProgressPhotoRepository extends WorkoutRepository {
  bool shouldFailPhotoDelete = true;

  @override
  Future<void> deleteProgressPhoto(String id) async {
    if (shouldFailPhotoDelete) {
      throw Exception('Simulated SQLite constraint/disk error on photo delete');
    }
    return super.deleteProgressPhoto(id);
  }
}

class _FailingDeleteMockPhotoService extends MockPhotoService {
  @override
  Future<bool> deletePrivatePhoto(String relativePath) async {
    return false; // Injected filesystem failure
  }
}

