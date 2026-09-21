import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';

import '../helpers/accessibility.dart';
import '../helpers/in_memory_settings_repository.dart';

typedef A11yPump =
    Future<void> Function(
      WidgetTester tester,
      Brightness brightness,
      double textScale,
    );

void usePhone(WidgetTester tester, {Size size = const Size(390, 844)}) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> frames(WidgetTester tester, [int count = 10]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget themedApp({
  required RouterConfig<Object> router,
  required Brightness brightness,
  required double textScale,
  bool reduceMotion = false,
}) => MaterialApp.router(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
  routerConfig: router,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: reduceMotion,
    ),
    child: child!,
  ),
);

Future<GoRouter> pumpRoutes(
  WidgetTester tester, {
  required List<RouteBase> routes,
  required String initialLocation,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  List<Override> overrides = const [],
  bool reduceMotion = false,
}) async {
  final router = GoRouter(initialLocation: initialLocation, routes: routes);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          InMemorySettingsRepository(),
        ),
        ...overrides,
      ],
      child: themedApp(
        router: router,
        brightness: brightness,
        textScale: textScale,
        reduceMotion: reduceMotion,
      ),
    ),
  );
  return router;
}

void accessibilityTests(String name, A11yPump pump) {
  for (final brightness in Brightness.values) {
    testWidgets('$name meets the guidelines in ${brightness.name}', (
      tester,
    ) async {
      await pump(tester, brightness, 1);
      await expectAccessible(tester);
    });
  }
  testWidgets('$name fits at text scale 2', (tester) async {
    await pump(tester, Brightness.light, 2);
    expect(tester.takeException(), isNull);
  });
}
