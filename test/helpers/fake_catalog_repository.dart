import 'package:lapse/features/catalog/domain/entities/catalog_service.dart';
import 'package:lapse/features/catalog/domain/repositories/catalog_repository.dart';

class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository(this.services, {this.fail = false});

  final List<CatalogService> services;
  bool fail;
  int calls = 0;

  @override
  Future<List<CatalogService>> all() async {
    calls++;
    if (fail) throw StateError('catalog unavailable');
    return services;
  }

  @override
  Future<CatalogService?> byKey(String key) async {
    for (final service in await all()) {
      if (service.key == key) return service;
    }
    return null;
  }
}
