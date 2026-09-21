import 'package:flutter/foundation.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';

typedef NextReminder = ({String service, DateTime fireAt});

@immutable
class NotificationHealth {
  const NotificationHealth({
    required this.permission,
    required this.exactAlarms,
    required this.batteryOptimised,
    required this.pendingCount,
    this.next,
  });

  final ReminderPermission permission;
  final bool exactAlarms;
  final bool batteryOptimised;
  final int pendingCount;
  final NextReminder? next;

  bool get notificationsAllowed => permission == ReminderPermission.granted;

  bool get needsAttention =>
      !notificationsAllowed || !exactAlarms || batteryOptimised;

  @override
  bool operator ==(Object other) =>
      other is NotificationHealth &&
      other.permission == permission &&
      other.exactAlarms == exactAlarms &&
      other.batteryOptimised == batteryOptimised &&
      other.pendingCount == pendingCount &&
      other.next == next;

  @override
  int get hashCode => Object.hash(
    permission,
    exactAlarms,
    batteryOptimised,
    pendingCount,
    next,
  );

  @override
  String toString() =>
      'NotificationHealth(${permission.name}, exact $exactAlarms, '
      'battery optimised $batteryOptimised, $pendingCount pending)';
}
