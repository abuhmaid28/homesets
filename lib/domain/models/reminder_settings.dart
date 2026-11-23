/// Domain model for daily workout reminder settings (WP16).
class ReminderSettings {
  final bool isEnabled;
  final int hour;
  final int minute;
  final DateTime updatedAt;
  final bool isPendingReconciliation;

  const ReminderSettings({
    this.isEnabled = false,
    this.hour = 15,
    this.minute = 30,
    required this.updatedAt,
    this.isPendingReconciliation = false,
  });

  Map<String, dynamic> toMap() => {
    'id': 'default',
    'is_enabled': isEnabled ? 1 : 0,
    'hour': hour,
    'minute': minute,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ReminderSettings.fromMap(
    Map<String, dynamic> map, {
    bool isPendingReconciliation = false,
  }) => ReminderSettings(
    isEnabled: (map['is_enabled'] as int? ?? 0) == 1,
    hour: map['hour'] as int? ?? 15,
    minute: map['minute'] as int? ?? 30,
    updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    isPendingReconciliation: isPendingReconciliation,
  );

  ReminderSettings copyWith({
    bool? isEnabled,
    int? hour,
    int? minute,
    DateTime? updatedAt,
    bool? isPendingReconciliation,
  }) => ReminderSettings(
    isEnabled: isEnabled ?? this.isEnabled,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    updatedAt: updatedAt ?? this.updatedAt,
    isPendingReconciliation: isPendingReconciliation ?? this.isPendingReconciliation,
  );
}
