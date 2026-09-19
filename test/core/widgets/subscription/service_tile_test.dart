import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/widgets/subscription/service_tile.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('ServiceTile.initialsFor', () {
    test('two words → first letter of each', () {
      expect(ServiceTile.initialsFor('Spotify Premium'), 'SP');
      expect(ServiceTile.initialsFor('iCloud+ 200GB'), 'I2');
    });

    test('one word → first two letters', () {
      expect(ServiceTile.initialsFor('Netflix'), 'NE');
      expect(ServiceTile.initialsFor('X'), 'X');
    });

    test('ignores punctuation and empty input', () {
      expect(ServiceTile.initialsFor('  Disney+  '), 'DI');
      expect(ServiceTile.initialsFor(''), '?');
      expect(ServiceTile.initialsFor('+++'), '?');
    });
  });

  testWidgets('falls back to initials when there is no logo', (tester) async {
    await tester.pumpLapse(const ServiceTile(name: 'Gym membership'));

    expect(find.text('GM'), findsOneWidget);
  });

  testWidgets('prefers explicit initials', (tester) async {
    await tester.pumpLapse(
      const ServiceTile(
        name: 'Netflix',
        initials: 'NF',
        brandColor: Color(0xFFE50914),
      ),
    );

    expect(find.text('NF'), findsOneWidget);
  });

  testWidgets('has the service name as its semantics label', (tester) async {
    await tester.pumpLapse(const ServiceTile(name: 'Spotify', initials: 'SP'));

    expect(
      tester.getSemantics(find.byType(ServiceTile)),
      matchesSemantics(label: 'Spotify', isImage: true),
    );
  });

  testWidgets('very dark brand colours get a border in dark mode', (
    tester,
  ) async {
    BoxBorder? borderFor(WidgetTester tester) =>
        (tester
                    .widget<Container>(
                      find.descendant(
                        of: find.byType(ServiceTile),
                        matching: find.byType(Container),
                      ),
                    )
                    .decoration!
                as BoxDecoration)
            .border;

    await tester.pumpLapse(
      const ServiceTile(
        name: 'Notion',
        initials: 'NT',
        brandColor: Color(0xFF000000),
      ),
      brightness: Brightness.dark,
    );
    await tester.pumpAndSettle();
    expect(borderFor(tester), isNotNull);

    await tester.pumpLapse(
      const ServiceTile(
        name: 'Netflix',
        initials: 'NF',
        brandColor: Color(0xFFE50914),
      ),
      brightness: Brightness.dark,
    );
    await tester.pumpAndSettle();
    expect(borderFor(tester), isNull);

    await tester.pumpLapse(
      const ServiceTile(
        name: 'Notion',
        initials: 'NT',
        brandColor: Color(0xFF000000),
      ),
    );
    await tester.pumpAndSettle();
    expect(borderFor(tester), isNull);
  });
}
