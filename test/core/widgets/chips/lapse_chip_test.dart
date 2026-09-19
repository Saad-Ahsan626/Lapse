import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/theme/tokens/lapse_colors.dart';
import 'package:lapse/core/widgets/chips/lapse_chip.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('LapseChip', () {
    const c = LapseColors.light;

    BoxDecoration decoration(WidgetTester tester) =>
        tester
                .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                .decoration!
            as BoxDecoration;

    TextStyle style(WidgetTester tester, String label) =>
        tester.widget<Text>(find.text(label)).style!;

    testWidgets('default selected chip uses primary without a border', (
      tester,
    ) async {
      await tester.pumpLapse(
        LapseChip(label: 'Monthly', selected: true, onTap: () {}),
      );

      expect(decoration(tester).color, c.primary);
      expect(decoration(tester).border, isNull);
      expect(style(tester, 'Monthly').color, c.onPrimary);
    });

    testWidgets('default unselected chip uses surfaceMuted', (tester) async {
      await tester.pumpLapse(
        LapseChip(label: 'Weekly', selected: false, onTap: () {}),
      );

      expect(decoration(tester).color, c.surfaceMuted);
      expect(style(tester, 'Weekly').color, c.onSurfaceMuted);
    });

    testWidgets('trial tone selected uses trial colours', (tester) async {
      await tester.pumpLapse(
        LapseChip(
          label: '7d',
          selected: true,
          tone: LapseChipTone.trial,
          onTap: () {},
        ),
      );

      expect(decoration(tester).color, c.trial);
      expect(style(tester, '7d').color, c.onTrial);
      expect(style(tester, '7d').fontWeight, FontWeight.w700);
    });

    testWidgets('onTint unselected chip is surface with a border', (
      tester,
    ) async {
      await tester.pumpLapse(
        LapseChip(label: '3d', selected: false, onTint: true, onTap: () {}),
      );

      expect(decoration(tester).color, c.surface);
      expect(decoration(tester).border, Border.all(color: c.inputBorder));
      expect(style(tester, '3d').color, c.onSurfaceMuted);
      expect(style(tester, '3d').fontWeight, FontWeight.w600);
    });

    testWidgets('shows a check when selected with showCheck', (tester) async {
      await tester.pumpLapse(
        LapseChip(
          label: '1 day',
          selected: true,
          showCheck: true,
          onTap: () {},
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('compact chips are narrower', (tester) async {
      await tester.pumpLapse(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LapseChip(
              key: const ValueKey('regular'),
              label: '7 days',
              selected: true,
              showCheck: true,
              onTap: () {},
            ),
            LapseChip(
              key: const ValueKey('compact'),
              label: '7 days',
              selected: true,
              showCheck: true,
              compact: true,
              onTap: () {},
            ),
          ],
        ),
      );

      expect(
        tester.getSize(find.byKey(const ValueKey('compact'))).width,
        lessThan(tester.getSize(find.byKey(const ValueKey('regular'))).width),
      );
    });
  });
}
