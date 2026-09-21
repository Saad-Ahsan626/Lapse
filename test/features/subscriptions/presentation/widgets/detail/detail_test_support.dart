import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/features/catalog/data/logo_availability.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/presentation/links/link_opener.dart';
import 'package:lapse/features/subscriptions/presentation/providers/link_opener_provider.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';
import 'package:lapse/features/subscriptions/presentation/screens/subscription_detail_screen.dart';

import '../../../../../helpers/fake_catalog_repository.dart';
import '../../../../../helpers/fake_subscription_repository.dart';
import '../../../../../helpers/in_memory_settings_repository.dart';
import '../../../../../helpers/test_clock.dart';

final detailToday = CalendarDate(2026, 9, 18);

class FakeLinkOpener implements LinkOpener {
  final List<Uri> opened = [];
  bool succeeds = true;

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return succeeds;
  }
}

Charge chargeFixture(String id, CalendarDate on, {int minor = 29900}) => Charge(
  id: id,
  subscriptionId: 'sub-1',
  amount: Money(minor, 'PKR'),
  chargedOn: on,
);

Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class DetailHarness {
  DetailHarness() : repository = FakeSubscriptionRepository();

  final FakeSubscriptionRepository repository;
  final FakeLinkOpener opener = FakeLinkOpener();
  late GoRouter router;

  String get location => router.state.uri.toString();

  Future<void> pump(
    WidgetTester tester, {
    String id = 'sub-1',
    bool pushed = true,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    Size size = const Size(400, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    router = GoRouter(
      initialLocation: pushed ? Routes.home : Routes.detail(id),
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/subscription/:id',
          builder: (_, state) =>
              SubscriptionDetailScreen(id: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) =>
                  Scaffold(body: Text('edit ${state.pathParameters['id']}')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(repository),
          settingsRepositoryProvider.overrideWithValue(
            InMemorySettingsRepository(),
          ),
          clockProvider.overrideWithValue(
            TestClock(DateTime(2026, 9, 18, 10)).call,
          ),
          newIdProvider.overrideWithValue(SequentialIds().call),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository(const []),
          ),
          logoAvailabilityProvider.overrideWith((ref) => LogoAvailability({})),
          linkOpenerProvider.overrideWithValue(opener),
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
    await tester.pump();
    if (pushed) {
      unawaited(router.push<void>(Routes.detail(id)));
    }
    await settle(tester);
  }
}
