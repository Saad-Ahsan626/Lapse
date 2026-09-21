import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/subscriptions/presentation/links/cancel_links.dart';
import 'package:lapse/features/subscriptions/presentation/links/link_opener.dart';
import 'package:lapse/features/subscriptions/presentation/links/url_launcher_link_opener.dart';
import 'package:lapse/features/subscriptions/presentation/providers/link_opener_provider.dart';

import '../../../../helpers/subscription_fixtures.dart';

class _RecordingOpener implements LinkOpener {
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

void main() {
  group('cancelUriFor', () {
    Uri? uriFor(String? url) =>
        cancelUriFor(subscriptionFixture(cancelUrl: url));

    test('parses https and http links', () {
      expect(
        uriFor('https://www.netflix.com/cancelplan'),
        Uri.parse('https://www.netflix.com/cancelplan'),
      );
      expect(uriFor('http://example.com'), Uri.parse('http://example.com'));
    });

    test('adds https to a bare host', () {
      expect(
        uriFor(' netflix.com/cancel '),
        Uri.parse('https://netflix.com/cancel'),
      );
    });

    test('rejects empty, missing and non-web links', () {
      expect(uriFor(null), isNull);
      expect(uriFor('   '), isNull);
      expect(uriFor('mailto:help@example.com'), isNull);
      expect(uriFor('ftp://example.com/file'), isNull);
      expect(uriFor('https://'), isNull);
    });
  });

  test('howToCancelSearchUri encodes the query', () {
    final uri = howToCancelSearchUri(' Disney+ & Hulu ');

    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/search');
    expect(
      uri.queryParameters['q'],
      'how to cancel Disney+ & Hulu subscription',
    );
    expect(uri.toString(), contains('Disney%2B+%26+Hulu'));
  });

  test(
    'linkOpenerProvider defaults to url_launcher and can be overridden',
    () async {
      final real = ProviderContainer();
      addTearDown(real.dispose);
      expect(real.read(linkOpenerProvider), isA<UrlLauncherLinkOpener>());

      final fake = _RecordingOpener();
      final container = ProviderContainer(
        overrides: [linkOpenerProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final uri = Uri.parse('https://example.com');

      expect(await container.read(linkOpenerProvider).open(uri), isTrue);
      expect(fake.opened, [uri]);
    },
  );
}
