import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/savings/presentation/celebration_result.dart';
import 'package:lapse/features/savings/presentation/widgets/celebration_sheet.dart';

import '../../../helpers/pump_app.dart';

const _body =
    "That's your third cancellation this year. "
    'It stays in the Cancelled tab in case you want it back.';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    Money saved = const Money(778800, 'PKR'),
    bool reduceMotion = false,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpLapse(
      CelebrationSheet(
        headline: 'iCloud+ 200GB cancelled',
        saved: saved,
        body: _body,
      ),
      reduceMotion: reduceMotion,
      brightness: brightness,
      textScale: textScale,
    );
  }

  testWidgets('shows the copy from the design', (tester) async {
    await pumpSheet(tester);
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(SavingsBadge), findsOneWidget);
    expect(find.byType(ConfettiBurst), findsOneWidget);
    expect(find.text('iCloud+ 200GB cancelled'), findsOneWidget);
    expect(find.text('Rs 7,788'), findsOneWidget);
    expect(find.text('saved per year'), findsOneWidget);
    expect(find.text('Nice move.'), findsOneWidget);
    expect(find.text(_body), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.bySemanticsLabel('Rs 7,788'), findsOneWidget);
  });

  testWidgets('Nice move is a header', (tester) async {
    await pumpSheet(tester);
    await tester.pump(const Duration(seconds: 2));

    final semantics = tester.getSemantics(find.text('Nice move.'));
    expect(semantics.flagsCollection.isHeader, isTrue);
  });

  testWidgets('the amount counts up', (tester) async {
    await pumpSheet(tester);

    expect(find.text('Rs 0'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Rs 0'), findsNothing);
    expect(find.text('Rs 7,788'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Rs 7,788'), findsOneWidget);
  });

  testWidgets('the amount is instant under reduce motion', (tester) async {
    await pumpSheet(tester, reduceMotion: true);

    expect(find.text('Rs 7,788'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('hides the amount when nothing is saved', (tester) async {
    await pumpSheet(tester, saved: const Money.zero('PKR'));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('saved per year'), findsNothing);
    expect(find.text('Rs 0'), findsNothing);
    expect(find.text('Nice move.'), findsOneWidget);
  });

  for (final entry in {
    'Done': CelebrationResult.done,
    'Undo': CelebrationResult.undo,
  }.entries) {
    testWidgets('${entry.key} pops ${entry.value.name}', (tester) async {
      CelebrationResult? result;
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpLapse(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<CelebrationResult>(
                MaterialPageRoute(
                  builder: (_) => const Scaffold(
                    body: CelebrationSheet(
                      headline: 'Spotify cancelled',
                      saved: Money(358800, 'PKR'),
                      body: 'Body',
                    ),
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();

      expect(result, entry.value);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('fits at text scale 2 in ${brightness.name}', (tester) async {
      await pumpSheet(tester, brightness: brightness, textScale: 2);
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Undo'), 200);
      expect(find.text('Undo').hitTestable(), findsOneWidget);
    });
  }
}
