import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/widgets/inputs/lapse_row_field.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('LapseRowField', () {
    testWidgets('editable row has a right-aligned inline field', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'netflix.com');
      addTearDown(controller.dispose);
      await tester.pumpLapse(
        LapseRowField(label: 'Cancel link', controller: controller),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textAlign, TextAlign.end);
      expect(find.text('Cancel link'), findsOneWidget);
      expect(tester.getSize(find.byType(LapseRowField)).height, 53);

      await tester.enterText(find.byType(TextField), 'hbo.com');
      expect(controller.text, 'hbo.com');
    });

    testWidgets('tappable row shows value and calls onTap', (tester) async {
      var taps = 0;
      await tester.pumpLapse(
        LapseRowField(
          label: 'Category',
          value: 'Music',
          onTap: () => taps++,
          trailing: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
      );

      expect(find.byType(TextField), findsNothing);
      expect(find.text('Music'), findsOneWidget);

      await tester.tap(find.text('Category'));
      await tester.pump();

      expect(taps, 1);
      expect(find.bySemanticsLabel('Category, Music'), findsOneWidget);
    });

    testWidgets('multiline row puts the label above the field', (
      tester,
    ) async {
      await tester.pumpLapse(
        LapseRowField(label: 'Notes', onChanged: (_) {}, maxLines: 4),
      );

      final label = tester.getRect(find.text('Notes'));
      final field = tester.getRect(find.byType(TextField));
      expect(field.top, greaterThanOrEqualTo(label.bottom));
      expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 4);
    });

    testWidgets('shows the error text under the row', (tester) async {
      await tester.pumpLapse(
        LapseRowField(
          label: 'Cancel link',
          onChanged: (_) {},
          errorText: 'Enter a valid link',
        ),
      );

      expect(find.text('Enter a valid link'), findsOneWidget);
    });
  });
}
