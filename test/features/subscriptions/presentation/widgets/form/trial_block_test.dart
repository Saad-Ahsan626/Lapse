import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_state.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/trial_block.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  late TextEditingController price;

  setUp(() => price = TextEditingController());
  tearDown(() => price.dispose());

  Future<void> pumpBlock(
    WidgetTester tester, {
    bool reduceMotion = false,
  }) async {
    var trial = false;
    await tester.pumpLapse(
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 360,
          child: TrialBlock(
            state: SubscriptionFormState(
              name: 'Netflix',
              currency: 'PKR',
              period: BillingPeriod.monthly,
              startDate: CalendarDate(2026, 9, 18),
              isTrial: trial,
            ),
            priceController: price,
            onTrialChanged: (value) => setState(() => trial = value),
            onTrialLengthChanged: (_) {},
            onPriceChanged: (_) {},
          ),
        ),
      ),
      reduceMotion: reduceMotion,
    );
  }

  double fieldsOpacity(WidgetTester tester) {
    final fades = tester.widgetList<FadeTransition>(
      find.ancestor(
        of: find.text('TRIAL LENGTH'),
        matching: find.byType(FadeTransition),
      ),
    );
    return fades.fold(1, (value, fade) => value * fade.opacity.value);
  }

  double blockHeight(WidgetTester tester) =>
      tester.getSize(find.byType(AnimatedSize)).height;

  testWidgets('fields fade in over 120ms after the 280ms height', (
    tester,
  ) async {
    await pumpBlock(tester);
    final closed = blockHeight(tester);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(fieldsOpacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 140));
    expect(blockHeight(tester), greaterThan(closed));
    expect(fieldsOpacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 140));
    final open = blockHeight(tester);
    expect(fieldsOpacity(tester), closeTo(0, 0.01));

    await tester.pump(const Duration(milliseconds: 60));
    expect(blockHeight(tester), open);
    expect(fieldsOpacity(tester), inExclusiveRange(0, 1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(fieldsOpacity(tester), 1);
  });

  testWidgets('the reveal timing comes from Motion tokens', (tester) async {
    expect(TrialBlock.revealDuration, const Duration(milliseconds: 400));
    final curve = TrialBlock.revealCurve as Interval;
    expect(curve.begin, 0.7);
    expect(curve.end, 1);
  });

  testWidgets('fields show at once with reduce motion', (tester) async {
    await pumpBlock(tester, reduceMotion: true);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(find.text('TRIAL LENGTH'), findsOneWidget);
    expect(fieldsOpacity(tester), 1);
  });
}
