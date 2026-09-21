import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:lapse/features/onboarding/presentation/widgets/worm_indicator.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';

import '../../helpers/in_memory_settings_repository.dart';
import '../../helpers/pump_app.dart';

const _titles = [
  'Free trials quietly turn into charges',
  'We remind you before — not after',
  'Cancel in one tap',
];

const _bodies = [
  'The average person forgets two of them a year. The bank never does.',
  'Nudges at 7, 3 and 1 day out, at a time you choose.',
  'We keep the cancel link for every service, so you never hunt for it.',
];

void _phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<GoRouter> _pumpRouted(
  WidgetTester tester, {
  bool reduceMotion = false,
}) async {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/setup',
        builder: (_, _) => const Scaffold(body: Text('Setup stub')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          InMemorySettingsRepository(),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
      ),
    ),
  );
  await _settle(tester);
  return router;
}

String _location(GoRouter router) =>
    router.routerDelegate.currentConfiguration.last.matchedLocation;

void main() {
  testWidgets('shows every slide copy as Next advances', (tester) async {
    _phone(tester);
    await _pumpRouted(tester);

    for (var i = 0; i < 3; i++) {
      expect(find.text(_titles[i]), findsOneWidget);
      expect(find.text(_bodies[i]), findsOneWidget);
      if (i < 2) {
        expect(find.text('Skip'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);
        await tester.tap(find.text('Next'));
        await _settle(tester);
      }
    }
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(find.text('Next'), findsNothing);
  });

  testWidgets('Next jumps instantly under reduce motion', (tester) async {
    _phone(tester);
    await _pumpRouted(tester, reduceMotion: true);

    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text(_titles[1]), findsOneWidget);
    expect(find.text(_titles[0]), findsNothing);
  });

  testWidgets('worm indicator follows the page', (tester) async {
    _phone(tester);
    await _pumpRouted(tester);
    expect(
      tester.widget<WormIndicator>(find.byType(WormIndicator)).page,
      0,
    );
    await tester.tap(find.text('Next'));
    await _settle(tester);
    expect(
      tester.widget<WormIndicator>(find.byType(WormIndicator)).page,
      1,
    );
  });

  testWidgets('Skip pushes setup', (tester) async {
    _phone(tester);
    final router = await _pumpRouted(tester);

    await tester.tap(find.text('Skip'));
    await _settle(tester);
    expect(_location(router), '/onboarding/setup');
    expect(find.text('Setup stub'), findsOneWidget);
  });

  testWidgets('Get started pushes setup', (tester) async {
    _phone(tester);
    final router = await _pumpRouted(tester);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Next'));
      await _settle(tester);
    }
    await tester.tap(find.text('Get started'));
    await _settle(tester);
    expect(_location(router), '/onboarding/setup');
    expect(find.text('Setup stub'), findsOneWidget);
  });

  testWidgets('swiping moves between slides', (tester) async {
    _phone(tester);
    await _pumpRouted(tester);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await _settle(tester);
    expect(find.text(_titles[1]), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('text scale 2 has no overflow in ${brightness.name}', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpLapse(
        const OnboardingScreen(),
        brightness: brightness,
        textScale: 2,
        wrapInScaffold: false,
        withProviders: true,
      );
      await _settle(tester);
      expect(tester.takeException(), isNull);

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Next'));
        await _settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.text(_titles[i + 1]), findsOneWidget);
      }
      expect(find.text('Get started'), findsOneWidget);
    });
  }
}
