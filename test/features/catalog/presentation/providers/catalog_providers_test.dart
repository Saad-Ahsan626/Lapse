import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/catalog/domain/entities/catalog_service.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';

import '../../../../helpers/fake_catalog_repository.dart';
import '../../../../helpers/subscription_fixtures.dart';
import '../../catalog_test_services.dart';

ProviderContainer catalogContainer({
  List<Subscription> subscriptions = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      catalogRepositoryProvider.overrideWithValue(
        FakeCatalogRepository(sampleCatalog),
      ),
      subscriptionsProvider.overrideWith((ref) => Stream.value(subscriptions)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

List<String> keysOf(AsyncValue<List<CatalogService>> value) => [
  for (final service in value.requireValue) service.key,
];

void main() {
  test('results react to the query', () async {
    final container = catalogContainer()
      ..listen(catalogResultsProvider, (_, _) {});

    expect(container.read(catalogResultsProvider).isLoading, isTrue);
    await container.read(catalogProvider.future);

    expect(keysOf(container.read(catalogResultsProvider)).take(3), [
      'netflix',
      'spotify',
      'youtube_premium',
    ]);

    container.read(catalogQueryProvider.notifier).set('  yt');
    expect(container.read(catalogQueryProvider), 'yt');
    expect(keysOf(container.read(catalogResultsProvider)), [
      'youtube_premium',
    ]);

    container.read(catalogQueryProvider.notifier).clear();
    expect(container.read(catalogQueryProvider), '');
    expect(
      container.read(catalogResultsProvider).requireValue,
      hasLength(sampleCatalog.length),
    );
  });

  test('popular services are sorted by rank', () async {
    final container = catalogContainer();
    await container.read(catalogProvider.future);

    expect(keysOf(container.read(popularServicesProvider)), [
      'netflix',
      'spotify',
      'youtube_premium',
      'disney_plus',
      'chatgpt_plus',
    ]);
  });

  test('services are found by key once loaded', () async {
    final container = catalogContainer()
      ..listen(catalogServiceByKeyProvider('hulu'), (_, _) {});

    expect(container.read(catalogServiceByKeyProvider('hulu')), isNull);
    await container.read(catalogProvider.future);

    expect(container.read(catalogServiceByKeyProvider('hulu'))?.name, 'Hulu');
    expect(container.read(catalogServiceByKeyProvider('nope')), isNull);
  });

  test('recent custom subscriptions: distinct, newest first, max 3', () async {
    final base = subscriptionFixture();
    DateTime day(int d) => DateTime.utc(2026, 9, d);
    final subscriptions = [
      base.copyWith(id: '1', name: 'Gym', createdAt: day(1)),
      base.copyWith(
        id: '2',
        name: 'Netflix',
        catalogKey: 'netflix',
        createdAt: day(9),
      ),
      base.copyWith(id: '3', name: 'gym ', createdAt: day(8)),
      base.copyWith(id: '4', name: 'Newspaper', createdAt: day(5)),
      base.copyWith(id: '5', name: 'Cloud host', createdAt: day(7)),
      base.copyWith(id: '6', name: 'Magazine', createdAt: day(3)),
    ];
    final container = catalogContainer(subscriptions: subscriptions)
      ..listen(recentCustomSubscriptionsProvider, (_, _) {});

    expect(container.read(recentCustomSubscriptionsProvider), isEmpty);
    await container.read(subscriptionsProvider.future);

    expect(
      container.read(recentCustomSubscriptionsProvider).map((s) => s.id),
      ['3', '5', '4'],
    );
  });
}
