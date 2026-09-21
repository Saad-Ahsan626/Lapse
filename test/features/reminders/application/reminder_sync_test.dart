import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/reminders/application/reminder_sync.dart';
import 'package:lapse/features/reminders/application/reminder_sync_result.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:lapse/features/reminders/domain/reminder_planner.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';

import '../../../helpers/fake_notification_gateway.dart';
import '../../../helpers/subscription_fixtures.dart';
import '../../../helpers/test_clock.dart';

class _ThrowingGateway extends FakeNotificationGateway {
  @override
  Future<void> schedule(PlannedReminder reminder, {required bool exact}) {
    if (reminder.fireAt.day == 24) {
      return Future.error(ArgumentError('past'));
    }
    return super.schedule(reminder, exact: exact);
  }
}

void main() {
  final now = DateTime(2026, 9, 19, 10);
  final subscriptions = [
    subscriptionFixture(nextBillingDate: CalendarDate(2026, 10, 1)),
    subscriptionFixture(
      id: 'sub-2',
      name: 'Netflix',
      isTrial: true,
      nextBillingDate: CalendarDate(2026, 9, 21),
      reminderOffsets: const [1],
    ),
    subscriptionFixture(
      id: 'sub-3',
      status: SubscriptionStatus.cancelled,
    ),
  ];

  test('cancels everything first, then schedules the plan', () async {
    final gateway = FakeNotificationGateway();
    final sync = ReminderSync(
      gateway: gateway,
      planner: const ReminderPlanner(),
    );

    final result = await sync.sync(
      subscriptions: subscriptions,
      reminderMinutes: 9 * 60,
      now: now,
    );

    expect(gateway.calls.first, 'cancelAll');
    expect(gateway.calls[1], 'canScheduleExact');
    expect(gateway.calls.skip(2), everyElement('schedule'));
    expect(result.scheduled, 3);
    expect(result.exact, isTrue);
    expect(result.syncedAt, now);
    expect(
      gateway.scheduledReminders.map((r) => r.fireAt),
      unorderedEquals([
        DateTime(2026, 9, 20, 9),
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 9, 30, 9),
      ]),
    );
    expect(gateway.scheduled.values.every((entry) => entry.$2), isTrue);
  });

  test('removes reminders that are no longer planned', () async {
    final gateway = FakeNotificationGateway();
    final sync = ReminderSync(
      gateway: gateway,
      planner: const ReminderPlanner(),
    );
    await sync.sync(
      subscriptions: subscriptions,
      reminderMinutes: 540,
      now: now,
    );

    final result = await sync.sync(
      subscriptions: subscriptions.take(1).toList(),
      reminderMinutes: 540,
      now: now,
    );

    expect(result.scheduled, 2);
    expect(gateway.scheduled, hasLength(2));
    expect(gateway.cancelAllCount, 2);
  });

  test('uses inexact alarms when exact ones are not allowed', () async {
    final gateway = FakeNotificationGateway(exactAllowed: false);
    final result = await ReminderSync(
      gateway: gateway,
      planner: const ReminderPlanner(),
    ).sync(subscriptions: subscriptions, reminderMinutes: 540, now: now);

    expect(result.exact, isFalse);
    expect(gateway.scheduled.values.any((entry) => entry.$2), isFalse);
  });

  test('skips reminders that are already due when scheduling', () async {
    final gateway = FakeNotificationGateway();
    final clock = TestClock(DateTime(2026, 9, 21, 9));
    final result = await ReminderSync(
      gateway: gateway,
      planner: const ReminderPlanner(),
      clock: clock.call,
    ).sync(subscriptions: subscriptions, reminderMinutes: 540, now: now);

    expect(result.scheduled, 2);
    expect(
      gateway.scheduledReminders.map((r) => r.fireAt),
      unorderedEquals([DateTime(2026, 9, 24, 9), DateTime(2026, 9, 30, 9)]),
    );
    expect(result.syncedAt, clock.now);
  });

  test('a failing reminder does not stop the others', () async {
    final gateway = _ThrowingGateway();
    final result = await ReminderSync(
      gateway: gateway,
      planner: const ReminderPlanner(),
    ).sync(subscriptions: subscriptions, reminderMinutes: 540, now: now);

    expect(result.scheduled, 2);
    expect(gateway.scheduled, hasLength(2));
  });

  test('no subscriptions still clears old reminders', () async {
    final gateway = FakeNotificationGateway();
    final result = await ReminderSync(
      gateway: gateway,
      planner: const ReminderPlanner(),
    ).sync(subscriptions: const [], reminderMinutes: 540, now: now);

    expect(gateway.cancelAllCount, 1);
    expect(
      result,
      ReminderSyncResult(scheduled: 0, exact: true, syncedAt: now),
    );
  });
}
