import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/application/reminder_sync_controller.dart';
import 'package:lapse/features/reminders/application/reminder_sync_result.dart';
import 'package:lapse/features/reminders/data/memory_reminder_plan_store.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/data/reminder_plan_store_provider.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';

import '../../../helpers/fake_notification_gateway.dart';
import '../../../helpers/subscription_fixtures.dart';
import 'reminder_test_support.dart';

void main() {
  const settle = ReminderSyncController.debounce;
  late MemoryReminderPlanStore store;

  setUp(() => store = MemoryReminderPlanStore());

  int syncs(ReminderHarness h) =>
      h.gateway.calls.where((c) => c == 'canScheduleExact').length;

  int schedules(ReminderHarness h) =>
      h.gateway.calls.where((c) => c == 'schedule').length;

  ReminderHarness harness({
    ReminderPermission permission = ReminderPermission.granted,
  }) {
    final result = ReminderHarness(
      gateway: FakeNotificationGateway(permissionResult: permission),
    );
    result.repository.seed([
      subscriptionFixture(nextBillingDate: CalendarDate(2026, 10, 1)),
    ]);
    return result;
  }

  ProviderContainer start(ReminderHarness h) {
    final container = h.container([
      reminderPlanStoreProvider.overrideWithValue(store),
    ]);
    addTearDown(container.dispose);
    container.listen(reminderSyncProvider, (_, _) {});
    return container;
  }

  testWidgets('runs one sync after start and stores the result', (
    tester,
  ) async {
    final h = harness();
    final container = start(h);

    await tester.pump(settle);
    await tester.pump();

    expect(syncs(h), 1);
    expect(h.gateway.scheduled, hasLength(4));
    expect(
      container.read(reminderSyncProvider),
      ReminderSyncResult(
        scheduled: 4,
        exact: true,
        syncedAt: DateTime(2026, 9, 19, 10),
      ),
    );
  });

  testWidgets('quick subscription changes are debounced into one sync', (
    tester,
  ) async {
    final h = harness();
    start(h);
    await tester.pump(settle);
    await tester.pump();
    expect(syncs(h), 1);

    for (var i = 2; i <= 4; i++) {
      await h.repository.upsert(
        subscriptionFixture(
          id: 'sub-$i',
          nextBillingDate: CalendarDate(2026, 10, i),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(syncs(h), 1);

    await tester.pump(settle);
    await tester.pump();

    expect(syncs(h), 2);
    expect(h.gateway.scheduled, hasLength(16));
  });

  testWidgets('deleting a subscription removes its reminders', (
    tester,
  ) async {
    final h = harness();
    start(h);
    await tester.pump(settle);
    await tester.pump();

    await h.repository.delete('sub-1');
    await tester.pump(settle);
    await tester.pump();

    expect(h.gateway.scheduled, isEmpty);
    expect(syncs(h), 2);
  });

  testWidgets('does nothing without permission and syncs once granted', (
    tester,
  ) async {
    final h = harness(permission: ReminderPermission.denied);
    final container = start(h);
    await tester.pump(settle);
    await tester.pump();

    expect(syncs(h), 0);
    expect(h.gateway.scheduled, isEmpty);
    expect(container.read(reminderSyncProvider), isNull);

    h.gateway.permissionResult = ReminderPermission.granted;
    await container.read(notificationPermissionProvider.notifier).refresh();
    await tester.pump(settle);
    await tester.pump();

    expect(syncs(h), 1);
    expect(h.gateway.scheduled, hasLength(4));
  });

  testWidgets('granting through request syncs right away', (tester) async {
    final h = harness(permission: ReminderPermission.denied);
    final container = start(h);
    await tester.pump(settle);

    await container.read(notificationPermissionProvider.notifier).request();
    await tester.pump();

    expect(syncs(h), 1);
    expect(h.gateway.scheduled, hasLength(4));

    await tester.pump(settle);
    expect(syncs(h), 1);
  });

  testWidgets('changing the reminder time re-syncs', (tester) async {
    final h = harness();
    final container = start(h);
    await tester.pump(settle);
    await tester.pump();

    await container
        .read(settingsProvider.notifier)
        .update((settings) => settings.copyWith(reminderMinutes: 20 * 60 + 30));
    await tester.pump(settle);
    await tester.pump();

    expect(syncs(h), 2);
    expect(
      h.gateway.scheduledReminders.map((r) => r.fireAt),
      unorderedEquals([
        DateTime(2026, 9, 24, 20, 30),
        DateTime(2026, 9, 30, 20, 30),
        DateTime(2026, 10, 25, 20, 30),
        DateTime(2026, 10, 31, 20, 30),
      ]),
    );
  });

  testWidgets('syncNow runs immediately and refreshes pending ids', (
    tester,
  ) async {
    final h = harness();
    final container = start(h);
    expect(await container.read(pendingReminderIdsProvider.future), isEmpty);

    final result = await container
        .read(reminderSyncProvider.notifier)
        .syncNow();
    await tester.pump();

    expect(result?.scheduled, 4);
    expect(syncs(h), 1);
    expect(
      await container.read(pendingReminderIdsProvider.future),
      hasLength(4),
    );

    await tester.pump(settle);
    expect(syncs(h), 1);
  });

  testWidgets('a repeated sync keeps the stored plan and reschedules nothing', (
    tester,
  ) async {
    final h = harness();
    final container = start(h);
    await tester.pump(settle);
    await tester.pump();
    expect(schedules(h), 4);
    expect(store.plan, hasLength(4));

    await container.read(reminderSyncProvider.notifier).syncNow();

    expect(syncs(h), 2);
    expect(schedules(h), 4);
    expect(h.gateway.cancelled, isEmpty);
    expect(h.gateway.cancelAllCount, 0);
  });

  testWidgets('losing permission forgets the plan so a grant reschedules', (
    tester,
  ) async {
    final h = harness();
    final container = start(h);
    await tester.pump(settle);
    await tester.pump();
    expect(store.plan, hasLength(4));

    h.gateway
      ..permissionResult = ReminderPermission.denied
      ..scheduled.clear();
    await container.read(notificationPermissionProvider.notifier).refresh();
    await container.read(reminderSyncProvider.notifier).syncNow();
    expect(store.plan, isEmpty);

    h.gateway.permissionResult = ReminderPermission.granted;
    await container.read(notificationPermissionProvider.notifier).refresh();
    await tester.pump();

    expect(schedules(h), 8);
    expect(h.gateway.scheduled, hasLength(4));
    expect(store.plan, hasLength(4));
    await tester.pump(settle);
  });

  testWidgets('syncNow without permission returns null', (tester) async {
    final h = harness(permission: ReminderPermission.denied);
    final container = start(h);

    final result = await container
        .read(reminderSyncProvider.notifier)
        .syncNow();

    expect(result, isNull);
    expect(syncs(h), 0);
    await tester.pump(settle);
  });

  testWidgets('planned reminders follow the subscriptions', (tester) async {
    final h = harness();
    final container = h.container();
    addTearDown(container.dispose);
    container.listen(plannedRemindersProvider, (_, _) {});
    await tester.pump();

    final planned = container.read(plannedRemindersProvider).requireValue;
    expect(planned, hasLength(4));
    expect(planned.first.fireAt, DateTime(2026, 9, 24, 9));
    await tester.pump(settle);
  });
}
