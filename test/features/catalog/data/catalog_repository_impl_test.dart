import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/catalog/data/catalog_repository_impl.dart';

Map<String, Object?> entry(String key, {String colour = '#000000'}) => {
  'key': key,
  'name': key.toUpperCase(),
  'category': 'Other',
  'initials': 'XX',
  'brandColor': colour,
  'defaultPeriod': 'monthly',
  'aliases': <String>[],
};

void main() {
  test('loads once and caches', () async {
    var calls = 0;
    final repository = CatalogRepositoryImpl(
      loadJson: () async {
        calls++;
        return jsonEncode({
          'version': 1,
          'services': [entry('a'), entry('b')],
        });
      },
    );

    final first = await repository.all();
    final second = await repository.all();

    expect(calls, 1);
    expect(first.map((s) => s.key), ['a', 'b']);
    expect(identical(first, second), isTrue);
    expect((await repository.byKey('b'))?.key, 'b');
    expect(await repository.byKey('missing'), isNull);
    expect(calls, 1);
  });

  test('skips invalid entries and records them', () async {
    final repository = CatalogRepositoryImpl(
      loadJson: () async => jsonEncode({
        'version': 1,
        'services': [
          entry('good'),
          entry('bad', colour: 'red'),
          'not an object',
          entry('good'),
          entry('fine'),
        ],
      }),
    );

    final services = await repository.all();

    expect(services.map((s) => s.key), ['good', 'fine']);
    expect(repository.skipped, hasLength(3));
    expect(repository.skipped.first, startsWith('services[1]'));
  });

  test('a failed load can be retried', () async {
    var calls = 0;
    final repository = CatalogRepositoryImpl(
      loadJson: () async {
        calls++;
        if (calls == 1) {
          throw StateError('asset missing');
        }
        return jsonEncode({'version': 1, 'services': <Object>[]});
      },
    );

    await expectLater(repository.all(), throwsStateError);
    expect(await repository.all(), isEmpty);
  });

  test('a malformed root is a FormatException', () async {
    final repository = CatalogRepositoryImpl(loadJson: () async => '[]');

    await expectLater(repository.all(), throwsFormatException);
  });
}
