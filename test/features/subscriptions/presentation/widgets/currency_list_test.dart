import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/currency_info.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/currency_list.dart';

import '../../../../helpers/pump_app.dart';

Future<List<String>> _pumpList(
  WidgetTester tester, {
  String selected = 'USD',
  String? pinned,
  String query = '',
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  final picked = <String>[];
  await tester.pumpLapse(
    SizedBox(
      height: 600,
      child: CurrencyList(
        selected: selected,
        pinned: pinned,
        query: query,
        onSelected: picked.add,
      ),
    ),
    brightness: brightness,
    textScale: textScale,
  );
  return picked;
}

void main() {
  group('ordering', () {
    test('keeps the popular order without a pin', () {
      expect(
        CurrencyList.ordered().map((c) => c.code),
        supportedCurrencies.map((c) => c.code),
      );
    });

    test('moves the pinned currency first', () {
      final codes = CurrencyList.ordered(pinned: 'GBP').map((c) => c.code);
      expect(codes.take(3), ['GBP', 'PKR', 'USD']);
      expect(codes.where((c) => c == 'GBP'), hasLength(1));
    });

    test('adds an unsupported pinned or selected currency', () {
      final codes = CurrencyList.ordered(
        pinned: 'DKK',
        selected: 'PLN',
      ).map((c) => c.code).toList();
      expect(codes.take(2), ['DKK', 'PLN']);
      expect(codes.length, supportedCurrencies.length + 2);
    });

    test('filters by name, code and exact symbol, keeping the pin first', () {
      expect(CurrencyList.filter('rupee').map((c) => c.code), [
        'PKR',
        'INR',
        'LKR',
        'NPR',
      ]);
      expect(
        CurrencyList.filter('rupee', pinned: 'INR').first.code,
        'INR',
      );
      expect(CurrencyList.filter('eur').map((c) => c.code), ['EUR']);
      expect(CurrencyList.filter('£').map((c) => c.code), ['GBP']);
      expect(CurrencyList.filter('zzz'), isEmpty);
      expect(CurrencyList.filter('  '), hasLength(supportedCurrencies.length));
    });
  });

  testWidgets('shows name and code rows and reports taps', (tester) async {
    final picked = await _pumpList(tester);

    expect(find.text('US dollar'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    await tester.tap(find.text('Euro'));
    expect(picked, ['EUR']);
  });

  testWidgets('the selected row is marked with a check and semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pumpList(tester, selected: 'EUR');

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Euro, EUR')),
      isSemantics(isButton: true, isSelected: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('US dollar, USD')),
      isSemantics(isButton: true, isSelected: false, hasTapAction: true),
    );
    handle.dispose();
  });

  testWidgets('the pinned currency is the first row', (tester) async {
    await _pumpList(tester, pinned: 'INR', selected: 'INR');

    final inr = tester.getTopLeft(find.text('Indian rupee')).dy;
    final pkr = tester.getTopLeft(find.text('Pakistani rupee')).dy;
    expect(inr, lessThan(pkr));
  });

  testWidgets('shows an empty message when nothing matches', (tester) async {
    await _pumpList(tester, query: 'zzz');

    expect(find.text('No currency matches “zzz”'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('text scale 2 in ${brightness.name} does not overflow', (
      tester,
    ) async {
      await _pumpList(tester, brightness: brightness, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  }
}
