import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/features/catalog/data/logo_availability.dart';
import 'package:lapse/features/catalog/domain/entities/catalog_service.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

import '../../../../../helpers/fake_catalog_repository.dart';
import '../../../../../helpers/fake_subscription_repository.dart';
import '../../../../../helpers/in_memory_settings_repository.dart';
import '../../../../../helpers/subscription_fixtures.dart';

final listNow = DateTime(2026, 9, 18, 10);

const settle = Duration(milliseconds: 400);

List<Subscription> seededSubscriptions() => [
  subscriptionFixture(
    id: 'spotify',
    nextBillingDate: CalendarDate(2026, 10, 1),
  ),
  subscriptionFixture(
    id: 'chatgpt',
    name: 'ChatGPT Plus',
    priceMinor: 20000,
    nextBillingDate: CalendarDate(2026, 9, 21),
  ),
  subscriptionFixture(
    id: 'notion',
    name: 'Notion Plus',
    priceMinor: 900000,
    period: BillingPeriod.yearly,
    nextBillingDate: CalendarDate(2026, 10, 5),
  ),
  subscriptionFixture(
    id: 'disney',
    name: 'Disney Plus',
    priceMinor: 64900,
    isTrial: true,
    nextBillingDate: CalendarDate(2026, 9, 30),
  ),
  subscriptionFixture(
    id: 'hulu',
    name: 'Hulu',
    nextBillingDate: CalendarDate(2026, 9, 25),
  ).copyWith(
    status: SubscriptionStatus.cancelled,
    cancelledAt: DateTime(2026, 9, 12, 12),
  ),
];

class RecordedPushes {
  final List<String> locations = [];
}

extension PumpList on WidgetTester {
  void usePhoneSize() {
    view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(view.reset);
  }

  Future<void> pumpListScreen(
    Widget screen, {
    required FakeSubscriptionRepository repository,
    RecordedPushes? pushes,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    List<CatalogService> catalog = const [],
    List<Override> overrides = const [],
    bool pushed = false,
  }) async {
    final recorder = pushes ?? RecordedPushes();
    final router = GoRouter(
      initialLocation: pushed ? '/' : '/subscriptions',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push('/subscriptions'),
                child: const Text('Open list'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/subscriptions',
          builder: (context, state) => screen,
        ),
        GoRoute(
          path: '/subscription/:id',
          builder: (context, state) {
            final location = state.uri.toString();
            if (recorder.locations.isEmpty ||
                recorder.locations.last != location) {
              recorder.locations.add(location);
            }
            return Scaffold(body: Text('Route $location'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            InMemorySettingsRepository(),
          ),
          subscriptionRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => listNow),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository(catalog),
          ),
          logoAvailabilityProvider.overrideWith(
            (ref) async => LogoAvailability({}),
          ),
          ...overrides,
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          routerConfig: router,
        ),
      ),
    );
    await pump();
    await pump(settle);
    if (pushed) {
      await tap(find.text('Open list'));
      await pump();
      await pump(settle);
    }
  }
}
