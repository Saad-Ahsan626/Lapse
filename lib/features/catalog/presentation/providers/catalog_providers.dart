import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:lapse/features/catalog/data/catalog_repository_impl.dart';
import 'package:lapse/features/catalog/data/logo_availability.dart';
import 'package:lapse/features/catalog/domain/entities/catalog_service.dart';
import 'package:lapse/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:lapse/features/catalog/domain/services/catalog_search.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_query_controller.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';

const catalogAssetPath = 'assets/catalog/services.json';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepositoryImpl(
    loadJson: () => rootBundle.loadString(catalogAssetPath),
  ),
);

final catalogProvider = FutureProvider<List<CatalogService>>(
  (ref) => ref.watch(catalogRepositoryProvider).all(),
);

final catalogSearchProvider = Provider<CatalogSearch>(
  (ref) => const CatalogSearch(),
);

final catalogQueryProvider = NotifierProvider<CatalogQueryController, String>(
  CatalogQueryController.new,
);

final catalogResultsProvider = Provider<AsyncValue<List<CatalogService>>>((
  ref,
) {
  final search = ref.watch(catalogSearchProvider);
  final query = ref.watch(catalogQueryProvider);
  return ref
      .watch(catalogProvider)
      .whenData((all) => search.search(all, query));
});

final popularServicesProvider = Provider<AsyncValue<List<CatalogService>>>((
  ref,
) {
  final search = ref.watch(catalogSearchProvider);
  return ref.watch(catalogProvider).whenData(search.popular);
});

final ProviderFamily<CatalogService?, String> catalogServiceByKeyProvider =
    Provider.family<CatalogService?, String>((ref, key) {
      final services = ref.watch(catalogProvider).value;
      if (services == null) {
        return null;
      }
      for (final service in services) {
        if (service.key == key) {
          return service;
        }
      }
      return null;
    });

final recentCustomSubscriptionsProvider = Provider<List<Subscription>>((ref) {
  final subscriptions = ref.watch(subscriptionsProvider).value;
  if (subscriptions == null) {
    return const [];
  }
  final custom = subscriptions.where((s) => s.catalogKey == null).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final seen = <String>{};
  final recent = <Subscription>[];
  for (final subscription in custom) {
    if (seen.add(subscription.name.trim().toLowerCase())) {
      recent.add(subscription);
      if (recent.length == 3) {
        break;
      }
    }
  }
  return List.unmodifiable(recent);
});

final logoAvailabilityProvider = FutureProvider<LogoAvailability>(
  (ref) => LogoAvailability.load(rootBundle),
);
