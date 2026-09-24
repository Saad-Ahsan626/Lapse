import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/app/providers/theme_mode_provider.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/domain/entities/app_theme_mode.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/settings/presentation/screens/notification_troubleshooting_screen.dart';
import 'package:lapse/features/settings/presentation/screens/settings_screen.dart';
import 'package:lapse/features/settings/presentation/widgets/settings_row.dart';

import '../../../../helpers/fake_notification_gateway.dart';
import '../../../../helpers/fake_system_bridge.dart';
import '../../../../helpers/subscription_fixtures.dart';
import '../settings_test_support.dart';

const _tall = Size(390, 2600);

Finder _row(String title) => find.widgetWithText(SettingsRow, title);

Finder _value(String title, String value) =>
    find.descendant(of: _row(title), matching: find.text(value));

Future<void> _tapRow(WidgetTester tester, String title) async {
  await tester.tap(_row(title));
  await settle(tester);
}

void main() {
  group('SettingsScreen rows', () {
    testWidgets('shows every group and value from settings', (tester) async {
      final h = SettingsHarness(
        settings: AppSettings(
          defaultCurrency: 'PKR',
          themeMode: AppThemeMode.light,
          userName: 'Saad',
          defaultReminderOffsets: const [7, 1, 0],
        ),
      );
      await h.pump(tester, size: _tall);

      expect(find.text('Settings'), findsOneWidget);
      for (final label in [
        'MONEY',
        'REMINDERS',
        'APPEARANCE',
        'YOUR DATA',
        'ABOUT',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(_value('Currency', 'PKR · Rs'), findsOneWidget);
      expect(find.text(SettingsScreen.currencyNote), findsOneWidget);
      expect(_value('Default reminders', '7d, 1d, Day of'), findsOneWidget);
      expect(_value('Reminder time', '09:00 AM'), findsOneWidget);
      expect(_value('Your name', 'Saad'), findsOneWidget);
      expect(_value('Export backup', '.json'), findsOneWidget);
      expect(_row('Import backup'), findsOneWidget);
      expect(_row('Rate Lapse'), findsOneWidget);
      expect(_row('Source code'), findsOneWidget);
      expect(_row('Licences'), findsOneWidget);
      expect(_value('Version', '0.1.0 (1)'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('empty reminders read Off and a missing name Not set', (
      tester,
    ) async {
      final h = SettingsHarness(
        settings: AppSettings(
          defaultCurrency: 'USD',
          defaultReminderOffsets: const [],
        ),
      );
      await h.pump(tester, size: _tall);

      expect(_value('Currency', r'USD · $'), findsOneWidget);
      expect(_value('Default reminders', 'Off'), findsOneWidget);
      expect(_value('Your name', 'Not set'), findsOneWidget);
    });

    testWidgets('the back arrow pops to the previous screen', (tester) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);

      await tester.tap(find.bySemanticsLabel('Back'));
      await settle(tester);

      expect(find.text('home'), findsOneWidget);
    });
  });

  group('editors', () {
    testWidgets('currency picker saves the default currency', (tester) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);

      await _tapRow(tester, 'Currency');
      await tester.tap(find.text('US dollar'));
      await settle(tester);

      expect(h.settings.load().defaultCurrency, 'USD');
      expect(_value('Currency', r'USD · $'), findsOneWidget);
    });

    testWidgets('default reminders sheet toggles chips and saves', (
      tester,
    ) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);

      await _tapRow(tester, 'Default reminders');
      expect(
        find.textContaining('Applies to new subscriptions'),
        findsOneWidget,
      );
      await tester.tap(find.text('3 days'));
      await tester.tap(find.text('Same day'));
      await tester.tap(find.text('1 day'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(h.settings.load().defaultReminderOffsets, [7, 3, 0]);
      expect(_value('Default reminders', '7d, 3d, Day of'), findsOneWidget);
    });

    testWidgets('clearing every default reminder shows Off', (tester) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);

      await _tapRow(tester, 'Default reminders');
      await tester.tap(find.text('7 days'));
      await tester.tap(find.text('1 day'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(h.settings.load().defaultReminderOffsets, isEmpty);
      expect(_value('Default reminders', 'Off'), findsOneWidget);
    });

    testWidgets('closing a sheet without saving changes nothing', (
      tester,
    ) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);

      await _tapRow(tester, 'Default reminders');
      await tester.tap(find.text('3 days'));
      await tester.tap(find.bySemanticsLabel('Close'));
      await settle(tester);

      expect(h.settings.saveCount, 0);
      expect(_value('Default reminders', '7d, 1d'), findsOneWidget);
    });

    testWidgets('reminder time saves and triggers a reminder resync', (
      tester,
    ) async {
      final h = SettingsHarness(
        subscriptions: [
          subscriptionFixture(nextBillingDate: CalendarDate(2026, 9, 25)),
        ],
      );
      await h.pump(tester, size: _tall, keepSyncAlive: true);
      await settle(tester);
      h.gateway.calls.clear();

      await _tapRow(tester, 'Reminder time');
      await tester.tap(find.text('PM'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(h.settings.load().reminderMinutes, 21 * 60);
      expect(_value('Reminder time', '09:00 PM'), findsOneWidget);
      expect(h.gateway.calls, containsAll(['canScheduleExact', 'schedule']));
      final scheduled = h.gateway.scheduledReminders;
      expect(scheduled, isNotEmpty);
      expect(scheduled.every((r) => r.fireAt.hour == 21), isTrue);
    });

    testWidgets('name sheet saves a trimmed name and clears it', (
      tester,
    ) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);

      await _tapRow(tester, 'Your name');
      await tester.enterText(find.byType(TextField), '  Ayesha  ');
      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(h.settings.load().userName, 'Ayesha');
      expect(_value('Your name', 'Ayesha'), findsOneWidget);

      await _tapRow(tester, 'Your name');
      await tester.tap(find.text('Clear'));
      await settle(tester);

      expect(h.settings.load().userName, isNull);
      expect(_value('Your name', 'Not set'), findsOneWidget);
    });

    testWidgets('name field is limited to 30 characters', (tester) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);

      await _tapRow(tester, 'Your name');
      await tester.enterText(find.byType(TextField), 'x' * 40);
      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(h.settings.load().userName, 'x' * 30);
    });

    testWidgets('theme segment switches the app theme instantly', (
      tester,
    ) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);
      BuildContext ctx() => tester.element(find.byType(SettingsScreen));
      expect(ctx().lapse.colors.isDark, isFalse);

      await tester.tap(find.text('Dark'));
      await settle(tester);

      expect(h.container.read(settingsProvider).themeMode, AppThemeMode.dark);
      expect(h.container.read(themeModeProvider), ThemeMode.dark);
      expect(h.settings.load().themeMode, AppThemeMode.dark);
      expect(ctx().lapse.colors.isDark, isTrue);

      await tester.tap(find.text('System'));
      await settle(tester);
      expect(h.container.read(themeModeProvider), ThemeMode.system);
    });
  });

  group('notification troubleshooting pill', () {
    testWidgets('shows OK when nothing needs attention', (tester) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);

      expect(
        find.descendant(
          of: _row('Notification troubleshooting'),
          matching: find.text('OK'),
        ),
        findsOneWidget,
      );
      expect(find.text('Check'), findsNothing);
      expect(
        find.bySemanticsLabel('Notification troubleshooting, all good'),
        findsOneWidget,
      );
    });

    for (final (name, gateway, bridge) in [
      (
        'notifications are off',
        FakeNotificationGateway(permissionResult: ReminderPermission.denied),
        FakeSystemBridge(),
      ),
      (
        'exact alarms are off',
        FakeNotificationGateway(exactAllowed: false),
        FakeSystemBridge(),
      ),
      (
        'battery is optimised',
        FakeNotificationGateway(),
        FakeSystemBridge(ignoringBatteryOptimizations: false),
      ),
    ]) {
      testWidgets('shows Check when $name', (tester) async {
        final h = SettingsHarness(gateway: gateway, bridge: bridge);
        await h.pump(tester, size: _tall);

        expect(find.text('Check'), findsOneWidget);
        expect(find.text('OK'), findsNothing);
        expect(
          find.bySemanticsLabel(
            'Notification troubleshooting, needs attention',
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('opens the troubleshooting screen', (tester) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);

      await _tapRow(tester, 'Notification troubleshooting');

      expect(find.byType(NotificationTroubleshootingScreen), findsOneWidget);
      expect(find.text('Troubleshooting'), findsOneWidget);
    });

    testWidgets('refreshes when the app resumes', (tester) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);
      expect(find.text('OK'), findsOneWidget);

      h.bridge.ignoringBatteryOptimizations = false;
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);

      expect(find.text('Check'), findsOneWidget);
    });
  });

  group('your data and about', () {
    testWidgets('export saves a backup through the system bridge', (
      tester,
    ) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);

      await _tapRow(tester, 'Export backup');

      expect(h.bridge.saved, hasLength(1));
      expect(h.bridge.saved.single.fileName, endsWith('.json'));
    });

    testWidgets('import asks the system for a document', (tester) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);

      await _tapRow(tester, 'Import backup');

      expect(h.bridge.documentsRequested, 1);
    });

    testWidgets('Rate Lapse opens the store and falls back to the web', (
      tester,
    ) async {
      final h = SettingsHarness();
      h.linkOpener.result = false;
      await h.pump(tester, size: _tall);

      await _tapRow(tester, 'Rate Lapse');

      expect(h.linkOpener.opened, [
        SettingsScreen.rateUri,
        SettingsScreen.rateWebUri,
      ]);
      expect(find.text(SettingsScreen.linkFailedMessage), findsOneWidget);
    });

    testWidgets('Rate Lapse stops at the store when it opens', (
      tester,
    ) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);

      await _tapRow(tester, 'Rate Lapse');

      expect(h.linkOpener.opened, [SettingsScreen.rateUri]);
      expect(
        SettingsScreen.rateUri.toString(),
        'market://details?id=io.github.saad_ahsan626.lapse',
      );
    });

    testWidgets('Source code opens the repository', (tester) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);

      await _tapRow(tester, 'Source code');

      expect(h.linkOpener.opened, [
        Uri.parse('https://github.com/Saad-Ahsan626/lapse'),
      ]);
    });

    testWidgets('Licences opens the licence page', (tester) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);

      await _tapRow(tester, 'Licences');

      expect(find.byType(LicensePage), findsOneWidget);
    });
  });

  group('developer group', () {
    testWidgets('appears in debug builds and opens the tools', (
      tester,
    ) async {
      final h = SettingsHarness();
      await h.pump(tester, size: _tall);

      expect(find.text('DEVELOPER'), findsOneWidget);
      for (final (title, path) in [
        ('Design gallery', Routes.gallery),
        ('Data inspector', Routes.dataInspector),
        ('Replay splash', Routes.splash),
      ]) {
        await _tapRow(tester, title);
        expect(h.pushed.last, path);
        h.router.pop();
        await settle(tester);
      }
    });

    testWidgets('is hidden when developer tools are off', (tester) async {
      final h = SettingsHarness();
      await h.pump(
        tester,
        size: _tall,
        settingsScreen: const SettingsScreen(showDeveloperTools: false),
      );

      expect(find.text('DEVELOPER'), findsNothing);
      expect(_row('Design gallery'), findsNothing);
    });
  });

  group('layout', () {
    for (final brightness in Brightness.values) {
      testWidgets('fits at text scale 2 in ${brightness.name} mode', (
        tester,
      ) async {
        final h = SettingsHarness(
          settings: AppSettings(
            defaultCurrency: 'PKR',
            themeMode: brightness == Brightness.dark
                ? AppThemeMode.dark
                : AppThemeMode.light,
            userName: 'A rather long name for a row',
            defaultReminderOffsets: const [7, 3, 1, 0],
          ),
          bridge: FakeSystemBridge(ignoringBatteryOptimizations: false),
        );
        await h.pump(tester, textScale: 2);
        expect(tester.takeException(), isNull);

        final scrollable = find.byType(Scrollable).first;
        for (var i = 0; i < 12; i++) {
          await tester.drag(scrollable, const Offset(0, -400));
          await settle(tester, 2);
          expect(tester.takeException(), isNull);
        }
        expect(find.text('Replay splash'), findsOneWidget);
        expect(
          tester.element(find.byType(SettingsScreen)).lapse.colors.brightness,
          brightness,
        );
      });
    }

    testWidgets('editor sheets fit at text scale 2', (tester) async {
      final h = SettingsHarness();
      await h.pump(tester, textScale: 2);

      for (final title in ['Default reminders', 'Reminder time', 'Your name']) {
        await tester.scrollUntilVisible(
          _row(title),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await _tapRow(tester, title);
        expect(tester.takeException(), isNull);
        await tester.tap(find.bySemanticsLabel('Close'));
        await settle(tester);
      }
    });
  });
}
