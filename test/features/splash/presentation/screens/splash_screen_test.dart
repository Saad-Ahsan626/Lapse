import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/splash/presentation/screens/splash_screen.dart';
import 'package:lapse/features/splash/presentation/widgets/animated_logo.dart';

import '../../../../helpers/in_memory_settings_repository.dart';

void main() {
  Future<List<String>> pumpSplash(
    WidgetTester tester, {
    required bool onboardingDone,
    bool reduceMotion = false,
    Brightness brightness = Brightness.light,
  }) async {
    final visited = <String>[];
    Widget destination(String name) => Builder(
      builder: (_) {
        visited.add(name);
        return Text(name);
      },
    );
    final router = GoRouter(
      initialLocation: Routes.splash,
      routes: [
        GoRoute(
          path: Routes.splash,
          builder: (_, _) => const SplashScreen(),
        ),
        GoRoute(path: Routes.home, builder: (_, _) => destination('home')),
        GoRoute(
          path: Routes.onboarding,
          builder: (_, _) => destination('onboarding'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            InMemorySettingsRepository(
              AppSettings(
                defaultCurrency: 'PKR',
                onboardingDone: onboardingDone,
              ),
            ),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduceMotion,
            ),
            child: child!,
          ),
          routerConfig: router,
        ),
      ),
    );
    return visited;
  }

  testWidgets('first launch plays the full sequence, then onboarding', (
    tester,
  ) async {
    final visited = await pumpSplash(tester, onboardingDone: false);

    expect(find.byType(AnimatedLogo), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2000));
    expect(visited, isEmpty);
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expect(visited, ['onboarding']);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('onboarding'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('returning launch plays the short sequence, then home', (
    tester,
  ) async {
    final visited = await pumpSplash(tester, onboardingDone: true);

    await tester.pump(const Duration(milliseconds: 450));
    expect(visited, isEmpty);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(visited, ['home']);
  });

  testWidgets('reduce motion fades out in 200 ms', (tester) async {
    final visited = await pumpSplash(
      tester,
      onboardingDone: false,
      reduceMotion: true,
    );

    await tester.pump(const Duration(milliseconds: 150));
    expect(visited, isEmpty);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(visited, ['onboarding']);
  });

  testWidgets('navigates once and leaves nothing pending', (tester) async {
    final visited = await pumpSplash(tester, onboardingDone: true);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 3));

    expect(visited, ['home']);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('disposing early does not navigate', (tester) async {
    final visited = await pumpSplash(tester, onboardingDone: false);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));

    expect(visited, isEmpty);
  });

  testWidgets('is labelled Lapse for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpSplash(tester, onboardingDone: false);

    expect(find.bySemanticsLabel('Lapse'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    handle.dispose();
  });

  for (final brightness in Brightness.values) {
    testWidgets('renders every phase in ${brightness.name} mode', (
      tester,
    ) async {
      await pumpSplash(
        tester,
        onboardingDone: false,
        brightness: brightness,
      );
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(
        scaffold.backgroundColor,
        brightness == Brightness.dark
            ? const Color(0xFF0B0B12)
            : const Color(0xFFFAFAFC),
      );

      for (final step in [300, 700, 300, 150, 250, 300]) {
        await tester.pump(Duration(milliseconds: step));
        expect(tester.takeException(), isNull);
      }
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
    });
  }
}
