import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/debug/presentation/widgets/reminders_debug_section.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

import '../../../../helpers/fake_notification_gateway.dart';
import '../../../../helpers/fake_subscription_repository.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/subscription_fixtures.dart';

final _now = DateTime(2026, 9, 18, 19);

List<Subscription> _subscriptions() => [
  subscriptionFixture(
    id: 'spotify',
    nextBillingDate: CalendarDate(2026, 9, 25),
  ),
  subscriptionFixture(
    id: 'netflix',
    name: 'Netflix',
    priceMinor: 64900,
    isTrial: true,
    nextBillingDate: CalendarDate(2026, 9, 21),
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required FakeNotificationGateway gateway,
  List<Subscription>? subscriptions,
}) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final repository = FakeSubscriptionRepository()
    ..seed(subscriptions ?? _subscriptions());
  await tester.pumpLapse(
    Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [RemindersDebugSection()],
      ),
    ),
    withProviders: true,
    wrapInScaffold: false,
    overrides: [
      notificationGatewayProvider.overrideWithValue(gateway),
      subscriptionRepositoryProvider.overrideWithValue(repository),
      clockProvider.overrideWithValue(() => _now),
    ],
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String _row(WidgetTester tester, String label) {
  final row = find.ancestor(of: find.text(label), matching: find.byType(Row));
  final texts = tester
      .widgetList<Text>(
        find.descendant(of: row.first, matching: find.byType(Text)),
      )
      .map((t) => t.data)
      .toList();
  return texts.last ?? '';
}

void main() {
  testWidgets('shows status from the providers and the planned list', (
    tester,
  ) async {
    final gateway = FakeNotificationGateway(exactAllowed: false);
    await _pump(tester, gateway: gateway);

    expect(find.text('REMINDERS'), findsOneWidget);
    expect(_row(tester, 'Permission'), 'granted');
    expect(_row(tester, 'Exact alarms'), 'no');
    expect(_row(tester, 'Pending'), '${gateway.scheduled.length}');
    expect(gateway.scheduled, isNotEmpty);
    expect(_row(tester, 'Last sync'), contains('scheduled'));
    expect(find.textContaining('Exact alarms are off'), findsOneWidget);
    expect(
      find.text('Netflix · Sun 20 Sep 09:00 · Netflix trial ends tomorrow'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Spotify Premium · Thu 24 Sep 09:00 ·'),
      findsOneWidget,
    );
  });

  testWidgets('shows the empty state and "never" when nothing is planned', (
    tester,
  ) async {
    final gateway = FakeNotificationGateway(
      permissionResult: ReminderPermission.denied,
    );
    await _pump(tester, gateway: gateway, subscriptions: const []);

    expect(_row(tester, 'Permission'), 'denied');
    expect(_row(tester, 'Exact alarms'), 'yes');
    expect(_row(tester, 'Pending'), '0');
    expect(_row(tester, 'Last sync'), 'never');
    expect(find.text('No reminders planned'), findsOneWidget);
    expect(find.textContaining('Exact alarms are off'), findsNothing);
  });

  testWidgets('Sync now re-schedules and reports the count', (tester) async {
    final gateway = FakeNotificationGateway();
    await _pump(tester, gateway: gateway);
    final before = gateway.cancelAllCount;

    await tester.tap(find.text('Sync now'));
    await _settle(tester);

    expect(gateway.cancelAllCount, before + 1);
    expect(gateway.scheduled, hasLength(2));
    expect(find.text('Scheduled 2 reminder(s)'), findsOneWidget);
    expect(_row(tester, 'Pending'), '2');
  });

  testWidgets('Fire test schedules a reminder 10 s ahead', (tester) async {
    final gateway = FakeNotificationGateway(
      permissionResult: ReminderPermission.denied,
    );
    await _pump(tester, gateway: gateway);
    expect(gateway.scheduled, isEmpty);

    await tester.tap(find.text('Fire test in 10 s'));
    await _settle(tester);

    final entry = gateway.scheduled[RemindersDebugSection.testReminderId];
    expect(entry, isNotNull);
    final (reminder, exact) = entry!;
    expect(exact, isTrue);
    expect(reminder.fireAt, _now.add(const Duration(seconds: 10)));
    expect(reminder.subscriptionId, 'netflix');
    expect(reminder.title, 'Netflix trial ends tomorrow');
    expect(find.text('Test reminder fires in 10 s'), findsOneWidget);
  });

  testWidgets('Fire test builds content when nothing is planned', (
    tester,
  ) async {
    final gateway = FakeNotificationGateway(
      permissionResult: ReminderPermission.denied,
    );
    await _pump(
      tester,
      gateway: gateway,
      subscriptions: [
        subscriptionFixture(
          id: 'late',
          name: 'Late',
          nextBillingDate: CalendarDate(2026, 9, 18),
          reminderOffsets: const [],
        ),
        subscriptionFixture(
          id: 'gone',
          name: 'Gone',
          status: SubscriptionStatus.cancelled,
        ),
      ],
    );

    await tester.tap(find.text('Fire test in 10 s'));
    await _settle(tester);

    final (reminder, _) =
        gateway.scheduled[RemindersDebugSection.testReminderId]!;
    expect(reminder.subscriptionId, 'late');
    expect(reminder.title, 'Late renews today');
    expect(reminder.fireAt, _now.add(const Duration(seconds: 10)));
  });

  testWidgets('request buttons call the gateway', (tester) async {
    final gateway = FakeNotificationGateway(
      permissionResult: ReminderPermission.denied,
      requestResult: ReminderPermission.permanentlyDenied,
    );
    await _pump(tester, gateway: gateway);

    await tester.tap(find.text('Request permission'));
    await _settle(tester);
    expect(gateway.permissionRequests, 1);
    expect(find.text('Permission: permanentlyDenied'), findsOneWidget);
    expect(_row(tester, 'Permission'), 'permanentlyDenied');

    await tester.tap(find.text('Request exact alarms'));
    await _settle(tester);
    expect(gateway.exactAlarmRequests, 1);
  });
}
