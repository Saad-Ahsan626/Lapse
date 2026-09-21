import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/providers/storage_providers.dart';
import 'package:lapse/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:lapse/features/onboarding/presentation/screens/setup_screen.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/reminders/presentation/screens/reminder_permission_screen.dart';
import 'package:lapse/features/splash/presentation/screens/splash_screen.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

import '../helpers/fake_notification_gateway.dart';
import '../helpers/fake_subscription_repository.dart';
import 'a11y_test_support.dart';

Widget _stub(String name) => Scaffold(body: Text(name));

Future<void> _pumpSlides(
  WidgetTester tester,
  Brightness brightness,
  double textScale,
  int slide,
) async {
  usePhone(tester);
  await pumpRoutes(
    tester,
    initialLocation: Routes.onboarding,
    brightness: brightness,
    textScale: textScale,
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: Routes.setup, builder: (_, _) => _stub('setup')),
    ],
  );
  await frames(tester, 12);
  for (var i = 0; i < slide; i++) {
    await tester.tap(find.text('Next'));
    await frames(tester, 12);
  }
}

void main() {
  accessibilityTests('splash end state', (tester, brightness, scale) async {
    usePhone(tester);
    await pumpRoutes(
      tester,
      initialLocation: Routes.splash,
      brightness: brightness,
      textScale: scale,
      routes: [
        GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
        GoRoute(path: Routes.home, builder: (_, _) => _stub('home')),
        GoRoute(
          path: Routes.onboarding,
          builder: (_, _) => _stub('onboarding'),
        ),
      ],
    );
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.byType(SplashScreen), findsOneWidget);
  });

  for (var slide = 0; slide < 3; slide++) {
    accessibilityTests(
      'onboarding slide ${slide + 1}',
      (tester, brightness, scale) =>
          _pumpSlides(tester, brightness, scale, slide),
    );
  }

  accessibilityTests('setup', (tester, brightness, scale) async {
    usePhone(tester);
    await pumpRoutes(
      tester,
      initialLocation: Routes.setup,
      brightness: brightness,
      textScale: scale,
      overrides: [deviceCountryProvider.overrideWithValue('PK')],
      routes: [
        GoRoute(
          path: Routes.onboarding,
          builder: (_, _) => _stub('slides'),
          routes: [
            GoRoute(path: 'setup', builder: (_, _) => const SetupScreen()),
          ],
        ),
      ],
    );
    await frames(tester, 8);
  });

  accessibilityTests('permission', (tester, brightness, scale) async {
    usePhone(tester);
    await pumpRoutes(
      tester,
      initialLocation: '/onboarding/permission',
      brightness: brightness,
      textScale: scale,
      overrides: [
        notificationGatewayProvider.overrideWithValue(
          FakeNotificationGateway(),
        ),
        subscriptionRepositoryProvider.overrideWithValue(
          FakeSubscriptionRepository(),
        ),
        clockProvider.overrideWithValue(() => DateTime(2026, 9, 18, 19)),
      ],
      routes: [
        GoRoute(
          path: '/onboarding/permission',
          builder: (_, _) => const ReminderPermissionScreen(inOnboarding: true),
        ),
      ],
    );
    await frames(tester, 8);
  });
}
