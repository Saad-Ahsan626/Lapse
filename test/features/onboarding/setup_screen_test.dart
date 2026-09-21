import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/providers/storage_providers.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/features/onboarding/presentation/screens/setup_screen.dart';
import 'package:lapse/features/onboarding/presentation/widgets/reminder_time_field.dart';
import 'package:lapse/features/onboarding/presentation/widgets/setup_progress_bar.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/currency_list.dart';

import '../../helpers/in_memory_settings_repository.dart';

Future<InMemorySettingsRepository> _pump(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final settings = InMemorySettingsRepository(
    AppSettings(defaultCurrency: 'INR'),
  );
  final router = GoRouter(
    initialLocation: Routes.onboarding,
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push(Routes.setup),
            child: const Text('Slides'),
          ),
        ),
        routes: [
          GoRoute(path: 'setup', builder: (_, _) => const SetupScreen()),
          GoRoute(
            path: 'permission',
            builder: (_, _) => const Scaffold(body: Text('Permission page')),
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
        deviceCountryProvider.overrideWithValue('IN'),
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
  await tester.tap(find.text('Slides'));
  await _settle(tester);
  return settings;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _continue(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
  await _settle(tester);
}

void main() {
  testWidgets('renders the design copy and sections', (tester) async {
    await _pump(tester);

    expect(find.byType(SetupProgressBar), findsOneWidget);
    expect(find.text(SetupScreen.title), findsOneWidget);
    expect(find.text(SetupScreen.subtitle), findsOneWidget);
    expect(find.text('CURRENCY'), findsOneWidget);
    expect(find.text('Search currency'), findsOneWidget);
    expect(find.text('DEFAULT REMINDER TIME'), findsOneWidget);
    expect(find.byType(ReminderTimeField), findsOneWidget);
    expect(find.text(SetupScreen.timeCaption), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('device currency is preselected and shown first', (
    tester,
  ) async {
    await _pump(tester);

    final list = tester.widget<CurrencyList>(find.byType(CurrencyList));
    expect(list.selected, 'INR');
    expect(list.pinned, 'INR');

    final inr = tester.getTopLeft(find.text('Indian rupee')).dy;
    final pkr = tester.getTopLeft(find.text('Pakistani rupee')).dy;
    expect(inr, lessThan(pkr));
    final check = tester.getCenter(find.byIcon(Icons.check_circle_rounded));
    expect(
      check.dy,
      closeTo(tester.getCenter(find.text('Indian rupee')).dy, 12),
    );
  });

  testWidgets('the list card shows about five rows and scrolls inside', (
    tester,
  ) async {
    await _pump(tester);

    final height = tester.getSize(find.byType(CurrencyList)).height;
    expect(height, closeTo(CurrencyList.rowExtent * 5, 12));
    expect(find.text('Mexican peso'), findsNothing);

    await tester.drag(find.byType(CurrencyList), const Offset(0, -3000));
    await _settle(tester);
    expect(find.text('Mexican peso'), findsOneWidget);
    expect(find.text(SetupScreen.title), findsOneWidget);
  });

  testWidgets('search narrows the list and the selection is saved', (
    tester,
  ) async {
    final settings = await _pump(tester);

    await tester.enterText(find.byType(TextField), 'euro');
    await _settle(tester);
    expect(find.text('US dollar'), findsNothing);
    expect(find.text('Euro'), findsOneWidget);
    expect(
      tester.getSize(find.byType(CurrencyList)).height,
      closeTo(CurrencyList.rowExtent * 5, 12),
    );

    await tester.tap(find.text('Euro'));
    await _settle(tester);
    expect(settings.load().defaultCurrency, 'INR');

    await _continue(tester);

    expect(settings.load().defaultCurrency, 'EUR');
    expect(find.text('Permission page'), findsOneWidget);
  });

  testWidgets('AM/PM and the time are saved as minutes', (tester) async {
    final settings = await _pump(tester);

    await tester.tap(find.text('PM'));
    await _settle(tester);
    await _continue(tester);

    expect(settings.load().reminderMinutes, 21 * 60);
    expect(settings.load().onboardingDone, isFalse);
  });

  testWidgets('Continue pushes permission and back returns to setup', (
    tester,
  ) async {
    final settings = await _pump(tester);

    await _continue(tester);
    expect(find.text('Permission page'), findsOneWidget);
    expect(settings.load().defaultCurrency, 'INR');
    expect(settings.load().reminderMinutes, 540);

    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    await navigator.maybePop();
    await _settle(tester);
    expect(find.byType(SetupScreen), findsOneWidget);

    await navigator.maybePop();
    await _settle(tester);
    expect(find.text('Slides'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('text scale 2 in ${brightness.name} does not overflow', (
      tester,
    ) async {
      await _pump(tester, brightness: brightness, textScale: 2);
      expect(tester.takeException(), isNull);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -2000),
      );
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(ReminderTimeField), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      await _continue(tester);
      expect(find.text('Permission page'), findsOneWidget);
    });
  }
}
