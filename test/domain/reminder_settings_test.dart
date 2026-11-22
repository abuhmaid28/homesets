import 'package:flutter_test/flutter_test.dart';
import 'package:homesets/data/database/database_helper.dart';
import 'package:homesets/data/repositories/workout_repository.dart';
import 'package:homesets/domain/models/reminder_settings.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setCustomFactory(databaseFactoryFfi);
  });

  group('ReminderSettings & Repository Tests (WP16)', () {
    test('ReminderSettings serialization and defaults', () {
      final defaultSettings = ReminderSettings(updatedAt: DateTime(2026, 11, 21));
      expect(defaultSettings.isEnabled, isFalse);
      expect(defaultSettings.hour, equals(15));
      expect(defaultSettings.minute, equals(30));

      final map = defaultSettings.toMap();
      expect(map['is_enabled'], equals(0));
      expect(map['hour'], equals(15));
      expect(map['minute'], equals(30));

      final roundtrip = ReminderSettings.fromMap(map);
      expect(roundtrip.isEnabled, isFalse);
      expect(roundtrip.hour, equals(15));
      expect(roundtrip.minute, equals(30));
    });

    test('WorkoutRepository saves and retrieves reminder settings', () async {
      final repo = WorkoutRepository();

      // Default when empty
      final initial = await repo.getReminderSettings();
      expect(initial.isEnabled, isFalse);
      expect(initial.hour, equals(15));
      expect(initial.minute, equals(30));

      // Save updated settings
      final updated = initial.copyWith(
        isEnabled: true,
        hour: 18,
        minute: 45,
        updatedAt: DateTime.now(),
      );
      await repo.saveReminderSettings(updated);

      final fetched = await repo.getReminderSettings();
      expect(fetched.isEnabled, isTrue);
      expect(fetched.hour, equals(18));
      expect(fetched.minute, equals(45));
    });
  });
}
