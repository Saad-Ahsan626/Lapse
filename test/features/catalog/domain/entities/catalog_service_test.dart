import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/catalog/domain/entities/catalog_service.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';

Map<String, Object?> validJson() => {
  'key': 'netflix',
  'name': 'Netflix',
  'category': 'Entertainment',
  'initials': 'NF',
  'brandColor': '#E50914',
  'defaultPeriod': 'monthly',
  'cancelUrl': 'https://www.netflix.com/cancelplan',
  'popularRank': 1,
  'aliases': ['nflx'],
};

void main() {
  test('parses a complete entry', () {
    final service = CatalogService.fromJson(validJson());

    expect(service.key, 'netflix');
    expect(service.name, 'Netflix');
    expect(service.category, 'Entertainment');
    expect(service.initials, 'NF');
    expect(service.brandColor, 0xFFE50914);
    expect(service.defaultPeriod, BillingPeriod.monthly);
    expect(service.cancelUrl, 'https://www.netflix.com/cancelplan');
    expect(service.popularRank, 1);
    expect(service.aliases, ['nflx']);
    expect(service.logoAsset, 'assets/logos/netflix.svg');
  });

  test('optional fields may be missing', () {
    final json = validJson()
      ..remove('cancelUrl')
      ..remove('popularRank')
      ..remove('aliases');

    final service = CatalogService.fromJson(json);

    expect(service.cancelUrl, isNull);
    expect(service.popularRank, isNull);
    expect(service.aliases, isEmpty);
  });

  test('lower-case colours parse', () {
    final json = validJson()..['brandColor'] = '#1db954';

    expect(CatalogService.fromJson(json).brandColor, 0xFF1DB954);
  });

  test('a bad colour is rejected', () {
    for (final colour in ['E50914', '#E5091', '#GGGGGG', '#E50914FF']) {
      final json = validJson()..['brandColor'] = colour;
      expect(
        () => CatalogService.fromJson(json),
        throwsFormatException,
        reason: colour,
      );
    }
  });

  test('an unknown period is rejected', () {
    final json = validJson()..['defaultPeriod'] = 'fortnightly';

    expect(() => CatalogService.fromJson(json), throwsFormatException);
  });

  test('a missing required field is rejected', () {
    for (final field in [
      'key',
      'name',
      'category',
      'initials',
      'brandColor',
      'defaultPeriod',
    ]) {
      final json = validJson()..remove(field);
      expect(
        () => CatalogService.fromJson(json),
        throwsFormatException,
        reason: field,
      );
    }
  });

  test('wrongly typed optional fields are rejected', () {
    expect(
      () => CatalogService.fromJson(validJson()..['popularRank'] = '1'),
      throwsFormatException,
    );
    expect(
      () => CatalogService.fromJson(validJson()..['aliases'] = [1]),
      throwsFormatException,
    );
    expect(
      () => CatalogService.fromJson(validJson()..['cancelUrl'] = 3),
      throwsFormatException,
    );
  });

  test('equality is by key', () {
    final a = CatalogService.fromJson(validJson());
    final b = CatalogService.fromJson(validJson()..['name'] = 'Other');

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a.toString(), contains('netflix'));
  });
}
