import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/reminders/data/notification_action_ids.dart';
import 'package:lapse/features/reminders/data/notification_channels.dart';
import 'package:lapse/features/reminders/data/notification_details_builder.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:lapse/features/reminders/domain/reminder_kind.dart';

const _body = "You'll be charged Rs 649 on Sat, 19 Sep. Tap to cancel.";

PlannedReminder _reminder({bool hasCancelLink = true}) => PlannedReminder(
  id: 42,
  subscriptionId: 'netflix',
  fireAt: DateTime(2026, 9, 18, 9),
  title: 'Netflix trial ends tomorrow',
  body: _body,
  kind: ReminderKind.trialEnding,
  hasCancelLink: hasCancelLink,
);

void main() {
  group('reminderNotificationDetails', () {
    late AndroidNotificationDetails android;

    setUp(() {
      android = reminderNotificationDetails(_reminder()).android!;
    });

    test('uses the renewal reminders channel', () {
      expect(android.channelId, 'renewal_reminders');
      expect(android.channelId, NotificationChannels.reminders);
      expect(android.channelName, 'Renewal reminders');
      expect(
        android.channelDescription,
        'Heads-up before a subscription or free trial charges you',
      );
    });

    test('is high importance and high priority', () {
      expect(android.importance, Importance.high);
      expect(android.priority, Priority.high);
    });

    test('shows the full body as big text with the title', () {
      final style = android.styleInformation;
      expect(style, isA<BigTextStyleInformation>());
      final bigText = style! as BigTextStyleInformation;
      expect(bigText.bigText, _body);
      expect(bigText.contentTitle, 'Netflix trial ends tomorrow');
    });

    test('uses the status-bar icon, brand colour, category and ticker', () {
      expect(android.icon, 'ic_stat_lapse');
      expect(android.color, const Color(0xFF4F46E5));
      expect(android.color, notificationAccentColor);
      expect(android.category, AndroidNotificationCategory.reminder);
      expect(android.ticker, 'Netflix trial ends tomorrow');
    });

    test('with a cancel link offers Cancel now then Snooze', () {
      final actions = android.actions!;
      expect(actions.map((a) => a.id), [
        NotificationActionIds.cancelNow,
        NotificationActionIds.snooze,
      ]);
      final cancel = actions.first;
      expect(cancel.title, 'Cancel now ↗');
      expect(cancel.showsUserInterface, isTrue);
      expect(cancel.cancelNotification, isTrue);
      final snooze = actions.last;
      expect(snooze.title, 'Snooze 1d');
      expect(snooze.showsUserInterface, isFalse);
      expect(snooze.cancelNotification, isTrue);
    });

    test('without a cancel link offers only Snooze', () {
      final actions = reminderNotificationDetails(
        _reminder(hasCancelLink: false),
      ).android!.actions!;
      expect(actions, hasLength(1));
      expect(actions.single.id, NotificationActionIds.snooze);
      expect(actions.single.showsUserInterface, isFalse);
      expect(actions.single.cancelNotification, isTrue);
    });
  });
}
