import 'package:lapse/features/reminders/data/notification_gateway.dart';
import 'package:lapse/features/reminders/data/notification_launch.dart';
import 'package:lapse/features/reminders/data/notification_tap.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';

class FakeNotificationGateway implements NotificationGateway {
  FakeNotificationGateway({
    this.permissionResult = ReminderPermission.granted,
    this.requestResult = ReminderPermission.granted,
    this.exactAllowed = true,
    this.launch,
  });

  ReminderPermission permissionResult;
  ReminderPermission requestResult;
  bool exactAllowed;
  NotificationLaunch? launch;

  final Map<int, (PlannedReminder, bool exact)> scheduled = {};
  final List<PlannedReminder> shown = [];
  final List<int> cancelled = [];
  final List<String> calls = [];
  int cancelAllCount = 0;
  int initializeCount = 0;
  int permissionRequests = 0;
  int exactAlarmRequests = 0;
  void Function(NotificationTap tap)? onTap;

  bool get isInitialized => onTap != null;

  List<PlannedReminder> get scheduledReminders => [
    for (final entry in scheduled.values) entry.$1,
  ];

  void simulateTap(NotificationTap tap) {
    final handler = onTap;
    if (handler == null) {
      throw StateError('FakeNotificationGateway was not initialized');
    }
    handler(tap);
  }

  @override
  Future<void> initialize({
    required void Function(NotificationTap tap) onTap,
  }) async {
    calls.add('initialize');
    initializeCount++;
    this.onTap = onTap;
  }

  @override
  Future<NotificationLaunch?> launchDetails() async {
    calls.add('launchDetails');
    return launch;
  }

  @override
  Future<ReminderPermission> permission() async {
    calls.add('permission');
    return permissionResult;
  }

  @override
  Future<ReminderPermission> requestPermission() async {
    calls.add('requestPermission');
    permissionRequests++;
    permissionResult = requestResult;
    return requestResult;
  }

  @override
  Future<bool> canScheduleExact() async {
    calls.add('canScheduleExact');
    return exactAllowed;
  }

  @override
  Future<void> requestExactAlarms() async {
    calls.add('requestExactAlarms');
    exactAlarmRequests++;
  }

  @override
  Future<void> schedule(PlannedReminder reminder, {required bool exact}) async {
    calls.add('schedule');
    scheduled[reminder.id] = (reminder, exact);
  }

  @override
  Future<void> showNow(PlannedReminder reminder) async {
    calls.add('showNow');
    shown.add(reminder);
  }

  @override
  Future<void> cancel(int id) async {
    calls.add('cancel');
    cancelled.add(id);
    scheduled.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    calls.add('cancelAll');
    cancelAllCount++;
    scheduled.clear();
  }

  @override
  Future<List<int>> pendingIds() async {
    calls.add('pendingIds');
    return scheduled.keys.toList();
  }
}
