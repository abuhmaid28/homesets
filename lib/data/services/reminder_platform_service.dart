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
  Future<bool> setReminderConsent(bool enabled);
  Future<bool> getReminderConsent();
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

  @override
  Future<bool> setReminderConsent(bool enabled) async {
    try {
      final result = await _channel.invokeMethod<bool>('setReminderConsent', {
        'enabled': enabled,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> getReminderConsent() async {
    try {
      final result = await _channel.invokeMethod<bool>('getReminderConsent');
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
  bool Function(int hour, int minute)? onScheduleDailyReminder;

  bool cancelDailyReminderResult = true;
  Exception? cancelDailyReminderException;
  int cancelDailyReminderCallCount = 0;

  bool isScheduled = false;
  int? scheduledHour;
  int? scheduledMinute;
  String? scheduledTitle;
  String? scheduledBody;

  bool consentEnabled = false;
  int setReminderConsentCallCount = 0;
  bool channelEnabled = true;

  MockReminderPlatformService({
    this.notificationsEnabled = true,
    this.channelEnabled = true,
    this.consentEnabled = false,
  });

  @override
  Future<bool> areNotificationsEnabled() async {
    return notificationsEnabled && channelEnabled;
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
    if (!channelEnabled) {
      return 'channelDisabled';
    }
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
    if (!channelEnabled || !notificationsEnabled) {
      return false;
    }
    if (onScheduleDailyReminder != null) {
      final res = onScheduleDailyReminder!(hour, minute);
      if (!res) {
        return false;
      }
    } else if (!scheduleDailyReminderResult) {
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

  @override
  Future<bool> setReminderConsent(bool enabled) async {
    setReminderConsentCallCount++;
    consentEnabled = enabled;
    return true;
  }

  @override
  Future<bool> getReminderConsent() async {
    return consentEnabled;
  }

  /// Simulates native broadcast receiver execution (WP12, P6-NOTIFY-07, P6-NOTIFY-08).
  /// Enforces fail-closed delivery invariant: returns true ONLY if OS notifications are enabled,
  /// notification channel is active, and explicit in-app consent is verified.
  bool simulateAlarmDelivery() {
    if (!notificationsEnabled || !channelEnabled || !consentEnabled) {
      // Receiver suppresses delivery fail-closed
      if (!consentEnabled) {
        isScheduled = false; // Self-healing cancel
      }
      return false;
    }
    return isScheduled;
  }
}
