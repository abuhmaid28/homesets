import 'package:flutter/services.dart';

/// Platform interface for scheduling local daily reminders (WP17).
abstract class ReminderPlatformService {
  Future<bool> areNotificationsEnabled();
  Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  });
  Future<bool> cancelDailyReminder();
}

/// Native Android implementation using NotificationManager and AlarmManager.
class AndroidReminderPlatformService implements ReminderPlatformService {
  static const MethodChannel _channel = MethodChannel('com.abuhmaid.homesets/reminders');

  const AndroidReminderPlatformService();

  @override
  Future<bool> areNotificationsEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('areNotificationsEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('scheduleDailyReminder', {
        'hour': hour,
        'minute': minute,
        'title': title,
        'body': body,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> cancelDailyReminder() async {
    try {
      final result = await _channel.invokeMethod<bool>('cancelDailyReminder');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}

/// In-memory mock reminder platform service for tests and non-Android environments.
class MockReminderPlatformService implements ReminderPlatformService {
  bool notificationsEnabled;
  bool isScheduled = false;
  int? scheduledHour;
  int? scheduledMinute;
  String? scheduledTitle;
  String? scheduledBody;

  MockReminderPlatformService({this.notificationsEnabled = true});

  @override
  Future<bool> areNotificationsEnabled() async {
    return notificationsEnabled;
  }

  @override
  Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    isScheduled = true;
    scheduledHour = hour;
    scheduledMinute = minute;
    scheduledTitle = title;
    scheduledBody = body;
    return true;
  }

  @override
  Future<bool> cancelDailyReminder() async {
    isScheduled = false;
    scheduledHour = null;
    scheduledMinute = null;
    scheduledTitle = null;
    scheduledBody = null;
    return true;
  }
}
