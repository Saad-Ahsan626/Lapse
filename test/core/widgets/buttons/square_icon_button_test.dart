import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/widgets/buttons/square_icon_button.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('SquareIconButton', () {
    testWidgets('is 44x44 with a 22px icon and calls onPressed', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpLapse(
        SquareIconButton(
          icon: Icons.tune_rounded,
          semanticLabel: 'Settings',
          onPressed: () => taps++,
        ),
      );

      expect(tester.getSize(find.byType(InkWell)), const Size(44, 44));
      expect(tester.widget<Icon>(find.byType(Icon)).size, 22);

      await tester.tap(find.byType(SquareIconButton));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('exposes a labelled button with a tooltip', (tester) async {
      await tester.pumpLapse(
        SquareIconButton(
          icon: Icons.tune_rounded,
          semanticLabel: 'Settings',
          onPressed: () {},
        ),
      );

      expect(
        tester.getSemantics(find.byType(SquareIconButton)),
        matchesSemantics(
          label: 'Settings',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(find.byTooltip('Settings'), findsOneWidget);
    });

    testWidgets('is disabled without onPressed', (tester) async {
      await tester.pumpLapse(
        const SquareIconButton(
          icon: Icons.tune_rounded,
          semanticLabel: 'Settings',
          onPressed: null,
        ),
      );

      expect(
        tester.getSemantics(find.byType(SquareIconButton)),
        matchesSemantics(
          label: 'Settings',
          isButton: true,
          hasEnabledState: true,
        ),
      );
    });
  });
}
