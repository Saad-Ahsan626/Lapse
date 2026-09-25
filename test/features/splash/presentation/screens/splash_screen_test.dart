import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/splash/presentation/screens/splash_screen.dart';
import 'package:lapse/features/splash/presentation/widgets/splash_painter.dart';

import '../../../../helpers/in_memory_settings_repository.dart';

Future<void> _play(WidgetTester tester, int milliseconds) async {
  for (var ms = 0; ms < milliseconds; ms += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

SplashPainter _painterOf(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(find.byKey(const ValueKey('splash-canvas')))
            .painter!
        as SplashPainter;

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

    expect(find.byKey(const ValueKey('splash-canvas')), findsOneWidget);
    await _play(tester, 2000);
    expect(visited, isEmpty);
    expect(find.byType(SplashScreen), findsOneWidget);

    await _play(tester, 200);
    expect(visited, ['onboarding']);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('onboarding'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('returning launch plays the same full sequence, then home', (
    tester,
  ) async {
    final visited = await pumpSplash(tester, onboardingDone: true);
    final painter = _painterOf(tester);
    expect(painter.timeline.isFull, isTrue);

    await _play(tester, 2000);
    expect(visited, isEmpty);
    expect(painter.elapsedMs, greaterThan(1500));

    await _play(tester, 200);
    expect(visited, ['home']);
  });

  testWidgets('reduce motion fades out in 200 ms', (tester) async {
    final visited = await pumpSplash(
      tester,
      onboardingDone: false,
      reduceMotion: true,
    );

    await _play(tester, 150);
    expect(visited, isEmpty);

    await _play(tester, 150);
    expect(visited, ['onboarding']);
  });

  testWidgets('navigates once and leaves nothing pending', (tester) async {
    final visited = await pumpSplash(tester, onboardingDone: true);

    await _play(tester, 2300);
    await tester.pump(const Duration(seconds: 3));

    expect(visited, ['home']);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('disposing early does not navigate', (tester) async {
    final visited = await pumpSplash(tester, onboardingDone: false);
    await _play(tester, 500);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));

    expect(visited, isEmpty);
  });

  testWidgets('is labelled Lapse for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpSplash(tester, onboardingDone: false);

    expect(find.bySemanticsLabel('Lapse'), findsOneWidget);

    await _play(tester, 2500);
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
        await _play(tester, step);
        expect(tester.takeException(), isNull);
      }
      await _play(tester, 700);
      expect(find.byType(SplashScreen), findsNothing);
    });
  }

  testWidgets('animates by repainting only, never rebuilding', (tester) async {
    await pumpSplash(tester, onboardingDone: false);
    await tester.pump();
    await tester.pump();

    final canvas = find.byKey(const ValueKey('splash-canvas'));
    final first = tester.widget<CustomPaint>(canvas);
    final painter = first.painter! as SplashPainter;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.ancestor(of: canvas, matching: find.byType(RepaintBoundary)).first,
    );
    expect(boundary, isNotNull);

    var repaints = 0;
    void count() => repaints++;
    final element = tester.element(canvas);
    final ticker = painter.elapsedMs;
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (painter.elapsedMs > ticker) count();
      expect(identical(tester.widget<CustomPaint>(canvas), first), isTrue);
      expect(identical(tester.element(canvas), element), isTrue);
    }
    expect(repaints, 10);
    expect(painter.isDisposed, isFalse);

    await _play(tester, 2500);
    expect(find.byType(SplashScreen), findsNothing);
    expect(painter.isDisposed, isTrue);
  });

  testWidgets('holds frame 0 until the first frame is presented', (
    tester,
  ) async {
    final visited = await pumpSplash(tester, onboardingDone: false);
    final painter = _painterOf(tester);

    expect(painter.isWarm, isTrue);
    expect(painter.elapsedMs, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(painter.elapsedMs, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(painter.elapsedMs, 0);

    await tester.pump(const Duration(milliseconds: 16));
    expect(painter.elapsedMs, closeTo(16, 0.01));
    expect(visited, isEmpty);
    await _play(tester, 2500);
  });

  testWidgets('a stalled frame slows the animation instead of skipping', (
    tester,
  ) async {
    final visited = await pumpSplash(tester, onboardingDone: false);
    final painter = _painterOf(tester);
    await _play(tester, 300);
    final before = painter.elapsedMs;
    expect(before, greaterThan(0));

    await tester.pump(const Duration(milliseconds: 900));

    final step = painter.elapsedMs - before;
    expect(step, greaterThan(0));
    expect(step, lessThanOrEqualTo(32.001));
    expect(visited, isEmpty);

    await _play(tester, 2500);
    expect(visited, ['onboarding']);
  });
}
