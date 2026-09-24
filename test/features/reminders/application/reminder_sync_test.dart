import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/reminders/application/reminder_sync.dart';
import 'package:lapse/features/reminders/application/reminder_sync_result.dart';
import 'package:lapse/features/reminders/data/memory_reminder_plan_store.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:lapse/features/reminders/domain/reminder_id.dart';
import 'package:lapse/features/reminders/domain/reminder_planner.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
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

  late FakeNotificationGateway gateway;
  late MemoryReminderPlanStore store;

  setUp(() {
    gateway = FakeNotificationGateway();
    store = MemoryReminderPlanStore();
  });

  ReminderSync syncWith({
    FakeNotificationGateway? using,
    TestClock? clock,
  }) => ReminderSync(
    gateway: using ?? gateway,
    planner: const ReminderPlanner(),
    planStore: store,
    clock: clock?.call,
  );

  Future<ReminderSyncResult> run(
    List<Subscription> items, {
    ReminderSync? sync,
  }) => (sync ?? syncWith()).sync(
    subscriptions: items,
    reminderMinutes: 9 * 60,
    now: now,
  );

  List<String> writes(FakeNotificationGateway g) => [
    for (final call in g.calls)
      if (call == 'schedule' || call == 'cancel' || call == 'cancelAll') call,
  ];

  Set<int> idsOf(String subscriptionId) => {
    for (final entry in gateway.scheduled.values)
      if (entry.$1.subscriptionId == subscriptionId) entry.$1.id,
  };

  test('first sync schedules the plan without clearing anything', () async {
    final result = await run(subscriptions);

    expect(gateway.cancelAllCount, 0);
    expect(gateway.cancelled, isEmpty);
    expect(writes(gateway), everyElement('schedule'));
    expect(result.scheduled, 5);
    expect(result.exact, isTrue);
    expect(result.syncedAt, now);
    expect(
      gateway.scheduledReminders.map((r) => r.fireAt),
      unorderedEquals([
        DateTime(2026, 9, 20, 9),
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 9, 30, 9),
        DateTime(2026, 10, 25, 9),
        DateTime(2026, 10, 31, 9),
      ]),
    );
    expect(gateway.scheduled.values.every((entry) => entry.$2), isTrue);
    expect(store.plan.keys, unorderedEquals(gateway.scheduled.keys));
  });

  test('an identical second sync makes no platform writes', () async {
    await run(subscriptions);
    gateway.calls.clear();

    final result = await run(subscriptions);

    expect(writes(gateway), isEmpty);
    expect(result.scheduled, 5);
  });

  test('a new ReminderSync with the same store is still a no-op', () async {
    await run(subscriptions);
    gateway.calls.clear();

    await run(subscriptions, sync: syncWith());

    expect(writes(gateway), isEmpty);
  });

  test('a changed subscription touches only its own ids', () async {
    await run(subscriptions);
    final before = idsOf('sub-1');
    final others = {...gateway.scheduled}
      ..removeWhere((id, _) => before.contains(id));
    gateway
      ..calls.clear()
      ..cancelled.clear();

    await run([
      subscriptions.first.copyWith(name: 'Spotify Duo'),
      ...subscriptions.skip(1),
    ]);

    expect(gateway.cancelled.toSet(), before);
    expect(
      writes(gateway).where((c) => c == 'schedule'),
      hasLength(before.length),
    );
    expect(gateway.cancelAllCount, 0);
    for (final entry in others.entries) {
      expect(gateway.scheduled[entry.key], entry.value);
    }
    expect(
      gateway.scheduledReminders
          .where((r) => r.subscriptionId == 'sub-1')
          .every((r) => r.title.startsWith('Spotify Duo')),
      isTrue,
    );
  });

  test('a removed subscription cancels only its ids', () async {
    await run(subscriptions);
    final netflix = idsOf('sub-2');
    gateway.calls.clear();

    final result = await run(subscriptions.take(1).toList());

    expect(gateway.cancelled.toSet(), netflix);
    expect(writes(gateway), everyElement('cancel'));
    expect(result.scheduled, 4);
    expect(gateway.scheduled, hasLength(4));
    expect(gateway.cancelAllCount, 0);
    expect(store.plan.keys, unorderedEquals(gateway.scheduled.keys));
  });

  test('switching to inexact alarms reschedules everything', () async {
    await run(subscriptions);
    gateway
      ..exactAllowed = false
      ..calls.clear();

    final result = await run(subscriptions);

    expect(result.exact, isFalse);
    expect(gateway.scheduled.values.any((entry) => entry.$2), isFalse);
    expect(writes(gateway).where((c) => c == 'schedule'), hasLength(5));
  });

  test('uses inexact alarms when exact ones are not allowed', () async {
    final inexact = FakeNotificationGateway(exactAllowed: false);
    final result = await run(subscriptions, sync: syncWith(using: inexact));

    expect(result.exact, isFalse);
    expect(inexact.scheduled.values.any((entry) => entry.$2), isFalse);
  });

  test('skips reminders that are already due when scheduling', () async {
    final clock = TestClock(DateTime(2026, 9, 21, 9));
    final result = await run(subscriptions, sync: syncWith(clock: clock));

    expect(result.scheduled, 4);
    expect(
      gateway.scheduledReminders.map((r) => r.fireAt),
      unorderedEquals([
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 9, 30, 9),
        DateTime(2026, 10, 25, 9),
        DateTime(2026, 10, 31, 9),
      ]),
    );
    expect(result.syncedAt, clock.now);
  });

  test('a failing reminder does not stop the others', () async {
    final throwing = _ThrowingGateway();
    final result = await run(subscriptions, sync: syncWith(using: throwing));

    expect(result.scheduled, 4);
    expect(throwing.scheduled, hasLength(4));
    expect(store.plan, hasLength(4));

    throwing.calls.clear();
    await run(subscriptions, sync: syncWith(using: throwing));
    expect(writes(throwing), isEmpty);
  });

  test('no subscriptions cancels the old reminders one by one', () async {
    await run(subscriptions);
    final old = gateway.scheduled.keys.toSet();

    final result = await run(const []);

    expect(gateway.cancelAllCount, 0);
    expect(gateway.cancelled.toSet(), old);
    expect(gateway.scheduled, isEmpty);
    expect(store.plan, isEmpty);
    expect(
      result,
      ReminderSyncResult(scheduled: 0, exact: true, syncedAt: now),
    );
  });

  group('reconciliation', () {
    test('reschedules everything when the device lost its alarms', () async {
      await run(subscriptions);
      final expected = {...gateway.scheduled};
      gateway.scheduled.clear();
      gateway.calls.clear();

      final result = await run(subscriptions);

      expect(result.scheduled, 5);
      expect(gateway.scheduled, expected);
      expect(writes(gateway), everyElement('schedule'));
      expect(gateway.cancelled, isEmpty);
    });

    test('schedules only the missing ids', () async {
      await run(subscriptions);
      final lost = idsOf('sub-2');
      gateway
        ..scheduled.removeWhere((id, _) => lost.contains(id))
        ..calls.clear();

      await run(subscriptions);

      expect(writes(gateway), List.filled(lost.length, 'schedule'));
      expect(idsOf('sub-2'), lost);
    });

    test('cancels pending ids that are not in the plan', () async {
      await run(subscriptions);
      final stray = subscriptions.first.copyWith(id: 'stray');
      await gateway.schedule(
        const ReminderPlanner()
            .planFor(stray, reminderMinutes: 540, now: now)
            .first,
        exact: true,
      );
      final strayId = reminderId('stray', CalendarDate(2026, 9, 24));
      gateway.calls.clear();

      await run(subscriptions);

      expect(gateway.cancelled, [strayId]);
      expect(writes(gateway), ['cancel']);
      expect(gateway.scheduled.containsKey(strayId), isFalse);
    });

    test('an empty store adopts pending reminders without cancels', () async {
      await run(subscriptions);
      await store.clear();
      gateway
        ..calls.clear()
        ..cancelled.clear();

      await run(subscriptions);

      expect(gateway.cancelled, isEmpty);
      expect(writes(gateway), everyElement('schedule'));
      expect(store.plan, hasLength(5));

      gateway.calls.clear();
      await run(subscriptions);
      expect(writes(gateway), isEmpty);
    });
  });

  test('forgetPlan clears the stored plan', () async {
    final sync = syncWith();
    await run(subscriptions, sync: sync);
    expect(store.plan, isNotEmpty);

    await sync.forgetPlan();

    expect(store.plan, isEmpty);
  });
}
