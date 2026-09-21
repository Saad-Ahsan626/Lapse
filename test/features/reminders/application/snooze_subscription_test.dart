import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/reminders/application/snooze_subscription.dart';
import 'package:lapse/features/reminders/domain/reminder_id.dart';
import 'package:lapse/features/reminders/domain/reminder_kind.dart';
import 'package:lapse/features/reminders/domain/reminder_planner.dart';
import 'package:lapse/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/fake_notification_gateway.dart';
import '../../../helpers/subscription_fixtures.dart';
import '../../../helpers/test_database.dart';

void main() {
  late Database database;
  late SubscriptionRepositoryImpl repository;
  late FakeNotificationGateway gateway;

  setUp(() async {
    database = await openTestDatabase();
    repository = SubscriptionRepositoryImpl(database);
    gateway = FakeNotificationGateway(exactAllowed: false);
  });

  tearDown(() async {
    await repository.dispose();
    await database.close();
  });

  Future<void> snooze(DateTime now, {int? notificationId}) =>
      snoozeSubscription(
        subscriptionId: 'sub-1',
        repository: repository,
        gateway: gateway,
        planner: const ReminderPlanner(),
        reminderMinutes: 540,
        now: now,
        notificationId: notificationId,
      );

  test('stores snoozedUntil and schedules the snoozed reminder', () async {
    await repository.upsert(
      subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 9, 21),
        reminderOffsets: const [2, 1],
      ),
    );
    final now = DateTime(2026, 9, 19, 8);

    await snooze(now, notificationId: 42);

    final stored = await repository.getById('sub-1');
    expect(stored!.snoozedUntil, now.toUtc().add(const Duration(hours: 24)));
    expect(gateway.cancelled, contains(42));
    expect(
      gateway.cancelled,
      contains(reminderId('sub-1', CalendarDate(2026, 9, 19))),
    );
    final scheduled = gateway.scheduledReminders;
    expect(scheduled, hasLength(1));
    expect(scheduled.single.kind, ReminderKind.snoozed);
    expect(scheduled.single.fireAt, DateTime(2026, 9, 20, 8));
    expect(gateway.scheduled.values.single.$2, isFalse);
  });

  test('keeps later reminders of the same subscription', () async {
    await repository.upsert(
      subscriptionFixture(nextBillingDate: CalendarDate(2026, 10, 1)),
    );

    await snooze(DateTime(2026, 9, 19, 10), notificationId: 7);

    final kinds = gateway.scheduledReminders.map((r) => r.kind).toList();
    expect(kinds, hasLength(3));
    expect(kinds.where((k) => k == ReminderKind.snoozed), hasLength(1));
  });

  test('an unknown subscription only dismisses the notification', () async {
    await snooze(DateTime(2026, 9, 19, 10), notificationId: 9);

    expect(gateway.cancelled, [9]);
    expect(gateway.scheduled, isEmpty);
  });
}
