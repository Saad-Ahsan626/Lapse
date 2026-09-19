import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lapse/features/catalog/domain/entities/catalog_service.dart';
import 'package:lapse/features/catalog/domain/repositories/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl({required Future<String> Function() loadJson})
    : _loadJson = loadJson;

  final Future<String> Function() _loadJson;
  final List<String> skipped = [];
  Future<List<CatalogService>>? _cache;

  @override
  Future<List<CatalogService>> all() => _cache ??= _load();

  @override
  Future<CatalogService?> byKey(String key) async {
    for (final service in await all()) {
      if (service.key == key) {
        return service;
      }
    }
    return null;
  }

  Future<List<CatalogService>> _load() async {
    final String raw;
    try {
      raw = await _loadJson();
    } catch (_) {
      _cache = null;
      rethrow;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Catalog root must be an object');
    }
    final entries = decoded['services'];
    if (entries is! List) {
      throw const FormatException('Catalog "services" must be a list');
    }
    final services = <CatalogService>[];
    final keys = <String>{};
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      try {
        if (entry is! Map<String, Object?>) {
          throw const FormatException('Entry must be an object');
        }
        final service = CatalogService.fromJson(entry);
        if (!keys.add(service.key)) {
          throw FormatException('Duplicate key "${service.key}"');
        }
        services.add(service);
      } on FormatException catch (error) {
        final message = 'services[$i]: ${error.message}';
        skipped.add(message);
        if (kDebugMode) {
          debugPrint('Catalog entry skipped: $message');
        }
      }
    }
    return List.unmodifiable(services);
  }
}
