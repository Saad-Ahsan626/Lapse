import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/platform/system_bridge_provider.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/domain/planned_reminder.dart';
import 'package:lapse/features/reminders/domain/reminder_kind.dart';
import 'package:lapse/features/settings/presentation/models/notification_health.dart';
import 'package:lapse/features/settings/presentation/providers/notification_health_provider.dart';

import '../../../../helpers/fake_notification_gateway.dart';
import '../../../../helpers/fake_system_bridge.dart';
import '../../../../helpers/subscription_fixtures.dart';
import '../../../reminders/application/reminder_test_support.dart';

PlannedReminder _planned(int id, String subscriptionId, DateTime fireAt) =>
    PlannedReminder(
      id: id,
      subscriptionId: subscriptionId,
      fireAt: fireAt,
      title: 'Title $id',
      body: 'Body',
      kind: ReminderKind.renewal,
      hasCancelLink: false,
    );

void main() {
  group('NotificationHealth.needsAttention', () {
    NotificationHealth health({
      ReminderPermission permission = ReminderPermission.granted,
      bool exact = true,
      bool optimised = false,
    }) => NotificationHealth(
      permission: permission,
      exactAlarms: exact,
      batteryOptimised: optimised,
      pendingCount: 0,
    );

    test('is false only when everything is fine', () {
      expect(health().needsAttention, isFalse);
      expect(
        health(permission: ReminderPermission.denied).needsAttention,
        isTrue,
      );
      expect(
        health(permission: ReminderPermission.unknown).needsAttention,
        isTrue,
      );
      expect(health(exact: false).needsAttention, isTrue);
      expect(health(optimised: true).needsAttention, isTrue);
    });
  });

  test('nextPendingReminder picks the earliest pending one', () {
    final next = nextPendingReminder(
      planned: [
        _planned(1, 'sub-1', DateTime(2026, 9, 30, 9)),
        _planned(2, 'sub-1', DateTime(2026, 9, 24, 9)),
        _planned(3, 'gone', DateTime(2026, 9, 20, 9)),
      ],
      pendingIds: const [1, 2, 99],
      subscriptions: [subscriptionFixture()],
    );
    expect(next, (
      service: 'Spotify Premium',
      fireAt: DateTime(2026, 9, 24, 9),
    ));
    expect(
      nextPendingReminder(
        planned: [_planned(3, 'gone', DateTime(2026, 9, 20, 9))],
        pendingIds: const [3],
        subscriptions: const [],
      )?.service,
      'Title 3',
    );
    expect(
      nextPendingReminder(
        planned: const [],
        pendingIds: const [1],
        subscriptions: const [],
      ),
      isNull,
    );
  });

  test('notificationHealthProvider combines gateway and bridge', () async {
    final harness = ReminderHarness(
      gateway: FakeNotificationGateway(exactAllowed: false),
    );
    harness.repository.seed([
      subscriptionFixture(nextBillingDate: CalendarDate(2026, 9, 25)),
    ]);
    final bridge = FakeSystemBridge(ignoringBatteryOptimizations: false);
    final container = harness.container([
      systemBridgeProvider.overrideWithValue(bridge),
    ]);
    addTearDown(container.dispose);

    final health = await container.read(notificationHealthProvider.future);

    expect(health.permission, ReminderPermission.granted);
    expect(health.exactAlarms, isFalse);
    expect(health.batteryOptimised, isTrue);
    expect(health.pendingCount, 0);
    expect(health.needsAttention, isTrue);
  });
}
