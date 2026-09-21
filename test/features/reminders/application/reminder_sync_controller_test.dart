import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/application/reminder_sync_controller.dart';
import 'package:lapse/features/reminders/application/reminder_sync_result.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';

import '../../../helpers/fake_notification_gateway.dart';
import '../../../helpers/subscription_fixtures.dart';
import 'reminder_test_support.dart';

void main() {
  const settle = ReminderSyncController.debounce;

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
    final container = h.container();
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

    expect(h.gateway.cancelAllCount, 1);
    expect(h.gateway.scheduled, hasLength(2));
    expect(
      container.read(reminderSyncProvider),
      ReminderSyncResult(
        scheduled: 2,
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
    expect(h.gateway.cancelAllCount, 1);

    for (var i = 2; i <= 4; i++) {
      await h.repository.upsert(
        subscriptionFixture(
          id: 'sub-$i',
          nextBillingDate: CalendarDate(2026, 10, i),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(h.gateway.cancelAllCount, 1);

    await tester.pump(settle);
    await tester.pump();

    expect(h.gateway.cancelAllCount, 2);
    expect(h.gateway.scheduled, hasLength(8));
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
    expect(h.gateway.cancelAllCount, 2);
  });

  testWidgets('does nothing without permission and syncs once granted', (
    tester,
  ) async {
    final h = harness(permission: ReminderPermission.denied);
    final container = start(h);
    await tester.pump(settle);
    await tester.pump();

    expect(h.gateway.cancelAllCount, 0);
    expect(h.gateway.scheduled, isEmpty);
    expect(container.read(reminderSyncProvider), isNull);

    h.gateway.permissionResult = ReminderPermission.granted;
    await container.read(notificationPermissionProvider.notifier).refresh();
    await tester.pump(settle);
    await tester.pump();

    expect(h.gateway.cancelAllCount, 1);
    expect(h.gateway.scheduled, hasLength(2));
  });

  testWidgets('granting through request syncs right away', (tester) async {
    final h = harness(permission: ReminderPermission.denied);
    final container = start(h);
    await tester.pump(settle);

    await container.read(notificationPermissionProvider.notifier).request();
    await tester.pump();

    expect(h.gateway.cancelAllCount, 1);
    expect(h.gateway.scheduled, hasLength(2));

    await tester.pump(settle);
    expect(h.gateway.cancelAllCount, 1);
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

    expect(h.gateway.cancelAllCount, 2);
    expect(
      h.gateway.scheduledReminders.map((r) => r.fireAt),
      unorderedEquals([
        DateTime(2026, 9, 24, 20, 30),
        DateTime(2026, 9, 30, 20, 30),
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

    expect(result?.scheduled, 2);
    expect(h.gateway.cancelAllCount, 1);
    expect(
      await container.read(pendingReminderIdsProvider.future),
      hasLength(2),
    );

    await tester.pump(settle);
    expect(h.gateway.cancelAllCount, 1);
  });

  testWidgets('syncNow without permission returns null', (tester) async {
    final h = harness(permission: ReminderPermission.denied);
    final container = start(h);

    final result = await container
        .read(reminderSyncProvider.notifier)
        .syncNow();

    expect(result, isNull);
    expect(h.gateway.cancelAllCount, 0);
    await tester.pump(settle);
  });

  testWidgets('planned reminders follow the subscriptions', (tester) async {
    final h = harness();
    final container = h.container();
    addTearDown(container.dispose);
    container.listen(plannedRemindersProvider, (_, _) {});
    await tester.pump();

    final planned = container.read(plannedRemindersProvider).requireValue;
    expect(planned, hasLength(2));
    expect(planned.first.fireAt, DateTime(2026, 9, 24, 9));
    await tester.pump(settle);
  });
}
