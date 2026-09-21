import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/reminders/data/notification_launch.dart';
import 'package:lapse/features/reminders/data/notification_tap.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:lapse/features/reminders/domain/reminder_kind.dart';

import '../../../helpers/fake_notification_gateway.dart';

PlannedReminder _reminder(int id) => PlannedReminder(
  id: id,
  subscriptionId: 'sub-$id',
  fireAt: DateTime(2026, 9, 20, 9),
  title: 'Title $id',
  body: 'Body $id',
  kind: ReminderKind.renewal,
  hasCancelLink: false,
);

void main() {
  test('records scheduled reminders with their exactness', () async {
    final gateway = FakeNotificationGateway();

    await gateway.schedule(_reminder(1), exact: true);
    await gateway.schedule(_reminder(2), exact: false);

    expect(gateway.scheduled.keys, [1, 2]);
    expect(gateway.scheduled[1]!.$2, isTrue);
    expect(gateway.scheduled[2]!.$2, isFalse);
    expect(gateway.scheduledReminders, [_reminder(1), _reminder(2)]);
    expect(await gateway.pendingIds(), [1, 2]);
  });

  test('cancel and cancelAll remove pending reminders', () async {
    final gateway = FakeNotificationGateway();
    await gateway.schedule(_reminder(1), exact: true);
    await gateway.schedule(_reminder(2), exact: true);

    await gateway.cancel(1);
    expect(gateway.cancelled, [1]);
    expect(await gateway.pendingIds(), [2]);

    await gateway.cancelAll();
    expect(gateway.cancelAllCount, 1);
    expect(await gateway.pendingIds(), isEmpty);
  });

  test('showNow records shown reminders', () async {
    final gateway = FakeNotificationGateway();

    await gateway.showNow(_reminder(4));

    expect(gateway.shown, [_reminder(4)]);
    expect(gateway.scheduled, isEmpty);
  });

  test('permissions, exact alarms and launch are configurable', () async {
    const launch = NotificationLaunch(
      NotificationTap(subscriptionId: 'a', action: NotificationAction.open),
    );
    final gateway = FakeNotificationGateway(
      permissionResult: ReminderPermission.denied,
      exactAllowed: false,
      launch: launch,
    );

    expect(await gateway.permission(), ReminderPermission.denied);
    expect(await gateway.requestPermission(), ReminderPermission.granted);
    expect(await gateway.permission(), ReminderPermission.granted);
    expect(gateway.permissionRequests, 1);
    expect(await gateway.canScheduleExact(), isFalse);
    await gateway.requestExactAlarms();
    expect(gateway.exactAlarmRequests, 1);
    expect(await gateway.launchDetails(), launch);
  });

  test('simulateTap calls the stored onTap', () async {
    final gateway = FakeNotificationGateway();
    final taps = <NotificationTap>[];
    const tap = NotificationTap(
      subscriptionId: 'sub-1',
      action: NotificationAction.snooze,
    );

    expect(() => gateway.simulateTap(tap), throwsStateError);
    await gateway.initialize(onTap: taps.add);
    gateway.simulateTap(tap);

    expect(gateway.isInitialized, isTrue);
    expect(gateway.initializeCount, 1);
    expect(taps, [tap]);
  });

  test('keeps a call log in order', () async {
    final gateway = FakeNotificationGateway();

    await gateway.cancelAll();
    await gateway.schedule(_reminder(1), exact: true);

    expect(gateway.calls, ['cancelAll', 'schedule']);
  });
}
