import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/domain/entities/app_theme_mode.dart';
import 'package:lapse/features/settings/presentation/actions/test_notification.dart';
import 'package:lapse/features/settings/presentation/screens/notification_troubleshooting_screen.dart';
import 'package:lapse/features/settings/presentation/widgets/troubleshooting_row.dart';

import '../../../../helpers/fake_notification_gateway.dart';
import '../../../../helpers/fake_system_bridge.dart';
import '../../../../helpers/subscription_fixtures.dart';
import '../settings_test_support.dart';

const _tall = Size(390, 2000);

Finder _row(String title) => find.widgetWithText(TroubleshootingRow, title);

Finder _in(String title, String text) =>
    find.descendant(of: _row(title), matching: find.text(text));

Future<void> _open(
  SettingsHarness h,
  WidgetTester tester, {
  double textScale = 1,
  Size size = _tall,
}) => h.pump(
  tester,
  initialLocation: Routes.notificationTroubleshooting,
  textScale: textScale,
  size: size,
);

void main() {
  testWidgets('shows a healthy setup with no fix buttons', (tester) async {
    final h = SettingsHarness();
    await _open(h, tester);

    expect(_in('Notifications', 'Allowed'), findsOneWidget);
    expect(_in('Exact timing', 'On'), findsOneWidget);
    expect(_in('Battery optimisation', 'Not optimised'), findsOneWidget);
    expect(_in('Scheduled reminders', '0 scheduled'), findsOneWidget);
    expect(find.text('Nothing scheduled yet.'), findsOneWidget);
    expect(find.text('Allow'), findsNothing);
    expect(find.text('Open settings'), findsNothing);
    expect(find.text('Open battery settings'), findsNothing);
    expect(find.text('Send test notification'), findsOneWidget);
    expect(find.text('Sync now'), findsOneWidget);
  });

  testWidgets('Allow requests the notification permission', (tester) async {
    final gateway = FakeNotificationGateway(
      permissionResult: ReminderPermission.denied,
    );
    final h = SettingsHarness(gateway: gateway);
    await _open(h, tester);

    expect(_in('Notifications', 'Off'), findsOneWidget);
    expect(
      find.text(NotificationTroubleshootingScreen.notificationsOffDetail),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: _row('Notifications'),
        matching: find.text('Allow'),
      ),
    );
    await settle(tester);

    expect(gateway.permissionRequests, 1);
    expect(h.bridge.notificationSettingsOpened, 0);
    expect(_in('Notifications', 'Allowed'), findsOneWidget);
  });

  testWidgets('a refused request falls back to the system settings', (
    tester,
  ) async {
    final gateway = FakeNotificationGateway(
      permissionResult: ReminderPermission.denied,
      requestResult: ReminderPermission.denied,
    );
    final h = SettingsHarness(gateway: gateway);
    await _open(h, tester);

    await tester.tap(find.text('Allow'));
    await settle(tester);

    expect(gateway.permissionRequests, 1);
    expect(h.bridge.notificationSettingsOpened, 1);
  });

  testWidgets('a permanently denied permission opens settings', (
    tester,
  ) async {
    final gateway = FakeNotificationGateway(
      permissionResult: ReminderPermission.permanentlyDenied,
    );
    final h = SettingsHarness(gateway: gateway);
    await _open(h, tester);

    await tester.tap(find.text('Open settings'));
    await settle(tester);

    expect(gateway.permissionRequests, 0);
    expect(h.bridge.notificationSettingsOpened, 1);
  });

  testWidgets('exact timing off explains the drift and asks for it', (
    tester,
  ) async {
    final gateway = FakeNotificationGateway(exactAllowed: false);
    final h = SettingsHarness(gateway: gateway);
    await _open(h, tester);

    expect(_in('Exact timing', 'Off'), findsOneWidget);
    expect(
      find.text(NotificationTroubleshootingScreen.exactOffDetail),
      findsOneWidget,
    );

    gateway.exactAllowed = true;
    await tester.tap(find.text('Allow'));
    await settle(tester);

    expect(gateway.exactAlarmRequests, 1);
    expect(_in('Exact timing', 'On'), findsOneWidget);
  });

  testWidgets('battery optimisation opens the battery settings', (
    tester,
  ) async {
    final bridge = FakeSystemBridge(ignoringBatteryOptimizations: false);
    final h = SettingsHarness(bridge: bridge);
    await _open(h, tester);

    expect(_in('Battery optimisation', 'Optimised'), findsOneWidget);

    bridge.ignoringBatteryOptimizations = true;
    await tester.tap(find.text('Open battery settings'));
    await settle(tester);

    expect(bridge.batterySettingsOpened, 1);
    expect(_in('Battery optimisation', 'Not optimised'), findsOneWidget);
  });

  testWidgets('refreshes the state when the app resumes', (tester) async {
    final h = SettingsHarness();
    await _open(h, tester);
    expect(_in('Battery optimisation', 'Not optimised'), findsOneWidget);

    h.bridge.ignoringBatteryOptimizations = false;
    h.gateway.exactAllowed = false;
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester);

    expect(_in('Battery optimisation', 'Optimised'), findsOneWidget);
    expect(_in('Exact timing', 'Off'), findsOneWidget);
  });

  testWidgets('Sync now schedules reminders and shows the next one', (
    tester,
  ) async {
    final h = SettingsHarness(
      subscriptions: [
        subscriptionFixture(nextBillingDate: CalendarDate(2026, 9, 25)),
      ],
    );
    await _open(h, tester);

    await tester.tap(find.text('Sync now'));
    await settle(tester);

    expect(h.gateway.scheduled, hasLength(1));
    expect(find.text('Scheduled 1 reminder'), findsOneWidget);
    expect(_in('Scheduled reminders', '1 scheduled'), findsOneWidget);
    expect(
      find.text('Next: Spotify Premium · Thu, 24 Sep · 09:00 AM'),
      findsOneWidget,
    );
  });

  testWidgets('Send test notification schedules one in 10 seconds', (
    tester,
  ) async {
    final h = SettingsHarness(
      subscriptions: [
        subscriptionFixture(nextBillingDate: CalendarDate(2026, 9, 25)),
      ],
    );
    await _open(h, tester);

    await tester.tap(find.text('Send test notification'));
    await settle(tester);

    final (reminder, exact) = h.gateway.scheduled[testNotificationId]!;
    expect(reminder.fireAt, h.reminders.clock().add(testNotificationDelay));
    expect(reminder.subscriptionId, 'sub-1');
    expect(exact, isTrue);
    expect(
      find.text(
        NotificationTroubleshootingScreen.testScheduledMessage(
          testNotificationDelay,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the test notification works without subscriptions', (
    tester,
  ) async {
    final h = SettingsHarness();
    await _open(h, tester);

    await tester.tap(find.text('Send test notification'));
    await settle(tester);

    final (reminder, _) = h.gateway.scheduled[testNotificationId]!;
    expect(reminder.title, 'Lapse test reminder');
  });

  testWidgets('the test notification needs notifications allowed', (
    tester,
  ) async {
    final gateway = FakeNotificationGateway(
      permissionResult: ReminderPermission.denied,
    );
    final h = SettingsHarness(gateway: gateway);
    await _open(h, tester);

    await tester.tap(find.text('Send test notification'));
    await settle(tester);

    expect(gateway.scheduled, isEmpty);
    expect(
      find.text(NotificationTroubleshootingScreen.notificationsOffMessage),
      findsOneWidget,
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets('fits at text scale 2 in ${brightness.name} mode', (
      tester,
    ) async {
      final h = SettingsHarness(
        gateway: FakeNotificationGateway(
          permissionResult: ReminderPermission.denied,
          exactAllowed: false,
        ),
        bridge: FakeSystemBridge(ignoringBatteryOptimizations: false),
        settings: AppSettings(
          defaultCurrency: 'PKR',
          themeMode: brightness == Brightness.dark
              ? AppThemeMode.dark
              : AppThemeMode.light,
        ),
      );
      await _open(h, tester, textScale: 2, size: const Size(390, 844));
      expect(tester.takeException(), isNull);

      final scrollable = find.byType(Scrollable).first;
      for (var i = 0; i < 10; i++) {
        await tester.drag(scrollable, const Offset(0, -400));
        await settle(tester, 2);
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Sync now'), findsOneWidget);
      expect(
        tester
            .element(find.byType(NotificationTroubleshootingScreen))
            .lapse
            .colors
            .brightness,
        brightness,
      );
    });
  }
}
