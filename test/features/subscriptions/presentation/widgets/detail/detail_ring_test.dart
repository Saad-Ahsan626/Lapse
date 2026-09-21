import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/core/domain/urgency.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_detail.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/detail/detail_ring.dart';

import '../../../../../helpers/pump_app.dart';
import '../../../../../helpers/subscription_fixtures.dart';

SubscriptionDetail detailFixture({
  int daysLeft = 3,
  DetailRingState state = DetailRingState.upcoming,
  double progress = 0.1,
}) => SubscriptionDetail(
  subscription: subscriptionFixture(),
  totalPaid: const Money.zero('PKR'),
  chargeCount: 0,
  daysLeft: daysLeft,
  urgency: Urgency.fromDaysLeft(daysLeft),
  progress: progress,
  ringState: state,
);

void main() {
  CountdownRing ring(WidgetTester tester) =>
      tester.widget<CountdownRing>(find.byType(CountdownRing));

  testWidgets('upcoming uses the urgency colour and the cycle progress', (
    tester,
  ) async {
    await tester.pumpLapse(DetailRing(detail: detailFixture()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('3'), findsOneWidget);
    expect(find.text('days left'), findsOneWidget);
    expect(ring(tester).size, 180);
    expect(ring(tester).strokeRatio, 0.075);
    expect(ring(tester).progress, 0.1);
    expect(ring(tester).color, LapseColors.light.warning);
    final label = tester.widget<Text>(find.text('days left'));
    expect(label.style!.color, LapseColors.light.warningText);
  });

  testWidgets('a far charge uses the primary colour', (tester) async {
    await tester.pumpLapse(DetailRing(detail: detailFixture(daysLeft: 20)));
    await tester.pump(const Duration(seconds: 1));

    expect(ring(tester).color, LapseColors.light.primary);
    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('today fills the ring in urgent red', (tester) async {
    await tester.pumpLapse(
      DetailRing(
        detail: detailFixture(daysLeft: 0, state: DetailRingState.today),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Today'), findsOneWidget);
    expect(ring(tester).progress, 1);
    expect(ring(tester).color, LapseColors.light.urgent);
  });

  testWidgets('overdue shows Due', (tester) async {
    await tester.pumpLapse(
      DetailRing(
        detail: detailFixture(daysLeft: -1, state: DetailRingState.overdue),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Due'), findsOneWidget);
    expect(ring(tester).progress, 1);
  });

  testWidgets('cancelled is a grey full ring in dark mode too', (
    tester,
  ) async {
    await tester.pumpLapse(
      DetailRing(detail: detailFixture(state: DetailRingState.cancelled)),
      brightness: Brightness.dark,
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Cancelled'), findsOneWidget);
    expect(ring(tester).progress, 1);
    expect(ring(tester).color, LapseColors.dark.inkSubtle);
  });

  testWidgets('fits at text scale 2 with reduce motion', (tester) async {
    await tester.pumpLapse(
      DetailRing(detail: detailFixture(daysLeft: 365)),
      textScale: 2,
      reduceMotion: true,
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(DetailRing)), const Size(180, 180));
  });
}
