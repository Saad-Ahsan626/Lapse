import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/widgets/inputs/lapse_text_field.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('shows leading and trailing widgets', (tester) async {
    await tester.pumpLapse(
      const LapseTextField(
        hint: 'Search services',
        leading: Icon(Icons.search_rounded),
        trailing: Icon(Icons.cancel_rounded),
      ),
    );

    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    expect(find.text('Search services'), findsOneWidget);
  });

  testWidgets('a tappable suffix calls back and is labelled', (tester) async {
    var taps = 0;
    await tester.pumpLapse(
      LapseTextField(
        prefixText: 'Rs',
        suffixText: 'PKR',
        onSuffixTap: () => taps++,
        suffixSemanticLabel: 'Change currency',
      ),
    );

    await tester.tap(find.text('PKR'));
    await tester.pump();

    expect(taps, 1);
    expect(find.bySemanticsLabel('Change currency'), findsOneWidget);
    final size = tester.getSize(
      find.byKey(const ValueKey('lapse-text-field-suffix')),
    );
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('a plain suffix is only text', (tester) async {
    await tester.pumpLapse(const LapseTextField(suffixText: 'PKR'));

    expect(find.text('PKR'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('lapse-text-field-suffix')),
      findsNothing,
    );
  });

  testWidgets('shows the error text under the field', (tester) async {
    await tester.pumpLapse(
      const LapseTextField(hint: 'Price', errorText: 'Enter a price'),
    );

    expect(find.text('Enter a price'), findsOneWidget);
  });
}
