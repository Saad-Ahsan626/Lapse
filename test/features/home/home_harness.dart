import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/features/catalog/data/logo_availability.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/home/presentation/screens/home_screen.dart';
import 'package:lapse/features/reminders/application/reminder_providers.dart';
import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_notification_gateway.dart';
import '../../helpers/fake_subscription_repository.dart';
import '../../helpers/in_memory_settings_repository.dart';

final homeNow = DateTime(2026, 9, 18, 19);

class HomeHarness {
  final List<String> pushed = [];
}

class SilentSubscriptionRepository extends FakeSubscriptionRepository {
  final StreamController<List<Subscription>> _never =
      StreamController<List<Subscription>>();

  @override
  Stream<List<Subscription>> watchAll() => _never.stream;
}

class FailingSubscriptionRepository extends FakeSubscriptionRepository {
  @override
  Stream<List<Subscription>> watchAll() =>
      Stream<List<Subscription>>.error(StateError('database unavailable'));
}

Future<HomeHarness> pumpHome(
  WidgetTester tester, {
  List<Subscription> subscriptions = const [],
  FakeSubscriptionRepository? repository,
  String? userName = 'Ayesha',
  DateTime? now,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  FakeNotificationGateway? gateway,
  InMemorySettingsRepository? settings,
}) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final harness = HomeHarness();
  final repo = (repository ?? FakeSubscriptionRepository())
    ..seed(subscriptions);
  final clockTime = now ?? homeNow;

  Widget page(GoRouterState state) {
    harness.pushed.add(state.uri.toString());
    return Scaffold(body: Text('Visited ${state.uri}'));
  }

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/settings', builder: (_, state) => page(state)),
      GoRoute(path: '/subscriptions', builder: (_, state) => page(state)),
      GoRoute(path: '/subscription/:id', builder: (_, state) => page(state)),
      GoRoute(
        path: '/reminders/permission',
        builder: (_, state) => page(state),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          settings ??
              InMemorySettingsRepository(
                AppSettings(defaultCurrency: 'PKR', userName: userName),
              ),
        ),
        notificationGatewayProvider.overrideWithValue(
          gateway ?? FakeNotificationGateway(),
        ),
        subscriptionRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(() => clockTime),
        catalogRepositoryProvider.overrideWithValue(
          FakeCatalogRepository(const []),
        ),
        logoAvailabilityProvider.overrideWith(
          (ref) async => LogoAvailability({}),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
      ),
    ),
  );
  await settleHome(tester);
  return harness;
}

Future<void> settleHome(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
