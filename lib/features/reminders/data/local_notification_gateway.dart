import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lapse/features/reminders/data/notification_channels.dart';
import 'package:lapse/features/reminders/data/notification_details_builder.dart';
import 'package:lapse/features/reminders/data/notification_gateway.dart';
import 'package:lapse/features/reminders/data/notification_launch.dart';
import 'package:lapse/features/reminders/data/notification_tap.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway({
    FlutterLocalNotificationsPlugin? plugin,
    DidReceiveBackgroundNotificationResponseCallback? onBackgroundResponse,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _onBackgroundResponse = onBackgroundResponse;

  static const remindersChannel = AndroidNotificationChannel(
    NotificationChannels.reminders,
    NotificationChannels.remindersName,
    description: NotificationChannels.remindersDescription,
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _plugin;
  final DidReceiveBackgroundNotificationResponseCallback? _onBackgroundResponse;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize({
    required void Function(NotificationTap tap) onTap,
  }) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(notificationSmallIcon),
      ),
      onDidReceiveNotificationResponse: (response) {
        final tap = NotificationTap.fromResponse(response);
        if (tap != null) {
          onTap(tap);
        }
      },
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
    );
    await _android?.createNotificationChannel(remindersChannel);
  }

  @override
  Future<NotificationLaunch?> launchDetails() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) {
      return null;
    }
    final response = details.notificationResponse;
    if (response == null) {
      return null;
    }
    final tap = NotificationTap.fromResponse(response);
    return tap == null ? null : NotificationLaunch(tap);
  }

  @override
  Future<ReminderPermission> permission() async {
    final android = _android;
    if (android == null) {
      return ReminderPermission.unknown;
    }
    return _fromEnabled(await android.areNotificationsEnabled());
  }

  @override
  Future<ReminderPermission> requestPermission() async {
    final android = _android;
    if (android == null) {
      return ReminderPermission.unknown;
    }
    final granted = await android.requestNotificationsPermission();
    if (granted == null) {
      return _fromEnabled(await android.areNotificationsEnabled());
    }
    return granted ? ReminderPermission.granted : ReminderPermission.denied;
  }

  @override
  Future<bool> canScheduleExact() async =>
      await _android?.canScheduleExactNotifications() ?? false;

  @override
  Future<void> requestExactAlarms() async {
    await _android?.requestExactAlarmsPermission();
  }

  @override
  Future<void> schedule(PlannedReminder reminder, {required bool exact}) {
    return _plugin.zonedSchedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.local),
      notificationDetails: reminderNotificationDetails(reminder),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: reminder.subscriptionId,
    );
  }

  @override
  Future<void> showNow(PlannedReminder reminder) {
    return _plugin.show(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      notificationDetails: reminderNotificationDetails(reminder),
      payload: reminder.subscriptionId,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<List<int>> pendingIds() async {
    final pending = await _plugin.pendingNotificationRequests();
    return [for (final request in pending) request.id];
  }

  ReminderPermission _fromEnabled(bool? enabled) => switch (enabled) {
    true => ReminderPermission.granted,
    false => ReminderPermission.denied,
    null => ReminderPermission.unknown,
  };
}
