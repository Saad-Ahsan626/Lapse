import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/router/app_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/providers/storage_providers.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/features/home/presentation/screens/home_screen.dart';
import 'package:lapse/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:lapse/features/onboarding/presentation/screens/setup_screen.dart';
import 'package:lapse/features/reminders/application/reminders_bootstrap.dart';
import 'package:lapse/features/reminders/data/notification_launch.dart';
import 'package:lapse/features/reminders/data/notification_tap.dart';
import 'package:lapse/features/reminders/presentation/screens/reminder_permission_screen.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/settings/presentation/screens/notification_troubleshooting_screen.dart';
import 'package:lapse/features/settings/presentation/screens/settings_screen.dart';
import 'package:lapse/features/splash/presentation/screens/splash_screen.dart';
import 'package:lapse/features/subscriptions/presentation/screens/subscription_detail_screen.dart';

import '../../features/reminders/application/reminder_test_support.dart';
import '../../helpers/in_memory_settings_repository.dart';
import '../../helpers/subscription_fixtures.dart';

class _StillDay extends DayTick {
  @override
  int build() => 0;
}

Future<void> _settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('onboardingRedirect', () {
    String? pending(String path, {bool debug = true}) => onboardingRedirect(
      path,
      onboardingDone: false,
      allowDebugRoutes: debug,
    );
    String? done(String path) => onboardingRedirect(path, onboardingDone: true);

    test('sends everything else to onboarding before it is done', () {
      expect(pending(Routes.home), Routes.onboarding);
      expect(pending(Routes.subscriptions), Routes.onboarding);
      expect(pending(Routes.detail('x')), Routes.onboarding);
      expect(pending(Routes.settings), Routes.onboarding);
      expect(pending('/onboardingx'), Routes.onboarding);
    });

    test('allows splash and the onboarding flow before it is done', () {
      expect(pending(Routes.splash), isNull);
      expect(pending(Routes.onboarding), isNull);
      expect(pending(Routes.setup), isNull);
      expect(pending(Routes.permission), isNull);
    });

    test('allows debug routes only in debug builds', () {
      expect(pending(Routes.gallery), isNull);
      expect(pending(Routes.dataInspector), isNull);
      expect(pending(Routes.gallery, debug: false), Routes.onboarding);
    });

    test('leaves the flow for Home once onboarding is done', () {
      expect(done(Routes.onboarding), Routes.home);
      expect(done(Routes.setup), Routes.home);
      expect(done(Routes.permission), Routes.home);
      expect(done(Routes.home), isNull);
      expect(done(Routes.splash), isNull);
      expect(done(Routes.detail('x')), isNull);
    });
  });

  group('app router', () {
    late ReminderHarness h;
    late ProviderContainer container;
    late GoRouter router;

    Future<void> pumpApp(
      WidgetTester tester, {
      required bool onboardingDone,
      required String initialLocation,
      void Function(ReminderHarness harness)? seed,
      bool settle = true,
    }) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      h = ReminderHarness(
        settings: InMemorySettingsRepository(
          AppSettings(defaultCurrency: 'PKR', onboardingDone: onboardingDone),
        ),
      );
      seed?.call(h);
      container = h.container([
        initialLocationProvider.overrideWithValue(initialLocation),
        deviceCountryProvider.overrideWithValue('PK'),
        dayTickProvider.overrideWith(_StillDay.new),
      ]);
      addTearDown(container.dispose);
      router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      if (settle) await _settle(tester);
    }

    String path() => router.routerDelegate.currentConfiguration.uri.path;

    testWidgets('blocks Home before onboarding is done', (tester) async {
      await pumpApp(
        tester,
        onboardingDone: false,
        initialLocation: Routes.home,
      );

      expect(path(), Routes.onboarding);
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      router.go(Routes.subscriptions);
      await _settle(tester);
      expect(path(), Routes.onboarding);
    });

    testWidgets('onboarding children render setup and permission', (
      tester,
    ) async {
      await pumpApp(
        tester,
        onboardingDone: false,
        initialLocation: Routes.onboarding,
      );

      unawaited(router.push<void>(Routes.setup));
      await _settle(tester);
      expect(find.byType(SetupScreen), findsOneWidget);

      unawaited(router.push<void>(Routes.permission));
      await _settle(tester);
      final screen = tester.widget<ReminderPermissionScreen>(
        find.byType(ReminderPermissionScreen),
      );
      expect(screen.inOnboarding, isTrue);
    });

    testWidgets('finishing onboarding refreshes the same router to Home', (
      tester,
    ) async {
      await pumpApp(
        tester,
        onboardingDone: false,
        initialLocation: Routes.setup,
      );
      final before = container.read(appRouterProvider);

      await container
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(onboardingDone: true));
      await _settle(tester);

      expect(identical(container.read(appRouterProvider), before), isTrue);
      expect(path(), Routes.home);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('redirects /onboarding away once it is done', (tester) async {
      await pumpApp(
        tester,
        onboardingDone: true,
        initialLocation: Routes.onboarding,
      );

      expect(path(), Routes.home);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('splash is the default start and hands off to Home', (
      tester,
    ) async {
      await pumpApp(
        tester,
        onboardingDone: true,
        initialLocation: initialLocationFor(null),
        settle: false,
      );
      await tester.pump();
      expect(path(), Routes.splash);
      expect(find.byType(SplashScreen), findsOneWidget);

      await _settle(tester, 30);

      expect(path(), Routes.home);
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('splash hands off to onboarding on a first launch', (
      tester,
    ) async {
      await pumpApp(
        tester,
        onboardingDone: false,
        initialLocation: Routes.splash,
      );
      expect(find.byType(SplashScreen), findsOneWidget);

      await _settle(tester, 80);

      expect(path(), Routes.onboarding);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('settings and troubleshooting have real screens', (
      tester,
    ) async {
      await pumpApp(tester, onboardingDone: true, initialLocation: Routes.home);

      unawaited(router.push<void>(Routes.settings));
      await _settle(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);

      unawaited(router.push<void>(Routes.notificationTroubleshooting));
      await _settle(tester);
      expect(find.byType(NotificationTroubleshootingScreen), findsOneWidget);
    });

    testWidgets('a notification launch opens the detail, skipping splash', (
      tester,
    ) async {
      const launch = NotificationLaunch(
        NotificationTap(
          subscriptionId: 'sub-1',
          action: NotificationAction.open,
        ),
      );
      await pumpApp(
        tester,
        onboardingDone: true,
        initialLocation: initialLocationFor(launch),
        seed: (harness) => harness.repository.seed([
          subscriptionFixture(nextBillingDate: CalendarDate(2026, 10, 1)),
        ]),
      );

      expect(path(), Routes.detail('sub-1'));
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(SubscriptionDetailScreen), findsOneWidget);
    });

    testWidgets('system back from a cold-start detail lands on Home', (
      tester,
    ) async {
      const launch = NotificationLaunch(
        NotificationTap(
          subscriptionId: 'sub-1',
          action: NotificationAction.open,
        ),
      );
      await pumpApp(
        tester,
        onboardingDone: true,
        initialLocation: initialLocationFor(launch),
        seed: (harness) => harness.repository.seed([
          subscriptionFixture(nextBillingDate: CalendarDate(2026, 10, 1)),
        ]),
      );
      expect(find.byType(SplashScreen), findsNothing);
      expect(path(), Routes.detail('sub-1'));

      final handled = await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(handled, isTrue);
      expect(path(), Routes.home);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SubscriptionDetailScreen), findsNothing);
    });

    testWidgets('system back from a pushed detail pops to Home', (
      tester,
    ) async {
      await pumpApp(
        tester,
        onboardingDone: true,
        initialLocation: Routes.home,
        seed: (harness) => harness.repository.seed([
          subscriptionFixture(nextBillingDate: CalendarDate(2026, 10, 1)),
        ]),
      );
      unawaited(router.push<void>(Routes.detail('sub-1')));
      await _settle(tester);
      expect(find.byType(SubscriptionDetailScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(path(), Routes.home);
      expect(find.byType(SubscriptionDetailScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
