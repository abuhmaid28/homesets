import 'package:flutter/services.dart';

/// Platform interface for scheduling local daily reminders (WP17).
abstract class ReminderPlatformService {
  Future<bool> areNotificationsEnabled();
  Future<bool> requestNotificationPermission();
  Future<String> getNotificationPermissionStatus();
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
  Future<bool> requestNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestNotificationPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<String> getNotificationPermissionStatus() async {
    try {
      final result = await _channel.invokeMethod<String>('getNotificationPermissionStatus');
      return result ?? 'notDetermined';
    } on PlatformException {
      return 'notDetermined';
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
  bool requestPermissionResult = true;
  String permissionStatus = 'granted';
  int requestPermissionCallCount = 0;
  bool scheduleDailyReminderResult = true;
  Exception? scheduleDailyReminderException;
  int scheduleDailyReminderCallCount = 0;

  bool cancelDailyReminderResult = true;
  Exception? cancelDailyReminderException;
  int cancelDailyReminderCallCount = 0;

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
  Future<bool> requestNotificationPermission() async {
    requestPermissionCallCount++;
    if (requestPermissionResult) {
      notificationsEnabled = true;
      permissionStatus = 'granted';
    } else {
      notificationsEnabled = false;
      permissionStatus = 'denied';
    }
    return requestPermissionResult;
  }

  @override
  Future<String> getNotificationPermissionStatus() async {
    return permissionStatus;
  }

  @override
  Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    scheduleDailyReminderCallCount++;
    if (scheduleDailyReminderException != null) {
      throw scheduleDailyReminderException!;
    }
    if (!scheduleDailyReminderResult) {
      return false;
    }
    isScheduled = true;
    scheduledHour = hour;
    scheduledMinute = minute;
    scheduledTitle = title;
    scheduledBody = body;
    return true;
  }

  @override
  Future<bool> cancelDailyReminder() async {
    cancelDailyReminderCallCount++;
    if (cancelDailyReminderException != null) {
      throw cancelDailyReminderException!;
    }
    if (!cancelDailyReminderResult) {
      return false;
    }
    isScheduled = false;
    scheduledHour = null;
    scheduledMinute = null;
    scheduledTitle = null;
    scheduledBody = null;
    return true;
  }
}
