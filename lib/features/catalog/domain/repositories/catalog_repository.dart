import 'package:lapse/features/catalog/domain/entities/catalog_service.dart';

abstract interface class CatalogRepository {
  Future<List<CatalogService>> all();

  Future<CatalogService?> byKey(String key);
}
