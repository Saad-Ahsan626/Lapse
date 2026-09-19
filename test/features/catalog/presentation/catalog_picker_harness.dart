import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/core/theme/app_theme.dart';
import 'package:lapse/features/catalog/data/logo_availability.dart';
import 'package:lapse/features/catalog/domain/entities/catalog_service.dart';
import 'package:lapse/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:lapse/features/catalog/presentation/catalog_picker.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

import '../../../helpers/fake_catalog_repository.dart';
import '../../../helpers/in_memory_settings_repository.dart';
import '../catalog_test_services.dart';

const popularNames = [
  'Netflix',
  'Spotify',
  'YouTube Premium',
  'Prime Video',
  'ChatGPT',
  'Canva',
  'Disney+',
  'iCloud+',
  'Notion',
  'Figma',
  'Apple One',
];

final List<CatalogService> pickerCatalog = [
  for (var i = 0; i < popularNames.length; i++)
    catalogServiceFixture(
      popularNames[i].toLowerCase().replaceAll(RegExp('[^a-z]'), '_'),
      popularNames[i],
      popularRank: i + 1,
    ),
  catalogServiceFixture('spotify_family', 'Spotify Family'),
  catalogServiceFixture('deezer', 'Deezer'),
  catalogServiceFixture('audible', 'Audible'),
];

List<Override> pickerOverrides({
  CatalogRepository? repository,
  List<Subscription> recent = const [],
}) => [
  catalogRepositoryProvider.overrideWithValue(
    repository ?? FakeCatalogRepository(pickerCatalog),
  ),
  logoAvailabilityProvider.overrideWith((ref) async => LogoAvailability({})),
  recentCustomSubscriptionsProvider.overrideWithValue(recent),
];

class PickerLauncher extends StatelessWidget {
  const PickerLauncher({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => showCatalogPicker(context),
        child: const Text('Open picker'),
      ),
    ),
  );
}

Future<List<Uri>> pumpPickerApp(
  WidgetTester tester, {
  Widget home = const PickerLauncher(),
  List<Override>? overrides,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final visited = <Uri>[];
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/subscription/new',
        builder: (_, state) {
          visited.add(state.uri);
          return const Scaffold(body: Text('New subscription form'));
        },
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
        ...overrides ?? pickerOverrides(),
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
  await tester.pump();
  return visited;
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> openPicker(WidgetTester tester) async {
  await tester.tap(find.text('Open picker'));
  await settle(tester);
}
