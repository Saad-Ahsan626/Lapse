import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/catalog/domain/entities/catalog_service.dart';
import 'package:lapse/features/catalog/domain/services/catalog_search.dart';

import '../../catalog_test_services.dart';

List<String> keys(List<CatalogService> services) => [
  for (final service in services) service.key,
];

void main() {
  const search = CatalogSearch();

  test('"net" puts Netflix first', () {
    final results = search.search(sampleCatalog, 'net');

    expect(keys(results), ['netflix', 'internet_archive']);
  });

  test('an exact name beats a prefix', () {
    final services = [
      catalogServiceFixture('hulu_live', 'Hulu Live'),
      catalogServiceFixture('hulu', 'Hulu'),
    ];

    expect(keys(search.search(services, 'HULU')), ['hulu', 'hulu_live']);
  });

  test('"yt" finds YouTube Premium through its alias', () {
    expect(keys(search.search(sampleCatalog, 'yt')), ['youtube_premium']);
  });

  test('"plus" finds services with a word starting with plus', () {
    final results = keys(search.search(sampleCatalog, 'plus'));

    expect(results, [
      'apple_tv_plus',
      'chatgpt_plus',
      'disney_plus',
      'paramount_plus',
      'dropbox',
    ]);
  });

  test('"+" is read as plus', () {
    expect(keys(search.search(sampleCatalog, 'disney+')), ['disney_plus']);
  });

  test('accents are ignored', () {
    expect(keys(search.search(sampleCatalog, 'deezér')), ['deezer']);
    expect(keys(search.search(sampleCatalog, 'ÁUDIBLE')), ['audible']);
  });

  test('contains matches still count', () {
    expect(keys(search.search(sampleCatalog, 'ify')), ['spotify']);
    expect(keys(search.search(sampleCatalog, 'enai')), ['chatgpt_plus']);
  });

  test('an empty query returns popular order then A-Z', () {
    final expected = [
      'netflix',
      'spotify',
      'youtube_premium',
      'disney_plus',
      'chatgpt_plus',
      'apple_tv_plus',
      'audible',
      'deezer',
      'dropbox',
      'hulu',
      'paramount_plus',
      'internet_archive',
    ];

    expect(keys(search.search(sampleCatalog, '')), expected);
    expect(keys(search.search(sampleCatalog, '   ')), expected);
  });

  test('no match returns an empty list', () {
    expect(search.search(sampleCatalog, 'zzzz'), isEmpty);
  });

  test('popular is sorted by rank', () {
    expect(keys(search.popular(sampleCatalog)), [
      'netflix',
      'spotify',
      'youtube_premium',
      'disney_plus',
      'chatgpt_plus',
    ]);
  });
}
