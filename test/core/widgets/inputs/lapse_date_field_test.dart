import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/widgets/inputs/lapse_date_field.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('LapseDateField', () {
    String format(CalendarDate d) => 'day ${d.toIso()}';

    testWidgets('shows the formatted value and trailing widget', (
      tester,
    ) async {
      await tester.pumpLapse(
        LapseDateField(
          label: 'Next billing date',
          value: CalendarDate(2026, 9, 19),
          format: format,
          onChanged: (_) {},
          trailing: const Text('Tomorrow'),
        ),
      );

      expect(find.text('day 2026-09-19'), findsOneWidget);
      expect(find.text('NEXT BILLING DATE'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Next billing date, day 2026-09-19'),
        findsOneWidget,
      );
    });

    testWidgets('shows a placeholder when empty', (tester) async {
      await tester.pumpLapse(
        LapseDateField(value: null, format: format, onChanged: (_) {}),
      );

      expect(find.text('Pick a date'), findsOneWidget);
    });

    testWidgets('opens a date picker and returns the chosen date', (
      tester,
    ) async {
      CalendarDate? picked;
      await tester.pumpLapse(
        LapseDateField(
          value: CalendarDate(2026, 9, 19),
          format: format,
          onChanged: (d) => picked = d,
        ),
      );

      await tester.tap(find.text('day 2026-09-19'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('21'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(picked, CalendarDate(2026, 9, 21));
    });

    testWidgets('shows the error text', (tester) async {
      await tester.pumpLapse(
        LapseDateField(
          value: null,
          format: format,
          onChanged: (_) {},
          errorText: 'Pick a billing date',
        ),
      );

      expect(find.text('Pick a billing date'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });
}
