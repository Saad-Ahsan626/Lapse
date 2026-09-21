import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/theme/tokens/lapse_typography.dart';
import 'package:lapse/core/widgets/motion/count_up_text.dart';

import '../../../helpers/pump_app.dart';

String _format(int v) => 'Rs $v';

Widget _counter(int value) => CountUpText(value: value, format: _format);

void main() {
  group('CountUpText', () {
    testWidgets('counts up from zero to the final value', (tester) async {
      await tester.pumpLapse(_counter(1000));

      expect(find.text('Rs 0'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      final middle = tester.widget<Text>(find.byType(Text)).data!;
      expect(middle, isNot('Rs 0'));
      expect(middle, isNot('Rs 1000'));

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Rs 1000'), findsOneWidget);
    });

    testWidgets('uses tabular figures', (tester) async {
      await tester.pumpLapse(
        const CountUpText(
          value: 10,
          format: _format,
          style: TextStyle(fontSize: 20),
        ),
      );

      final style = tester.widget<Text>(find.byType(Text)).style!;
      expect(style.fontFeatures, LapseTypography.tabular);
      expect(style.fontSize, 20);
    });

    testWidgets('shows the final value instantly with reduce motion', (
      tester,
    ) async {
      await tester.pumpLapse(_counter(1000), reduceMotion: true);

      expect(find.text('Rs 1000'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('animates from the old value to the new one', (tester) async {
      await tester.pumpLapse(_counter(100));
      await tester.pumpAndSettle();
      expect(find.text('Rs 100'), findsOneWidget);

      await tester.pumpLapse(_counter(200));
      expect(find.text('Rs 100'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      final middle = tester.widget<Text>(find.byType(Text)).data!;
      final shown = int.parse(middle.substring(3));
      expect(shown, greaterThan(100));
      expect(shown, lessThan(200));

      await tester.pumpAndSettle();
      expect(find.text('Rs 200'), findsOneWidget);
    });

    testWidgets('semantics label is the final value', (tester) async {
      await tester.pumpLapse(_counter(1000));

      expect(
        tester.getSemantics(find.byType(CountUpText)),
        matchesSemantics(label: 'Rs 1000'),
      );
      await tester.pumpAndSettle();
    });
  });
}
