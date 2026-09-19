import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/theme/tokens/lapse_colors.dart';
import 'package:lapse/core/widgets/layout/lapse_row_group.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('LapseRowGroup', () {
    Finder dividers() => find.byWidgetPredicate(
      (w) => w is ColoredBox && w.color == LapseColors.light.border,
    );

    testWidgets('inserts a divider between each child', (tester) async {
      await tester.pumpLapse(
        const LapseRowGroup(children: [Text('A'), Text('B'), Text('C')]),
      );

      expect(dividers(), findsNWidgets(2));
      expect(tester.getSize(dividers().first).height, 1);
    });

    testWidgets('has no divider with a single child', (tester) async {
      await tester.pumpLapse(const LapseRowGroup(children: [Text('A')]));

      expect(dividers(), findsNothing);
    });
  });
}
