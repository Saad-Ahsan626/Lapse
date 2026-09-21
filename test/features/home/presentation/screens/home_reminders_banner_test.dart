import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/home/presentation/widgets/home_header.dart';
import 'package:lapse/features/home/presentation/widgets/home_hero_card.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/presentation/widgets/reminders_off_banner.dart';

import '../../../../helpers/fake_notification_gateway.dart';
import '../../../../helpers/subscription_fixtures.dart';
import '../../home_harness.dart';

void main() {
  final subscriptions = [
    subscriptionFixture(
      id: 'spotify',
      nextBillingDate: CalendarDate(2026, 9, 25),
    ),
  ];

  testWidgets('no banner when reminders are allowed', (tester) async {
    await pumpHome(tester, subscriptions: subscriptions);

    expect(find.text('Reminders are off'), findsNothing);
  });

  testWidgets('banner sits between the header and the hero when denied', (
    tester,
  ) async {
    final harness = await pumpHome(
      tester,
      subscriptions: subscriptions,
      gateway: FakeNotificationGateway(
        permissionResult: ReminderPermission.denied,
      ),
    );

    expect(find.text('Reminders are off'), findsOneWidget);
    final header = tester.getRect(find.byType(HomeHeader));
    final banner = tester.getRect(find.byType(RemindersOffBanner));
    final hero = tester.getRect(find.byType(HomeHeroCard));
    expect(banner.top, greaterThanOrEqualTo(header.bottom));
    expect(hero.top, greaterThanOrEqualTo(banner.bottom));
    expect(
      tester.getRect(find.text('Reminders are off')).left,
      greaterThan(22),
    );

    await tester.tap(find.text('Turn on'));
    await settleHome(tester);
    expect(harness.pushed, ['/reminders/permission']);
  });

  testWidgets('banner also shows on the empty state', (tester) async {
    await pumpHome(
      tester,
      gateway: FakeNotificationGateway(
        permissionResult: ReminderPermission.permanentlyDenied,
      ),
    );

    expect(find.text('Reminders are off'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('banner fits at text scale 2 in dark mode', (tester) async {
    await pumpHome(
      tester,
      subscriptions: subscriptions,
      brightness: Brightness.dark,
      textScale: 2,
      gateway: FakeNotificationGateway(
        permissionResult: ReminderPermission.denied,
      ),
    );

    expect(find.text('Reminders are off'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
