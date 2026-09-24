import 'package:lapse/features/catalog/domain/entities/catalog_service.dart';

class CatalogSearch {
  const CatalogSearch();

  static const Map<String, String> _folds = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ñ': 'n',
    'ç': 'c',
    '+': ' plus',
  };

  static final RegExp _spaces = RegExp(r'\s+');
  static final RegExp _wordSeparators = RegExp(r'[\s\-_.&/]+');

  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final char in input.toLowerCase().split('')) {
      buffer.write(_folds[char] ?? char);
    }
    return buffer.toString().replaceAll(_spaces, ' ').trim();
  }

  List<CatalogService> search(List<CatalogService> services, String query) {
    final needle = normalize(query);
    if (needle.isEmpty) {
      final rest = _sortedByName(
        services.where((s) => s.popularRank == null),
      );
      return [...popular(services), ...rest];
    }
    final scored = <(CatalogService, String, int)>[];
    for (final service in services) {
      final name = normalize(service.name);
      final score = _score(service, name, needle);
      if (score != null) {
        scored.add((service, name, score));
      }
    }
    scored.sort((a, b) {
      final byScore = a.$3.compareTo(b.$3);
      return byScore != 0 ? byScore : a.$2.compareTo(b.$2);
    });
    return [for (final entry in scored) entry.$1];
  }

  List<CatalogService> popular(List<CatalogService> services) =>
      services.where((s) => s.popularRank != null).toList()
        ..sort((a, b) => a.popularRank!.compareTo(b.popularRank!));

  static List<CatalogService> _sortedByName(
    Iterable<CatalogService> services,
  ) {
    final named = [
      for (final service in services) (service, normalize(service.name)),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final entry in named) entry.$1];
  }

  int? _score(CatalogService service, String name, String needle) {
    if (name == needle) {
      return 0;
    }
    if (name.startsWith(needle)) {
      return 1;
    }
    if (name.split(_wordSeparators).any((w) => w.startsWith(needle))) {
      return 2;
    }
    final aliases = service.aliases.map(normalize).toList();
    if (aliases.any((a) => a.startsWith(needle))) {
      return 3;
    }
    if (name.contains(needle)) {
      return 4;
    }
    if (aliases.any((a) => a.contains(needle))) {
      return 5;
    }
    return null;
  }
}
