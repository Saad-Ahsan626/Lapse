import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/widgets/inputs/lapse_select_field.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('LapseSelectField', () {
    testWidgets('shows the hint when no value is set', (tester) async {
      await tester.pumpLapse(
        LapseSelectField<String>(
          value: null,
          options: const ['Music', 'Fitness'],
          labelOf: (v) => v,
          onChanged: (_) {},
          hint: 'Choose',
          label: 'Category',
        ),
      );

      expect(find.text('Choose'), findsOneWidget);
      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    });

    testWidgets('opens a sheet and returns the tapped option', (tester) async {
      String? picked;
      await tester.pumpLapse(
        LapseSelectField<String>(
          value: 'Music',
          options: const ['Music', 'Fitness'],
          labelOf: (v) => v,
          onChanged: (v) => picked = v,
          sheetTitle: 'Pick category',
        ),
      );

      await tester.tap(find.text('Music'));
      await tester.pumpAndSettle();

      expect(find.text('Pick category'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.text('Fitness'));
      await tester.pumpAndSettle();

      expect(picked, 'Fitness');
      expect(find.text('Pick category'), findsNothing);
    });

    testWidgets('shows the error text', (tester) async {
      await tester.pumpLapse(
        LapseSelectField<String>(
          value: null,
          options: const ['Music'],
          labelOf: (v) => v,
          onChanged: (_) {},
          errorText: 'Pick one',
        ),
      );

      expect(find.text('Pick one'), findsOneWidget);
    });
  });
}
