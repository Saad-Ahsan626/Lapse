import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/router/app_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/application/reminders_bootstrap.dart';
import 'package:lapse/features/reminders/data/notification_launch.dart';
import 'package:lapse/features/reminders/data/notification_tap.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/domain/reminder_kind.dart';

import '../../../helpers/fake_notification_gateway.dart';
import '../../../helpers/subscription_fixtures.dart';
import 'reminder_test_support.dart';

void main() {
  late ReminderHarness h;
  late GoRouter router;
  late List<String> visits;
  late ProviderContainer container;

  setUp(() {
    h = ReminderHarness(
      gateway: FakeNotificationGateway(
        permissionResult: ReminderPermission.denied,
      ),
    );
    h.repository.seed([
      subscriptionFixture(
        nextBillingDate: CalendarDate(2026, 10, 1),
        cancelUrl: 'https://example.com/cancel',
      ),
      subscriptionFixture(
        id: 'sub-2',
        name: 'Gym',
        nextBillingDate: CalendarDate(2026, 10, 1),
      ),
    ]);
    visits = [];
    router = GoRouter(
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) {
            visits.add('home');
            return const Text('home');
          },
        ),
        GoRoute(
          path: '/subscription/:id',
          builder: (_, state) {
            final id = state.pathParameters['id']!;
            visits.add('detail $id');
            return Text('detail $id');
          },
        ),
      ],
    );
  });

  Future<void> pumpRouter(WidgetTester tester) async {
    container = h.container([appRouterProvider.overrideWithValue(router)]);
    addTearDown(container.dispose);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  Future<void> tap(
    WidgetTester tester,
    String id,
    NotificationAction action,
  ) async {
    await container
        .read(notificationTapHandlerProvider)
        .handle(NotificationTap(subscriptionId: id, action: action));
    await tester.pumpAndSettle();
  }

  String location() => router.state.uri.path;

  testWidgets('tapping the body opens the detail', (tester) async {
    await pumpRouter(tester);

    await tap(tester, 'sub-1', NotificationAction.open);

    expect(location(), Routes.detail('sub-1'));
    expect(find.text('detail sub-1'), findsOneWidget);
    expect(h.linkOpener.opened, isEmpty);
  });

  testWidgets('cancel now opens the cancel link and stays put', (
    tester,
  ) async {
    await pumpRouter(tester);

    await tap(tester, 'sub-1', NotificationAction.cancelNow);

    expect(h.linkOpener.opened, [Uri.parse('https://example.com/cancel')]);
    expect(location(), Routes.home);
  });

  testWidgets('cancel now without a link opens the detail', (tester) async {
    await pumpRouter(tester);

    await tap(tester, 'sub-2', NotificationAction.cancelNow);

    expect(h.linkOpener.opened, isEmpty);
    expect(location(), Routes.detail('sub-2'));
  });

  testWidgets('cancel now falls back to the detail when the link fails', (
    tester,
  ) async {
    h.linkOpener.result = false;
    await pumpRouter(tester);

    await tap(tester, 'sub-1', NotificationAction.cancelNow);

    expect(h.linkOpener.opened, hasLength(1));
    expect(location(), Routes.detail('sub-1'));

    h.linkOpener.fails = true;
    router.go(Routes.home);
    await tester.pumpAndSettle();
    await tap(tester, 'sub-1', NotificationAction.cancelNow);
    expect(location(), Routes.detail('sub-1'));
  });

  testWidgets('a deleted subscription goes home', (tester) async {
    await pumpRouter(tester);
    router.go(Routes.detail('sub-2'));
    await tester.pumpAndSettle();

    await tap(tester, 'gone', NotificationAction.open);

    expect(location(), Routes.home);
  });

  testWidgets('snooze in the foreground snoozes without navigating', (
    tester,
  ) async {
    await pumpRouter(tester);

    await tap(tester, 'sub-1', NotificationAction.snooze);

    final stored = h.repository.subscriptions['sub-1']!;
    expect(
      stored.snoozedUntil,
      h.clock.now.toUtc().add(const Duration(hours: 24)),
    );
    expect(
      h.gateway.scheduledReminders.where((r) => r.kind == ReminderKind.snoozed),
      hasLength(1),
    );
    expect(location(), Routes.home);
    expect(visits.where((v) => v.startsWith('detail')), isEmpty);
  });

  testWidgets('bootstrap wires taps to the handler', (tester) async {
    const launch = NotificationLaunch(
      NotificationTap(
        subscriptionId: 'sub-1',
        action: NotificationAction.open,
      ),
    );
    h.gateway.launch = launch;
    await pumpRouter(tester);

    final result = await bootstrapReminders(container);

    expect(result, launch);
    expect(h.timezoneCalls, 1);
    expect(h.gateway.calls.take(2), ['initialize', 'launchDetails']);

    h.gateway.simulateTap(
      const NotificationTap(
        subscriptionId: 'sub-2',
        action: NotificationAction.open,
      ),
    );
    await tester.pumpAndSettle();
    expect(location(), Routes.detail('sub-2'));
  });

  testWidgets('a cold-start cancel tap opens the link', (tester) async {
    await pumpRouter(tester);

    await container
        .read(notificationTapHandlerProvider)
        .handleLaunch(
          const NotificationLaunch(
            NotificationTap(
              subscriptionId: 'sub-1',
              action: NotificationAction.cancelNow,
            ),
          ),
        );
    await container
        .read(notificationTapHandlerProvider)
        .handleLaunch(
          const NotificationLaunch(
            NotificationTap(
              subscriptionId: 'sub-1',
              action: NotificationAction.open,
            ),
          ),
        );

    expect(h.linkOpener.opened, hasLength(1));
  });
}
