import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/catalog/data/catalog_repository_impl.dart';

const categories = {
  'Entertainment',
  'Music',
  'Productivity',
  'AI',
  'Storage',
  'Design',
  'Developer',
  'Education',
  'Health',
  'Gaming',
  'Security',
  'News & reading',
  'Other',
};

void main() {
  test('the bundled services.json is complete and consistent', () async {
    final repository = CatalogRepositoryImpl(
      loadJson: () => File('assets/catalog/services.json').readAsString(),
    );

    final services = await repository.all();

    expect(repository.skipped, isEmpty);
    expect(services.length, greaterThanOrEqualTo(45));

    final keys = services.map((s) => s.key).toList();
    expect(keys.toSet(), hasLength(keys.length));
    final keyPattern = RegExp(r'^[a-z0-9_]+$');
    for (final key in keys) {
      expect(keyPattern.hasMatch(key), isTrue, reason: key);
    }

    final ranks = [
      for (final s in services)
        if (s.popularRank != null) s.popularRank!,
    ]..sort();
    expect(ranks, List.generate(11, (i) => i + 1));

    for (final service in services) {
      expect(categories, contains(service.category), reason: service.key);
      expect(
        service.initials.length,
        inInclusiveRange(1, 2),
        reason: service.key,
      );
      final url = service.cancelUrl;
      if (url != null) {
        expect(url, startsWith('https://'), reason: service.key);
      }
    }
    expect(services.firstWhere((s) => s.key == 'disney_plus').initials, 'D+');
  });
}
