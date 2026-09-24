import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';

import '../../../helpers/fake_notification_gateway.dart';
import 'reminder_test_support.dart';

void main() {
  ProviderContainer start(FakeNotificationGateway gateway) {
    final container = ReminderHarness(gateway: gateway).container();
    addTearDown(container.dispose);
    return container;
  }

  test('loads the current permission', () async {
    final gateway = FakeNotificationGateway(
      permissionResult: ReminderPermission.denied,
    );
    final container = start(gateway);

    expect(
      await container.read(notificationPermissionProvider.future),
      ReminderPermission.denied,
    );
  });

  test('refresh picks up a change made in system settings', () async {
    final gateway = FakeNotificationGateway(
      permissionResult: ReminderPermission.denied,
      exactAllowed: false,
    );
    final container = start(gateway);
    await container.read(notificationPermissionProvider.future);
    expect(await container.read(exactAlarmsAllowedProvider.future), isFalse);

    gateway
      ..permissionResult = ReminderPermission.granted
      ..exactAllowed = true;
    await container.read(notificationPermissionProvider.notifier).refresh();

    expect(
      container.read(notificationPermissionProvider).value,
      ReminderPermission.granted,
    );
    expect(await container.read(exactAlarmsAllowedProvider.future), isTrue);
  });

  test('request asks the system and stores the answer', () async {
    final gateway = FakeNotificationGateway(
      permissionResult: ReminderPermission.denied,
      requestResult: ReminderPermission.permanentlyDenied,
    );
    final container = start(gateway);
    await container.read(notificationPermissionProvider.future);

    final result = await container
        .read(notificationPermissionProvider.notifier)
        .request();

    expect(result, ReminderPermission.permanentlyDenied);
    expect(gateway.permissionRequests, 1);
    expect(
      container.read(notificationPermissionProvider).value,
      ReminderPermission.permanentlyDenied,
    );
    expect(gateway.cancelAllCount, 0);
  });

  test('a granted request triggers a sync', () async {
    final gateway = FakeNotificationGateway(
      permissionResult: ReminderPermission.denied,
    );
    final container = start(gateway);
    await container.read(notificationPermissionProvider.future);
    container.listen(reminderSyncProvider, (_, _) {});

    final result = await container
        .read(notificationPermissionProvider.notifier)
        .request();
    await pumpEventQueue();

    expect(result, ReminderPermission.granted);
    expect(gateway.calls, contains('pendingIds'));
    expect(gateway.cancelAllCount, 0);
    expect(container.read(reminderSyncProvider), isNotNull);
  });
}
