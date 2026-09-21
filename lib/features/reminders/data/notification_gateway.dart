import 'package:lapse/features/reminders/data/notification_launch.dart';
import 'package:lapse/features/reminders/data/notification_tap.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';

abstract interface class NotificationGateway {
  Future<void> initialize({
    required void Function(NotificationTap tap) onTap,
  });

  Future<NotificationLaunch?> launchDetails();

  Future<ReminderPermission> permission();

  Future<ReminderPermission> requestPermission();

  Future<bool> canScheduleExact();

  Future<void> requestExactAlarms();

  Future<void> schedule(PlannedReminder reminder, {required bool exact});

  Future<void> showNow(PlannedReminder reminder);

  Future<void> cancel(int id);

  Future<void> cancelAll();

  Future<List<int>> pendingIds();
}
