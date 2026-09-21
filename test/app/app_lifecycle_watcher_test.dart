import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/app/app_lifecycle_watcher.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/application/reminder_sync_controller.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

import '../helpers/fake_notification_gateway.dart';
import '../helpers/fake_subscription_repository.dart';
import '../helpers/in_memory_settings_repository.dart';
import '../helpers/subscription_fixtures.dart';
import '../helpers/test_clock.dart';

class _FailingRepository extends FakeSubscriptionRepository {
  int calls = 0;

  @override
  Stream<List<Subscription>> watchAll() => Stream.value(const []);

  @override
  Future<List<Subscription>> getAll() {
    calls++;
    return Future.error(StateError('database unavailable'));
  }
}

void main() {
  late FakeNotificationGateway gateway;
  late String timezone;
  late int timezoneCalls;

  setUp(() {
    gateway = FakeNotificationGateway();
    timezone = 'Asia/Karachi';
    timezoneCalls = 0;
  });

  Future<void> pumpWatcher(
    WidgetTester tester,
    FakeSubscriptionRepository repository,
    TestClock clock,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(clock.call),
          newIdProvider.overrideWithValue(SequentialIds().call),
          settingsRepositoryProvider.overrideWithValue(
            InMemorySettingsRepository(),
          ),
          notificationGatewayProvider.overrideWithValue(gateway),
          configureTimezoneProvider.overrideWithValue(() async {
            timezoneCalls++;
            return timezone;
          }),
        ],
        child: const AppLifecycleWatcher(child: SizedBox()),
      ),
    );
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(ReminderSyncController.debounce);
    await tester.pump(ReminderSyncController.debounce);
    await tester.pump();
  }

  Future<void> backgroundAndResume(WidgetTester tester) async {
    const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ].forEach(tester.binding.handleAppLifecycleStateChanged);
    await tester.pump();
  }

  testWidgets('rolls over after the first frame and again on resume', (
    tester,
  ) async {
    final clock = TestClock(DateTime(2026, 9, 19, 10));
    final repository = FakeSubscriptionRepository()
      ..seed([subscriptionFixture(nextBillingDate: CalendarDate(2026, 9, 10))]);

    await pumpWatcher(tester, repository, clock);

    expect(
      repository.subscriptions['sub-1']!.nextBillingDate,
      CalendarDate(2026, 10, 10),
    );
    expect(repository.charges, hasLength(1));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );
    expect(container.read(todayProvider), CalendarDate(2026, 9, 19));

    clock.advance(const Duration(days: 30));
    await backgroundAndResume(tester);

    expect(
      repository.subscriptions['sub-1']!.nextBillingDate,
      CalendarDate(2026, 11, 10),
    );
    expect(repository.charges, hasLength(2));
    expect(container.read(todayProvider), CalendarDate(2026, 10, 19));
    await settle(tester);
  });

  testWidgets('roll-over failures do not surface', (tester) async {
    final repository = _FailingRepository();
    final clock = TestClock(DateTime(2026, 9, 19, 10));

    await pumpWatcher(tester, repository, clock);
    await backgroundAndResume(tester);

    expect(tester.takeException(), isNull);
    expect(repository.calls, 2);
    expect(find.byType(SizedBox), findsOneWidget);
    await settle(tester);
  });

  testWidgets('starts reminder sync after the first frame', (tester) async {
    final clock = TestClock(DateTime(2026, 9, 19, 10));
    final repository = FakeSubscriptionRepository()
      ..seed([subscriptionFixture(nextBillingDate: CalendarDate(2026, 10, 1))]);

    await pumpWatcher(tester, repository, clock);
    await settle(tester);

    expect(gateway.isInitialized, isFalse);
    expect(gateway.cancelAllCount, 1);
    expect(gateway.scheduled, hasLength(2));
    expect(timezoneCalls, 1);
  });

  testWidgets('resume refreshes the permission', (tester) async {
    gateway.permissionResult = ReminderPermission.denied;
    final clock = TestClock(DateTime(2026, 9, 19, 10));
    final repository = FakeSubscriptionRepository()
      ..seed([subscriptionFixture(nextBillingDate: CalendarDate(2026, 10, 1))]);

    await pumpWatcher(tester, repository, clock);
    await settle(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );
    expect(
      container.read(notificationPermissionProvider).value,
      ReminderPermission.denied,
    );
    expect(gateway.cancelAllCount, 0);

    gateway.permissionResult = ReminderPermission.granted;
    await backgroundAndResume(tester);
    await settle(tester);

    expect(
      container.read(notificationPermissionProvider).value,
      ReminderPermission.granted,
    );
    expect(gateway.cancelAllCount, 1);
    expect(gateway.scheduled, hasLength(2));
  });

  testWidgets('resume re-syncs only when the timezone changed', (
    tester,
  ) async {
    final clock = TestClock(DateTime(2026, 9, 19, 10));
    final repository = FakeSubscriptionRepository()
      ..seed([subscriptionFixture(nextBillingDate: CalendarDate(2026, 10, 1))]);

    await pumpWatcher(tester, repository, clock);
    await settle(tester);
    expect(gateway.cancelAllCount, 1);

    await backgroundAndResume(tester);
    await settle(tester);
    expect(timezoneCalls, 2);
    expect(gateway.cancelAllCount, 1);

    timezone = 'Europe/London';
    await backgroundAndResume(tester);
    await settle(tester);
    expect(timezoneCalls, 3);
    expect(gateway.cancelAllCount, 2);
  });
}
