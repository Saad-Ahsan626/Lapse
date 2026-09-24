import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/app/app_lifecycle_watcher.dart';
import 'package:lapse/app/app_ready_controller.dart';
import 'package:lapse/app/router/initial_location_provider.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/application/reminder_sync_controller.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/domain/reminder_kind.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';
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
    TestClock clock, {
    String initialLocation = Routes.home,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue(initialLocation),
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

  int syncs() => gateway.calls.where((c) => c == 'canScheduleExact').length;

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

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(SizedBox)));

  testWidgets('waits for the splash before rolling over or syncing', (
    tester,
  ) async {
    final clock = TestClock(DateTime(2026, 9, 19, 10));
    final repository = FakeSubscriptionRepository()
      ..seed([subscriptionFixture(nextBillingDate: CalendarDate(2026, 9, 10))]);

    await pumpWatcher(
      tester,
      repository,
      clock,
      initialLocation: Routes.splash,
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await backgroundAndResume(tester);
    await settle(tester);

    expect(
      repository.subscriptions['sub-1']!.nextBillingDate,
      CalendarDate(2026, 9, 10),
    );
    expect(repository.charges, isEmpty);
    expect(repository.refreshCount, 0);
    expect(syncs(), 0);
    expect(timezoneCalls, 0);

    final container = containerOf(tester);
    container.read(appReadyProvider.notifier).markReady();
    await tester.pump();
    expect(repository.charges, isEmpty);

    await tester.pump();
    expect(
      repository.subscriptions['sub-1']!.nextBillingDate,
      CalendarDate(2026, 10, 10),
    );
    expect(repository.charges, hasLength(1));
    expect(timezoneCalls, 1);
    expect(syncs(), 0);

    await settle(tester);
    expect(syncs(), 1);
    expect(container.read(reminderSyncProvider), isNotNull);
  });

  testWidgets('a notification cold start starts the work right away', (
    tester,
  ) async {
    final clock = TestClock(DateTime(2026, 9, 19, 10));
    final repository = FakeSubscriptionRepository()
      ..seed([subscriptionFixture(nextBillingDate: CalendarDate(2026, 9, 10))]);

    await pumpWatcher(
      tester,
      repository,
      clock,
      initialLocation: Routes.detail('sub-1'),
    );

    expect(repository.charges, hasLength(1));
    await settle(tester);
    expect(syncs(), 1);
  });

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
    expect(syncs(), 1);
    expect(gateway.scheduled, hasLength(4));
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
    expect(syncs(), 0);

    gateway.permissionResult = ReminderPermission.granted;
    await backgroundAndResume(tester);
    await settle(tester);

    expect(
      container.read(notificationPermissionProvider).value,
      ReminderPermission.granted,
    );
    expect(syncs(), 2);
    expect(gateway.scheduled, hasLength(4));
  });

  testWidgets('every resume configures the timezone and re-syncs', (
    tester,
  ) async {
    final clock = TestClock(DateTime(2026, 9, 19, 10));
    final repository = FakeSubscriptionRepository()
      ..seed([subscriptionFixture(nextBillingDate: CalendarDate(2026, 10, 1))]);

    await pumpWatcher(tester, repository, clock);
    await settle(tester);
    expect(syncs(), 1);

    await backgroundAndResume(tester);
    await settle(tester);
    expect(timezoneCalls, 2);
    expect(syncs(), 2);

    timezone = 'Europe/London';
    await backgroundAndResume(tester);
    await settle(tester);
    expect(timezoneCalls, 3);
    expect(syncs(), 3);
  });

  testWidgets('resume refreshes the repository without invalidating', (
    tester,
  ) async {
    final clock = TestClock(DateTime(2026, 9, 19, 10));
    final repository = FakeSubscriptionRepository()
      ..seed([subscriptionFixture(nextBillingDate: CalendarDate(2026, 10, 1))]);

    await pumpWatcher(tester, repository, clock);
    await settle(tester);
    final container = containerOf(tester);
    var builds = 0;
    final listAll = container.listen(
      subscriptionsProvider,
      (_, _) => builds++,
    );
    addTearDown(listAll.close);
    final before = container.read(subscriptionsProvider);

    await backgroundAndResume(tester);
    await settle(tester);

    expect(repository.refreshCount, 1);
    expect(identical(container.read(subscriptionsProvider), before), isTrue);
    expect(builds, 0);
  });

  testWidgets('resume picks up a snooze written outside the app', (
    tester,
  ) async {
    final clock = TestClock(DateTime(2026, 9, 19, 10));
    final repository = FakeSubscriptionRepository()
      ..seed([subscriptionFixture(nextBillingDate: CalendarDate(2026, 10, 1))]);

    await pumpWatcher(tester, repository, clock);
    await settle(tester);
    expect(
      gateway.scheduledReminders.any((r) => r.kind == ReminderKind.snoozed),
      isFalse,
    );

    final snoozedUntil = DateTime(2026, 9, 20, 10);
    repository.subscriptions['sub-1'] = repository.subscriptions['sub-1']!
        .copyWith(snoozedUntil: snoozedUntil.toUtc());
    expect(repository.refreshCount, 0);

    await backgroundAndResume(tester);
    await settle(tester);

    expect(repository.refreshCount, 1);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );
    final cached = container.read(subscriptionsProvider).requireValue;
    expect(cached.single.snoozedUntil, snoozedUntil.toUtc());
    final snoozed = gateway.scheduledReminders.where(
      (r) => r.kind == ReminderKind.snoozed,
    );
    expect(snoozed.map((r) => r.fireAt), [snoozedUntil]);
  });
}
