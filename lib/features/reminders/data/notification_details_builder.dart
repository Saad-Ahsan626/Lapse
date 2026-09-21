import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lapse/features/reminders/data/notification_action_ids.dart';
import 'package:lapse/features/reminders/data/notification_channels.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';

const notificationAccentColor = Color(0xFF4F46E5);
const notificationSmallIcon = 'ic_stat_lapse';

NotificationDetails reminderNotificationDetails(PlannedReminder reminder) {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      NotificationChannels.reminders,
      NotificationChannels.remindersName,
      channelDescription: NotificationChannels.remindersDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: notificationSmallIcon,
      color: notificationAccentColor,
      category: AndroidNotificationCategory.reminder,
      ticker: reminder.title,
      styleInformation: BigTextStyleInformation(
        reminder.body,
        contentTitle: reminder.title,
      ),
      actions: <AndroidNotificationAction>[
        if (reminder.hasCancelLink)
          const AndroidNotificationAction(
            NotificationActionIds.cancelNow,
            'Cancel now ↗',
            showsUserInterface: true,
          ),
        const AndroidNotificationAction(
          NotificationActionIds.snooze,
          'Snooze 1d',
        ),
      ],
    ),
  );
}
