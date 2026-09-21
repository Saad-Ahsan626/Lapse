import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/currency_list.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/currency_picker_sheet.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  Future<List<String?>> open(WidgetTester tester) async {
    final results = <String?>[];
    await tester.pumpLapse(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              results.add(await showCurrencyPicker(context, 'PKR')),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('uses the shared currency list', (tester) async {
    await open(tester);

    expect(find.byType(CurrencyList), findsOneWidget);
    expect(find.text('Pakistani rupee'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('search narrows the list and picking pops the code', (
    tester,
  ) async {
    final results = await open(tester);

    await tester.enterText(find.byType(TextField), 'euro');
    await tester.pumpAndSettle();
    expect(find.text('US dollar'), findsNothing);

    await tester.tap(find.text('Euro'));
    await tester.pumpAndSettle();

    expect(results, ['EUR']);
    expect(find.byType(CurrencyPickerSheet), findsNothing);
  });

  test('filter still delegates to the shared list', () {
    expect(CurrencyPickerSheet.filter('usd').single.code, 'USD');
  });
}
