import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('chips stay 36 tall with a 48 tap area', (tester) async {
    var taps = 0;
    await tester.pumpLapse(
      LapseChip(label: 'Monthly', selected: false, onTap: () => taps++),
    );

    final chip = find.byType(LapseChip);
    final visual = find.descendant(
      of: chip,
      matching: find.byType(AnimatedContainer),
    );
    expect(tester.getSize(visual).height, Sizes.chip);
    expect(tester.getSize(chip).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(chip).height, Sizes.minTap);

    await tester.tapAt(tester.getTopLeft(chip) + const Offset(20, 2));
    await tester.pump(const Duration(milliseconds: 300));
    expect(taps, 1);
  });

  testWidgets('icon buttons draw 44 and answer taps across 48', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpLapse(
      SquareIconButton(
        icon: Icons.settings_rounded,
        semanticLabel: 'Settings',
        onPressed: () => taps++,
      ),
    );

    final button = find.byType(SquareIconButton);
    expect(tester.getSize(button), const Size.square(Sizes.minTap));
    expect(
      tester.getSize(
        find.descendant(of: button, matching: find.byType(InkWell)),
      ),
      const Size.square(Sizes.iconButton),
    );

    await tester.tapAt(tester.getTopLeft(button) + const Offset(1, 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(taps, 1);
  });

  testWidgets('segments fill the full 48 height', (tester) async {
    await tester.pumpLapse(
      SizedBox(
        width: 200,
        child: SegmentedTabs<int>(
          tabs: const [
            SegmentedTab(value: 0, label: 'AM'),
            SegmentedTab(value: 1, label: 'PM'),
          ],
          selected: 0,
          onChanged: (_) {},
        ),
      ),
    );

    final handle = tester.ensureSemantics();
    final node = tester.getSemantics(find.bySemanticsLabel('PM'));
    expect(node.rect.height, greaterThanOrEqualTo(Sizes.minTap));
    expect(node.rect.width, greaterThanOrEqualTo(Sizes.minTap));
    handle.dispose();
  });
}
