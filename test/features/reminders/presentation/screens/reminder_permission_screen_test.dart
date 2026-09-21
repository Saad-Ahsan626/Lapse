import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/data/reminder_permission.dart';
import 'package:lapse/features/reminders/data/system_settings.dart';
import 'package:lapse/features/reminders/presentation/screens/reminder_permission_screen.dart';
import 'package:lapse/features/reminders/presentation/widgets/bell_illustration.dart';
import 'package:lapse/features/reminders/presentation/widgets/notification_preview_card.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

import '../../../../helpers/fake_notification_gateway.dart';
import '../../../../helpers/fake_subscription_repository.dart';
import '../../../../helpers/in_memory_settings_repository.dart';

final _now = DateTime(2026, 9, 18, 19);

class _Harness {
  _Harness(this.gateway, this.settings);

  final FakeNotificationGateway gateway;
  final InMemorySettingsRepository settings;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  ReminderPermission initial = ReminderPermission.denied,
  ReminderPermission requestResult = ReminderPermission.granted,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool inOnboarding = false,
}) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final gateway = FakeNotificationGateway(
    permissionResult: initial,
    requestResult: requestResult,
  );
  final settings = InMemorySettingsRepository();
  final router = GoRouter(
    initialLocation: inOnboarding
        ? '/onboarding/permission'
        : '/reminders/permission',
    routes: [
      GoRoute(
        path: '/onboarding/permission',
        builder: (_, _) => const ReminderPermissionScreen(inOnboarding: true),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home page')),
        routes: [
          GoRoute(
            path: 'reminders/permission',
            builder: (_, _) => const ReminderPermissionScreen(),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
        notificationGatewayProvider.overrideWithValue(gateway),
        subscriptionRepositoryProvider.overrideWithValue(
          FakeSubscriptionRepository(),
        ),
        clockProvider.overrideWithValue(() => _now),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await _settle(tester);
  return _Harness(gateway, settings);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tap(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  testWidgets('renders the design copy, bell and preview card', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(BellIllustration), findsOneWidget);
    expect(find.text(ReminderPermissionScreen.title), findsOneWidget);
    expect(find.text(ReminderPermissionScreen.body), findsOneWidget);
    expect(find.byType(NotificationPreviewCard), findsOneWidget);
    expect(find.text('Lapse'), findsOneWidget);
    expect(find.text('now'), findsOneWidget);
    expect(
      find.text(NotificationPreviewCard.sampleMessage),
      findsOneWidget,
    );
    expect(find.text('Allow notifications'), findsOneWidget);
    expect(find.text('Maybe later'), findsOneWidget);
    expect(find.text('Open settings'), findsNothing);
  });

  testWidgets('Allow requests permission and pops with a snackbar', (
    tester,
  ) async {
    final harness = await _pump(tester);

    await _tap(tester, 'Allow notifications');

    expect(harness.gateway.permissionRequests, 1);
    expect(find.text('Home page'), findsOneWidget);
    expect(find.byType(ReminderPermissionScreen), findsNothing);
    expect(find.text(ReminderPermissionScreen.grantedMessage), findsOneWidget);
  });

  testWidgets('denied request switches to Open settings with a hint', (
    tester,
  ) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      systemSettingsChannel,
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        systemSettingsChannel,
        null,
      ),
    );
    final harness = await _pump(
      tester,
      requestResult: ReminderPermission.permanentlyDenied,
    );

    await _tap(tester, 'Allow notifications');

    expect(harness.gateway.permissionRequests, 1);
    expect(find.byType(ReminderPermissionScreen), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
    expect(find.text('Allow notifications'), findsNothing);
    expect(find.text(ReminderPermissionScreen.deniedHint), findsOneWidget);

    await _tap(tester, 'Open settings');
    expect(calls, ['openNotificationSettings']);
  });

  testWidgets('permanently denied on open shows Open settings', (
    tester,
  ) async {
    await _pump(tester, initial: ReminderPermission.permanentlyDenied);

    expect(find.text('Open settings'), findsOneWidget);
    expect(find.text(ReminderPermissionScreen.deniedHint), findsOneWidget);
  });

  testWidgets('granting in system settings pops on resume', (tester) async {
    final harness = await _pump(
      tester,
      requestResult: ReminderPermission.denied,
    );
    await _tap(tester, 'Allow notifications');
    expect(find.text('Open settings'), findsOneWidget);

    harness.gateway.permissionResult = ReminderPermission.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _settle(tester);

    expect(find.text('Home page'), findsOneWidget);
    expect(find.text(ReminderPermissionScreen.grantedMessage), findsOneWidget);
  });

  testWidgets('already granted shows the done state', (tester) async {
    final harness = await _pump(tester, initial: ReminderPermission.granted);

    expect(find.text('Reminders are already on'), findsOneWidget);
    expect(find.text('Allow notifications'), findsNothing);
    expect(find.text('Maybe later'), findsNothing);

    await _tap(tester, 'Done');

    expect(find.text('Home page'), findsOneWidget);
    expect(harness.gateway.permissionRequests, 0);
    expect(find.text(ReminderPermissionScreen.grantedMessage), findsNothing);
  });

  testWidgets('Maybe later snoozes the prompt for 7 days and pops', (
    tester,
  ) async {
    final harness = await _pump(tester);

    await _tap(tester, 'Maybe later');

    expect(
      harness.settings.load().remindersPromptSnoozedUntil,
      _now.toUtc().add(const Duration(days: 7)),
    );
    expect(harness.settings.load().remindersPromptSnoozedUntil!.isUtc, isTrue);
    expect(harness.gateway.permissionRequests, 0);
    expect(find.text('Home page'), findsOneWidget);
  });

  group('in onboarding', () {
    testWidgets('Allow finishes onboarding and goes Home when granted', (
      tester,
    ) async {
      final harness = await _pump(tester, inOnboarding: true);

      await _tap(tester, 'Allow notifications');

      expect(harness.gateway.permissionRequests, 1);
      expect(harness.settings.load().onboardingDone, isTrue);
      expect(find.text('Home page'), findsOneWidget);
      expect(find.byType(ReminderPermissionScreen), findsNothing);
      expect(
        find.text(ReminderPermissionScreen.grantedMessage),
        findsOneWidget,
      );
    });

    testWidgets('Allow still goes Home when the request is denied', (
      tester,
    ) async {
      final harness = await _pump(
        tester,
        inOnboarding: true,
        requestResult: ReminderPermission.permanentlyDenied,
      );

      await _tap(tester, 'Allow notifications');

      expect(harness.gateway.permissionRequests, 1);
      expect(harness.settings.load().onboardingDone, isTrue);
      expect(find.text('Home page'), findsOneWidget);
      expect(find.text('Open settings'), findsNothing);
      expect(find.text(ReminderPermissionScreen.grantedMessage), findsNothing);
    });

    testWidgets('Maybe later snoozes, finishes onboarding and goes Home', (
      tester,
    ) async {
      final harness = await _pump(tester, inOnboarding: true);

      await _tap(tester, 'Maybe later');

      expect(harness.gateway.permissionRequests, 0);
      expect(harness.settings.load().onboardingDone, isTrue);
      expect(
        harness.settings.load().remindersPromptSnoozedUntil,
        _now.toUtc().add(ReminderPermissionScreen.snooze),
      );
      expect(find.text('Home page'), findsOneWidget);
      expect(find.byType(ReminderPermissionScreen), findsNothing);
    });

    testWidgets('already granted Done finishes onboarding', (tester) async {
      final harness = await _pump(
        tester,
        inOnboarding: true,
        initial: ReminderPermission.granted,
      );

      await _tap(tester, 'Done');

      expect(harness.settings.load().onboardingDone, isTrue);
      expect(find.text('Home page'), findsOneWidget);
    });
  });

  testWidgets('outside onboarding the flag is left alone', (tester) async {
    final harness = await _pump(tester);

    await _tap(tester, 'Maybe later');

    expect(harness.settings.load().onboardingDone, isFalse);
  });

  for (final brightness in Brightness.values) {
    testWidgets('text scale 2 in ${brightness.name} does not overflow', (
      tester,
    ) async {
      await _pump(tester, brightness: brightness, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.text('Allow notifications'), findsOneWidget);

      await _tap(tester, 'Maybe later');
      expect(tester.takeException(), isNull);
    });

    testWidgets('denied state at text scale 2 in ${brightness.name}', (
      tester,
    ) async {
      await _pump(
        tester,
        brightness: brightness,
        textScale: 2,
        initial: ReminderPermission.permanentlyDenied,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Open settings'), findsOneWidget);
    });
  }
}
