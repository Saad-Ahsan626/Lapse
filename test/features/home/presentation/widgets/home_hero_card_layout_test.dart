import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/home/presentation/widgets/home_hero_card.dart';
import 'package:lapse/features/subscriptions/domain/services/spending_summary.dart';

import '../../../../helpers/pump_app.dart';

SpendingSummary _summary(int monthMinor) => SpendingSummary(
  thisMonth: Money(monthMinor, 'PKR'),
  yearly: Money(monthMinor * 12, 'PKR'),
  savedPerYear: const Money(0, 'PKR'),
);

Widget _hero(int monthMinor) => CustomScrollView(
  slivers: [
    SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverToBoxAdapter(
        child: HomeHeroCard(summary: _summary(monthMinor)),
      ),
    ),
    const SliverToBoxAdapter(child: SizedBox(height: 400)),
  ],
);

void main() {
  testWidgets('the count-up relays out only its own line', (tester) async {
    await tester.pumpLapse(_hero(100), wrapInScaffold: false);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpLapse(_hero(987654300), wrapInScaffold: false);
    await tester.pump(const Duration(milliseconds: 16));

    final layouts = <String>[];
    final previous = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) layouts.add(message);
    };
    debugPrintLayouts = true;
    try {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    } finally {
      debugPrintLayouts = false;
      debugPrint = previous;
    }

    bool laidOut(String type) =>
        layouts.any((line) => line.contains('out') && line.contains(type));

    expect(laidOut('RenderParagraph'), isTrue);
    expect(laidOut('RenderSliver'), isFalse);
    expect(laidOut('RenderFlex'), isFalse);
    expect(laidOut('RenderStack'), isFalse);
    expect(layouts.where((line) => line.contains('RenderWrap')), isEmpty);
  });

  testWidgets('a wide amount still scales down to fit', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpLapse(_hero(99999999999900), wrapInScaffold: false);
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    final fitted = tester.getSize(find.byType(FittedBox));
    final line = HomeHeroCard.heroLineHeight(
      const TextStyle(fontSize: 40, height: 1.1),
      TextScaler.noScaling,
    );
    expect(fitted.height, line);
    expect(
      tester.getSize(find.byType(RichText).at(1)).width,
      greaterThan(fitted.width),
    );
  });
}
